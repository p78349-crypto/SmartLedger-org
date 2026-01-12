import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/nutrition_report_utils.dart';

void main() {
  group('NutritionReportUtils', () {
    test('estimateSugarCubesForCola2L returns expected range', () {
      final est = NutritionReportUtils.estimateSugarCubesForCola2L();
      expect(est.sugarMinG, 200);
      expect(est.sugarMaxG, 220);
      expect(est.minCubes, 50); // 200/4
      expect(est.maxCubes, 73); // 220/3 rounded
    });

    test('buildFromRawText extracts items, merges ranges, and detects cola 2L', () {
      const raw = '사과(1000-1200원) 우유 2500~3000원 사과 900~1100원 콜라 2L 2500원';
      final report = NutritionReportUtils.buildFromRawText(raw);

      expect(report.items, isNotEmpty);
      expect(report.hasCola2LHint, isTrue);

      final apple = report.items.firstWhere((i) => i.name.contains('사과'));
      expect(apple.priceMinWon, 900);
      expect(apple.priceMaxWon, 1200);

      // Total is sum of merged unique names.
      expect(report.totalMinWon, greaterThan(0));
      expect(report.totalMaxWon, greaterThanOrEqualTo(report.totalMinWon));
    });

    test('buildFromRawText sorts items by mid price (desc)', () {
      const raw = 'A 100~100원 B 1000~1000원 C 500~500원';
      final report = NutritionReportUtils.buildFromRawText(raw);
      expect(report.items.first.name, 'B');
      expect(report.items.last.name, 'A');
    });
  });
}
