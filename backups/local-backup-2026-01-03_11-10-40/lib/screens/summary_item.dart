import 'package:flutter/material.dart';

String formatCurrency(num value) {
  return value
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

class SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final num value;
  final Color color;
  final bool? isIncome; // true: 수입, false: 지출, null: 잔액
  const SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isIncome,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          isIncome == null
              ? '${formatCurrency(value)}원'
              : isIncome!
              ? '+${formatCurrency(value)}원'
              : '-${formatCurrency(value)}원',
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
