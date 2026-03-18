import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/root_memo_service_v2.dart';
import '../utils/dialog_utils.dart';
import '../utils/snackbar_utils.dart';
import '../utils/root_memo_migration_util.dart';
import '../screens/root_memo_list_screen.dart';

/// ROOT 메모 섹션 위젯 (SQLite 기반 V2)
class RootMemoSectionV2 extends StatefulWidget {
  const RootMemoSectionV2({super.key});

  @override
  State<RootMemoSectionV2> createState() => _RootMemoSectionV2State();
}

class _RootMemoSectionV2State extends State<RootMemoSectionV2> {
  final RootMemoServiceV2 _memoService = RootMemoServiceV2.getInstance();
  List<RootMemo> _memos = [];
  bool _isLoading = true;
  bool _migrationChecked = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadMemos();
  }

  /// 초기화 및 메모 로딩 (마이그레이션 포함)
  Future<void> _initializeAndLoadMemos() async {
    if (!_migrationChecked) {
      await RootMemoMigrationUtil.checkAndMigrate(context);
      _migrationChecked = true;
    }
    await _loadMemos();
  }

  Future<void> _loadMemos() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final memos = await _memoService.getAllMemos();
      if (mounted) {
        setState(() {
          _memos = memos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('메모 로딩 오류: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addMemo() async {
    final result = await _showMemoDialog();
    if (result == true) {
      await _loadMemos();
      if (mounted) {
        SnackbarUtils.showSuccess(context, '메모가 추가되었습니다');
      }
    }
  }

  Future<void> _editMemo(RootMemo memo) async {
    final result = await _showMemoDialog(memo: memo);
    if (result == true) {
      await _loadMemos();
      if (mounted) {
        SnackbarUtils.showSuccess(context, '메모가 수정되었습니다');
      }
    }
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

  Future<bool?> _showMemoDialog({RootMemo? memo}) async {
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
                const SizedBox(height: 12),

                // 내용 입력
                TextField(
                  controller: contentController,
                  focusNode: contentFocusNode,
                  textInputAction: TextInputAction.newline,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '메모 내용',
                    hintText: '메모 내용을 입력하세요...',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),

                // 고정 옵션
                CheckboxListTile(
                  title: const Text('📌 상단 고정'),
                  value: isPinned,
                  onChanged: (value) {
                    setDialogState(() => isPinned = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                // 색상 선택
                const Text(
                  '🎨 색상',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                      onTap: () =>
                          setDialogState(() => selectedColor = 'green'),
                    ),
                    _ColorChip(
                      color: Colors.yellow.shade100,
                      label: '노랑',
                      isSelected: selectedColor == 'yellow',
                      onTap: () =>
                          setDialogState(() => selectedColor = 'yellow'),
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

                Navigator.pop(context, resultId != null);
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

    return result;
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

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.note_alt, color: theme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'ROOT 메모',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addMemo,
                  icon: const Icon(Icons.add),
                  tooltip: '새 메모',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 메모 목록 또는 로딩
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_memos.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.note_add, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      '아직 메모가 없습니다\n첫 번째 메모를 추가해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else ...[
              // 메모 리스트 (최대 3개)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _memos.length > 3 ? 3 : _memos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final memo = _memos[index];
                  return _MemoTileV2(
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
      ),
    );
  }
}

/// 메모 타일 위젯 (V2)
class _MemoTileV2 extends StatelessWidget {
  final RootMemo memo;
  final Color? color;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _MemoTileV2({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: memo.isPinned ? Colors.red.shade300 : Colors.grey.shade300,
          width: memo.isPinned ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                if (memo.isPinned)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: const Icon(
                      Icons.push_pin,
                      color: Colors.red,
                      size: 14,
                    ),
                  ),
                Expanded(
                  child: Text(
                    memo.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: memo.isPinned
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(
                            memo.isPinned
                                ? Icons.push_pin_outlined
                                : Icons.push_pin,
                          ),
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
                      case 'pin':
                        onPin();
                        break;
                      case 'edit':
                        onTap();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 6),

            // 내용
            Text(
              memo.content,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // 하단 정보
            Text(
              dateFormat.format(memo.updatedAt),
              style: theme.textTheme.caption?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
