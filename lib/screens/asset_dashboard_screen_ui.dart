part of asset_dashboard_screen;

extension _AssetDashboardScreenUi on _AssetDashboardScreenState {
  Widget buildUi(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    final isRoot = widget.accountName.toLowerCase() == 'root';
    final assetLockedFuture = isRoot
        ? Future.value(false)
        : AssetSecurityService.isLocked(widget.accountName);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FutureBuilder<bool>(
                future: assetLockedFuture,
                builder: (context, snap) {
                  final locked = isRoot ? false : (snap.data ?? true);
                  return Row(
                    children: [
                      Expanded(
                        child: _QuickAccessCard(
                          icon: IconCatalog.pieChart,
                          label: '자산 통계',
                          onTap: () async {
                            if (locked) {
                              await _showAssetLockedDialog(
                                context,
                                message: '자산 보안이 설정되어 있어 통계를 볼 수 없습니다.',
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) {
                                  return AssetAllocationScreen(
                                    accountName: widget.accountName,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAccessCard(
                          icon: IconCatalog.barChart,
                          label: '자산 배분',
                          onTap: () async {
                            if (locked) {
                              await _showAssetLockedDialog(
                                context,
                                message: '자산 보안이 설정되어 있어 배분 정보를 볼 수 없습니다.',
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) {
                                  return AssetAllocationScreen(
                                    accountName: widget.accountName,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildDashboardSummary(theme),
            const SizedBox(height: 16),
            _buildAssetCards(theme),
            const SizedBox(height: 16),
            _buildRecentTimeline(theme),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssetLockedDialog(
    BuildContext context, {
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('자산 보안 잠금'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardSummary(ThemeData theme) {
    final summary = AssetManagementUtils.generateDashboardSummary(_assets);
    return AssetUIBuilder.buildDashboardSummaryCard(
      theme: theme,
      summary: summary,
    );
  }

  Widget _buildAssetCards(ThemeData theme) {
    if (_assets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                '등록된 자산이 없습니다',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자산별 현황',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._assets.map((asset) => _buildAssetCard(asset, theme)),
        ],
      ),
    );
  }

  Widget _buildAssetCard(Asset asset, ThemeData theme) {
    final cardInfo = AssetManagementUtils.generateAssetCardInfo(asset);
    return AssetUIBuilder.buildAssetCard(
      theme: theme,
      cardInfo: cardInfo,
      onTap: () async {
        final locked = await AssetSecurityService.isLocked(widget.accountName);
        if (!mounted) return;
        if (locked) {
          final doAuth = await showDialog<bool>(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: const Text('자산 보안 잠금'),
                content: const Text('이 자산은 잠겨 있습니다. 인증하여 열겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('인증하여 열기'),
                  ),
                ],
              );
            },
          );
          if (!mounted) return;
          if (doAuth != true) return;
          final ok = await AssetSecurityService.authenticateAndUnlock(
            widget.accountName,
          );
          if (!mounted) return;
          if (!ok) return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              return AssetDetailScreen(
                accountName: widget.accountName,
                asset: asset,
              );
            },
          ),
        );
        if (!mounted) return;
        _loadData();
      },
    );
  }

  Widget _buildRecentTimeline(ThemeData theme) {
    final allMoves = AssetMoveService().getMoves(widget.accountName);
    final recentMoves = AssetManagementUtils.getRecentMoves(allMoves);
    if (recentMoves.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '최근 자산 이동',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recentMoves.map((move) => _buildTimelineItem(move, theme)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(AssetMove move, ThemeData theme) {
    return AssetUIBuilder.buildTimelineItem(theme: theme, move: move);
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
