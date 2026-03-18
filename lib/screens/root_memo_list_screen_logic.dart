part of 'root_memo_list_screen.dart';

extension RootMemoListScreenLogic on _RootMemoListScreenState {
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMemos = _memos;
      } else {
        // 로컬 필터링 (서버에서 검색하려면 _memoService.searchMemos(query) 사용)
        _filteredMemos = _memos
            .where(
              (memo) =>
                  memo.title.toLowerCase().contains(query.toLowerCase()) ||
                  memo.content.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
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
    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: '메모 삭제',
      message: '「${memo.title}」 메모를 삭제하시겠습니까?',
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
                        onTap: () =>
                            setDialogState(() => selectedColor = 'red'),
                      ),
                      _ColorChip(
                        color: Colors.blue.shade100,
                        label: '파랑',
                        isSelected: selectedColor == 'blue',
                        onTap: () =>
                            setDialogState(() => selectedColor = 'blue'),
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
                      _ColorChip(
                        color: Colors.purple.shade100,
                        label: '보라',
                        isSelected: selectedColor == 'purple',
                        onTap: () =>
                            setDialogState(() => selectedColor = 'purple'),
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

                if (!context.mounted) return;
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
}
