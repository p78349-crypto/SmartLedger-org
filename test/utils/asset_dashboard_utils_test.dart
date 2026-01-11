import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/models/asset_move.dart';
import 'package:smart_ledger/utils/asset_dashboard_utils.dart';

void main() {
  test('AssetManagementUtils calculates totals and rates', () {
    final assets = [
      Asset(id: 'a1', name: 'A', amount: 1200, costBasis: 1000),
      Asset(id: 'a2', name: 'B', amount: 800, costBasis: 900),
      Asset(id: 'a3', name: 'C', amount: 0, costBasis: 0),
    ];

    expect(AssetManagementUtils.calculateTotalAssets(assets), 2000);
    expect(AssetManagementUtils.calculateTotalCostBasis(assets), 1900);
    expect(AssetManagementUtils.calculateTotalProfitLoss(assets), 100);

    final rate = AssetManagementUtils.calculateTotalProfitLossRate(assets);
    expect(rate, closeTo((100 / 1900) * 100, 0.0001));

    final summary = AssetManagementUtils.generateDashboardSummary(assets);
    expect(summary.totalAssets, 2000);
    expect(summary.totalCostBasis, 1900);
    expect(summary.totalProfitLoss, 100);
    expect(summary.formattedTotalAssets, isNotEmpty);
    expect(summary.profitLossLabel, isNotEmpty);
  });

  test('getRecentMoves sorts by date descending and limits', () {
    final base = DateTime(2026, 1, 11, 12);
    final moves = [
      AssetMove(
        id: 'm1',
        accountName: 'acc',
        fromAssetId: 'a1',
        amount: 10,
        date: base.subtract(const Duration(days: 2)),
      ),
      AssetMove(
        id: 'm2',
        accountName: 'acc',
        fromAssetId: 'a1',
        amount: 20,
        date: base.subtract(const Duration(days: 1)),
      ),
      AssetMove(
        id: 'm3',
        accountName: 'acc',
        fromAssetId: 'a1',
        amount: 30,
        date: base,
      ),
    ];

    final recent = AssetManagementUtils.getRecentMoves(moves, limit: 2);
    expect(recent.length, 2);
    expect(recent.first.id, 'm3');
    expect(recent.last.id, 'm2');
  });

  test('grouping and classification helpers', () {
    final assets = [
      Asset(
        id: 'a1',
        name: 'Stock1',
        amount: 1500,
        costBasis: 1000,
        category: AssetCategory.stock,
      ),
      Asset(
        id: 'a2',
        name: 'Bond1',
        amount: 800,
        costBasis: 900,
        category: AssetCategory.bond,
      ),
      Asset(
        id: 'a3',
        name: 'Cash',
        amount: 100,
        costBasis: 100,
        category: AssetCategory.cash,
      ),
    ];

    final grouped = AssetManagementUtils.groupAssetsByCategory(assets);
    expect(grouped[AssetCategory.stock]!.length, 1);
    expect(grouped[AssetCategory.bond]!.length, 1);

    final classified = AssetManagementUtils.classifyAssetsByProfitLoss(assets);
    expect(classified['profits']!.map((e) => e.id), contains('a1'));
    expect(classified['losses']!.map((e) => e.id), contains('a2'));
    expect(classified['neutral']!.map((e) => e.id), contains('a3'));

    final successRate = AssetManagementUtils.calculateSuccessRate(assets);
    expect(successRate, closeTo((1 / 3) * 100, 0.0001));
  });
}
