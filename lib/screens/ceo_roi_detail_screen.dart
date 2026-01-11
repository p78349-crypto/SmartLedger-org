import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';

import '../services/transaction_service.dart';
import '../utils/roi_utils.dart';
import '../utils/number_formats.dart';
import '../utils/icon_catalog.dart';

class CEORoiDetailScreen extends StatelessWidget {
  final String accountName; // expect 'root'
  final DateTime start;
  final DateTime end;
  final int lookaheadMonths;

  const CEORoiDetailScreen({
    super.key,
    required this.accountName,
    required this.start,
    required this.end,
    this.lookaheadMonths = 3,
  });

  @override
  Widget build(BuildContext context) {
    final allTx = TransactionService().getAllTransactions();
    final summary = RoiUtils.computeOverallRoi(
      allTx,
      start: start,
      end: end,
      lookaheadMonths: lookaheadMonths,
    );
    final byCategory = summary['byCategory'] as Map<String, dynamic>;

    // build monthly ROI series for the chart
    List<DateTime> monthsInWindow(DateTime s, DateTime e) {
      final res = <DateTime>[];
      var cur = DateTime(s.year, s.month);
      final endMonth = DateTime(e.year, e.month);
      while (!cur.isAfter(endMonth)) {
        res.add(cur);
        cur = DateTime(cur.year, cur.month + 1);
      }
      return res;
    }

    final monthsList = monthsInWindow(start, DateTime(end.year, end.month - 1));
    final List<double> monthlyRoi = [];
    for (final m in monthsList) {
      final mStart = DateTime(m.year, m.month);
      final mEnd = DateTime(m.year, m.month + 1);
      final ms = RoiUtils.computeOverallRoi(
        allTx,
        start: mStart,
        end: mEnd,
        lookaheadMonths: lookaheadMonths,
      );
      final or = ms['overallRoi'] as double?;
      monthlyRoi.add(or ?? 0.0);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ROI 상세 분석')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ROI trend chart
            SizedBox(
              height: 160,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: monthlyRoi.isEmpty
                      ? const Center(child: Text('차트 데이터가 없습니다.'))
                      : LineChart(
                          LineChartData(
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (v, meta) {
                                    final idx = v.toInt();
                                    if (idx < 0 || idx >= monthsList.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final dt = monthsList[idx];
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text('${dt.month}/${dt.year}'),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  monthlyRoi.length,
                                  (i) =>
                                      FlSpot(i.toDouble(), monthlyRoi[i] * 100),
                                ),
                                isCurved: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0x1155AAFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '카테고리별 지출 대비 수익 (${start.year}-${start.month.toString().padLeft(2, '0')} ~ ${end.year}-${(end.month - 1).toString().padLeft(2, '0')}, lookahead $lookaheadMonths개월)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(IconCatalog.download),
                  tooltip: 'CSV 내보내기 및 공유',
                  onPressed: () => _exportCsvAndShare(
                    context,
                    byCategory,
                    start,
                    end,
                    lookaheadMonths,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('카테고리')),
                    DataColumn(label: Text('지출')),
                    DataColumn(label: Text('수익')),
                    DataColumn(label: Text('ROI')),
                  ],
                  rows: byCategory.entries.map<DataRow>((e) {
                    final cat = e.key;
                    final map = Map<String, dynamic>.from(e.value as Map);
                    final spent = (map['spent'] as double?) ?? 0.0;
                    final ret = (map['return'] as double?) ?? 0.0;
                    final roi = map['roi'] as double?;
                    final roiLabel = roi == null
                        ? 'N/A'
                        : '${(roi * 100).toStringAsFixed(1)}%';
                    return DataRow(
                      cells: [
                        DataCell(Text(cat)),
                        DataCell(
                          Text(
                            '₩${NumberFormats.currency.format(spent.toInt())}',
                          ),
                        ),
                        DataCell(
                          Text(
                            '₩${NumberFormats.currency.format(ret.toInt())}',
                          ),
                        ),
                        DataCell(Text(roiLabel)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsvAndShare(
    BuildContext context,
    Map<String, dynamic> byCategory,
    DateTime start,
    DateTime end,
    int lookaheadMonths,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final rows = <List<String>>[];
    rows.add(['category', 'spent', 'return', 'roi']);
    for (final e in byCategory.entries) {
      final cat = e.key;
      final map = Map<String, dynamic>.from(e.value as Map);
      final spent = (map['spent'] as double?) ?? 0.0;
      final ret = (map['return'] as double?) ?? 0.0;
      final roi = map['roi'] as double?;
      final roiStr = roi == null ? '' : roi.toString();
      rows.add([cat, spent.toString(), ret.toString(), roiStr]);
    }

    final csv = rows
        .map((r) => r.map((c) => '"${c.replaceAll('"', '""')}"').join(','))
        .join('\n');

    try {
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final path =
          '${dir.path}/ceo_roi_detail_${start.year}${start.month.toString().padLeft(2, '0')}_to_${end.year}${end.month.toString().padLeft(2, '0')}_la${lookaheadMonths}_$stamp.csv';
      await File(path).writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(text: 'CEO ROI 상세 CSV', files: [XFile(path)]),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text('CSV 내보내기 실패: $e')));
    }
  }
}
