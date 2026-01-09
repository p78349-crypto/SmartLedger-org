import 'package:flutter/material.dart';
import '../models/fixed_cost.dart';
import '../models/transaction.dart';
import '../services/fixed_cost_service.dart';
import '../services/recent_input_service.dart';
import '../services/transaction_service.dart';
import '../utils/date_formats.dart';
import '../utils/utils.dart';
import '../widgets/smart_input_field.dart';

class FixedCostTabScreen extends StatefulWidget {
  final String accountName;
  const FixedCostTabScreen({super.key, required this.accountName});

  @override
  State<FixedCostTabScreen> createState() => _FixedCostTabScreenState();
}

enum _FixedCostAction { record, edit, delete }

class _FixedCostTabScreenState extends State<FixedCostTabScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  bool _loading = true;
  List<FixedCost> _costs = const [];
  List<String> _recentPaymentMethods = const [];
  List<String> _recentMemos = const [];
  bool _isEditing = false;
  int? _editingIndex;
  int? _dueDay;
  static const List<int> _dayOptions = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
  ];

  // 거래 추가 화면과 결제수단을 공유하도록 키 변경
  String get _paymentPrefsKey =>
      'favorite_payments_${widget.accountName}_expense';
  String get _memoPrefsKey => 'recent_memos_fixed_cost_${widget.accountName}';

  @override
  void initState() {
    super.initState();
    _loadRecentInputs();
    _loadCosts();
  }

  Future<void> _loadCosts({bool showSpinner = false}) async {
    if (showSpinner && mounted) {
      setState(() => _loading = true);
    }
    await FixedCostService().loadFixedCosts();
    final loaded = FixedCostService().getFixedCosts(widget.accountName);
    if (!mounted) return;
    setState(() {
      _costs = loaded;
      _loading = false;
    });
  }

  Future<void> _loadRecentInputs() async {
    final payments = await RecentInputService.loadValues(_paymentPrefsKey);
    final memos = await RecentInputService.loadValues(_memoPrefsKey);
    if (!mounted) return;
    setState(() {
      _recentPaymentMethods = payments;
      _recentMemos = memos;
      // 거래 추가에서 입력한 결제수단이 있으면 그것을 사용
      if (_paymentController.text.isEmpty && payments.isNotEmpty) {
        _paymentController.text = payments.first;
      }
      if (_memoController.text.isEmpty && memos.isNotEmpty) {
        _memoController.text = memos.first;
      }
    });
  }

  void _clearForm({bool resetMemo = false}) {
    _nameController.clear();
    _amountController.clear();
    _vendorController.clear();
    if (resetMemo) {
      _memoController.clear();
    }
    _dueDay = null;
  }

  Future<void> _submitCost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final existingId = (_isEditing && _editingIndex != null)
        ? _costs[_editingIndex!].id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final cost = FixedCost(
      id: existingId,
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      vendor: _vendorController.text.trim().isEmpty
          ? null
          : _vendorController.text.trim(),
      paymentMethod: _paymentController.text.trim(),
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      dueDay: _dueDay,
    );
    final memoValue = _memoController.text.trim();
    if (_isEditing && _editingIndex != null) {
      final updatedList = List<FixedCost>.from(_costs);
      updatedList[_editingIndex!] = cost;
      await FixedCostService().replaceFixedCosts(
        widget.accountName,
        updatedList,
      );
    } else {
      await FixedCostService().addFixedCost(widget.accountName, cost);
    }
    final updatedPayments = await RecentInputService.saveValue(
      _paymentPrefsKey,
      _paymentController.text.trim(),
    );
    List<String> updatedMemos = _recentMemos;
    if (memoValue.isNotEmpty) {
      updatedMemos = await RecentInputService.saveValue(
        _memoPrefsKey,
        memoValue,
      );
    }
    final wasEditing = _isEditing;
    if (!mounted) return;
    _clearForm(resetMemo: true);
    setState(() {
      _recentPaymentMethods = updatedPayments;
      _recentMemos = updatedMemos;
      if (updatedPayments.isNotEmpty) {
        _paymentController.text = updatedPayments.first;
      }
      _memoController.text = !_isEditing && _recentMemos.isNotEmpty
          ? _recentMemos.first
          : '';
    });
    setState(() {
      _isEditing = false;
      _editingIndex = null;
    });
    SnackbarUtils.showSuccess(
      context,
      wasEditing ? '고정비용이 수정되었습니다.' : '고정비용이 저장되었습니다.',
    );
    await _loadCosts(showSpinner: true);
  }

  void _startEditing(FixedCost cost, int index) {
    setState(() {
      _isEditing = true;
      _editingIndex = index;
      _nameController.text = cost.name;
      _amountController.text = CurrencyFormatter.format(
        cost.amount,
        showUnit: false,
      );
      _vendorController.text = cost.vendor ?? '';
      _paymentController.text = cost.paymentMethod;
      _memoController.text = cost.memo ?? '';
      _dueDay = cost.dueDay;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingIndex = null;
      _clearForm();
      if (_recentMemos.isNotEmpty) {
        _memoController.text = _recentMemos.first;
      }
    });
  }

  Future<void> _deleteCost(int index) async {
    final confirmed = await DialogUtils.showDeleteConfirmDialog(
      context,
      itemName: _costs[index].name,
    );
    if (confirmed != true) {
      return;
    }
    final updatedList = List<FixedCost>.from(_costs)..removeAt(index);
    await FixedCostService().replaceFixedCosts(widget.accountName, updatedList);
    if (_isEditing && _editingIndex == index) {
      _cancelEditing();
    }
    await _loadCosts(showSpinner: true);
    if (!mounted) return;
    SnackbarUtils.showSuccess(context, '고정비용이 삭제되었습니다.');
  }

  DateTime _suggestPaymentDate(FixedCost cost) {
    final now = DateTime.now();
    if (cost.dueDay == null) {
      return DateFormatter.stripTime(now);
    }
    final lastDay = DateUtils.getDaysInMonth(now.year, now.month);
    final targetDay = cost.dueDay!.clamp(1, lastDay).toInt();
    final candidate = DateTime(now.year, now.month, targetDay);
    return DateFormatter.stripTime(candidate);
  }

  List<Transaction> _findDuplicateTransactions(
    List<Transaction> transactions,
    FixedCost cost,
    DateTime targetDate,
  ) {
    return transactions.where((tx) {
      final sameDay = DateFormatter.isSameDay(tx.date, targetDate);
      final sameAmount = (tx.amount - cost.amount).abs() < 0.01;
      return tx.type == TransactionType.expense &&
          sameDay &&
          sameAmount &&
          tx.description.trim() == cost.name.trim();
    }).toList();
  }

  Future<void> _recordCostAsTransaction(FixedCost cost) async {
    final transactionService = TransactionService();
    await transactionService.loadTransactions();

    final targetDate = _suggestPaymentDate(cost);
    final existingTransactions = transactionService.getTransactions(
      widget.accountName,
    );
    final duplicates = _findDuplicateTransactions(
      existingTransactions,
      cost,
      targetDate,
    );

    final amountLabel = CurrencyFormatter.format(cost.amount);
    final dateLabel = DateFormats.yMd.format(targetDate);

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고정비용을 지출로 기록할까요?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$dateLabel에 ${cost.name}을(를) 지출로 반영합니다.'),
            const SizedBox(height: 12),
            Text('금액: $amountLabel'),
            Text('결제 수단: ${cost.paymentMethod}'),
            if (duplicates.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '⚠️ 동일한 금액/이름의 지출이 이미 ${duplicates.length}건 존재합니다. '
                '중복 기록이 필요하지 않은지 확인하세요.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if ((cost.memo ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('메모: ${cost.memo}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('기록'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    final memoBuffer = StringBuffer('[고정비 자동기록]');
    final trimmedMemo = cost.memo?.trim();
    if (trimmedMemo != null && trimmedMemo.isNotEmpty) {
      memoBuffer.write(' ');
      memoBuffer.write(trimmedMemo);
    }

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.expense,
      description: cost.name,
      amount: cost.amount,
      date: targetDate,
      unitPrice: cost.amount,
      paymentMethod: cost.paymentMethod,
      memo: memoBuffer.toString(),
    );

    await transactionService.addTransaction(widget.accountName, transaction);
    await RecentInputService.saveValue(_paymentPrefsKey, cost.paymentMethod);
    if (trimmedMemo != null && trimmedMemo.isNotEmpty) {
      await RecentInputService.saveValue(_memoPrefsKey, trimmedMemo);
    }

    if (!mounted) return;
    SnackbarUtils.showSuccess(
      context,
      '지출이 기록되었습니다. 필요하면 거래 내역에서 카테고리를 정리하세요.',
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _memoController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSectionHeader('기본 정보'),
                    SmartInputField(
                      controller: _nameController,
                      label: '정기지출 이름',
                      prefixIcon: const Icon(Icons.label),
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          Validators.required(value, fieldName: '정기지출 이름'),
                    ),
                    const SizedBox(height: 12),
                    SmartInputField(
                      controller: _amountController,
                      label: '금액',
                      prefixIcon: const Icon(Icons.attach_money),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          Validators.positiveNumber(value, fieldName: '금액'),
                    ),
                    const SizedBox(height: 12),
                    SmartInputField(
                      controller: _vendorController,
                      label: '납부처 (선택)',
                      prefixIcon: const Icon(Icons.business),
                      textInputAction: TextInputAction.next,
                    ),

                    _buildSectionHeader('결제 및 일정'),
                    SmartInputField(
                      controller: _paymentController,
                      label: '결제 수단',
                      prefixIcon: const Icon(Icons.payment),
                      hint: '결제 수단 입력',
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          Validators.required(value, fieldName: '결제 수단'),
                    ),
                    if (_recentPaymentMethods.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 8,
                          children: _recentPaymentMethods
                              .take(5)
                              .map(
                                (method) => ChoiceChip(
                                  label: Text(method),
                                  selected: _paymentController.text == method,
                                  onSelected: (_) => setState(
                                    () => _paymentController.text = method,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: _dueDay,
                      decoration: const InputDecoration(
                        labelText: '납부일 (선택)',
                        prefixIcon: Icon(Icons.calendar_today),
                        helperText: '입력 시 알림 등 일정 관리에 활용할 수 있어요.',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(child: Text('선택 안 함')),
                        ..._dayOptions.map(
                          (day) => DropdownMenuItem<int?>(
                            value: day,
                            child: Text('매월 $day일'),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _dueDay = value),
                    ),

                    _buildSectionHeader('메모'),
                    SmartInputField(
                      controller: _memoController,
                      label: '메모 (선택)',
                      prefixIcon: const Icon(Icons.note),
                      suffixIcon: _recentMemos.isEmpty
                          ? null
                          : PopupMenuButton<String>(
                              icon: const Icon(Icons.history),
                              tooltip: '최근 메모 선택',
                              onSelected: (value) =>
                                  setState(() => _memoController.text = value),
                              itemBuilder: (context) => _recentMemos
                                  .map(
                                    (memo) => PopupMenuItem(
                                      value: memo,
                                      child: Text(memo),
                                    ),
                                  )
                                  .toList(),
                            ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitCost(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitCost,
                        icon: Icon(_isEditing ? Icons.save : Icons.add_task),
                        label: Text(_isEditing ? '수정 완료' : '정기지출 저장'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _cancelEditing,
                            child: const Text('편집 취소'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '고정비용 목록',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    tooltip: '편집 안내',
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('편집 방법'),
                          content: const Text(
                            '목록 항목 오른쪽 ⋮ 메뉴에서 고정비용을 수정하거나 삭제할 수 있습니다.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('확인'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (_costs.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('등록된 고정비용이 없습니다.')),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final cost = _costs[index];
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.calendar_month,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(cost.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [
                                if (cost.vendor != null &&
                                    cost.vendor!.isNotEmpty)
                                  '납부처: ${cost.vendor}',
                                '결제: ${cost.paymentMethod}',
                                if (cost.dueDay != null)
                                  '납부일: 매월 ${cost.dueDay}일',
                              ].join(' · '),
                            ),
                            if (cost.memo != null && cost.memo!.isNotEmpty)
                              Text('메모: ${cost.memo}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CurrencyFormatter.format(cost.amount),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            PopupMenuButton<_FixedCostAction>(
                              onSelected: (action) {
                                switch (action) {
                                  case _FixedCostAction.record:
                                    _recordCostAsTransaction(cost);
                                    break;
                                  case _FixedCostAction.edit:
                                    _startEditing(cost, index);
                                    break;
                                  case _FixedCostAction.delete:
                                    _deleteCost(index);
                                    break;
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: _FixedCostAction.record,
                                  child: Text('이번 달 지출로 기록'),
                                ),
                                PopupMenuItem(
                                  value: _FixedCostAction.edit,
                                  child: Text('수정'),
                                ),
                                PopupMenuItem(
                                  value: _FixedCostAction.delete,
                                  child: Text('삭제'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (index < _costs.length - 1) const Divider(height: 1),
                    ],
                  );
                }, childCount: _costs.length),
              ),
            SliverToBoxAdapter(
              child: SizedBox(height: bottomInset > 0 ? bottomInset : 16),
            ),
          ],
        ),
      ),
    );
  }
}
