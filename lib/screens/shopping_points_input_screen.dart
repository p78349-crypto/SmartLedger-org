import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shopping_points_draft_entry.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../utils/benefit_aggregation_utils.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_input_formatter.dart';
import '../widgets/smart_input_field.dart';

class ShoppingPointsInputScreen extends StatefulWidget {
  const ShoppingPointsInputScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<ShoppingPointsInputScreen> createState() =>
      _ShoppingPointsInputScreenState();
}

class _ShoppingPointsInputScreenState extends State<ShoppingPointsInputScreen> {
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  bool _loading = true;
  List<ShoppingPointsDraftEntry> _drafts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final drafts = await UserPrefService.getShoppingPointsDrafts(
      accountName: widget.accountName,
    );

    drafts.sort((a, b) => b.at.compareTo(a.at));

    if (!mounted) return;
    setState(() {
      _drafts = drafts;
      _loading = false;
    });
  }

  double _parseMoneyOrZero(String raw) {
    final parsed = CurrencyFormatter.parse(raw.trim());
    return (parsed ?? 0).toDouble();
  }

  double _computePoints({
    required double total,
    required double charged,
    required double martDiscount,
    required double cardDiscount,
  }) {
    final diff = total - charged - martDiscount - cardDiscount;
    return diff > 0 ? diff : 0;
  }

  String _dateLabel(DateTime at) {
    return _dateFormatter.format(at);
  }

  Future<void> _openDraftEditor(ShoppingPointsDraftEntry draft) async {
    final theme = Theme.of(context);

    final totalController = TextEditingController(
      text: CurrencyFormatter.format(draft.receiptTotal, showUnit: false),
    );
    final chargedController = TextEditingController();
    final martDiscountController = TextEditingController();
    final cardDiscountController = TextEditingController();
    final pointsDirectController = TextEditingController();
    final storeController = TextEditingController(
      text: (draft.store ?? '').trim(),
    );
    final cardController = TextEditingController(
      text: (draft.card ?? '').trim(),
    );
    final memoController = TextEditingController(
      text: (draft.memo ?? '').trim(),
    );

    final chargedFocus = FocusNode();
    var at = draft.at;
    var sameAsTotal = false;

    final result =
        await showDialog<
          ({
            DateTime at,
            double total,
            double charged,
            double martDiscount,
            double cardDiscount,
            double pointsDirect,
            String store,
            String card,
            String memo,
          })
        >(
          context: context,
          builder: (dialogContext) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!chargedFocus.hasFocus) {
                chargedFocus.requestFocus();
              }
            });

            return StatefulBuilder(
              builder: (context, setState) {
                final total = _parseMoneyOrZero(totalController.text);
                final charged = _parseMoneyOrZero(chargedController.text);
                final martDiscount = _parseMoneyOrZero(
                  martDiscountController.text,
                );
                final cardDiscount = _parseMoneyOrZero(
                  cardDiscountController.text,
                );
                final pointsDirect = _parseMoneyOrZero(
                  pointsDirectController.text,
                );
                final computedPoints = _computePoints(
                  total: total,
                  charged: charged,
                  martDiscount: martDiscount,
                  cardDiscount: cardDiscount,
                );
                final points = pointsDirect > 0 ? pointsDirect : computedPoints;

                final helperStyle = theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                );

                return AlertDialog(
                  title: const Text('마트/쇼핑몰,카드 포인트\n혜택받으셨나요'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '합계금액 - 카드결제금액 - 마트할인 - 카드할인 = 포인트',
                          style: helperStyle,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: Text('날짜: ${_dateLabel(at)}')),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: at,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked == null) return;
                                setState(() => at = picked);
                              },
                              child: const Text('변경'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SmartInputField(
                          label: '합계금액',
                          controller: totalController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          suffixText: '원',
                          compact: true,
                          onChanged: (_) {
                            if (!sameAsTotal) return;
                            chargedController.text = totalController.text;
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 8),
                        SmartInputField(
                          label: '카드결제금액',
                          controller: chargedController,
                          focusNode: chargedFocus,
                          enabled: !sameAsTotal,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          suffixText: '원',
                          compact: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        SmartInputField(
                          label: '마트/쇼핑몰 할인',
                          controller: martDiscountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          suffixText: '원',
                          compact: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        SmartInputField(
                          label: '카드할인',
                          controller: cardDiscountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          suffixText: '원',
                          compact: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        SmartInputField(
                          label: '포인트(금액 알고있으면 직접입력)',
                          hint: '입력하면 자동계산을 건너뜁니다',
                          controller: pointsDirectController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          suffixText: '원',
                          compact: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: sameAsTotal,
                          title: const Text('결제금액 같음(포인트 0)'),
                          onChanged: (v) {
                            final next = v ?? false;
                            setState(() {
                              sameAsTotal = next;
                              if (sameAsTotal) {
                                chargedController.text = totalController.text;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '포인트: ${CurrencyFormatter.format(points)}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SmartInputField(
                          label: '구매처(선택)',
                          controller: storeController,
                          compact: true,
                        ),
                        const SizedBox(height: 8),
                        SmartInputField(
                          label: '사용 카드(선택)',
                          controller: cardController,
                          compact: true,
                        ),
                        const SizedBox(height: 8),
                        SmartInputField(
                          label: '포인트 메모(선택)',
                          controller: memoController,
                          compact: true,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final total = _parseMoneyOrZero(totalController.text);
                        final charged = _parseMoneyOrZero(
                          chargedController.text,
                        );
                        final martDiscount = _parseMoneyOrZero(
                          martDiscountController.text,
                        );
                        final cardDiscount = _parseMoneyOrZero(
                          cardDiscountController.text,
                        );
                        final pointsDirect = _parseMoneyOrZero(
                          pointsDirectController.text,
                        );
                        Navigator.of(dialogContext).pop((
                          at: at,
                          total: total,
                          charged: charged,
                          martDiscount: martDiscount,
                          cardDiscount: cardDiscount,
                          pointsDirect: pointsDirect,
                          store: storeController.text.trim(),
                          card: cardController.text.trim(),
                          memo: memoController.text.trim(),
                        ));
                      },
                      child: const Text('다음'),
                    ),
                  ],
                );
              },
            );
          },
        );

    totalController.dispose();
    chargedController.dispose();
    martDiscountController.dispose();
    cardDiscountController.dispose();
    pointsDirectController.dispose();
    storeController.dispose();
    cardController.dispose();
    memoController.dispose();
    chargedFocus.dispose();

    if (result == null || !mounted) return;

    if (result.total <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('구입 총액을 입력해 주세요.')));
      return;
    }

    if (result.pointsDirect <= 0 && result.charged <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카드결제금액을 입력해 주세요.')));
      return;
    }

    if (result.charged > 0 && result.charged > result.total) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카드결제금액이 합계금액보다 큽니다.')));
      return;
    }

    final computedPoints = _computePoints(
      total: result.total,
      charged: result.charged,
      martDiscount: result.martDiscount,
      cardDiscount: result.cardDiscount,
    );
    final points = result.pointsDirect > 0
        ? result.pointsDirect
        : computedPoints;

    if (points > 0) {
      final memoParts = <String>[
        BenefitAggregationUtils.savedPointsMemoTag,
        if (result.store.trim().isNotEmpty) '구매처:${result.store.trim()}',
        if (result.card.trim().isNotEmpty) '카드:${result.card.trim()}',
        '합계:${CurrencyFormatter.format(result.total)}',
        if (result.charged > 0)
          '카드결제:${CurrencyFormatter.format(result.charged)}',
        if (result.martDiscount > 0)
          '마트할인:${CurrencyFormatter.format(result.martDiscount)}',
        if (result.cardDiscount > 0)
          '카드할인:${CurrencyFormatter.format(result.cardDiscount)}',
        if (result.memo.trim().isNotEmpty) result.memo.trim(),
      ];

      final tx = Transaction(
        id: 'points_${DateTime.now().microsecondsSinceEpoch}',
        type: TransactionType.savings,
        description: '포인트 적립',
        amount: points,
        date: result.at,
        memo: memoParts.join(' '),
        savingsAllocation: SavingsAllocation.assetIncrease,
      );

      await TransactionService().addTransaction(widget.accountName, tx);
    }

    await UserPrefService.removeShoppingPointsDraft(
      accountName: widget.accountName,
      id: draft.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(points > 0 ? '포인트를 저장했어요.' : '포인트 0원으로 처리했어요.')),
      );
    }

    await _load();
  }

  Future<void> _deleteDraft(ShoppingPointsDraftEntry draft) async {
    await UserPrefService.removeShoppingPointsDraft(
      accountName: widget.accountName,
      id: draft.id,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트 입력'),
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
          : _drafts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '쇼핑 후 포인트를 사후 입력할 수 있어요.\n'
                  '장바구니에서 “체크 항목 거래 입력”을 마치면 목록이 쌓입니다.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _drafts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final d = _drafts[index];
                final store = (d.store ?? '').trim();
                final card = (d.card ?? '').trim();
                final memo = (d.memo ?? '').trim();

                final title = store.isEmpty
                    ? _dateLabel(d.at)
                    : '${_dateLabel(d.at)} · $store';

                final subtitleParts = <String>[
                  '구입총액 ${CurrencyFormatter.format(d.receiptTotal)}',
                  if (card.isNotEmpty) '카드:$card',
                  if (memo.isNotEmpty) memo,
                ];

                return Card(
                  elevation: 1,
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(
                      subtitleParts.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _openDraftEditor(d),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _openDraftEditor(d);
                        if (v == 'delete') _deleteDraft(d);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('입력')),
                        PopupMenuItem(value: 'delete', child: Text('삭제')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
