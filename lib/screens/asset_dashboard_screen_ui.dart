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
                builder: (_, snap) {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _QuickAccessCard(
                icon: Icons.analytics_outlined,
                label: '자산 분석',
                onTap: () async {
                  if (isRoot) {
                    if (!mounted) return;
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (_) => AssetPortfolioAnalysisScreen(
                          accountName: widget.accountName,
                        ),
                      ),
                    );
                    return;
                  }
                  final locked = await AssetSecurityService.isLocked(
                    widget.accountName,
                  );
                  if (!mounted) return;
                  if (locked) {
                    await _showAssetLockedDialog(
                      this.context,
                      message: '자산 보안이 설정되어 있어 분석을 볼 수 없습니다.',
                    );
                    return;
                  }
                  if (!mounted) return;
                  Navigator.of(this.context).push(
                    MaterialPageRoute(
                      builder: (_) => AssetPortfolioAnalysisScreen(
                        accountName: widget.accountName,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _QuickAccessCard(
                icon: Icons.route_outlined,
                label: '투자 로드맵',
                onTap: () async {
                  if (isRoot) {
                    if (!mounted) return;
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (_) => AssetInvestmentRoadmapScreen(
                          accountName: widget.accountName,
                        ),
                      ),
                    );
                    return;
                  }
                  final locked = await AssetSecurityService.isLocked(
                    widget.accountName,
                  );
                  if (!mounted) return;
                  if (locked) {
                    await _showAssetLockedDialog(
                      this.context,
                      message: '자산 보안이 설정되어 있어 로드맵을 볼 수 없습니다.',
                    );
                    return;
                  }
                  if (!mounted) return;
                  Navigator.of(this.context).push(
                    MaterialPageRoute(
                      builder: (_) => AssetInvestmentRoadmapScreen(
                        accountName: widget.accountName,
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildDashboardSummary(theme),
            const SizedBox(height: 12),
            _buildEvaluationNoticeCard(theme),
            const SizedBox(height: 12),
            _buildEvaluationComparisonCard(theme),
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
    final summary = AssetManagementUtils.generateDashboardSummary(
      _internalAssets,
    );
    return AssetUIWidgets.buildDashboardSummary(
      theme: theme,
      summary: summary,
      onRefresh: _loadData,
      onProjectClick: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OneHundredMillionProjectScreen(accountName: widget.accountName),
          ),
        );
      },
    );
  }

  Widget _buildEvaluationNoticeCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '대시보드는 전체 요약 화면입니다. 개별 자산의 상세 성과 평가는 자산 상세의 “평가 리포트”에서 확인하세요.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationComparisonCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '대시보드 vs 평가 리포트',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildComparisonColumn(
                    theme,
                    title: '대시보드',
                    accent: theme.colorScheme.primary,
                    items: const [
                      '목적: 전체 요약/현황',
                      '대상: 모든 자산',
                      '지표: 총액, 총 손익, 최근 이동',
                      '진입: 자산 탭 > 대시보드',
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComparisonColumn(
                    theme,
                    title: '평가 리포트',
                    accent: theme.colorScheme.tertiary,
                    items: const [
                      '목적: 개별 자산 성과 분석',
                      '대상: 선택한 자산 1개',
                      '지표: ROI, 납입/회수, 메모',
                      '진입: 자산 상세 > 평가 리포트',
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonColumn(
    ThemeData theme, {
    required String title,
    required Color accent,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(item, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  Widget _buildAssetCards(ThemeData theme) {
    if (_internalAssets.isEmpty) {
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
          ..._internalAssets.map((asset) => _buildAssetCard(asset, theme)),
        ],
      ),
    );
  }

  Widget _buildAssetCard(Asset asset, ThemeData theme) {
    final cardInfo = AssetManagementUtils.generateAssetCardInfo(asset);
    return AssetUIWidgets.buildAssetCard(
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
    return AssetUIWidgets.buildTimelineItem(theme: theme, move: move);
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
