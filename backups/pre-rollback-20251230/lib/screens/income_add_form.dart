import 'package:flutter/material.dart';
import 'package:smart_ledger/services/recent_input_service.dart';
import 'package:smart_ledger/utils/date_formatter.dart';

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
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 수입명
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '수입명',
              hintText: '예) 월급, 프리랜스 수입, 이자 수익',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? '수입명을 입력하세요.' : null,
          ),
          const SizedBox(height: 12),
          // 금액
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '금액',
              hintText: '실제 입금된 금액',
              border: OutlineInputBorder(),
              prefixText: '₩ ',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? '금액을 입력하세요.' : null,
          ),
          const SizedBox(height: 12),
          // 날짜
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('수입 발생일'),
            subtitle: Text(DateFormatter.formatDate(_date)),
            trailing: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('날짜 선택'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (!mounted) return;
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          // 카테고리
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: '카테고리',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '급여', child: Text('급여')),
              DropdownMenuItem(value: '용돈', child: Text('용돈')),
              DropdownMenuItem(value: '투자', child: Text('투자')),
              DropdownMenuItem(value: '환급', child: Text('환급')),
              DropdownMenuItem(value: '기타', child: Text('기타')),
            ],
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          // 수입처
          TextFormField(
            controller: _sourceController,
            decoration: const InputDecoration(
              labelText: '수입처',
              hintText: '회사명, 은행명, 개인 등',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // 메모
          TextFormField(
            controller: _memoController,
            decoration: InputDecoration(
              labelText: '메모',
              hintText: '상세 설명 (예: 11월 프로젝트 완료 수익)',
              border: const OutlineInputBorder(),
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
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 12),
            title: const Text('추가 옵션'),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: '결제 수단',
                  border: OutlineInputBorder(),
                ),
                items: _paymentOptions
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _paymentMethod = v);
                },
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _taxStatus,
                decoration: const InputDecoration(
                  labelText: '세금 처리',
                  border: OutlineInputBorder(),
                ),
                items: _taxStatusOptions
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _taxStatus = v);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('반복 여부'),
                subtitle: const Text('월급처럼 정기적으로 발생하는 수입 자동 등록'),
                value: _repeat,
                onChanged: (v) => setState(() => _repeat = v),
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.repeat),
              ),
              SwitchListTile(
                title: const Text('알림 설정'),
                subtitle: const Text('다음 수입 예정일 알림'),
                value: _alarm,
                onChanged: (v) => setState(() => _alarm = v),
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_active),
              ),
              if (_alarm)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('다음 수입 예정일'),
                  subtitle: Text(
                    _nextIncomeDate == null
                        ? '선택 안됨'
                        : DateFormatter.formatDate(_nextIncomeDate!),
                  ),
                  trailing: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('선택'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _nextIncomeDate = picked);
                      }
                    },
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagController,
                decoration: InputDecoration(
                  labelText: '태그 (쉼표로 구분)',
                  hintText: '예) #프리랜스, #부수입, #연말정산',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final input = _tagController.text.trim();
                      if (input.isNotEmpty) {
                        setState(() {
                          _tags.addAll(
                            input
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty),
                          );
                          _tagController.clear();
                        });
                      }
                    },
                  ),
                ),
                onFieldSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      _tags.addAll(
                        v
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty),
                      );
                      _tagController.clear();
                    });
                  }
                },
              ),
              if (_tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Wrap(
                    spacing: 6,
                    children: _tags
                        .map(
                          (t) => Chip(
                            label: Text(t),
                            onDeleted: () => setState(() => _tags.remove(t)),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('저장'),
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final navigator = Navigator.of(context);
              final memoValue = _memoController.text.trim();
              final payments = await RecentInputService.saveValue(
                _paymentPrefsKey,
                _paymentMethod,
              );
              List<String> memos = _recentMemos;
              if (memoValue.isNotEmpty) {
                memos = await RecentInputService.saveValue(
                  _memoPrefsKey,
                  memoValue,
                );
              }
              if (!mounted) return;
              setState(() {
                _recentPaymentMethods = payments;
                _recentMemos = memos;
              });
              widget.onSave?.call({
                'name': _nameController.text.trim(),
                'amount': double.tryParse(_amountController.text) ?? 0,
                'date': _date,
                'category': _category,
                'source': _sourceController.text.trim(),
                'paymentMethod': _paymentMethod,
                'taxStatus': _taxStatus,
                'memo': memoValue,
                'tags': _tags,
                'repeat': _repeat,
                'alarm': _alarm,
                'nextIncomeDate': _nextIncomeDate,
              });
              navigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

