import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/emergency_transaction.dart';
import '../services/asset_service.dart';
import '../services/emergency_fund_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formats.dart';
import '../utils/debounce_utils.dart';
import '../widgets/state_placeholders.dart';

part 'emergency_fund_list_screen_actions.dart';
part 'emergency_fund_list_screen_dialogs.dart';
part 'emergency_fund_list_screen_list_ui.dart';

/// 비상금 지갑 리스트 화면 (자산 리스트 UI와 유사)
class EmergencyFundListScreen extends StatefulWidget {
  final String accountName;
  const EmergencyFundListScreen({super.key, required this.accountName});

  @override
  State<EmergencyFundListScreen> createState() =>
      _EmergencyFundListScreenState();
}

class _EmergencyFundListScreenState extends State<EmergencyFundListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 220),
  );
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  String? _error;
  List<EmergencyTransaction> _transactions = const [];

  @override
  void initState() {
    super.initState();
    loadTransactions();
    _searchController.addListener(() {
      _searchDebouncer.run(_applyFilter);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  List<EmergencyTransaction> get _filtered {
    final query = _searchController.text.trim();
    final lower = query.toLowerCase();
    if (query.isEmpty) return _transactions;
    return _transactions.where((t) {
      return t.description.toLowerCase().contains(lower) ||
          t.amount.toString().contains(query);
    }).toList();
  }

  void _applyFilter() => setState(() {});

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.accountName} - 비상금 지갑')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '비상금 거래',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _toggleSelectionMode,
                  child: Text(_isSelectionMode ? '취소' : '선택'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '설명 또는 금액으로 검색',
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _applyFilter(),
            ),
          ),
          Expanded(child: _buildListContent(items, isLandscape)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildListContent(
    List<EmergencyTransaction> items,
    bool isLandscape,
  ) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: LoadingCardListSkeleton(itemCount: 6, height: 76),
      );
    }
    if (_error != null) {
      return ErrorState(message: _error, onRetry: loadTransactions);
    }
    if (items.isEmpty) {
      final hasQuery = _searchController.text.trim().isNotEmpty;
      return EmptyState(
        title: hasQuery ? '검색 결과가 없습니다' : '비상금 거래가 없습니다',
        message: hasQuery
            ? '검색어를 바꾸거나 초기화하세요.'
            : '입금/출금을 추가해 비상금을 관리하세요.',
        secondaryLabel: hasQuery ? '검색 초기화' : null,
        onSecondary: hasQuery
            ? () {
                _searchController.clear();
                _applyFilter();
              }
            : null,
      );
    }

    return isLandscape
        ? buildLandscapeList(items)
        : buildPortraitList(items);
  }

  Widget? _buildBottomBar() {
    if (!_isSelectionMode || _selectedIds.isEmpty) return null;
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: deleteSelected,
                icon: const Icon(Icons.delete),
                label: Text('삭제 (${_selectedIds.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _selectedIds.length == 1 ? editSelected : null,
                icon: const Icon(Icons.edit),
                label: const Text('수정'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
