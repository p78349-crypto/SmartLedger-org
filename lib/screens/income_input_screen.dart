import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/recent_input_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/date_formatter.dart';
import 'package:smart_ledger/utils/snackbar_utils.dart';
import 'package:smart_ledger/widgets/smart_input_field.dart';

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

  static const List<String> _paymentOptions = [
    '계좌이체',
    '현금',
    '카드',
    '암호화폐',
    '기타',
  ];
  static const List<String> _taxStatusOptions = ['과세', '비과세'];

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureInitialSnapshotIfNeeded();
    });
  }

  void _captureInitialSnapshotIfNeeded() {
    if (!mounted) return;
    if (_initialSnapshot != null) return;
    _initialSnapshot = _InitialIncomeFormSnapshot(
      nameText: _nameController.text,
      amountText: _amountController.text,
      incomeDate: _incomeDate,
      category: _category,
      sourceText: _sourceController.text,
      paymentMethod: _paymentMethod,
      memoText: _memoController.text,
      tagInputText: _tagInputController.text,
      tags: List<String>.from(_tags),
      isRecurring: _isRecurring,
      alarmEnabled: _alarmEnabled,
      alarmTime: _alarmTime,
      taxStatus: _taxStatus,
    );
  }

  Future<void> _promptRevertToInitial() async {
    _captureInitialSnapshotIfNeeded();
    final snapshot = _initialSnapshot;
    if (snapshot == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('입력값 되돌리기'),
          content: const Text('화면을 열었을 때의 입력값으로 되돌릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('되돌리기'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      FocusScope.of(context).unfocus();
      setState(() {
        _nameController.text = snapshot.nameText;
        _amountController.text = snapshot.amountText;
        _incomeDate = snapshot.incomeDate;
        _category = snapshot.category;
        _sourceController.text = snapshot.sourceText;
        _paymentMethod = snapshot.paymentMethod;
        _memoController.text = snapshot.memoText;
        _tagInputController.text = snapshot.tagInputText;
        _tags
          ..clear()
          ..addAll(snapshot.tags);
        _isRecurring = snapshot.isRecurring;
        _alarmEnabled = snapshot.alarmEnabled;
        _alarmTime = snapshot.alarmTime;
        _taxStatus = snapshot.taxStatus;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incomeDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _incomeDate = picked);
    }
  }

  Future<void> _pickAlarmTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime ?? TimeOfDay.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _alarmTime = picked);
    }
  }

  void _addTag(String tag) {
    if (tag.trim().isEmpty) return;
    setState(() {
      _tags.add(tag.trim());
      _tagInputController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    // 금액 검증
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      if (mounted) {
        SnackbarUtils.showWarning(context, '유효한 금액을 입력하세요');
      }
      return;
    }

    try {
      final sourceValue = _sourceController.text.trim();
      final memoValue = _memoController.text.trim();

      final memoLines = <String>[];
      if (memoValue.isNotEmpty) {
        memoLines.add(memoValue);
      }
      if (sourceValue.isNotEmpty) {
        memoLines.add('수입처: $sourceValue');
      }
      if (_taxStatus != '과세') {
        memoLines.add('세금: $_taxStatus');
      }
      if (_isRecurring) {
        memoLines.add('반복: 예');
      }
      if (_alarmEnabled && _alarmTime != null) {
        final alarmLabel =
            '${_alarmTime!.hour.toString().padLeft(2, '0')}:'
            '${_alarmTime!.minute.toString().padLeft(2, '0')}';
        memoLines.add('알림: $alarmLabel');
      }
      if (_tags.isNotEmpty) {
        memoLines.add('태그: ${_tags.join(', ')}');
      }

      final mergedMemo = memoLines.join('\n');

      // 거래 객체 생성
      final transaction = Transaction(
        id: const Uuid().v4(),
        type: TransactionType.income,
        amount: amount,
        date: _incomeDate ?? DateTime.now(),
        description: _nameController.text.trim(),
        paymentMethod: _paymentMethod,
        mainCategory: _category,
        subCategory: sourceValue.isEmpty ? null : sourceValue,
        memo: mergedMemo,
      );

      // 거래 저장
      await TransactionService().addTransaction(
        widget.accountName,
        transaction,
      );

      // 최근 입력값 저장
      await RecentInputService.saveValue(_paymentPrefsKey, _paymentMethod);
      if (memoValue.isNotEmpty) {
        await RecentInputService.saveValue(_memoPrefsKey, memoValue);
      }
      await _loadRecentInputs();

      if (mounted) {
        SnackbarUtils.showSuccess(context, '수입이 저장되었습니다');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '저장 실패: $e');
      }
    }
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SmartInputField(
                label: '수입명',
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? '수입명을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              SmartInputField(
                label: '금액',
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return '금액을 입력하세요';
                  final n = double.tryParse(v.replaceAll(',', ''));
                  if (n == null || n < 0) return '유효한 금액을 입력하세요';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('날짜'),
                  const SizedBox(width: 12),
                  Text(
                    _incomeDate != null
                        ? DateFormatter.formatDate(_incomeDate!)
                        : '',
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: _pickDate, child: const Text('선택')),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: const [
                  DropdownMenuItem(value: '급여', child: Text('급여')),
                  DropdownMenuItem(value: '용돈', child: Text('용돈')),
                  DropdownMenuItem(value: '투자', child: Text('투자')),
                  DropdownMenuItem(value: '환급', child: Text('환급')),
                  DropdownMenuItem(value: '기타', child: Text('기타')),
                ],
                onChanged: (v) => setState(() => _category = v ?? '급여'),
                decoration: const InputDecoration(labelText: '카테고리'),
              ),
              const SizedBox(height: 16),
              SmartInputField(label: '수입처', controller: _sourceController),
              const SizedBox(height: 16),
              SmartInputField(
                label: '메모',
                controller: _memoController,
                hint: '',
                maxLines: 3,
                suffixIcon: _recentMemos.isEmpty
                    ? null
                    : PopupMenuButton<String>(
                        icon: const Icon(Icons.history),
                        tooltip: '최근 메모 선택',
                        onSelected: (value) =>
                            setState(() => _memoController.text = value),
                        itemBuilder: (context) => _recentMemos
                            .map(
                              (memo) =>
                                  PopupMenuItem(value: memo, child: Text(memo)),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 16),
                title: const Text('추가 옵션'),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    items: _paymentOptions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _paymentMethod = v ?? '계좌이체'),
                    decoration: const InputDecoration(labelText: '결제 수단'),
                  ),
                  if (_recentPaymentMethods.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        children: _recentPaymentMethods
                            .map(
                              (method) => ChoiceChip(
                                label: Text(method),
                                selected: _paymentMethod == method,
                                onSelected: (_) {
                                  if (_paymentOptions.contains(method)) {
                                    setState(() => _paymentMethod = method);
                                  }
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _taxStatus,
                    items: _taxStatusOptions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _taxStatus = v ?? '과세'),
                    decoration: const InputDecoration(labelText: '세금 처리'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('반복 여부'),
                    value: _isRecurring,
                    onChanged: (v) => setState(() => _isRecurring = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('알림 설정'),
                    value: _alarmEnabled,
                    onChanged: (v) => setState(() => _alarmEnabled = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_alarmEnabled)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Row(
                        children: [
                          const Text('알림 시간'),
                          const SizedBox(width: 8),
                          Text(
                            _alarmTime != null
                                ? _alarmTime!.format(context)
                                : '',
                          ),
                          TextButton(
                            onPressed: _pickAlarmTime,
                            child: const Text('선택'),
                          ),
                        ],
                      ),
                    ),
                  if (_tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 6,
                        children: _tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                onDeleted: () => _removeTag(tag),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  TextFormField(
                    controller: _tagInputController,
                    decoration: const InputDecoration(labelText: '태그 추가'),
                    onFieldSubmitted: _addTag,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _saveIncome, child: const Text('저장')),
            ],
          ),
        ),
      ),
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
