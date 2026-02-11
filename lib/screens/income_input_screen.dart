import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../services/recent_input_service.dart';
import '../services/transaction_service.dart';
import '../utils/date_formatter.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/smart_input_field.dart';

part 'income_input_screen_actions.dart';
part 'income_input_screen_ui.dart';

const List<String> _paymentOptions = [
  '계좌이체',
  '현금',
  '카드',
  '암호화폐',
  '기타',
];
const List<String> _taxStatusOptions = ['과세', '비과세'];

class IncomeInputScreen extends StatefulWidget {
  final String accountName;
  const IncomeInputScreen({super.key, required this.accountName});

  @override
  State<IncomeInputScreen> createState() => _IncomeInputScreenState();
}

class _IncomeInputScreenState extends State<IncomeInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime? _incomeDate = DateTime.now();
  String _category = '급여';
  final TextEditingController _sourceController = TextEditingController();
  String _paymentMethod = '계좌이체';
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();
  final List<String> _tags = [];
  bool _isRecurring = false;
  bool _alarmEnabled = false;
  TimeOfDay? _alarmTime;
  List<String> _recentPaymentMethods = const [];
  List<String> _recentMemos = const [];
  String _taxStatus = '과세';

  _InitialIncomeFormSnapshot? _initialSnapshot;

  String get _paymentPrefsKey =>
      'recent_payments_income_input_${widget.accountName}';
  String get _memoPrefsKey => 'recent_memos_income_input_${widget.accountName}';

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
    _tagInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수입내역 입력'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: '입력값 되돌리기',
            icon: const Icon(Icons.restart_alt),
            onPressed: _promptRevertToInitial,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}

class _InitialIncomeFormSnapshot {
  const _InitialIncomeFormSnapshot({
    required this.nameText,
    required this.amountText,
    required this.incomeDate,
    required this.category,
    required this.sourceText,
    required this.paymentMethod,
    required this.memoText,
    required this.tagInputText,
    required this.tags,
    required this.isRecurring,
    required this.alarmEnabled,
    required this.alarmTime,
    required this.taxStatus,
  });

  final String nameText;
  final String amountText;
  final DateTime? incomeDate;
  final String category;
  final String sourceText;
  final String paymentMethod;
  final String memoText;
  final String tagInputText;
  final List<String> tags;
  final bool isRecurring;
  final bool alarmEnabled;
  final TimeOfDay? alarmTime;
  final String taxStatus;
}
