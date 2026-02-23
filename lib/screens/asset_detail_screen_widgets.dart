part of 'asset_detail_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension AssetDetailWidgets on _AssetDetailScreenState {
  /// 통계 항목 빌드
  Widget _buildStatItem(
    ThemeData theme, String label, String value, IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }

  /// 이동 타입에 따른 이모지
  String _getMoveTypeEmoji(AssetMoveType type) {
    switch (type) {
      case AssetMoveType.purchase:
        return '💳';
      case AssetMoveType.sale:
        return '💰';
      case AssetMoveType.transfer:
        return '➡️';
      case AssetMoveType.exchange:
        return '🔄';
      case AssetMoveType.deposit:
        return '🏦';
    }
  }

  /// 고유 이동 타입 개수
  String _getUniqueMoveTypes(List<AssetMove> moves) {
    final types = moves.map((m) => m.type).toSet();
    return '${types.length}가지';
  }

  /// 이동 기간
  String _getMoveDateRange(List<AssetMove> moves) {
    if (moves.isEmpty) return '-';
    final dates = moves.map((move) => move.date).toList()..sort();
    if (dates.length == 1) return DateFormatter.mmdd.format(dates.first);
    final startLabel = DateFormatter.mmdd.format(dates.first);
    final endLabel = DateFormatter.mmdd.format(dates.last);
    return '$startLabel ~ $endLabel';
  }

  /// 손익 정보 표시 위젯
  Widget _buildProfitLossDisplay(ThemeData theme) {
    if (_currentAsset.costBasis == null || _currentAsset.costBasis! == 0) {
      return const SizedBox.shrink();
    }

    final profitLoss = ProfitLossCalculator.calculateProfitLoss(
      _currentAsset.amount,
      _currentAsset.costBasis,
    );
    final profitLossRate = ProfitLossCalculator.calculateProfitLossRate(
      _currentAsset.amount,
      _currentAsset.costBasis,
    );
    final profitLossColor = ProfitLossCalculator.getProfitLossColor(profitLoss);
    final profitLossLabel = ProfitLossCalculator.getProfitLossLabel(profitLoss);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: profitLossColor.withValues(alpha: 0.1),
        border: Border.all(color: profitLossColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profitLossLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: profitLossColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ProfitLossCalculator.formatProfitLoss(profitLoss),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: profitLossColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            '(${ProfitLossCalculator.formatProfitLossRate(profitLossRate)})',
            style: theme.textTheme.labelMedium?.copyWith(
              color: profitLossColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
