import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/stats_view_utils.dart';

void main() {
  group('StatsViewUtils', () {
    test('meta returns stable id/label/icon', () {
      final meta = StatsViewUtils.meta(StatsView.year);
      expect(meta.id, 'stats_year');
      expect(meta.label, 'Year');
      expect(meta.icon, isNotNull);
    });

    test('allMetas includes all registered views', () {
      final metas = StatsViewUtils.allMetas();
      expect(metas, hasLength(StatsView.values.length));
      expect(metas.map((m) => m.id).toSet(), contains('stats_chart'));
    });

    test('string helpers classify views', () {
      expect(StatsViewUtils.isRangeView('halfYear'), isTrue);
      expect(StatsViewUtils.isChartView('chart'), isTrue);
      expect(StatsViewUtils.isDetailView('expenseDetail'), isTrue);
      expect(StatsViewUtils.isDetailView('month'), isFalse);
    });

    test('toggleView switches to month when toggling same target', () {
      expect(StatsViewUtils.toggleView('month', 'year'), 'year');
      expect(StatsViewUtils.toggleView('year', 'year'), 'month');
    });

    test('detailViewForTransaction maps types', () {
      expect(
        StatsViewUtils.detailViewForTransaction(TransactionType.expense),
        StatsView.expenseDetail,
      );
      expect(
        StatsViewUtils.detailViewForTransaction(TransactionType.refund),
        StatsView.refundDetail,
      );
    });
  });
}
