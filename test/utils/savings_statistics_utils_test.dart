import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/cooking_usage_log.dart';
import 'package:smart_ledger/utils/savings_statistics_utils.dart';

void main() {
  group('SavingsStatisticsUtils', () {
    group('calculateCookingSuccessIndex', () {
      test('returns 0 for empty logs', () {
        final result = SavingsStatisticsUtils.calculateCookingSuccessIndex([]);
        expect(result, 0);
      });

      test('counts logs from existing inventory in challenge period', () {
        final now = DateTime.now();
        final challengeDate = DateTime(now.year, now.month, 22);

        final logs = <CookingUsageLog>[
          CookingUsageLog(
            id: '1',
            recipeName: '달걀요리',
            usageDate: challengeDate,
            isFromExistingInventory: true,
            totalUsedPrice: 1000,
          ),
          CookingUsageLog(
            id: '2',
            recipeName: '양파요리',
            usageDate: challengeDate,
            isFromExistingInventory: false, // not from inventory
            totalUsedPrice: 500,
          ),
        ];

        final result = SavingsStatisticsUtils.calculateCookingSuccessIndex(logs);
        expect(result, 1);
      });
    });

    group('calculateSavedIngredientsValue', () {
      test('returns 0 for empty logs', () {
        final result = SavingsStatisticsUtils.calculateSavedIngredientsValue([]);
        expect(result, 0);
      });

      test('sums values from inventory logs', () {
        final logs = <CookingUsageLog>[
          CookingUsageLog(
            id: '1',
            recipeName: '달걀요리',
            usageDate: DateTime.now(),
            isFromExistingInventory: true,
            totalUsedPrice: 1000,
          ),
          CookingUsageLog(
            id: '2',
            recipeName: '양파요리',
            usageDate: DateTime.now(),
            isFromExistingInventory: true,
            totalUsedPrice: 500,
          ),
        ];

        final result = SavingsStatisticsUtils.calculateSavedIngredientsValue(logs);
        expect(result, 1500);
      });

      test('includes logs with 임박 in memo', () {
        final logs = <CookingUsageLog>[
          CookingUsageLog(
            id: '1',
            recipeName: '우유요리',
            usageDate: DateTime.now(),
            isFromExistingInventory: false,
            totalUsedPrice: 2000,
            memo: '유통기한 임박 사용',
          ),
        ];

        final result = SavingsStatisticsUtils.calculateSavedIngredientsValue(logs);
        expect(result, 2000);
      });
    });

    group('calculateMonthlyFoodExpenses', () {
      test('returns empty for empty transactions', () {
        final result = SavingsStatisticsUtils.calculateMonthlyFoodExpenses([]);
        expect(result, isEmpty);
      });
    });

    group('compareSavings', () {
      test('calculates savings between months', () {
        final now = DateTime.now();
        final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final lastMonthDate = DateTime(now.year, now.month - 1);
        final lastMonth = '${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}';

        final expenses = {
          lastMonth: 500000.0,
          thisMonth: 400000.0,
        };

        final result = SavingsStatisticsUtils.compareSavings(expenses);
        expect(result.beforePrice, 500000);
        expect(result.afterPrice, 400000);
        expect(result.savingsAmount, 100000);
        expect(result.savingsPercent, closeTo(20, 1));
      });

      test('handles missing month data', () {
        final result = SavingsStatisticsUtils.compareSavings({});
        expect(result.beforePrice, 0);
        expect(result.afterPrice, 0);
        expect(result.savingsAmount, 0);
      });
    });
  });
}
