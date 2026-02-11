part of 'top_level_main_screen.dart';

Widget _buildSummaryRow({
  required String label,
  required String value,
  Color? valueColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
        ),
      ],
    ),
  );
}

String _formatCurrency(
  NumberFormat format,
  double value, {
  bool includeSign = false,
}) {
  final formatted = format.format(value.abs());
  if (!includeSign) {
    return '$formatted원';
  }
  if (value > 0) {
    return '+$formatted원';
  }
  if (value < 0) {
    return '-$formatted원';
  }
  return '$formatted원';
}

String _formatAmountByType(
  NumberFormat format,
  double value,
  TransactionType type,
) {
  final formatted = format.format(value.abs());
  return '${type.sign}$formatted원';
}

IconData _iconForType(TransactionType type) {
  switch (type) {
    case TransactionType.income:
      return IconCatalog.trendingUp;
    case TransactionType.savings:
      return IconCatalog.savings;
    case TransactionType.expense:
      return IconCatalog.trendingDown;
    case TransactionType.refund:
      return RefundUtils.icon;
  }
}

Color _colorForType(TransactionType type, ThemeData theme) {
  switch (type) {
    case TransactionType.income:
      return theme.colorScheme.primary;
    case TransactionType.savings:
      return Colors.amber[700] ?? theme.colorScheme.secondary;
    case TransactionType.expense:
      return theme.colorScheme.error;
    case TransactionType.refund:
      return RefundUtils.color;
  }
}

String _fixedCostSubtitle(FixedCost cost) {
  final parts = <String>[];
  if (cost.paymentMethod.isNotEmpty) {
    parts.add(cost.paymentMethod);
  }
  if (cost.vendor != null && cost.vendor!.trim().isNotEmpty) {
    parts.add(cost.vendor!.trim());
  }
  if (cost.dueDay != null) {
    parts.add('매월 ${cost.dueDay}일');
  }
  if (cost.memo != null && cost.memo!.trim().isNotEmpty) {
    parts.add(cost.memo!.trim());
  }
  if (parts.isEmpty) {
    return '추가 정보 없음';
  }
  return parts.join(' · ');
}
