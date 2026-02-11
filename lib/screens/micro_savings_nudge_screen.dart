import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/benefit_aggregation_utils.dart';
import '../utils/currency_formatter.dart';

part 'micro_savings_nudge_screen_dialogs.dart';

class MicroSavingsNudgeScreen extends StatefulWidget {
  const MicroSavingsNudgeScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<MicroSavingsNudgeScreen> createState() =>
      _MicroSavingsNudgeScreenState();
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
    return DateTime(now.year, now.month);
  }

  DateTime _startOfLookback() {
    final now = DateTime.now();
    return DateTime(now.year, now.month - 5);
  }

  _SumCount _sumWhere(
    Iterable<Transaction> txs,
    bool Function(Transaction) pred,
  ) {
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
      _skippedThisMonth = _sumWhere(
        thisMonth,
        BenefitAggregationUtils.isSkippedSpendRecord,
      );
      _skippedLookback = _sumWhere(
        lookback,
        BenefitAggregationUtils.isSkippedSpendRecord,
      );
      _pointsThisMonth = _sumWhere(
        thisMonth,
        BenefitAggregationUtils.isSavedPointsRecord,
      );
      _pointsLookback = _sumWhere(
        lookback,
        BenefitAggregationUtils.isSavedPointsRecord,
      );
      _roundUpThisMonth = _sumWhere(
        thisMonth,
        BenefitAggregationUtils.isRoundUpRecord,
      );
      _roundUpLookback = _sumWhere(
        lookback,
        BenefitAggregationUtils.isRoundUpRecord,
      );
      _loading = false;
    });
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
              '이번달 ${month.count}건 · 최근 6개월 '
              '${CurrencyFormatter.format(lookback.total)} '
              '(${lookback.count}건)',
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
                      description: '이 기록은 1억 프로젝트의 "혜택/절약"에 포함됩니다.',
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
                      description: '이 기록은 1억 프로젝트의 "혜택/절약"에 포함됩니다.',
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
