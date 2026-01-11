import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/ceo_monthly_defense_report_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test(
    'generate monthly defense report files',
    () async {
      final res = await generateMonthlyDefenseReportFiles(
        'root',
        includeRoots: true,
      );
      expect(res.containsKey('text'), true);
      expect(res.containsKey('csv'), true);
      expect(res.containsKey('pdf'), true);
      final csvPath = res['csv']!;
      final pdfPath = res['pdf']!;
      expect(File(csvPath).existsSync(), true);
      expect(File(pdfPath).existsSync(), true);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
