import 'package:flutter/material.dart';

import '../services/monthly_agg_cache_service.dart';
import '../services/transaction_service.dart';
import '../utils/number_formats.dart';

class CEORecoveryPlanScreen extends StatelessWidget {
  final String accountName;
  const CEORecoveryPlanScreen({super.key, required this.accountName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('복구 계획 제안')),
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
          final months = cache.months.keys.toList()..sort();
          if (months.isEmpty) return const Center(child: Text('데이터 부족'));

          final recent = cache.months[months.last]!;
          final avgExpense =
              months
                  .map((m) => cache.months[m]!.expenseAggAmount)
                  .fold<double>(0, (s, v) => s + v) /
              months.length;

          final suggestedCut = (avgExpense * 0.3).toInt();
          final suggestedNoSpendSavings = (avgExpense * 0.1).toInt();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 월 지출: ₩${NumberFormats.currency.format(recent.expenseAggAmount.toInt())}',
                ),
                const SizedBox(height: 8),
                Text(
                  '평균 월 지출: ₩${NumberFormats.currency.format(avgExpense.toInt())}',
                ),
                const SizedBox(height: 12),
                const Text('권장 복구 계획'),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('1) 비용 우선순위 조정'),
                    subtitle: Text(
                      '비핵심 지출을 3개월간 30% 감축 — 예상 절감: ₩${NumberFormats.currency.format(suggestedCut)} (월)',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Card(
                  child: ListTile(
                    title: Text('2) 예비비 사용 가이드라인'),
                    subtitle: Text('예외 지출은 예비비의 50% 이상 초과 금지는 승인 필요'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('3) 무지출 캠페인'),
                    subtitle: Text(
                      '무지출 데이 4회 도입으로 예상 절감: ₩${NumberFormats.currency.format(suggestedNoSpendSavings)} (월)',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Placeholder: apply plan (would toggle flags / create tasks)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('복구 계획이 임시로 적용되었습니다.')),
                        );
                      },
                      child: const Text('계획 적용 (임시)'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
