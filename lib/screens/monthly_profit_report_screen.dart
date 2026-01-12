import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';
import '../services/monthly_agg_cache_service.dart';
import '../services/transaction_service.dart';
import '../utils/number_formats.dart';
import '../utils/icon_catalog.dart';

/// CEO용: 월간 손익보고서 화면
class MonthlyProfitReportScreen extends StatefulWidget {
  final String accountName; // should be 'root' for aggregated view

  const MonthlyProfitReportScreen({super.key, required this.accountName});

  @override
  State<MonthlyProfitReportScreen> createState() =>
      _MonthlyProfitReportScreenState();
}

class _MonthlyProfitReportScreenState extends State<MonthlyProfitReportScreen> {
  late final List<Transaction> _allTxs;

  @override
  void initState() {
    super.initState();
    _allTxs = TransactionService().getAllTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = widget.accountName.toLowerCase() == 'root';
    if (!isRoot) {
      return Scaffold(
        appBar: AppBar(title: const Text('월간 손익보고서')),
        body: const Center(child: Text('이 보고서는 루트(root) 계정에서만 볼 수 있습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('월간 손익보고서'),
        actions: [
          IconButton(
            tooltip: 'CSV 내보내기',
            icon: const Icon(IconCatalog.download),
            onPressed: () async {
              await _exportCsv(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<MonthlyAggCache>(
        future: MonthlyAggCacheService().ensureBuilt(
          accountName: widget.accountName,
          transactions: _allTxs,
          maxMonths: 12,
        ),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final cache = snap.data ?? MonthlyAggCache.empty();

          // Sort months descending
          final months = cache.months.keys.toList()
            ..sort((a, b) => b.compareTo(a));
          if (months.isEmpty) {
            return const Center(child: Text('집계할 데이터가 없습니다.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 ${months.length}개월 손익',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('월')),
                        DataColumn(label: Text('수입')),
                        DataColumn(label: Text('지출')),
                        DataColumn(label: Text('환불')),
                        DataColumn(label: Text('순이익')),
                      ],
                      rows: months.map((ym) {
                        final bucket = cache.months[ym]!;
                        final income = bucket.incomeAmount;
                        final expense = bucket.expenseAggAmount;
                        final refund = bucket.refundAmount;
                        final net = income - expense;
                        return DataRow(
                          cells: [
                            DataCell(Text(ym)),
                            DataCell(
                              Text(
                                '₩'
                                '${NumberFormats.currency.format(income.toInt())}',
                              ),
                            ),
                            DataCell(
                              Text(
                                '₩'
                                '${NumberFormats.currency.format(expense.toInt())}',
                              ),
                            ),
                            DataCell(
                              Text(
                                '₩'
                                '${NumberFormats.currency.format(refund.toInt())}',
                              ),
                            ),
                            DataCell(
                              Text(
                                '₩'
                                '${NumberFormats.currency.format(net.toInt())}',
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '요약',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        _buildSummary(cache, months),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final cache = await MonthlyAggCacheService().ensureBuilt(
        accountName: widget.accountName,
        transactions: _allTxs,
        maxMonths: 12,
      );
      if (!context.mounted) return;
      final months = cache.months.keys.toList()..sort((a, b) => b.compareTo(a));
      if (months.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('집계 데이터가 없어 내보낼 항목이 없습니다.')),
        );
        return;
      }

      final headers = ['월', '수입', '지출', '환불', '순이익'];
      final rows = <List<dynamic>>[
        headers,
        for (final ym in months)
          () {
            final b = cache.months[ym]!;
            final income = b.incomeAmount.toInt();
            final expense = b.expenseAggAmount.toInt();
            final refund = b.refundAmount.toInt();
            final net = (b.incomeAmount - b.expenseAggAmount).toInt();
            return [ym, income, expense, refund, net];
          }(),
      ];

      final csvData = const ListToCsvConverter().convert(rows);
      final dir = await getDownloadsDirectory();
      if (dir == null) {
        if (!context.mounted) return;
        messenger?.showSnackBar(
          const SnackBar(content: Text('다운로드 폴더를 찾을 수 없습니다.')),
        );
        return;
      }
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final csvPath = '${dir.path}/monthly_profit_report_$stamp.csv';
      await File(csvPath).writeAsString(csvData);

      await SharePlus.instance.share(
        ShareParams(text: '월간 손익보고서 CSV', files: [XFile(csvPath)]),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text('CSV 내보내기 실패: $e')));
    }
  }

  Widget _buildSummary(MonthlyAggCache cache, List<String> months) {
    double totalIncome = 0;
    double totalExpense = 0;
    double totalRefund = 0;
    for (final ym in months) {
      final b = cache.months[ym]!;
      totalIncome += b.incomeAmount;
      totalExpense += b.expenseAggAmount;
      totalRefund += b.refundAmount;
    }
    final totalNet = totalIncome - totalExpense;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('기간 합계 (${months.length}개월)'),
        const SizedBox(height: 6),
        Text('총 수입: ₩${NumberFormats.currency.format(totalIncome.toInt())}'),
        Text('총 지출: ₩${NumberFormats.currency.format(totalExpense.toInt())}'),
        Text('총 환불: ₩${NumberFormats.currency.format(totalRefund.toInt())}'),
        const SizedBox(height: 6),
        Text(
          '총 순이익: ₩${NumberFormats.currency.format(totalNet.toInt())}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
