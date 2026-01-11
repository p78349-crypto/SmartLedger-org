import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../models/asset_move.dart';
import 'asset_allocation_screen.dart';
import 'asset_detail_screen.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../services/transaction_service.dart';
import '../services/asset_security_service.dart';
import '../utils/asset_dashboard_utils.dart';
import '../utils/icon_catalog.dart';

/// 자산 대시보드 - 총 자산, 총 손익, 자산별 카드 뷰, 타임라인
class AssetDashboardScreen extends StatefulWidget {
  final String accountName;

  const AssetDashboardScreen({super.key, required this.accountName});

  @override
  State<AssetDashboardScreen> createState() => _AssetDashboardScreenState();
}

class _AssetDashboardScreenState extends State<AssetDashboardScreen> {
  List<Asset> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    await AssetService().loadAssets();
    await AssetMoveService().loadMoves();
    await TransactionService().loadTransactions();
    if (!mounted) return;
    setState(() {
      _assets = AssetService().getAssets(widget.accountName);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            // 빠른 액세스 아이콘: 자산 통계 / 자산 배분
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FutureBuilder<bool>(
                future: assetLockedFuture,
                builder: (context, snap) {
                  final locked = isRoot ? false : (snap.data ?? true);
                  return Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            if (locked) {
                              // Show locked notice
                              showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('자산 보안 잠금'),
                                  content: const Text(
                                    '자산 보안이 설정되어 있어 통계를 볼 수 없습니다.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('닫기'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            // Navigate to asset stats (reusing AssetAllocationScreen)
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AssetAllocationScreen(
                                  accountName: widget.accountName,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outline.withAlpha(60),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  IconCatalog.pieChart,
                                  size: 28,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '자산 통계',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            if (locked) {
                              showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('자산 보안 잠금'),
                                  content: const Text(
                                    '자산 보안이 설정되어 있어 배분 정보를 볼 수 없습니다.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('닫기'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AssetAllocationScreen(
                                  accountName: widget.accountName,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outline.withAlpha(60),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  IconCatalog.barChart,
                                  size: 28,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '자산 배분',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // 📊 대시보드 요약 카드
            _buildDashboardSummary(theme),
            const SizedBox(height: 16),

            // 📈 자산별 카드 뷰
            _buildAssetCards(theme),
            const SizedBox(height: 16),

            // ⏱️ 최근 타임라인 (전체 자산 이동 기록)
            _buildRecentTimeline(theme),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  /// 📊 대시보드 요약: 총 자산, 총 손익, 손익률
  Widget _buildDashboardSummary(ThemeData theme) {
    final summary = AssetManagementUtils.generateDashboardSummary(_assets);
    return AssetUIBuilder.buildDashboardSummaryCard(
      theme: theme,
      summary: summary,
    );
  }

  /// 📈 자산별 카드 뷰
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

  /// 자산 카드
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
            builder: (_) => AlertDialog(
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
            ),
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
            builder: (_) => AssetDetailScreen(
              accountName: widget.accountName,
              asset: asset,
            ),
          ),
        );
        if (!mounted) return;
        _loadData();
      },
    );
  }

  /// ⏱️ 최근 타임라인
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

  /// 타임라인 아이템
  Widget _buildTimelineItem(AssetMove move, ThemeData theme) {
    return AssetUIBuilder.buildTimelineItem(theme: theme, move: move);
  }
}
