import '../models/asset.dart';
import '../models/asset_move.dart';
import '../models/asset_dashboard_models.dart';
import 'currency_formatter.dart';
import 'profit_loss_calculator.dart';

/// 자산 관리 핵심 로직 유틸리티
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
