import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/stats_labels.dart';

void main() {
  group('StatsLabels', () {
    group('Transaction type labels', () {
      test('expense is 지출', () {
        expect(StatsLabels.expense, '지출');
      });

      test('income is 수입', () {
        expect(StatsLabels.income, '수입');
      });

      test('savings is 예금', () {
        expect(StatsLabels.savings, '예금');
      });
    });

    group('Detail labels', () {
      test('expenseDetails is defined', () {
        expect(StatsLabels.expenseDetails, '지출 상세내역');
      });

      test('incomeDetails is defined', () {
        expect(StatsLabels.incomeDetails, '수입 상세내역');
      });

      test('transactionDetails is defined', () {
        expect(StatsLabels.transactionDetails, '거래 상세내역');
      });
    });

    group('Income distribution labels', () {
      test('incomeDistributionMenu is defined', () {
        expect(StatsLabels.incomeDistributionMenu, '수입배분');
      });

      test('incomeDistributionTooltip is defined', () {
        expect(StatsLabels.incomeDistributionTooltip, '수입 배분');
      });
    });

    group('Other labels', () {
      test('carryover is 이월', () {
        expect(StatsLabels.carryover, '이월');
      });

      test('backup is 백업/복원', () {
        expect(StatsLabels.backup, '백업/복원');
      });
    });

    group('Fixed cost labels', () {
      test('fixedCostLabel is 고정비', () {
        expect(StatsLabels.fixedCostLabel, '고정비');
      });

      test('includeFixedCosts is defined', () {
        expect(StatsLabels.includeFixedCosts, '고정비 포함');
      });

      test('fixedCostSection is defined', () {
        expect(StatsLabels.fixedCostSection, '고정비 항목');
      });

      test('fixedCostStats is defined', () {
        expect(StatsLabels.fixedCostStats, '고정비 통계');
      });
    });
  });
}
