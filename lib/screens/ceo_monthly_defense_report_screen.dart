import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import '../services/asset_service.dart';
import '../services/monthly_agg_cache_service.dart';
import '../services/policy_service.dart';
import '../services/transaction_service.dart';
import '../utils/number_formats.dart';
import '../utils/pref_keys.dart';

part 'ceo_monthly_defense_report_screen_dialogs.dart';
part 'ceo_monthly_defense_report_screen_report.dart';

const double _kDefenseGoalWon = 100000000.0;

class CEOMonthlyDefenseReportScreen extends StatefulWidget {
  final String accountName;
  const CEOMonthlyDefenseReportScreen({super.key, required this.accountName});

  @override
  State<CEOMonthlyDefenseReportScreen> createState() =>
      _CEOMonthlyDefenseReportScreenState();
}

class _CEOMonthlyDefenseReportScreenState
    extends State<CEOMonthlyDefenseReportScreen> {
  late final Future<_ReportData> _reportFuture;
  late final FlutterTts _tts;
  bool _includeRoots = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _reportFuture = _fetchReportData(widget.accountName);
    _tts = FlutterTts();
    _tts.awaitSpeakCompletion(true);
    _applyTtsSettings();
  }

  Future<void> _applyTtsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final rate = prefs.getDouble(PrefKeys.ttsSpeechRate) ?? 0.5;
    final pitch = prefs.getDouble(PrefKeys.ttsPitch) ?? 1.0;
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('[TOP SECRET] 월간 자산 방어 전투 보고서'),
        actions: [
          IconButton(
            tooltip: 'TTS 설정',
            icon: const Icon(Icons.settings_voice),
            onPressed: _openTtsDialog,
          ),
        ],
      ),
      body: FutureBuilder<_ReportData>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text('보고서 데이터를 불러오지 못했습니다: ${snapshot.error}'),
            );
          }
          final data = snapshot.data!;
          final reportText = buildDefenseReportText(
            data.now,
            data.totalAssets,
            data.progressPct,
            data.budgetRemaining,
            data.topCategories,
            data.captainBadgeCount,
            data.workerBadgeCount,
            data.points,
            _includeRoots,
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      reportText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('전략적 뿌리 포함'),
                      selected: _includeRoots,
                      onSelected: (value) =>
                          setState(() => _includeRoots = value),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(text: reportText),
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text('텍스트 공유'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _copyReport(reportText),
                      icon: const Icon(Icons.copy),
                      label: const Text('복사'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _exportCsv(data),
                      icon: const Icon(Icons.grid_on),
                      label: const Text('CSV'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _exportPdf(data, reportText),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _toggleSpeech(reportText),
                      icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                      label: Text(_isSpeaking ? '중지' : 'TTS'),
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

class _ReportData {
  final DateTime now;
  final double totalAssets;
  final double progressPct;
  final double budgetRemaining;
  final List<MapEntry<String, double>> topCategories;
  final int captainBadgeCount;
  final int workerBadgeCount;
  final int points;

  const _ReportData({
    required this.now,
    required this.totalAssets,
    required this.progressPct,
    required this.budgetRemaining,
    required this.topCategories,
    required this.captainBadgeCount,
    required this.workerBadgeCount,
    required this.points,
  });
}

Future<_ReportData> _fetchReportData(String accountName) async {
  final now = DateTime.now();
  final transactionService = TransactionService();
  final transactions = transactionService.getAllTransactions();
  final cache = await MonthlyAggCacheService().ensureBuilt(
    accountName: accountName,
    transactions: transactions,
    maxMonths: 12,
  );

  double totalAssets = 0;
  final assetService = AssetService();
  for (final acct in assetService.getTrackedAccountNames()) {
    for (final asset in assetService.getAssets(acct)) {
      totalAssets += asset.amount;
    }
  }
  final progressPct =
      (totalAssets / _kDefenseGoalWon * 100).clamp(0.0, 999.9);

  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final monthAgg = cache.months[monthKey];
  final monthIncome = monthAgg?.incomeAmount ?? 0.0;
  final monthExpense = monthAgg?.expenseAggAmount ?? 0.0;
  final budgetRemaining = monthIncome - monthExpense;

  final monthExpenses = transactions
      .where(
        (t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month,
      )
      .toList();
  final Map<String, double> byCat = {};
  for (final tx in monthExpenses) {
    final key = tx.mainCategory;
    byCat[key] = (byCat[key] ?? 0) + tx.amount.abs();
  }
  final sorted = byCat.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final holds = await PolicyService().listHolds();
  final rules = await PolicyService().listBlockingRules();
  final captainBadgeCount = holds.length;
  final workerBadgeCount = rules.length;
  final points =
      (captainBadgeCount * 50) +
      (workerBadgeCount * 100) +
      (budgetRemaining > 0 ? (budgetRemaining / 1000).round() : 0);

  return _ReportData(
    now: now,
    totalAssets: totalAssets,
    progressPct: progressPct,
    budgetRemaining: budgetRemaining,
    topCategories: sorted,
    captainBadgeCount: captainBadgeCount,
    workerBadgeCount: workerBadgeCount,
    points: points,
  );
}
