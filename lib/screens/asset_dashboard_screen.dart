import 'package:flutter/material.dart';

import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/models/asset_move.dart';
import 'package:smart_ledger/screens/asset_detail_screen.dart';
import 'package:smart_ledger/services/asset_move_service.dart';
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/asset_dashboard_utils.dart';

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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetailScreen(
              accountName: widget.accountName,
              asset: asset,
            ),
          ),
        );
        _loadData();
      },
    );
  }

  /// ⏱️ 최근 타임라인
  Widget _buildRecentTimeline(ThemeData theme) {
    final allMoves = AssetMoveService().getMoves(widget.accountName);
    final recentMoves = AssetManagementUtils.getRecentMoves(
      allMoves,
    );

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
