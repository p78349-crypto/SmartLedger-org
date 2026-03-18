import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_dashboard_models.dart';
import '../models/asset_move.dart';
import '../utils/asset_icon_utils.dart';
import '../utils/asset_management_utils.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';

/// 자산 화면용 UI 위젯 라이브러리 (300줄 이내 관리)
class AssetUIWidgets {
  /// 대시보드 요약 카드
  static Widget buildDashboardSummary({
    required ThemeData theme,
    required DashboardSummary summary,
    VoidCallback? onRefresh,
    VoidCallback? onProjectClick,
  }) {
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, onRefresh, onProjectClick),
          const SizedBox(height: 32),
          _buildTotalAssets(theme, summary),
          const SizedBox(height: 24),
          _buildPLStats(theme, summary),
        ],
      ),
    );
  }

  static Widget _buildHeader(
    ThemeData theme,
    VoidCallback? onRefresh,
    VoidCallback? onProjectClick,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              IconCatalog.accountBalanceWalletRounded,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(width: 12),
            Text(
              '내 자산 흐름',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
        _buildHeaderActions(theme, onRefresh, onProjectClick),
      ],
    );
  }

  static Widget _buildHeaderActions(
    ThemeData theme,
    VoidCallback? onRefresh,
    VoidCallback? onProjectClick,
  ) {
    return Row(
      children: [
        if (onProjectClick != null)
          IconButton(
            tooltip: '1억 프로젝트',
            onPressed: onProjectClick,
            icon: const Icon(IconCatalog.emojiEvents, color: Colors.white),
          ),
        if (onRefresh != null)
          IconButton(
            tooltip: '새로고침',
            onPressed: onRefresh,
            icon: const Icon(IconCatalog.refresh, color: Colors.white),
          ),
      ],
    );
  }

  static Widget _buildTotalAssets(ThemeData theme, DashboardSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '총 자산',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          summary.formattedTotalAssets,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  static Widget _buildPLStats(ThemeData theme, DashboardSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStatCol(theme, '총 손익', summary.formattedProfitLoss),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatCol(theme, '손익률', summary.formattedProfitLossRate),
        ],
      ),
    );
  }

  static Widget _buildStatCol(ThemeData theme, String label, String val) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 자산 카드
  static Widget buildAssetCard({
    required ThemeData theme,
    required AssetCardInfo cardInfo,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildAssetCardHeader(theme, cardInfo),
              const SizedBox(height: 20),
              _buildAssetCardBalance(theme, cardInfo),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildAssetCardHeader(ThemeData theme, AssetCardInfo info) {
    return Row(
      children: [
        Icon(AssetIconUtils.getIconData(info.asset.category)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.asset.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                info.asset.category.label,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    );
  }

  static Widget _buildAssetCardBalance(ThemeData theme, AssetCardInfo info) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(info.formattedAmount, style: theme.textTheme.titleLarge),
        if (info.asset.inputType == AssetInputType.detail)
          Text(
            info.formattedProfitLoss,
            style: TextStyle(
              color: info.profitLossColor,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  /// 타임라인 아이템
  static Widget buildTimelineItem({
    required ThemeData theme,
    required AssetMove move,
  }) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(AssetManagementUtils.getMoveTypeEmoji(move.type)),
      ),
      title: Text(AssetManagementUtils.getMoveTypeLabel(move.type)),
      subtitle: Text(DateFormatter.mmddHHmm.format(move.date)),
      trailing: Text(CurrencyFormatter.format(move.amount)),
    );
  }
}
