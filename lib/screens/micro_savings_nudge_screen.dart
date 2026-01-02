import 'package:flutter/material.dart';

import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/benefit_aggregation_utils.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';

class MicroSavingsNudgeScreen extends StatefulWidget {
  const MicroSavingsNudgeScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<MicroSavingsNudgeScreen> createState() => _MicroSavingsNudgeScreenState();
}

typedef _SumCount = ({double total, int count});

class _MicroSavingsNudgeScreenState extends State<MicroSavingsNudgeScreen> {
  bool _loading = true;

  _SumCount _skippedThisMonth = (total: 0, count: 0);
  _SumCount _skippedLookback = (total: 0, count: 0);

  _SumCount _pointsThisMonth = (total: 0, count: 0);
  _SumCount _pointsLookback = (total: 0, count: 0);

  _SumCount _roundUpThisMonth = (total: 0, count: 0);
  _SumCount _roundUpLookback = (total: 0, count: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _startOfThisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime _startOfLookback() {
    final now = DateTime.now();
    return DateTime(now.year, now.month - 5, 1);
  }

  _SumCount _sumWhere(Iterable<Transaction> txs, bool Function(Transaction) pred) {
    var total = 0.0;
    var count = 0;
    for (final t in txs) {
      if (!pred(t)) continue;
      if (t.amount <= 0) continue;
      total += t.amount;
      count += 1;
    }
    return (total: total, count: count);
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    await TransactionService().loadTransactions();
    final all = TransactionService().getTransactions(widget.accountName);

    final thisMonthStart = _startOfThisMonth();
    final lookbackStart = _startOfLookback();

    final thisMonth = <Transaction>[];
    final lookback = <Transaction>[];

    for (final t in all) {
      if (t.date.isBefore(lookbackStart)) continue;
      lookback.add(t);
      if (!t.date.isBefore(thisMonthStart)) {
        thisMonth.add(t);
      }
    }

    if (!mounted) return;
    setState(() {
      _skippedThisMonth = _sumWhere(thisMonth, BenefitAggregationUtils.isSkippedSpendRecord);
      _skippedLookback = _sumWhere(lookback, BenefitAggregationUtils.isSkippedSpendRecord);
      _pointsThisMonth = _sumWhere(thisMonth, BenefitAggregationUtils.isSavedPointsRecord);
      _pointsLookback = _sumWhere(lookback, BenefitAggregationUtils.isSavedPointsRecord);
      _roundUpThisMonth = _sumWhere(thisMonth, BenefitAggregationUtils.isRoundUpRecord);
      _roundUpLookback = _sumWhere(lookback, BenefitAggregationUtils.isRoundUpRecord);
      _loading = false;
    });
  }

  Future<void> _openQuickRecordDialog({
    required String title,
    required String description,
    required String memoTag,
  }) async {
    final amountController = TextEditingController();
    final memoController = TextEditingController();
    final amountFocusNode = FocusNode();
    final memoFocusNode = FocusNode();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!amountFocusNode.hasFocus) {
            amountFocusNode.requestFocus();
          }
          final text = amountController.text;
          amountController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: text.length,
          );
        });

        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                focusNode: amountFocusNode,
                decoration: const InputDecoration(
                  labelText: '금액',
                  hintText: '예: 5000',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autofocus: true,
                onSubmitted: (_) => memoFocusNode.requestFocus(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memoController,
                focusNode: memoFocusNode,
                decoration: const InputDecoration(
                  labelText: '메모(선택)',
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('기록'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      amountController.dispose();
      memoController.dispose();
      amountFocusNode.dispose();
      memoFocusNode.dispose();
      return;
    }

    final parsed = CurrencyFormatter.parse(amountController.text.trim());
    final memo = memoController.text.trim();

    amountController.dispose();
    memoController.dispose();
    amountFocusNode.dispose();
    memoFocusNode.dispose();

    final amount = (parsed ?? 0).toDouble();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금액을 확인해주세요.')),
      );
      return;
    }

    final tx = Transaction(
      id: 'micro_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.savings,
      description: title,
      amount: amount,
      date: DateTime.now(),
      paymentMethod: '현금',
      memo: memo.isEmpty ? memoTag : '$memoTag $memo',
      savingsAllocation: SavingsAllocation.assetIncrease,
    );

    await TransactionService().addTransaction(widget.accountName, tx);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title ${CurrencyFormatter.format(amount)} 기록 완료')),
    );

    await _load();
  }

  Future<void> _openRoundUpDialog() async {
    final amountController = TextEditingController();
    final amountFocusNode = FocusNode();

    var unit = 1000.0;
    double? computed;

    double computeRoundUp(double base) {
      if (base <= 0) return 0;
      if (unit <= 0) return 0;
      final rounded = (base / unit).ceil() * unit;
      final diff = rounded - base;
      return diff > 0 ? diff : 0;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!amountFocusNode.hasFocus) {
            amountFocusNode.requestFocus();
          }
          final text = amountController.text;
          amountController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: text.length,
          );
        });

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final parsed = CurrencyFormatter.parse(amountController.text.trim());
            final base = (parsed ?? 0).toDouble();
            computed = computeRoundUp(base);

            return AlertDialog(
              title: const Text('잔돈 모으기(반올림)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    focusNode: amountFocusNode,
                    decoration: const InputDecoration(
                      labelText: '결제 금액',
                      hintText: '예: 9900',
                    ),
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<double>(
                    key: ValueKey<double>(unit),
                    initialValue: unit,
                    decoration: const InputDecoration(
                      labelText: '반올림 단위',
                    ),
                    items: const [
                      DropdownMenuItem(value: 1000, child: Text('1,000원')),
                      DropdownMenuItem(value: 10000, child: Text('10,000원')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() => unit = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '저축 금액(잔돈): ${CurrencyFormatter.format(computed ?? 0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '이 기록은 1억 프로젝트의 “혜택/절약”에 포함됩니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('저축 기록'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) {
      amountController.dispose();
      amountFocusNode.dispose();
      return;
    }

    final parsed = CurrencyFormatter.parse(amountController.text.trim());
    amountController.dispose();
    amountFocusNode.dispose();

    final base = (parsed ?? 0).toDouble();
    final diff = computeRoundUp(base);
    if (base <= 0 || diff <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반올림할 금액이 없습니다.')),
      );
      return;
    }

    final rounded = (base / unit).ceil() * unit;
    final memo =
        '${BenefitAggregationUtils.roundUpMemoTag} ${CurrencyFormatter.format(base)}→${CurrencyFormatter.format(rounded)}';

    final tx = Transaction(
      id: 'roundup_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.savings,
      description: '잔돈 모으기',
      amount: diff,
      date: DateTime.now(),
      paymentMethod: '현금',
      memo: memo,
      savingsAllocation: SavingsAllocation.assetIncrease,
    );

    await TransactionService().addTransaction(widget.accountName, tx);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('잔돈 ${CurrencyFormatter.format(diff)} 저축 기록 완료')),
    );

    await _load();
  }

  Widget _metric(
    ThemeData theme, {
    required String title,
    required _SumCount month,
    required _SumCount lookback,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(month.total),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '이번달 ${month.count}건 · 최근 6개월 ${CurrencyFormatter.format(lookback.total)} (${lookback.count}건)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 가속(푼돈 모으기)'),
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '푼돈(포인트/절약)을 비상금에 모으고, 일정 금액이 되면 투자로 전환하세요.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _metric(
                  theme,
                  title: '참은 소비',
                  month: _skippedThisMonth,
                  lookback: _skippedLookback,
                ),
                const SizedBox(height: 12),
                _metric(
                  theme,
                  title: '포인트 모으기',
                  month: _pointsThisMonth,
                  lookback: _pointsLookback,
                ),
                const SizedBox(height: 12),
                _metric(
                  theme,
                  title: '잔돈 모으기(반올림)',
                  month: _roundUpThisMonth,
                  lookback: _roundUpLookback,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openQuickRecordDialog(
                      title: '참은 소비',
                      description: '이 기록은 1억 프로젝트의 “혜택/절약”에 포함됩니다.',
                      memoTag: BenefitAggregationUtils.skippedSpendMemoTag,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('참은 소비 기록'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openQuickRecordDialog(
                      title: '포인트 모으기',
                      description: '이 기록은 1억 프로젝트의 “혜택/절약”에 포함됩니다.',
                      memoTag: BenefitAggregationUtils.savedPointsMemoTag,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('포인트 모으기 기록'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openRoundUpDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('잔돈 모으기(반올림) 기록'),
                  ),
                ),
              ],
            ),
    );
  }
}

