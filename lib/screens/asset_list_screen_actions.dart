// ignore_for_file: invalid_use_of_protected_member
part of 'asset_list_screen.dart';

/// 자산 목록 액션: 삭제, 편집, 액션시트
extension AssetListScreenActions on _AssetListScreenState {
  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: '삭제 확인',
      message: '선택한 ${_selectedIds.length}개 항목을 삭제하시겠습니까?',
      confirmText: '삭제',
      isDangerous: true,
    );

    if (confirmed) {
      final assetService = AssetService();
      for (final id in _selectedIds) {
        await assetService.deleteAsset(widget.accountName, id);
      }
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        SnackbarUtils.showSuccess(context, '삭제되었습니다');
      }
    }
  }

  Future<void> _editSelected() async {
    if (_selectedIds.length != 1) {
      SnackbarUtils.showWarning(context, '수정할 항목을 1개만 선택하세요');
      return;
    }

    final assets = AssetService().getAssets(widget.accountName);
    final asset = assets.firstWhere((a) => a.id == _selectedIds.first);

    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AssetInputScreen(
          accountName: widget.accountName,
          initialAsset: asset,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _showAssetActionSheet(Asset asset) async {
    final rootContext = context;
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                asset.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${asset.category.label} · '
                    '${_dateFormat.format(asset.date)}',
                  ),
                  if (asset.memo.isNotEmpty) Text(asset.memo),
                ],
              ),
              trailing: Text(
                '${_currencyFormat.format(asset.amount)}원',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 4),
            ListTile(
              leading: Icon(
                IconCatalog.infoOutline,
                color: theme.colorScheme.secondary,
              ),
              title: const Text('상세보기'),
              subtitle: const Text('이동 기록 타임라인'),
              onTap: () async {
                Navigator.pop(context);
                final isRoot = widget.accountName.toLowerCase() == 'root';
                final locked = isRoot
                    ? false
                    : await AssetSecurityService.isLocked(widget.accountName);
                if (!rootContext.mounted) return;
                if (locked) {
                  final doAuth = await showDialog<bool>(
                    context: rootContext,
                    builder: (_) => AlertDialog(
                      title: const Text('자산 보안 잠금'),
                      content: const Text('이 자산은 잠겨 있습니다. 인증하여 열겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(rootContext, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(rootContext, true),
                          child: const Text('인증하여 열기'),
                        ),
                      ],
                    ),
                  );
                  if (!rootContext.mounted) return;
                  if (doAuth != true) return;
                  final ok = await AssetSecurityService.authenticateAndUnlock(
                    widget.accountName,
                  );
                  if (!rootContext.mounted) return;
                  if (!ok) return;
                }

                await Navigator.push(
                  rootContext,
                  MaterialPageRoute(
                    builder: (_) => AssetDetailScreen(
                      accountName: widget.accountName,
                      asset: asset,
                    ),
                  ),
                );
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: Icon(IconCatalog.edit, color: theme.colorScheme.primary),
              title: const Text('편집'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssetInputScreen(
                      accountName: widget.accountName,
                      initialAsset: asset,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(IconCatalog.refresh, color: Colors.blue),
              title: const Text('이동'),
              subtitle: const Text('다른 자산으로 이동'),
              onTap: () async {
                Navigator.pop(context);
                final result = await showDialog<bool>(
                  context: rootContext,
                  builder: (_) => AssetMoveDialog(
                    accountName: widget.accountName,
                    fromAsset: asset,
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(IconCatalog.delete, color: Colors.red),
              title: const Text('삭제'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await DialogUtils.showConfirmDialog(
                  rootContext,
                  title: '자산 삭제',
                  message: '${asset.name}을(를) 삭제할까요?',
                  confirmText: '삭제',
                  isDangerous: true,
                );
                if (confirmed) {
                  await AssetService().deleteAsset(
                    widget.accountName,
                    asset.id,
                  );
                  if (!mounted) return;
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
