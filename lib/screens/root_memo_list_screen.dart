import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/root_memo_service_v2.dart';
import '../utils/dialog_utils.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/background_widget.dart';

/// ROOT 메모 전체보기 화면
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

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMemos = _memos;
      } else {
        // 로컬 필터링 (서버에서 검색하려면 _memoService.searchMemos(query) 사용)
        _filteredMemos = _memos.where((memo) =>
          memo.title.toLowerCase().contains(query.toLowerCase()) ||
          memo.content.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _loadMemos() async {
    setState(() => _isLoading = true);
    final memos = await _memoService.getAllMemos();
    setState(() {
      _memos = memos;
      _filteredMemos = _memos;
      _isLoading = false;
    });
  }

  Future<void> _addMemo() async {
    await _showMemoDialog();
  }

  Future<void> _editMemo(RootMemo memo) async {
    await _showMemoDialog(memo: memo);
  }

  Future<void> _deleteMemo(RootMemo memo) async {
    final confirmed = await DialogUtils.showConfirmationDialog(
      context,
      title: '메모 삭제',
      content: '「${memo.title}」 메모를 삭제하시겠습니까?',
      confirmText: '삭제',
      cancelText: '취소',
    );

    if (confirmed == true) {
      final success = await _memoService.deleteMemo(memo.id);
      if (success) {
        await _loadMemos();
        if (mounted) {
          SnackbarUtils.showSuccess(context, '메모가 삭제되었습니다');
        }
      } else if (mounted) {
        SnackbarUtils.showError(context, '메모 삭제에 실패했습니다');
      }
    }
  }

  Future<void> _togglePin(RootMemo memo) async {
    final success = await _memoService.togglePin(memo.id);
    if (success) {
      await _loadMemos();
    } else if (mounted) {
      SnackbarUtils.showError(context, '메모 고정 변경에 실패했습니다');
    }
  }

  Future<void> _showMemoDialog({RootMemo? memo}) async {
    final titleController = TextEditingController(text: memo?.title ?? '');
    final contentController = TextEditingController(text: memo?.content ?? '');
    final titleFocusNode = FocusNode();
    final contentFocusNode = FocusNode();
    bool isPinned = memo?.isPinned ?? false;
    String? selectedColor = memo?.color;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(memo == null ? '✏️ 새 메모' : '📝 메모 수정'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 입력
                  TextField(
                    controller: titleController,
                    focusNode: titleFocusNode,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => contentFocusNode.requestFocus(),
                    decoration: const InputDecoration(
                      labelText: '메모 제목',
                      hintText: '예: 중요한 할 일, 아이디어 등',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 내용 입력
                  TextField(
                    controller: contentController,
                    focusNode: contentFocusNode,
                    textInputAction: TextInputAction.newline,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: '메모 내용',
                      hintText: '메모 내용을 상세히 입력하세요...',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 고정 옵션
                  CheckboxListTile(
                    title: const Text('📌 상단 고정'),
                    subtitle: const Text('중요한 메모를 상단에 고정합니다'),
                    value: isPinned,
                    onChanged: (value) {
                      setDialogState(() => isPinned = value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),

                  // 색상 선택
                  const Text(
                    '🎨 메모 색상',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ColorChip(
                        color: null,
                        label: '기본',
                        isSelected: selectedColor == null,
                        onTap: () => setDialogState(() => selectedColor = null),
                      ),
                      _ColorChip(
                        color: Colors.red.shade100,
                        label: '빨강',
                        isSelected: selectedColor == 'red',
                        onTap: () => setDialogState(() => selectedColor = 'red'),
                      ),
                      _ColorChip(
                        color: Colors.blue.shade100,
                        label: '파랑',
                        isSelected: selectedColor == 'blue',
                        onTap: () => setDialogState(() => selectedColor = 'blue'),
                      ),
                      _ColorChip(
                        color: Colors.green.shade100,
                        label: '초록',
                        isSelected: selectedColor == 'green',
                        onTap: () => setDialogState(() => selectedColor = 'green'),
                      ),
                      _ColorChip(
                        color: Colors.yellow.shade100,
                        label: '노랑',
                        isSelected: selectedColor == 'yellow',
                        onTap: () => setDialogState(() => selectedColor = 'yellow'),
                      ),
                      _ColorChip(
                        color: Colors.purple.shade100,
                        label: '보라',
                        isSelected: selectedColor == 'purple',
                        onTap: () => setDialogState(() => selectedColor = 'purple'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final content = contentController.text.trim();
                
                if (title.isEmpty) {
                  SnackbarUtils.showError(context, '제목을 입력해주세요');
                  return;
                }
                if (content.isEmpty) {
                  SnackbarUtils.showError(context, '내용을 입력해주세요');
                  return;
                }

                String? resultId;
                if (memo == null) {
                  resultId = await _memoService.addMemo(
                    title: title,
                    content: content,
                    isPinned: isPinned,
                    color: selectedColor,
                  );
                } else {
                  final success = await _memoService.updateMemo(
                    id: memo.id,
                    title: title,
                    content: content,
                    isPinned: isPinned,
                    color: selectedColor,
                  );
                  resultId = success ? memo.id : null;
                }
                
                if (resultId != null) {
                  Navigator.pop(context, true);
                } else {
                  SnackbarUtils.showError(context, '메모 저장에 실패했습니다');
                }
              },
              child: Text(memo == null ? '추가' : '수정'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    contentController.dispose();
    titleFocusNode.dispose();
    contentFocusNode.dispose();

    if (result == true) {
      await _loadMemos();
      if (mounted) {
        SnackbarUtils.showSuccess(
          context, 
          memo == null ? '메모가 추가되었습니다' : '메모가 수정되었습니다',
        );
      }
    }
  }

  Color? _getColorFromString(String? colorName) {
    switch (colorName) {
      case 'red': return Colors.red.shade100;
      case 'blue': return Colors.blue.shade100;
      case 'green': return Colors.green.shade100;
      case 'yellow': return Colors.yellow.shade100;
      case 'purple': return Colors.purple.shade100;
      default: return null;
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
                final stats = snapshot.data ?? {'total': 0, 'pinned': 0, 'recent': 0};
                
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
                            _searchQuery.isNotEmpty ? Icons.search_off : Icons.note_add,
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
class _MemoCard extends StatelessWidget {
  final RootMemo memo;
  final Color? color;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _MemoCard({
    required this.memo,
    this.color,
    required this.searchQuery,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Card(
      color: color,
      elevation: memo.isPinned ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (제목 + 메뉴)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (memo.isPinned)
                    Container(
                      margin: const EdgeInsets.only(right: 8, top: 2),
                      child: const Icon(
                        Icons.push_pin,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      memo.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: memo.isPinned ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(memo.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                            const SizedBox(width: 8),
                            Text(memo.isPinned ? '고정 해제' : '상단 고정'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('수정'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'pin': onPin(); break;
                        case 'edit': onTap(); break;
                        case 'delete': onDelete(); break;
                      }
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 내용
              Text(
                memo.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // 하단 정보
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '수정: ${dateFormat.format(memo.updatedAt)}',
                    style: theme.textTheme.caption,
                  ),
                  const Spacer(),
                  if (memo.createdAt != memo.updatedAt) 
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 통계 칩 위젯
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

/// 색상 선택 칩
class _ColorChip extends StatelessWidget {
  final Color? color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChip({
    this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}