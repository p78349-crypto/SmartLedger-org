// 날짜별 거래 그룹핑 및 합계 표시용 위젯
import 'package:flutter/material.dart';
import 'package:smart_ledger/models/transaction.dart' as model;
import 'package:smart_ledger/utils/currency_formatter.dart';

class GroupedTransactionList extends StatelessWidget {
  final List<model.Transaction> transactions;
  const GroupedTransactionList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, List<model.Transaction>> grouped = {};
    for (final t in transactions) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    double totalOutflowAll = 0;
    final List<_DailyOutflow> dailyOutflows = [];
    for (final date in sortedDates) {
      final entries = grouped[date]!;
      final expense = entries
          .where((t) => t.type == model.TransactionType.expense)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final savings = entries
          .where((t) => t.type == model.TransactionType.savings)
          .fold<double>(0, (sum, t) {
            if (t.savingsAllocation == model.SavingsAllocation.assetIncrease) {
              return sum + t.amount;
            }
            return sum - t.amount;
          });
      final dailyOutflow = expense + savings.abs();
      totalOutflowAll += dailyOutflow;
      dailyOutflows.add(_DailyOutflow(date: date, outflow: dailyOutflow));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dailyOutflows.length + 1,
      separatorBuilder: (context, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _AmountRow(
            label: '지출 합계',
            amount: '-${CurrencyFormatter.formatLargeAmount(totalOutflowAll)}원',
            emphasize: true,
          );
        }
        final daily = dailyOutflows[index - 1];
        final label = '${daily.date.month}-${daily.date.day}';
        return _AmountRow(
          label: label,
          amount: '-${CurrencyFormatter.formatLargeAmount(daily.outflow)}원',
          emphasize: false,
        );
      },
    );
  }
}

class _DailyOutflow {
  final DateTime date;
  final double outflow;
  const _DailyOutflow({required this.date, required this.outflow});
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool emphasize;
  const _AmountRow({
    required this.label,
    required this.amount,
    required this.emphasize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
              fontSize: emphasize ? 15 : 14,
            ),
          ),
          Expanded(
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: emphasize ? Colors.red[700] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

