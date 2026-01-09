import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';
import '../utils/number_formats.dart';

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

  void _loadAssets() {
    _assets = AssetService().getAssets(widget.accountName);
    _calculateStats();
  }

  void _calculateStats() {
    _stats.clear();
    _totalAmount = 0;

    // 합계 계산
    for (var asset in _assets) {
      _totalAmount += asset.amount;
    }

    // 카테고리별 통계
    for (var category in AssetCategory.values) {
      final categoryAssets = _assets
          .where((a) => a.category == category)
          .toList();
      if (categoryAssets.isNotEmpty) {
        double totalAmount = 0;
        double totalTarget = 0;
        for (var asset in categoryAssets) {
          totalAmount += asset.amount;
          totalTarget += asset.targetRatio ?? 0;
        }
        _stats[category] = AssetCategoryStats(
          category: category,
          assets: categoryAssets,
          totalAmount: totalAmount,
          totalTarget: totalTarget,
          actualRatio: _totalAmount > 0
              ? (totalAmount / _totalAmount) * 100
              : 0,
        );
      }
    }
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

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('자산 배분 분석')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 총 자산
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '총 자산',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₩${NumberFormats.currency.format(_totalAmount.toInt())}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_assets.length}개 자산',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 카테고리별 배분
            Text(
              '카테고리별 자산 배분',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 카테고리별 상세 정보
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedStats.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = sortedStats[index];
                final stats = entry.value;
                return _buildCategoryCard(context, stats);
              },
            ),
            const SizedBox(height: 24),

            // 배분 목표 가이드
            if (_hasTargetRatios())
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '배분 목표 분석',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    color: scheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💡 자산 배분 전략',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._buildRecommendations(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // 3개 주머니 설명
            Card(
              elevation: 2,
              color: scheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎯 3개 주머니 전략',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 비상금(예비비)은 메인 자산 배분 화면에서 노출하지 않습니다.
                    const SizedBox(height: 12),
                    _buildPocketInfo(
                      emoji: '🚀',
                      title: '트레이딩 (Trading)',
                      description: '단기 고위험 수익',
                      amount: _calculatePocketAmount(AssetCategory.crypto),
                    ),
                    const SizedBox(height: 12),
                    _buildPocketInfo(
                      emoji: '🏆',
                      title: '자산형성 (Long-term)',
                      description: '장기 분산 투자',
                      amount:
                          _calculatePocketAmount(AssetCategory.stock) +
                          _calculatePocketAmount(AssetCategory.bond) +
                          _calculatePocketAmount(AssetCategory.realEstate),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, AssetCategoryStats stats) {
    final scheme = Theme.of(context).colorScheme;
    final category = stats.category;
    final categoryColor = Color(category.color);
    final actualPercent = stats.actualRatio;
    final targetPercent = stats.totalTarget;
    final difference = actualPercent - targetPercent;
    final formattedTotal = NumberFormats.currency.format(
      stats.totalAmount.toInt(),
    );
    final formattedPercent = actualPercent.toStringAsFixed(1);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: categoryColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${stats.assets.length}개 자산',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₩$formattedTotal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: categoryColor,
                      ),
                    ),
                    Text(
                      '$formattedPercent%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 진행률 바
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: actualPercent / 100,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
              ),
            ),
            if (targetPercent > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '목표: ${targetPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    difference > 0
                        ? '+${difference.toStringAsFixed(1)}%'
                        : '${difference.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: difference > 0 ? scheme.error : scheme.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // 자산 목록
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: stats.assets.map((asset) {
                  final assetPercent = (asset.amount / _totalAmount) * 100;
                  final formattedAssetAmount = NumberFormats.currency.format(
                    asset.amount.toInt(),
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            asset.name,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₩$formattedAssetAmount',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${assetPercent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPocketInfo({
    required String emoji,
    required String title,
    required String description,
    required double amount,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₩${NumberFormats.currency.format(amount.toInt())}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              _totalAmount > 0
                  ? '${((amount / _totalAmount) * 100).toStringAsFixed(1)}%'
                  : '0%',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildRecommendations() {
    final recommendations = <Widget>[];

    for (var entry in _stats.entries) {
      final stats = entry.value;
      if (stats.totalTarget > 0) {
        final difference = stats.actualRatio - stats.totalTarget;
        if (difference.abs() > 5) {
          final isOver = difference > 0;
          recommendations.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    isOver ? '📈' : '📉',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final diffStr = difference.abs().toStringAsFixed(1);
                        final message = isOver
                            ? '${stats.category.label}이(가) 목표보다 $diffStr% 많습니다'
                            : '${stats.category.label}을(를) $diffStr% 더 늘려야 합니다';
                        return Text(
                          message,
                          style: const TextStyle(fontSize: 13),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text('✅', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '자산 배분이 목표에 가깝습니다!',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return recommendations;
  }

  double _calculatePocketAmount(AssetCategory category) {
    return _stats[category]?.totalAmount ?? 0;
  }

  bool _hasTargetRatios() {
    return _assets.any((a) => a.targetRatio != null && a.targetRatio! > 0);
  }
}
