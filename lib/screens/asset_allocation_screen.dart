library;

import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';
import '../services/asset_move_service.dart';
import '../services/transaction_service.dart';
import '../services/monthly_agg_cache_service.dart';
import '../utils/number_formats.dart';

part 'asset_allocation_screen_logic.dart';
part 'asset_allocation_screen_cards.dart';

class AssetCategoryStats {
  final AssetCategory category;
  final List<Asset> assets;
  final double totalAmount;
  final double totalTarget;
  final double actualRatio;

  AssetCategoryStats({
    required this.category,
    required this.assets,
    required this.totalAmount,
    required this.totalTarget,
    required this.actualRatio,
  });
}

class AssetAllocationScreen extends StatefulWidget {
  final String accountName;

  const AssetAllocationScreen({super.key, required this.accountName});

  @override
  State<AssetAllocationScreen> createState() => _AssetAllocationScreenState();
}

class _AssetAllocationScreenState extends State<AssetAllocationScreen> {
  late List<Asset> _assets = [];
  late final Map<AssetCategory, AssetCategoryStats> _stats = {};
  late double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  Widget build(BuildContext context) {
    if (_assets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('자산 배분 분석')),
        body: const Center(child: Text('등록된 자산이 없습니다.\n먼저 자산을 입력해주세요.')),
      );
    }

    final sortedStats = _stats.entries.toList()
      ..sort((a, b) => b.value.totalAmount.compareTo(a.value.totalAmount));

    final isRoot = widget.accountName.toLowerCase() == 'root';

    return Scaffold(
      appBar: AppBar(title: const Text('자산 배분 분석')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isRoot)
            FutureBuilder<Map<String, dynamic>>(
              future: _buildRootDiagnostics(),
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null) {
                  return const SizedBox.shrink();
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _diagChip('자산 개수', '${data['assetCount']}'),
                    _diagChip(
                      '자산 총액',
                      NumberFormats.currency.format(
                        (data['assetTotal'] as num).toInt(),
                      ),
                      icon: Icons.savings,
                    ),
                    _diagChip('이동 기록', '${data['moveCount']}'),
                    _diagChip('거래 수', '${data['txCount']}'),
                    _diagChip('집계 상태', data['aggStatus'].toString()),
                  ],
                );
              },
            ),
          if (isRoot) const SizedBox(height: 12),
          if (_hasTargetRatios()) ...[
            ..._buildRecommendations(),
            const SizedBox(height: 16),
          ],
          ...sortedStats.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCategoryCard(context, entry.value),
            );
          }),
        ],
      ),
    );
  }
}
