import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shopping_points_draft_entry.dart';
import '../services/last_input_service.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_input_formatter.dart';
import '../widgets/smart_input_field.dart';
import 'shopping_points_input_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _paymentMethodController = TextEditingController();
    _chargedAmountController = TextEditingController();
    _otherAmountController = TextEditingController();
    _totalAmountController = TextEditingController();
    _cardPointController = TextEditingController();
    _martNameController = TextEditingController();
    _martDiscountController = TextEditingController();
    _memoController = TextEditingController();

    _load();
  }

  @override
  void dispose() {
    _paymentMethodController.dispose();
    _chargedAmountController.dispose();
    _otherAmountController.dispose();
    _totalAmountController.dispose();
    _cardPointController.dispose();
    _martNameController.dispose();
    _martDiscountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = await LastInputService.instance.getShoppingSession(
        widget.accountName,
      );
      final drafts = await UserPrefService.getShoppingPointsDrafts(
        accountName: widget.accountName,
      );
      final sortedDrafts = drafts.toList()
        ..sort((a, b) => b.at.compareTo(a.at));
      if (!mounted) return;
      final paymentMethod =
          session?.paymentMethod ?? widget.lastPaymentMethod ?? '';
      final storeName = session?.storeName ?? widget.lastMemo ?? '';
      final totalAmount = session?.totalAmount ?? widget.totalAmount;
      final chargedAmount = session?.chargedAmount ?? widget.chargedAmount;
      _paymentMethodController.text = paymentMethod;
      _martNameController.text = storeName;
      if (totalAmount != null && totalAmount > 0) {
        _totalAmountController.text = CurrencyFormatter.format(
          totalAmount,
          showUnit: false,
        );
      }
      if (chargedAmount != null && chargedAmount > 0) {
        _chargedAmountController.text = CurrencyFormatter.format(
          chargedAmount,
          showUnit: false,
        );
      }
      setState(() {
        _drafts = sortedDrafts;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

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

  Future<void> _save() async {
    final points = _totalDiscount;
    final tx = createShoppingDiscountTransaction(
      totalDiscount: points,
      date: _selectedDate,
      martName: _martNameController.text.trim(),
      paymentMethod: _paymentMethodController.text.trim(),
      totalAmount: _totalAmount,
      chargedAmount: _chargedAmount,
      cardPoint: _cardPoint,
      martDiscount: _martDiscount,
      memo: _memoController.text.trim(),
    );
    if (tx != null) {
      await TransactionService().addTransaction(widget.accountName, tx);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            points > 0
                ? '할인 ${CurrencyFormatter.format(points)}을 저장했어요.'
                : '할인 0원으로 처리했어요.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트/할인 입력'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.itemCount != null && widget.itemCount! > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${widget.itemCount}개 아이템 지출입력 완료',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ShoppingDatePickerCard(
                    selectedDate: _selectedDate,
                    dateLabel: _dateLabel,
                    onDateChanged: (d) => setState(() => _selectedDate = d),
                  ),
                  const SizedBox(height: 16),
                  Text('결제 정보', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SmartInputField(
                    label: '결제수단 (카드명)',
                    controller: _paymentMethodController,
                    hint: '예: 농협체크카드',
                  ),
                  const SizedBox(height: 12),
                  SmartInputField(
                    label: '카드 결제금액',
                    controller: _chargedAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                    suffixText: '원',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SmartInputField(
                    label: '기타 결제금액 (현금 등)',
                    controller: _otherAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                    suffixText: '원',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  Text('상품 정보', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SmartInputField(
                    label: '총 상품 가격',
                    controller: _totalAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                    suffixText: '원',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  ShoppingDiscountInputs(
                    cardPointController: _cardPointController,
                    martNameController: _martNameController,
                    martDiscountController: _martDiscountController,
                    memoController: _memoController,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  PointsDiscountSummaryCard(
                    cardPoint: _cardPoint,
                    martDiscount: _martDiscount,
                    totalDiscount: _totalDiscount,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('저장'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ShoppingDraftList(
                    drafts: _drafts,
                    dateLabel: _dateLabel,
                    onLoadDraft: _loadDraft,
                    onDeleteDraft: _deleteDraft,
                  ),
                ],
              ),
            ),
    );
  }

  void _loadDraft(ShoppingPointsDraftEntry draft) {
    setState(() {
      _selectedDate = draft.at;
      _totalAmountController.text = CurrencyFormatter.format(
        draft.receiptTotal,
        showUnit: false,
      );
      _martNameController.text = draft.store ?? '';
      _paymentMethodController.text = draft.card ?? '';
      _memoController.text = draft.memo ?? '';
    });
  }

  Future<void> _deleteDraft(ShoppingPointsDraftEntry draft) async {
    await UserPrefService.removeShoppingPointsDraft(
      accountName: widget.accountName,
      id: draft.id,
    );
    await _load();
  }
}
