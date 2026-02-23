import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/root_memo_service.dart';
import '../utils/dialog_utils.dart';
import '../utils/snackbar_utils.dart';
import '../screens/root_memo_list_screen.dart';

/// ROOT 전용 메모 섹션 위젯
class RootMemoSection extends StatefulWidget {
  const RootMemoSection({super.key});

  @override
  State<RootMemoSection> createState() => _RootMemoSectionState();
}

class _RootMemoSectionState extends State<RootMemoSection> {
  final RootMemoService _memoService = RootMemoService.getInstance();
  List<RootMemo> _memos = [];
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    setState(() => _isLoading = true);
    await _memoService.loadMemos();
    setState(() {
      _memos = _memoService.getAllMemos();
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
      await _memoService.deleteMemo(memo.id);
      await _loadMemos();
      if (mounted) {
        SnackbarUtils.showSuccess(context, '메모가 삭제되었습니다');
      }
    }
  }

  Future<void> _togglePin(RootMemo memo) async {
    await _memoService.togglePin(memo.id);
    await _loadMemos();
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
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: '메모 내용',
                    hintText: '메모 내용을 입력하세요...',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // 옵션들
                Row(
                  children: [
                    // 고정 옵션
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('📌 상단 고정'),
                        subtitle: const Text('중요한 메모'),
                        value: isPinned,
                        onChanged: (value) {
                          setDialogState(() => isPinned = value ?? false);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                    ),
                  ],
                ),

                // 색상 선택
                const Text('🎨 메모 색상', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
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
                  ],
                ),
              ],
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
                
                if (title.isEmpty || content.isEmpty) {
                  SnackbarUtils.showError(context, '제목과 내용을 모두 입력해주세요');
                  return;
                }

                if (memo == null) {
                  // 새 메모 추가
                  await _memoService.addMemo(
                    title: title,
                    content: content,
                    isPinned: isPinned,
                    color: selectedColor,
                  );
                } else {
                  // 기존 메모 수정
                  await _memoService.updateMemo(
                    id: memo.id,
                    title: title,
                    content: content,
                    isPinned: isPinned,
                    color: selectedColor,
                  );
                }
                
                Navigator.pop(context, true);
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
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _memoService.getStats();
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          ListTile(
            leading: const Icon(Icons.sticky_note_2, color: Colors.amber),
            title: const Text(
              '📝 ROOT 메모',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '총 ${stats['total']}개 • 고정 ${stats['pinned']}개',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '새 메모 추가',
                  onPressed: _addMemo,
                ),
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  tooltip: _isExpanded ? '접기' : '펼치기',
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),

          // 메모 목록
          if (_isExpanded) ...[
            const Divider(height: 1),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_memos.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.note_add, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        '아직 메모가 없습니다\n새 메모를 추가해보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _memos.length > 3 ? 3 : _memos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final memo = _memos[index];
                  return _MemoTile(
                    memo: memo,
                    color: _getColorFromString(memo.color),
                    onTap: () => _editMemo(memo),
                    onPin: () => _togglePin(memo),
                    onDelete: () => _deleteMemo(memo),
                  );
                },
              ),
            
            if (_memos.length > 3)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.more_horiz),
                    label: Text('더보기 (${_memos.length - 3}개)'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RootMemoListScreen(),
                        ),
                      ).then((_) => _loadMemos());
                    },
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// 메모 타일 위젯
class _MemoTile extends StatelessWidget {
  final RootMemo memo;
  final Color? color;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _MemoTile({
    required this.memo,
    this.color,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MM/dd HH:mm');

    return Container(
      color: color,
      child: ListTile(
        leading: Icon(
          memo.isPinned ? Icons.push_pin : Icons.note,
          color: memo.isPinned ? Colors.red : Colors.grey,
        ),
        title: Text(
          memo.title,
          style: TextStyle(
            fontWeight: memo.isPinned ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              memo.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '수정: ${dateFormat.format(memo.updatedAt)}',
              style: theme.textTheme.caption,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
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
        onTap: onTap,
      ),
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
        padding: const EdgeInsets.all(8),
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