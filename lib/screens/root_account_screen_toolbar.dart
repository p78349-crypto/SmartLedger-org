part of 'root_account_screen.dart';

/// 상단 툴바, 검색, 계정 삭제 시트 관련 메서드
extension RootAccountScreenToolbar on RootAccountScreen {
  Widget _buildAccountToolbar(BuildContext context, ThemeData theme) {
    final accounts = overview?.accountSummaries ?? [];
    final canDelete = accounts.length > 1;

    final menuItems = <PopupMenuEntry<_AccountMenuAction>>[
      const PopupMenuItem(
        value: _AccountMenuAction.create,
        child: Row(
          children: [Icon(IconCatalog.add), SizedBox(width: 12), Text('계정 추가')],
        ),
      ),
      PopupMenuItem(
        value: _AccountMenuAction.delete,
        enabled: canDelete,
        child: const Row(
          children: [
            Icon(IconCatalog.deleteOutline),
            SizedBox(width: 12),
            Text('계정 삭제'),
          ],
        ),
      ),
      PopupMenuItem(
        value: _AccountMenuAction.trash,
        enabled: onOpenTrash != null,
        child: const Row(
          children: [
            Icon(IconCatalog.deleteSweepOutlined),
            SizedBox(width: 12),
            Text('휴지통'),
          ],
        ),
      ),
    ];

    return Row(
      children: [
        if (onOpenSearch != null)
          OutlinedButton.icon(
            onPressed: onOpenSearch,
            icon: const Icon(IconCatalog.search),
            label: const Text('검색 열기'),
          ),
        if (onOpenSearch != null) const SizedBox(width: 8),
        const Spacer(),
        PopupMenuButton<_AccountMenuAction>(
          tooltip: '계정 관리',
          onSelected: (action) => _handleToolbarAction(context, action),
          itemBuilder: (context) => menuItems,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('계정 관리', style: theme.textTheme.titleMedium),
              const SizedBox(width: 4),
              const Icon(IconCatalog.expandMore),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildAccountActions(BuildContext context, ThemeData theme) {
    if (!showSearchField) {
      return null;
    }

    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        labelText: '계정 검색',
        hintText: '계정명을 입력하세요',
        prefixIcon: const Icon(IconCatalog.search),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(IconCatalog.close),
                tooltip: '검색어 지우기',
                onPressed: () {
                  searchController.clear();
                  FocusScope.of(context).unfocus();
                },
              ),
      ),
    );
  }

  Future<void> _handleToolbarAction(
    BuildContext context,
    _AccountMenuAction action,
  ) async {
    switch (action) {
      case _AccountMenuAction.create:
        onCreateAccount();
        break;
      case _AccountMenuAction.delete:
        await _showDeleteAccountSheet(context);
        break;
      case _AccountMenuAction.trash:
        onOpenTrash?.call();
        break;
    }
  }

  Future<void> _showDeleteAccountSheet(BuildContext context) async {
    final accounts = overview?.accountSummaries ?? [];
    if (accounts.isEmpty) {
      SnackbarUtils.showWarning(context, '삭제할 계정이 없습니다.');
      return;
    }

    if (accounts.length <= 1) {
      SnackbarUtils.showWarning(context, '최소 하나의 계정은 유지해야 합니다.');
      return;
    }

    final labelByAccount = <String, String>{};
    int userIndex = 0;
    for (final a in accounts) {
      final name = a.accountName;
      if (name.trim().toUpperCase() == 'ROOT') {
        labelByAccount[name] = 'ROOT';
        continue;
      }
      userIndex++;
      if (userIndex == 1) {
        labelByAccount[name] = '유저1';
      } else if (userIndex == 2) {
        labelByAccount[name] = '유저2';
      }
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.6;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '삭제할 계정을 선택하세요',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: accounts.length,
                    separatorBuilder: (context, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final label = labelByAccount[account.accountName];
                      return ListTile(
                        title: Text(account.accountName),
                        subtitle: Text(
                          '자산 ${_formatCurrency(account.totalAssets)} · '
                          '거래 ${account.transactionCount}건',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (label != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  label,
                                  style: Theme.of(
                                    sheetContext,
                                  ).textTheme.labelMedium,
                                ),
                              ),
                            const Icon(IconCatalog.deleteOutline),
                          ],
                        ),
                        onTap: () =>
                            Navigator.of(sheetContext).pop(account.accountName),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted) return;
    if (selected == null) return;

    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: '계정 삭제',
      message: '"$selected" 계정을 휴지통으로 이동할까요?',
      confirmText: '삭제',
      isDangerous: true,
    );

    if (!context.mounted) return;

    if (confirmed) {
      onDeleteAccount(selected);
    }
  }
}
