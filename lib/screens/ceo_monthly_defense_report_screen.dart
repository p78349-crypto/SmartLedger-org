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

  Future<void> _openTtsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    var rate = prefs.getDouble(PrefKeys.ttsSpeechRate) ?? 0.5;
    var pitch = prefs.getDouble(PrefKeys.ttsPitch) ?? 1.0;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: const Text('TTS 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('속도'),
                      Expanded(
                        child: Slider(
                          value: rate,
                          min: 0.1,
                          divisions: 9,
                          label: rate.toStringAsFixed(2),
                          onChanged: (v) => setLocalState(() => rate = v),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('톤'),
                      Expanded(
                        child: Slider(
                          value: pitch,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          label: pitch.toStringAsFixed(2),
                          onChanged: (v) => setLocalState(() => pitch = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await prefs.setDouble(PrefKeys.ttsSpeechRate, rate);
                    await prefs.setDouble(PrefKeys.ttsPitch, pitch);
                    if (!mounted || !ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    messenger?.showSnackBar(
                      const SnackBar(content: Text('TTS 설정 저장')),
                    );
                    await _applyTtsSettings();
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _copyReport(String text) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    messenger?.showSnackBar(const SnackBar(content: Text('보고서를 복사했습니다.')));
  }

  Future<void> _toggleSpeech(String reportText) async {
    if (_isSpeaking) {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    await _applyTtsSettings();
    await _tts.speak(reportText);
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _exportCsv(_ReportData data) async {
    final csvString = _encodeCsv(_buildCsvRows(data, _includeRoots));
    try {
      final file = await _writeTextFile(_fileStem(data.now), 'csv', csvString);
      await SharePlus.instance.share(
        ShareParams(
          text: '[TOP SECRET] 월간 자산 방어 전투 보고서 CSV',
          files: [XFile(file.path)],
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV 저장 및 공유 완료: ${file.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV 내보내기 실패: $e')));
    }
  }

  Future<void> _exportPdf(_ReportData data, String reportText) async {
    try {
      final bytes = await _buildPdfBytes(data, _includeRoots, reportText);
      final file = await _writeBinaryFile(_fileStem(data.now), 'pdf', bytes);
      await SharePlus.instance.share(
        ShareParams(
          text: '[TOP SECRET] 월간 자산 방어 전투 보고서 PDF',
          files: [XFile(file.path)],
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 저장 및 공유 완료: ${file.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 내보내기 실패: $e')));
    }
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
  final progressPct = (totalAssets / _kDefenseGoalWon * 100).clamp(0.0, 999.9);

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

String buildDefenseReportText(
  DateTime now,
  double totalAssets,
  double progressPct,
  double budgetRemaining,
  List<MapEntry<String, double>> categories,
  int captainBadgeCount,
  int workerBadgeCount,
  int points,
  bool includeRoots,
) {
  final currency = NumberFormats.currency;
  final compact = NumberFormats.currencyCompactKo;
  final buffer = StringBuffer();

  buffer.writeln('[TOP SECRET] 월간 자산 방어 전투 보고서');
  buffer.writeln('${now.year}년 ${now.month}월 작전 상황 요약');
  buffer.writeln(
    '총 자산: ${currency.format(totalAssets)} (목표 대비 ${progressPct.toStringAsFixed(1)}%)',
  );
  buffer.writeln('이번 달 작전 잔여 예산: ${currency.format(budgetRemaining)}');
  buffer.writeln();
  final topCount = categories.length >= 3 ? 3 : categories.length;
  buffer.writeln('적 지출 TOP ${topCount == 0 ? '0' : topCount}');
  if (categories.isEmpty) {
    buffer.writeln('- 보고된 지출 없음: 방어선 안정');
  } else {
    for (final entry in categories.take(3)) {
      buffer.writeln('- ${entry.key}: ${compact.format(entry.value)}');
    }
  }
  buffer.writeln();
  buffer.writeln('제이모 훈장 $captainBadgeCount개, 워커 훈장 $workerBadgeCount개 확보');
  buffer.writeln('지휘 포인트: ${points}pt');
  buffer.writeln();

  if (includeRoots) {
    buffer.writeln('※ 전략적 뿌리 해석');
    buffer.writeln('1) 방어선과 현금 흐름을 주간 단위로 재점검하십시오.');
    buffer.writeln('2) 지출 집중 카테고리를 원천 봉쇄 후보로 지정하고 48시간 경보를 유지하십시오.');
    buffer.writeln('3) 예비비는 방어 함대에 우선 배치하십시오.');
  } else {
    buffer.writeln('전략적 뿌리 정보는 비공개 상태입니다.');
  }

  buffer.writeln();
  buffer.writeln('보고 종료 — 외부 반출 금지.');
  return buffer.toString().trim();
}

List<List<String>> _buildCsvRows(_ReportData data, bool includeRoots) {
  final rows = <List<String>>[
    ['section', 'category', 'amount', 'note'],
  ];
  for (final entry in data.topCategories) {
    rows.add(['expense', entry.key, entry.value.toStringAsFixed(2), '']);
  }
  rows.add([
    'achievements',
    'captain_badges',
    data.captainBadgeCount.toString(),
    '',
  ]);
  rows.add([
    'achievements',
    'worker_badges',
    data.workerBadgeCount.toString(),
    '',
  ]);
  rows.add(['summary', 'points', data.points.toString(), '']);
  if (includeRoots) {
    rows.add(['note', 'strategic_roots', '', '전략적 뿌리 포함']);
  }
  return rows;
}

String _encodeCsv(List<List<String>> rows) {
  return rows
      .map(
        (row) => row
            .map((cell) {
              final escaped = cell.replaceAll('"', '""');
              return '"$escaped"';
            })
            .join(','),
      )
      .join('\n');
}

Future<List<int>> _buildPdfBytes(
  _ReportData data,
  bool includeRoots,
  String reportText,
) async {
  final font = await _loadKoreanFont();
  final doc = pw.Document();
  final baseStyle = font != null
      ? pw.TextStyle(font: font, fontSize: 12)
      : const pw.TextStyle(fontSize: 12);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text(
          '[TOP SECRET] 월간 자산 방어 전투 보고서',
          style: baseStyle.copyWith(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text('${data.now.year}년 ${data.now.month}월 상황', style: baseStyle),
        pw.SizedBox(height: 12),
        pw.Text(reportText, style: baseStyle),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          data: _buildCsvRows(data, includeRoots),
          headerStyle: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
          cellStyle: baseStyle,
        ),
      ],
    ),
  );
  return doc.save();
}

Future<pw.Font?> _loadKoreanFont() async {
  try {
    final data = await rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf');
    return pw.Font.ttf(data);
  } catch (e) {
    debugPrint('Font bundle load failed: $e');
    try {
      final file = File('assets/fonts/NotoSansKR-Regular.ttf');
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        return pw.Font.ttf(ByteData.view(bytes.buffer));
      }
    } catch (e2) {
      debugPrint('Font file fallback failed: $e2');
    }
  }
  return null;
}

Future<Directory> _resolveWritableDirectory() async {
  try {
    return await getTemporaryDirectory();
  } catch (e) {
    debugPrint('getTemporaryDirectory failed: $e');
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e2) {
      debugPrint('getApplicationDocumentsDirectory failed: $e2');
      return Directory.systemTemp;
    }
  }
}

Future<File> _writeTextFile(
  String stem,
  String extension,
  String contents,
) async {
  final dir = await _resolveWritableDirectory();
  final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final file = File('${dir.path}/${stem}_$stamp.$extension');
  return file.writeAsString(contents);
}

Future<File> _writeBinaryFile(
  String stem,
  String extension,
  List<int> bytes,
) async {
  final dir = await _resolveWritableDirectory();
  final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final file = File('${dir.path}/${stem}_$stamp.$extension');
  return file.writeAsBytes(bytes);
}

String _fileStem(DateTime now) =>
    'monthly_defense_report_${now.year}_${now.month.toString().padLeft(2, '0')}';

Future<Map<String, String>> generateMonthlyDefenseReportFiles(
  String accountName, {
  bool includeRoots = false,
}) async {
  final data = await _fetchReportData(accountName);
  final reportText = buildDefenseReportText(
    data.now,
    data.totalAssets,
    data.progressPct,
    data.budgetRemaining,
    data.topCategories,
    data.captainBadgeCount,
    data.workerBadgeCount,
    data.points,
    includeRoots,
  );

  final csvString = _encodeCsv(_buildCsvRows(data, includeRoots));
  final csvFile = await _writeTextFile(_fileStem(data.now), 'csv', csvString);
  final pdfBytes = await _buildPdfBytes(data, includeRoots, reportText);
  final pdfFile = await _writeBinaryFile(_fileStem(data.now), 'pdf', pdfBytes);

  return {'text': reportText, 'csv': csvFile.path, 'pdf': pdfFile.path};
}
