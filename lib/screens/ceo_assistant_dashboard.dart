import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../services/asset_service.dart';
import '../services/monthly_agg_cache_service.dart';
import '../services/transaction_service.dart';
import '../utils/number_formats.dart';

/// CEO 지능형 비서 대시보드 (root 전용)
///
/// 컴파일/테스트 안정성을 위해 이 화면은 “가벼운 허브” 역할만 합니다.
/// (깊은 분석/복잡한 휴리스틱은 각 전용 화면에서 수행)
class CEOAssistantDashboard extends StatelessWidget {
  final String accountName; // expect 'root'

  const CEOAssistantDashboard({super.key, required this.accountName});

  @override
  Widget build(BuildContext context) {
    final isRoot = accountName.toLowerCase() == 'root';
    if (!isRoot) {
      return Scaffold(
        appBar: AppBar(title: const Text('CEO 비서 대시보드')),
        body: const Center(child: Text('루트(root) 계정에서만 접근 가능합니다.')),
      );
    }

    final txs = TransactionService().getAllTransactions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CEO 비서 대시보드'),
        actions: [
          IconButton(
            tooltip: '월간 자산 방어 보고서',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.ceoMonthlyDefenseReport),
          ),
        ],
      ),
      body: FutureBuilder<MonthlyAggCache>(
        future: MonthlyAggCacheService().ensureBuilt(
          accountName: accountName,
          transactions: txs,
          maxMonths: 12,
        ),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final cache = snap.data;

          double totalAssets = 0;
          final assetService = AssetService();
          for (final acct in assetService.getTrackedAccountNames()) {
            for (final a in assetService.getAssets(acct)) {
              totalAssets += a.amount;
            }
          }

          final months = (cache?.months.keys.toList() ?? <String>[])..sort();
          double lastMonthIncome = 0;
          double lastMonthExpense = 0;
          if (months.isNotEmpty && cache != null) {
            final last = cache.months[months.last];
            if (last != null) {
              lastMonthIncome = last.incomeAmount;
              lastMonthExpense = last.expenseAggAmount;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metricCard(
                    context,
                    title: '총 자산',
                    value:
                        '₩'
                        '${NumberFormats.currency.format(totalAssets.toInt())}',
                    icon: Icons.account_balance_wallet,
                  ),
                  _metricCard(
                    context,
                    title: '최근 월 수입',
                    value:
                        '₩'
                        '${NumberFormats.currency.format(lastMonthIncome.toInt())}',
                    icon: Icons.trending_up,
                  ),
                  _metricCard(
                    context,
                    title: '최근 월 지출',
                    value:
                        '₩'
                        '${NumberFormats.currency.format(lastMonthExpense.toInt())}',
                    icon: Icons.trending_down,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.shield),
                      title: const Text('월간 자산 방어 전투 보고서'),
                      subtitle: const Text('CSV/PDF 내보내기 및 TTS 포함'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.ceoMonthlyDefenseReport),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.show_chart),
                      title: const Text('ROI 상세 분석'),
                      subtitle: const Text('기본값: 최근 12개월 + 3개월 전망'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.ceoRoiDetail),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.warning_amber),
                      title: const Text('예외 지출 상세'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.ceoExceptionDetails),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.build_circle_outlined),
                      title: const Text('복구 계획 제안'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.ceoRecoveryPlan),
                    ),
                  ],
                ),
              ),
              if (cache == null) ...[
                const SizedBox(height: 12),
                const Text('집계 데이터가 없어 일부 지표가 비어있습니다.'),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: SizedBox(
        width: 220,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
