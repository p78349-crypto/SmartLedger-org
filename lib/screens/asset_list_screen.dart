import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import 'asset_detail_screen.dart';
import 'asset_input_screen.dart';
import '../services/asset_service.dart';
import '../services/asset_security_service.dart';
import '../utils/date_formatter.dart';
import '../utils/dialog_utils.dart';
import '../utils/debounce_utils.dart';
import '../utils/icon_catalog.dart';
import '../utils/korean_search_utils.dart';
import '../utils/number_formats.dart';
import '../utils/profit_loss_calculator.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/asset_move_dialog.dart';
import '../widgets/smart_input_field.dart';
import '../widgets/state_placeholders.dart';

part 'asset_list_screen_actions.dart';
part 'asset_list_screen_list_builders.dart';

class AssetListScreen extends StatefulWidget {
  final String accountName;
  const AssetListScreen({super.key, required this.accountName});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 180),
  );
  final NumberFormat _currencyFormat = NumberFormats.currency;
  final DateFormat _dateFormat = DateFormatter.defaultDate;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

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

  List<Asset> _getFilteredAssets() {
    final assets = AssetService().getAssets(widget.accountName);
    final query = _searchController.text;

    if (query.isEmpty) {
      return assets;
    }

    return assets.where((asset) {
      return MultilingualSearchUtils.matches(asset.name, query) ||
          MultilingualSearchUtils.matches(asset.memo, query);
    }).toList();
  }

  String _getAssetTypeLabel(Asset asset) {
    return asset.inputType == AssetInputType.simple ? '간단' : '상세';
  }

  @override
  Widget build(BuildContext context) {
    final filteredAssets = _getFilteredAssets();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.accountName} - 자산 목록')),
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
                  '자산 목록',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            child: SmartInputField(
              hint: '자산명 또는 메모로 검색',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              onChanged: (_) {
                _searchDebouncer.run(() {
                  if (!mounted) return;
                  setState(() {});
                });
              },
            ),
          ),
          Expanded(
            child: filteredAssets.isEmpty
                ? EmptyState(
                    title: _searchController.text.trim().isEmpty
                        ? '자산이 없습니다'
                        : '검색 결과가 없습니다',
                    message: _searchController.text.trim().isEmpty
                        ? '자산을 추가해 관리하세요.'
                        : '검색어를 변경하거나 초기화하세요.',
                    secondaryLabel: _searchController.text.trim().isNotEmpty
                        ? '검색 초기화'
                        : null,
                    onSecondary: _searchController.text.trim().isNotEmpty
                        ? () {
                            _searchController.clear();
                            setState(() {});
                          }
                        : null,
                  )
                : isLandscape
                    ? _buildLandscapeList(filteredAssets)
                    : _buildPortraitList(filteredAssets),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
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
                onPressed: _deleteSelected,
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
                onPressed: _selectedIds.length == 1 ? _editSelected : null,
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
