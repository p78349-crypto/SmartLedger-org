part of 'asset_allocation_screen.dart';

extension _AssetAllocationLogic on _AssetAllocationScreenState {
  Widget _diagChip(String label, String value, {IconData? icon}) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _buildRootDiagnostics() async {
    final accounts = AssetService().getTrackedAccountNames();
    final assets = <Asset>[];
    final moves = <dynamic>[];
    for (final acct in accounts) {
      assets.addAll(AssetService().getAssets(acct));
      moves.addAll(AssetMoveService().getMoves(acct));
    }
    final txs = TransactionService().getAllTransactions();
    String aggStatus = 'unknown';
    try {
      final cache = await MonthlyAggCacheService().load(widget.accountName);
      final months = cache.months.keys.toList();
      aggStatus = months.isEmpty ? 'empty' : '${months.length} months';
    } catch (_) {
      aggStatus = 'error';
    }

    final total = assets.fold<double>(0, (sum, asset) => sum + asset.amount);
    return {
      'assetCount': assets.length,
      'assetTotal': total,
      'moveCount': moves.length,
      'txCount': txs.length,
      'aggStatus': aggStatus,
    };
  }

  void _loadAssets() {
    _assets = AssetService().getAssets(widget.accountName);
    _calculateStats();
  }

  void _calculateStats() {
    _stats.clear();
    _totalAmount = 0;

    for (final asset in _assets) {
      _totalAmount += asset.amount;
    }

    for (final category in AssetCategory.values) {
      final categoryAssets =
          _assets.where((asset) => asset.category == category).toList();
      if (categoryAssets.isEmpty) {
        continue;
      }

      double totalAmount = 0;
      double totalTarget = 0;
      for (final asset in categoryAssets) {
        totalAmount += asset.amount;
        totalTarget += asset.targetRatio ?? 0;
      }

      _stats[category] = AssetCategoryStats(
        category: category,
        assets: categoryAssets,
        totalAmount: totalAmount,
        totalTarget: totalTarget,
        actualRatio:
            _totalAmount > 0 ? (totalAmount / _totalAmount) * 100 : 0,
      );
    }
  }

  List<Widget> _buildRecommendations() {
    final recommendations = <Widget>[];

    for (final stats in _stats.values) {
      final target = stats.totalTarget;
      if (target <= 0) {
        continue;
      }

      final difference = stats.actualRatio - target;
      if (difference.abs() <= 5) {
        continue;
      }

      final isOver = difference > 0;
      recommendations.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(isOver ? '📈' : '📉', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOver
                      ? '${stats.category.label}이(가) 목표보다 '
                          '${difference.abs().toStringAsFixed(1)}% 많습니다'
                      : '${stats.category.label}을(를) '
                          '${difference.abs().toStringAsFixed(1)}% 늘려야 합니다',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
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

  bool _hasTargetRatios() {
    return _assets.any((asset) => (asset.targetRatio ?? 0) > 0);
  }
}
