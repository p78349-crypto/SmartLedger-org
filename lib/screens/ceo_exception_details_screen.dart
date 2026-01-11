import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/monthly_agg_cache_service.dart';
import '../services/transaction_service.dart';
import '../utils/number_formats.dart';

class CEOExceptionDetailsScreen extends StatelessWidget {
  final String accountName;
  const CEOExceptionDetailsScreen({super.key, required this.accountName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('예외 지출 상세')),
      body: FutureBuilder<MonthlyAggCache>(
        future: MonthlyAggCacheService().ensureBuilt(
          accountName: accountName,
          transactions: TransactionService().getAllTransactions(),
          maxMonths: 12,
        ),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cache = snap.data!;
          final months = cache.months.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          // Heuristic: months with expense > median*1.5
          final expenses =
              months.map((m) => cache.months[m]!.expenseAggAmount).toList()
                ..sort();
          final median = expenses.isEmpty
              ? 0.0
              : expenses[expenses.length ~/ 2];
          final flagged = months
              .where((m) => cache.months[m]!.expenseAggAmount > median * 1.5)
              .toList();

          if (flagged.isEmpty) {
            return const Center(child: Text('최근 예외 지출이 없습니다.'));
          }

          // Build grouped causes across flagged months
          final allTxs = TransactionService().getAllTransactions();
          final Map<String, List<Transaction>> byStore = {};
          final Map<String, List<Transaction>> byCategory = {};

          for (final ym in flagged) {
            final monthTxs = allTxs
                .where(
                  (t) =>
                      MonthlyAggCacheService.yearMonthOf(t.date) == ym &&
                      t.type == TransactionType.expense,
                )
                .toList();
            for (final t in monthTxs) {
              final store = t.store?.trim().isNotEmpty == true
                  ? t.store!.trim()
                  : (t.memo.trim().isNotEmpty ? t.memo.trim() : '알 수 없음');
              byStore.putIfAbsent(store, () => []).add(t);
              final main = t.mainCategory.trim().isEmpty
                  ? Transaction.defaultMainCategory
                  : t.mainCategory.trim();
              final sub = (t.subCategory ?? '').trim();
              final cat = sub.isEmpty ? main : '$main / $sub';
              byCategory.putIfAbsent(cat, () => []).add(t);
            }
          }

          // Sort groups by total amount desc
          final topStores = byStore.entries.toList()
            ..sort(
              (a, b) => b.value
                  .fold<double>(0, (s, t) => s + t.amount.abs())
                  .compareTo(
                    a.value.fold<double>(0, (s, t) => s + t.amount.abs()),
                  ),
            );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '예외 지출 원인 (가게 기준)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...topStores.take(10).map((entry) {
                final key = entry.key;
                final list = entry.value;
                final total = list.fold<double>(
                  0,
                  (s, t) => s + t.amount.abs(),
                );
                return ExpansionTile(
                  title: Text(
                    '$key · ₩${NumberFormats.currency.format(total.toInt())}',
                  ),
                  subtitle: Text('${list.length}건'),
                  children: list
                      .map(
                        (t) => ListTile(
                          title: Text(
                            t.memo.isNotEmpty ? t.memo : (t.store ?? ''),
                          ),
                          subtitle: Text(
                            '${t.mainCategory} ${t.subCategory ?? ''}'.trim(),
                          ),
                          trailing: Text(
                            '₩${NumberFormats.currency.format(t.amount.abs().toInt())}',
                          ),
                        ),
                      )
                      .toList(),
                );
              }),
              const SizedBox(height: 12),
              const Text(
                '예외 지출 원인 (카테고리 기준)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...byCategory.entries.take(10).map((entry) {
                final key = entry.key;
                final list = entry.value;
                final total = list.fold<double>(
                  0,
                  (s, t) => s + t.amount.abs(),
                );
                return ExpansionTile(
                  title: Text(
                    '$key · ₩${NumberFormats.currency.format(total.toInt())}',
                  ),
                  subtitle: Text('${list.length}건'),
                  children: list
                      .map(
                        (t) => ListTile(
                          title: Text(
                            t.memo.isNotEmpty ? t.memo : (t.store ?? ''),
                          ),
                          subtitle: Text(
                            '${DateTime(t.date.year, t.date.month, t.date.day)}',
                          ),
                          trailing: Text(
                            '₩${NumberFormats.currency.format(t.amount.abs().toInt())}',
                          ),
                        ),
                      )
                      .toList(),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
