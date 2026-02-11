part of 'ceo_monthly_defense_report_screen.dart';

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
    '총 자산: ${currency.format(totalAssets)} '
    '(목표 대비 ${progressPct.toStringAsFixed(1)}%)',
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
    'monthly_defense_report_${now.year}_'
    '${now.month.toString().padLeft(2, '0')}';

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
