import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shopping_points_draft_entry.dart';
import '../models/transaction.dart';
import '../services/last_input_service.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../utils/benefit_aggregation_utils.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_input_formatter.dart';
import '../widgets/smart_input_field.dart';

part 'shopping_points_input_screen_logic.dart';
part 'shopping_points_input_screen_ui.dart';

class ShoppingPointsInputScreen extends StatefulWidget {
  const ShoppingPointsInputScreen({
    super.key,
    required this.accountName,
    this.lastPaymentMethod,
    this.lastMemo,
    this.totalAmount,
    this.chargedAmount,
    this.itemCount,
  });

  final String accountName;
  final String? lastPaymentMethod;
  final String? lastMemo;
  final double? totalAmount;
  final double? chargedAmount;
  final int? itemCount;

  @override
  State<ShoppingPointsInputScreen> createState() =>
      _ShoppingPointsInputScreenState();
}

class _ShoppingPointsInputScreenState extends State<ShoppingPointsInputScreen> {
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  // 폼 컨트롤러
  late final TextEditingController _paymentMethodController;
  late final TextEditingController _chargedAmountController;
  late final TextEditingController _otherAmountController;
  late final TextEditingController _totalAmountController;
  late final TextEditingController _cardPointController;
  late final TextEditingController _martNameController;
  late final TextEditingController _martDiscountController;
  late final TextEditingController _memoController;

  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  List<ShoppingPointsDraftEntry> _drafts = const [];

  double _parseMoneyOrZero(String raw) {
    final parsed = CurrencyFormatter.parse(raw.trim());
    return (parsed ?? 0).toDouble();
  }

  double get _cardPoint => _parseMoneyOrZero(_cardPointController.text);
  double get _martDiscount => _parseMoneyOrZero(_martDiscountController.text);
  double get _totalDiscount => _cardPoint + _martDiscount;
  double get _totalAmount => _parseMoneyOrZero(_totalAmountController.text);
  double get _chargedAmount => _parseMoneyOrZero(_chargedAmountController.text);

  String _dateLabel(DateTime at) => _dateFormatter.format(at);

  @override
  void initState() {
    super.initState();
    _initControllers();
    _load();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildBody(context);
}
