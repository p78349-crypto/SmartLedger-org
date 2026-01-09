import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import 'asset_icon_utils.dart';
import 'currency_formatter.dart';
import 'date_formatter.dart';
import 'profit_loss_calculator.dart';

/// 자산 관리 완전 유틸리티 - 모든 자산 관련 기능 통합
/// 재사용 가능하도록 설계된 정적 메서드 모음
class AssetManagementUtils {
  /// 총 자산 계산
  static double calculateTotalAssets(List<Asset> assets) {
    return assets.fold(0.0, (sum, asset) => sum + asset.amount);
  }

  /// 총 원가 계산
  static double calculateTotalCostBasis(List<Asset> assets) {
    return assets.fold(0.0, (sum, asset) => sum + (asset.costBasis ?? 0));
  }

  /// 총 손익 계산
  static double calculateTotalProfitLoss(List<Asset> assets) {
    final totalAssets = calculateTotalAssets(assets);
    final totalCostBasis = calculateTotalCostBasis(assets);
    return totalAssets - totalCostBasis;
  }

  /// 총 손익률 계산 (%)
  static double calculateTotalProfitLossRate(List<Asset> assets) {
    final totalCostBasis = calculateTotalCostBasis(assets);
    if (totalCostBasis == 0) return 0;
    final totalProfitLoss = calculateTotalProfitLoss(assets);
    return (totalProfitLoss / totalCostBasis) * 100;
  }

  /// 이동 유형 이모지 반환
  static String getMoveTypeEmoji(AssetMoveType type) {
    switch (type) {
      case AssetMoveType.purchase:
        return '💰';
      case AssetMoveType.sale:
        return '💸';
      case AssetMoveType.transfer:
        return '🔄';
      case AssetMoveType.exchange:
        return '🔁';
      case AssetMoveType.deposit:
        return '📥';
    }
  }

  /// 이동 유형 라벨 반환
  static String getMoveTypeLabel(AssetMoveType type) {
    switch (type) {
      case AssetMoveType.purchase:
        return '매수/구매';
      case AssetMoveType.sale:
        return '매도/판매';
      case AssetMoveType.transfer:
        return '이동/송금';
      case AssetMoveType.exchange:
        return '교환/전환';
      case AssetMoveType.deposit:
        return '입금';
    }
  }

  /// 대시보드 요약 정보 생성
  static DashboardSummary generateDashboardSummary(List<Asset> assets) {
    final totalAssets = calculateTotalAssets(assets);
    final totalCostBasis = calculateTotalCostBasis(assets);
    final totalProfitLoss = calculateTotalProfitLoss(assets);
    final totalProfitLossRate = calculateTotalProfitLossRate(assets);

    return DashboardSummary(
      totalAssets: totalAssets,
      totalCostBasis: totalCostBasis,
      totalProfitLoss: totalProfitLoss,
      totalProfitLossRate: totalProfitLossRate,
      profitLossColor: ProfitLossCalculator.getProfitLossColor(totalProfitLoss),
      profitLossLabel: ProfitLossCalculator.getProfitLossLabel(totalProfitLoss),
      formattedTotalAssets: CurrencyFormatter.format(totalAssets),
      formattedProfitLoss: ProfitLossCalculator.formatProfitLoss(
        totalProfitLoss,
      ),
      formattedProfitLossRate: ProfitLossCalculator.formatProfitLossRate(
        totalProfitLossRate,
      ),
    );
  }

  /// 자산 카드 정보 생성
  static AssetCardInfo generateAssetCardInfo(Asset asset) {
    final profitLoss = ProfitLossCalculator.calculateProfitLoss(
      asset.amount,
      asset.costBasis,
    );
    final profitLossRate = ProfitLossCalculator.calculateProfitLossRate(
      asset.amount,
      asset.costBasis,
    );
    final profitLossColor = ProfitLossCalculator.getProfitLossColor(profitLoss);

    return AssetCardInfo(
      asset: asset,
      profitLoss: profitLoss,
      profitLossRate: profitLossRate,
      profitLossColor: profitLossColor,
      formattedAmount: CurrencyFormatter.format(asset.amount),
      formattedCostBasis: asset.costBasis != null && asset.costBasis! > 0
          ? CurrencyFormatter.format(asset.costBasis!)
          : null,
      formattedProfitLoss: ProfitLossCalculator.formatProfitLoss(profitLoss),
      formattedProfitLossRate: ProfitLossCalculator.formatProfitLossRate(
        profitLossRate,
      ),
    );
  }

  /// 최근 이동 기록 필터링 (최신순, 개수 제한)
  static List<AssetMove> getRecentMoves(
    List<AssetMove> allMoves, {
    int limit = 10,
  }) {
    final sorted = List<AssetMove>.from(allMoves);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  /// 카테고리별 자산 그룹핑
  static Map<AssetCategory, List<Asset>> groupAssetsByCategory(
    List<Asset> assets,
  ) {
    final grouped = <AssetCategory, List<Asset>>{};
    for (final category in AssetCategory.values) {
      grouped[category] = assets.where((a) => a.category == category).toList();
    }
    return grouped;
  }

  /// 카테고리별 총 손익 계산
  static double calculateCategoryProfitLoss(
    List<Asset> assets,
    AssetCategory category,
  ) {
    final categoryAssets = assets.where((a) => a.category == category).toList();
    return calculateTotalProfitLoss(categoryAssets);
  }

  /// 손익별 자산 분류 (이익/손실/중립)
  static Map<String, List<Asset>> classifyAssetsByProfitLoss(
    List<Asset> assets,
  ) {
    final profits = <Asset>[];
    final losses = <Asset>[];
    final neutral = <Asset>[];

    for (final asset in assets) {
      final profitLoss = ProfitLossCalculator.calculateProfitLoss(
        asset.amount,
        asset.costBasis,
      );
      if (profitLoss > 0) {
        profits.add(asset);
      } else if (profitLoss < 0) {
        losses.add(asset);
      } else {
        neutral.add(asset);
      }
    }

    return {'profits': profits, 'losses': losses, 'neutral': neutral};
  }

  /// 자산 성과 비율 (이익 자산 수 / 전체 자산 수)
  static double calculateSuccessRate(List<Asset> assets) {
    if (assets.isEmpty) return 0;
    final profitCount = assets.where((a) {
      final profitLoss = ProfitLossCalculator.calculateProfitLoss(
        a.amount,
        a.costBasis,
      );
      return profitLoss > 0;
    }).length;
    return (profitCount / assets.length) * 100;
  }

  /// 최고 수익률 자산 찾기
  static Asset? findBestPerformingAsset(List<Asset> assets) {
    if (assets.isEmpty) return null;
    Asset? best;
    double bestRate = double.negativeInfinity;

    for (final asset in assets) {
      final rate = ProfitLossCalculator.calculateProfitLossRate(
        asset.amount,
        asset.costBasis,
      );
      if (rate > bestRate) {
        bestRate = rate;
        best = asset;
      }
    }
    return best;
  }

  /// 최악 수익률 자산 찾기
  static Asset? findWorstPerformingAsset(List<Asset> assets) {
    if (assets.isEmpty) return null;
    Asset? worst;
    double worstRate = double.infinity;

    for (final asset in assets) {
      final rate = ProfitLossCalculator.calculateProfitLossRate(
        asset.amount,
        asset.costBasis,
      );
      if (rate < worstRate) {
        worstRate = rate;
        worst = asset;
      }
    }
    return worst;
  }
}

/// ============================================================================
/// 하위호환성 별칭 (기존 코드와의 호환성 유지)
/// ============================================================================
@Deprecated('Use AssetManagementUtils instead')
typedef AssetDashboardUtils = AssetManagementUtils;

/// ============================================================================
/// 자산 화면 빌더 유틸리티 - UI 위젯 생성 헬퍼
/// ============================================================================
class AssetUIBuilder {
  /// 대시보드 요약 카드 위젯 생성
  static Widget buildDashboardSummaryCard({
    required ThemeData theme,
    required DashboardSummary summary,
    VoidCallback? onRefresh,
    VoidCallback? onProjectClick,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 24,
                    ),
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
              Row(
                children: [
                  if (onProjectClick != null)
                    IconButton(
                      tooltip: '1억 프로젝트',
                      onPressed: onProjectClick,
                      icon: Icon(
                        Icons.emoji_events_outlined,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  if (onRefresh != null)
                    IconButton(
                      onPressed: onRefresh,
                      icon: Icon(
                        Icons.refresh,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            '총 자산',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.formattedTotalAssets,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '총 손익',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.formattedProfitLoss,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '손익률',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.formattedProfitLossRate,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 자산 카드 위젯 생성
  static Widget buildAssetCard({
    required ThemeData theme,
    required AssetCardInfo cardInfo,
    required VoidCallback onTap,
  }) {
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      AssetIconUtils.getIconData(cardInfo.asset.category),
                      size: 24,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardInfo.asset.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cardInfo.asset.category.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '현재 잔액',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cardInfo.formattedAmount,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  if (cardInfo.asset.inputType == AssetInputType.detail)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cardInfo.profitLossColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cardInfo.profitLoss >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 14,
                            color: cardInfo.profitLossColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cardInfo.formattedProfitLoss,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cardInfo.profitLossColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 타임라인 아이템 위젯 생성
  static Widget buildTimelineItem({
    required ThemeData theme,
    required AssetMove move,
  }) {
    final dateFormat = DateFormatter.mmddHHmm;
    final typeEmoji = AssetManagementUtils.getMoveTypeEmoji(move.type);
    final typeLabel = AssetManagementUtils.getMoveTypeLabel(move.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(typeEmoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          typeLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(move.memo),
            Text(
              dateFormat.format(move.date),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        trailing: Text(
          CurrencyFormatter.format(move.amount),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 대시보드 요약 정보 모델
class DashboardSummary {
  final double totalAssets;
  final double totalCostBasis;
  final double totalProfitLoss;
  final double totalProfitLossRate;
  final Color profitLossColor;
  final String profitLossLabel;
  final String formattedTotalAssets;
  final String formattedProfitLoss;
  final String formattedProfitLossRate;

  DashboardSummary({
    required this.totalAssets,
    required this.totalCostBasis,
    required this.totalProfitLoss,
    required this.totalProfitLossRate,
    required this.profitLossColor,
    required this.profitLossLabel,
    required this.formattedTotalAssets,
    required this.formattedProfitLoss,
    required this.formattedProfitLossRate,
  });

  bool get hasProfit => totalProfitLoss > 0;
  bool get hasLoss => totalProfitLoss < 0;
  bool get isNeutral => totalProfitLoss == 0;
}

/// 자산 카드 정보 모델
class AssetCardInfo {
  final Asset asset;
  final double profitLoss;
  final double profitLossRate;
  final Color profitLossColor;
  final String formattedAmount;
  final String? formattedCostBasis;
  final String formattedProfitLoss;
  final String formattedProfitLossRate;

  AssetCardInfo({
    required this.asset,
    required this.profitLoss,
    required this.profitLossRate,
    required this.profitLossColor,
    required this.formattedAmount,
    this.formattedCostBasis,
    required this.formattedProfitLoss,
    required this.formattedProfitLossRate,
  });

  bool get hasProfit => profitLoss > 0;
  bool get hasLoss => profitLoss < 0;
  bool get isNeutral => profitLoss == 0;
  bool get hasCostBasis => formattedCostBasis != null;
}
