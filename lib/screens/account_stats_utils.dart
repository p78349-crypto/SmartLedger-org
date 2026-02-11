import 'package:flutter/material.dart';

import '../models/transaction.dart';

/// 거래 유형에 맞는 아이콘 반환.
IconData statsIconForType(TransactionType type) {
  switch (type) {
    case TransactionType.income:
    case TransactionType.refund:
      return Icons.trending_up;
    case TransactionType.savings:
      return Icons.savings;
    case TransactionType.expense:
      return Icons.trending_down;
  }
}

/// 거래 유형에 맞는 색상 반환.
Color statsColorForType(TransactionType type, ThemeData theme) {
  switch (type) {
    case TransactionType.income:
    case TransactionType.refund:
      return theme.colorScheme.primary;
    case TransactionType.savings:
      return Colors.amber[700] ?? theme.colorScheme.secondary;
    case TransactionType.expense:
      return theme.colorScheme.error;
  }
}
