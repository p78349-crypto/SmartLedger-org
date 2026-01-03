import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final file = File('${Directory.current.path}/tools/INDEX_CODE_FEATURES.md');
  if (!file.existsSync()) {
    stderr.writeln('INDEX file not found at tools/INDEX_CODE_FEATURES.md');
    exit(2);
  }
  final lines = file.readAsLinesSync();

  final rows = <Map<String, String>>[];
  bool inTable = false;
  for (final line in lines) {
    if (line.startsWith('|---')) {
      inTable = true;
      continue;
    }
    if (!inTable) continue;
    if (!line.startsWith('|')) continue;

    // split on | and trim
    final parts = line.split('|').map((p) => p.trim()).toList();
    // parts: ['', Date, What, Old, New, Note, ''] (depending on trailing pipes)
    if (parts.length < 6) continue;
    final date = parts[1];
    final what = parts[2];
    final old = parts[3];
    final ne = parts[4];
    final note = parts[5];

    rows.add({'date': date, 'what': what, 'old': old, 'new': ne, 'note': note});
  }

  // Output CSV
  final csv = StringBuffer();
  csv.writeln('date,what,old,new,note');
  for (final r in rows) {
    final csvLine = [
      r['date'],
      r['what'],
      r['old'],
      r['new'],
      r['note'],
    ].map((s) => '"${(s ?? '').replaceAll('"', '""')}"').join(',');
    csv.writeln(csvLine);
  }
  final outCsv = File('tools/index_export.csv');
  outCsv.writeAsStringSync(csv.toString());

  // Output JSON
  final outJson = File('tools/index_export.json');
  outJson.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));

  stdout.writeln(
    'Exported ${rows.length} index rows to tools/index_export.csv and tools/index_export.json',
  );
}
