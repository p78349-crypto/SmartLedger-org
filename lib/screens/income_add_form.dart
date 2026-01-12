library income_add_form;

import 'package:flutter/material.dart';
import '../services/recent_input_service.dart';
import '../utils/date_formatter.dart';

part 'income_add_form_ui.dart';
part 'income_add_form_options.dart';

class IncomeAddForm extends StatefulWidget {
  final void Function(Map<String, dynamic> incomeData)? onSave;
  const IncomeAddForm({super.key, this.onSave});

  @override
  State<IncomeAddForm> createState() => _IncomeAddFormState();
}

class _IncomeAddFormState extends State<IncomeAddForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _memoController = TextEditingController();
  final _tagController = TextEditingController();

  String _category = '급여';
  String _paymentMethod = '계좌이체';
  String _taxStatus = '과세';
  DateTime _date = DateTime.now();
  final List<String> _tags = [];
  bool _repeat = false;
  bool _alarm = false;
  DateTime? _nextIncomeDate;
  List<String> _recentPaymentMethods = const [];
  List<String> _recentMemos = const [];

  static const List<String> _paymentOptions = [
    '계좌이체',
    '현금',
    '카드',
    '암호화폐',
    '기타',
  ];
  static const List<String> _taxStatusOptions = ['과세', '비과세'];
  static const String _paymentPrefsKey = 'recent_payments_income_add_form';
  static const String _memoPrefsKey = 'recent_memos_income_add_form';

  @override
  void initState() {
    super.initState();
    _loadRecentInputs();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _sourceController.dispose();
    _memoController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentInputs() async {
    final payments = await RecentInputService.loadValues(_paymentPrefsKey);
    final memos = await RecentInputService.loadValues(_memoPrefsKey);
    if (!mounted) return;
    setState(() {
      _recentPaymentMethods = payments;
      _recentMemos = memos;
      final preferredPayment = payments.firstWhere(
        (value) => _paymentOptions.contains(value),
        orElse: () => _paymentMethod,
      );
      _paymentMethod = preferredPayment;
      if (_memoController.text.isEmpty && memos.isNotEmpty) {
        _memoController.text = memos.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildForm(context);
  }
}
