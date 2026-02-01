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

  @override
  void initState() {
    super.initState();

    // 컨트롤러 초기화 (빈 값으로 시작, _load에서 채움)
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
      // 1. 중앙 저장소에서 쇼핑 세션 정보 가져오기 (우선)
      final session = await LastInputService.instance.getShoppingSession(
        widget.accountName,
      );

      // 2. 드래프트 목록 로드
      final drafts = await UserPrefService.getShoppingPointsDrafts(
        accountName: widget.accountName,
      );
      // toList()로 mutable list 생성 후 정렬
      final sortedDrafts = drafts.toList()
        ..sort((a, b) => b.at.compareTo(a.at));

      if (!mounted) return;

      // 3. 세션 데이터 또는 widget 파라미터로 폼 초기화
      // 우선순위: 세션 > widget 파라미터 > 빈 값
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
      // 에러 발생 시에도 로딩 해제
      if (mounted) {
        setState(() => _loading = false);
      }
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

  String _dateLabel(DateTime at) {
    return _dateFormatter.format(at);
  }

  Future<void> _save() async {
    // 모든 필드가 비어있어도 저장 가능 (할인 0원 처리)
    final points = _totalDiscount;

    if (points > 0) {
      final memoParts = <String>[
        BenefitAggregationUtils.savedPointsMemoTag,
        if (_martNameController.text.trim().isNotEmpty)
          '마트:${_martNameController.text.trim()}',
        if (_paymentMethodController.text.trim().isNotEmpty)
          '결제:${_paymentMethodController.text.trim()}',
        '합계:${CurrencyFormatter.format(_totalAmount)}',
        if (_chargedAmount > 0)
          '카드결제:${CurrencyFormatter.format(_chargedAmount)}',
        if (_cardPoint > 0) '카드포인트:${CurrencyFormatter.format(_cardPoint)}',
        if (_martDiscount > 0)
          '마트할인:${CurrencyFormatter.format(_martDiscount)}',
        if (_memoController.text.trim().isNotEmpty) _memoController.text.trim(),
      ];

      final tx = Transaction(
        id: 'points_${DateTime.now().microsecondsSinceEpoch}',
        type: TransactionType.savings,
        description: '포인트/할인 적립',
        amount: points,
        date: _selectedDate,
        memo: memoParts.join(' '),
        savingsAllocation: SavingsAllocation.assetIncrease,
      );

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
                  // 입력 아이템 개수 표시
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

                  // 날짜 선택
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('날짜'),
                      subtitle: Text(_dateLabel(_selectedDate)),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: const Text('변경'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. 결제 종류
                  Text('결제 정보', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SmartInputField(
                    label: '결제수단 (카드명)',
                    controller: _paymentMethodController,
                    hint: '예: 농협체크카드',
                  ),
                  const SizedBox(height: 12),

                  // 2. 카드 결제금액
                  SmartInputField(
                    label: '카드 결제금액',
                    controller: _chargedAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                    suffixText: '원',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // 3. 결제금액 외 금액 (현금 등)
                  SmartInputField(
                    label: '기타 결제금액 (현금 등)',
                    controller: _otherAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                    suffixText: '원',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // 4. 총 상품 가격
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

                  // 할인 정보 섹션
                  Text('할인 정보', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),

                  // 5. 카드포인트 할인금액
                  SmartInputField(
                    label: '카드포인트 할인',
                    controller: _cardPointController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                    suffixText: '원',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // 6. 마트할인 (마트이름 + 금액)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SmartInputField(
                          label: '마트/쇼핑몰 이름',
                          controller: _martNameController,
                          hint: '예: 하나로마트',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: SmartInputField(
                          label: '마트 할인금액',
                          controller: _martDiscountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          suffixText: '원',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 7. 메모
                  SmartInputField(
                    label: '메모 (선택)',
                    controller: _memoController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // 8. 할인 합계
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '할인 합계',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '카드포인트',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(_cardPoint),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '마트 할인',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(_martDiscount),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '총 할인',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(_totalDiscount),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 저장 버튼
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

                  // 기존 드래프트 목록
                  if (_drafts.isNotEmpty) ...[
                    Text('이전 쇼핑 기록', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _drafts.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final d = _drafts[index];
                        final store = (d.store ?? '').trim();

                        final title = store.isEmpty
                            ? _dateLabel(d.at)
                            : '${_dateLabel(d.at)} · $store';

                        return Card(
                          elevation: 1,
                          child: ListTile(
                            title: Text(title),
                            subtitle: Text(
                              '총액 ${CurrencyFormatter.format(d.receiptTotal)}',
                            ),
                            onTap: () => _loadDraft(d),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteDraft(d),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
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
