import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/root_memo_service_v2.dart';
import '../utils/dialog_utils.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/background_widget.dart';

/// ROOT 메모 전체보기 화면
part 'root_memo_list_screen_logic.dart';

part 'root_memo_list_screen_widgets.dart';

class RootMemoListScreen extends StatefulWidget {
  const RootMemoListScreen({super.key});

  @override
  State<RootMemoListScreen> createState() => _RootMemoListScreenState();
}

class _RootMemoListScreenState extends State<RootMemoListScreen> {
  final RootMemoServiceV2 _memoService = RootMemoServiceV2.getInstance();
  final TextEditingController _searchController = TextEditingController();
  List<RootMemo> _memos = [];
  List<RootMemo> _filteredMemos = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMemos();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color? _getColorFromString(String? colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red.shade100;
      case 'blue':
        return Colors.blue.shade100;
      case 'green':
        return Colors.green.shade100;
      case 'yellow':
        return Colors.yellow.shade100;
      case 'purple':
        return Colors.purple.shade100;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) => Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('📝 ROOT 메모'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '새 메모',
              onPressed: _addMemo,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: '메모 검색',
                  hintText: '제목이나 내용으로 검색...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // 통계 정보 - FutureBuilder 사용
            FutureBuilder<Map<String, int>>(
              future: _memoService.getStats(),
              builder: (context, snapshot) {
                final stats =
                    snapshot.data ?? {'total': 0, 'pinned': 0, 'recent': 0};

                return Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(
                        icon: Icons.note,
                        label: '전체',
                        count: stats['total']!,
                        color: Colors.blue,
                      ),
                      _StatChip(
                        icon: Icons.push_pin,
                        label: '고정',
                        count: stats['pinned']!,
                        color: Colors.red,
                      ),
                      _StatChip(
                        icon: Icons.access_time,
                        label: '최근',
                        count: stats['recent']!,
                        color: Colors.green,
                      ),
                    ],
                  ),
                );
              },
            ),

            // 메모 목록
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMemos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off
                                : Icons.note_add,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? '${_searchQuery}에 대한\n검색 결과가 없습니다'
                                : '아직 메모가 없습니다\n새 메모를 추가해보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _addMemo,
                              icon: const Icon(Icons.add),
                              label: const Text('첫 번째 메모 작성'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMemos,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredMemos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final memo = _filteredMemos[index];
                          return _MemoCard(
                            memo: memo,
                            color: _getColorFromString(memo.color),
                            searchQuery: _searchQuery,
                            onTap: () => _editMemo(memo),
                            onPin: () => _togglePin(memo),
                            onDelete: () => _deleteMemo(memo),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addMemo,
          tooltip: '새 메모 추가',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// 메모 카드 위젯

/// 통계 칩 위젯

/// 색상 선택 칩
