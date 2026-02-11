import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import '../models/emergency_transaction.dart';
import '../models/transaction.dart';
import 'transaction_add_detailed_screen.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../services/budget_service.dart';
import '../services/emergency_fund_service.dart';
import '../services/transaction_service.dart';
import '../services/recent_input_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/transaction_utils.dart';

part 'transaction_detail_screen_actions.dart';
part 'transaction_detail_screen_move.dart';
part 'transaction_detail_screen_refund.dart';
part 'transaction_detail_screen_refund_process.dart';
part 'transaction_detail_screen_list.dart';
part 'transaction_detail_screen_build.dart';

/// $("\uac70\ub798 \uc0c1\uc138\ub0b4\uc5ed \ud654\uba74")
class TransactionDetailScreen extends StatefulWidget {
  final String accountName;
  final TransactionType? initialType;

  const TransactionDetailScreen({
    super.key,
    required this.accountName,
    this.initialType,
  });

  @override
  State<TransactionDetailScreen> createState() {
    return _TransactionDetailScreenState();
  }
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  TransactionType _selectedType = TransactionType.expense;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? TransactionType.expense;
  }

  String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return '\uc9c0\ucd9c';
      case TransactionType.income:
        return '\uc218\uc785';
      case TransactionType.savings:
        return '\uc800\ucd95';
      case TransactionType.refund:
        return '\ubc18\ud488';
    }
  }

  Color _typeColor(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.expense:
        return theme.colorScheme.error;
      case TransactionType.income:
        return Colors.green[600] ?? theme.colorScheme.primary;
      case TransactionType.savings:
        return theme.colorScheme.primary;
      case TransactionType.refund:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}
