import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../services/asset_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/profit_loss_calculator.dart';

class AssetPortfolioAnalysisScreen extends StatelessWidget {
  final String accountName;

  const AssetPortfolioAnalysisScreen({super.key, required this.accountName});

  Future<List<Asset>> _loadAssets() async {
    final service = AssetService();
    await service.loadAssets();
    return service.getAssets(accountName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Asset>>(
      future: _loadAssets(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final assets = snapshot.data ?? [];
        if (assets.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('자산 분석')),
            body: const Center(child: Text('분석할 자산이 없습니다.')),
          );
        }

        final rows = _buildCategoryRows(assets);
        return Scaffold(
          appBar: AppBar(title: const Text('자산 분석')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '자산 종류별 분석',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('카테고리')),
                    DataColumn(label: Text('개수')),
                    DataColumn(label: Text('총액')),
                    DataColumn(label: Text('원가')),
                    DataColumn(label: Text('손익')),
                    DataColumn(label: Text('손익률')),
                    DataColumn(label: Text('월수익')),
                  ],
                  rows: rows,
                ),
              ),
              const SizedBox(height: 16),
              _buildLegend(theme),
            ],
          ),
        );
      },
    );
  }

  List<DataRow> _buildCategoryRows(List<Asset> assets) {
    const categories = AssetCategory.values;
    final rows = <DataRow>[];

    for (final category in categories) {
      final categoryAssets = assets
          .where((a) => a.category == category)
          .toList();
      if (categoryAssets.isEmpty) continue;

      final totalAmount = categoryAssets.fold<double>(
        0,
        (sum, asset) => sum + asset.amount,
      );
      final totalCostBasis = categoryAssets.fold<double>(
        0,
        (sum, asset) => sum + (asset.costBasis ?? 0),
      );
      final totalProfitLoss = totalAmount - totalCostBasis;
      final double totalProfitLossRate = totalCostBasis == 0
          ? 0.0
          : (totalProfitLoss / totalCostBasis) * 100;
      final totalMonthlyIncome = categoryAssets.fold<double>(
        0,
        (sum, asset) => sum + (asset.monthlyIncome ?? 0),
      );
      final profitLossColor = ProfitLossCalculator.getProfitLossColor(
        totalProfitLoss,
      );

      rows.add(
        DataRow(
          cells: [
            DataCell(Text('${category.emoji} ${category.label}')),
            DataCell(Text(categoryAssets.length.toString())),
            DataCell(Text(CurrencyFormatter.format(totalAmount))),
            DataCell(Text(CurrencyFormatter.format(totalCostBasis))),
            DataCell(
              Text(
                ProfitLossCalculator.formatProfitLoss(totalProfitLoss),
                style: TextStyle(color: profitLossColor),
              ),
            ),
            DataCell(
              Text(
                ProfitLossCalculator.formatProfitLossRate(totalProfitLossRate),
                style: TextStyle(color: profitLossColor),
              ),
            ),
            DataCell(Text(CurrencyFormatter.format(totalMonthlyIncome))),
          ],
        ),
      );
    }

    return rows;
  }

  Widget _buildLegend(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        '손익/손익률은 원가 기반입니다. 원가가 없는 자산은 0%로 표시됩니다.',
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
