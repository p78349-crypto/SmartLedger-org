import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/food_expiry_item.dart';
import 'package:smart_ledger/utils/cost_prediction_utils.dart';

void main() {
  final now = DateTime.now();

  List<FoodExpiryItem> createItems({
    List<double>? prices,
    DateTime? expiryDate,
    String? category,
  }) {
    final expiry = expiryDate ?? now;
    return (prices ?? [1000, 2000, 3000]).map((price) {
      return FoodExpiryItem(
        id: 'item-$price',
        name: '테스트 $price',
        purchaseDate: now.subtract(const Duration(days: 1)),
        expiryDate: expiry,
        createdAt: now,
        price: price,
        category: category ?? '식재료',
      );
    }).toList();
  }

  group('CostPredictionUtils', () {
    group('getCurrentMonthTotalCost', () {
      test('returns 0 for empty list', () {
        expect(CostPredictionUtils.getCurrentMonthTotalCost([]), 0);
      });

      test('sums prices of items expiring this month', () {
        final items = createItems(prices: [1000, 2000, 3000]);
        final result = CostPredictionUtils.getCurrentMonthTotalCost(items);
        expect(result, 6000);
      });

      test('excludes items from other months', () {
        final thisMonth = createItems(prices: [1000]);
        final nextMonth = createItems(
          prices: [5000],
          expiryDate: DateTime(now.year, now.month + 1),
        );
        final result = CostPredictionUtils.getCurrentMonthTotalCost(
          [...thisMonth, ...nextMonth],
        );
        expect(result, 1000); // 이번 달 항목만
      });
    });

    group('predictMonthlyExpense', () {
      test('returns 0 for empty list', () {
        expect(CostPredictionUtils.predictMonthlyExpense([], now), 0);
      });
    });

    group('analyzeBudget', () {
      test('calculates usage correctly', () {
        final items = createItems(prices: [25000, 25000]); // 총 50,000원
        final analysis = CostPredictionUtils.analyzeBudget(
          items,
          monthlyBudget: 100000,
        );

        expect(analysis.monthlyBudget, 100000);
        expect(analysis.currentCost, 50000);
        expect(analysis.remaining, 50000);
        expect(analysis.usagePercentage, 50);
        expect(analysis.isOverBudget, isFalse);
      });

      test('detects over budget', () {
        final items = createItems(prices: [60000, 60000]); // 총 120,000원
        final analysis = CostPredictionUtils.analyzeBudget(
          items,
          monthlyBudget: 100000,
        );

        expect(analysis.isOverBudget, isTrue);
        expect(analysis.remaining, -20000);
      });
    });

    group('getBudgetWarning', () {
      test('shows over budget message', () {
        final analysis = BudgetAnalysis(
          monthlyBudget: 100000,
          currentCost: 120000,
          remaining: -20000,
          usagePercentage: 120,
          isOverBudget: true,
        );

        final message = CostPredictionUtils.getBudgetWarning(analysis);
        expect(message, contains('예산 초과'));
      });

      test('shows warning for >80% usage', () {
        final analysis = BudgetAnalysis(
          monthlyBudget: 100000,
          currentCost: 85000,
          remaining: 15000,
          usagePercentage: 85,
          isOverBudget: false,
        );

        final message = CostPredictionUtils.getBudgetWarning(analysis);
        expect(message, contains('예산 경고'));
      });

      test('shows moderate message for >50% usage', () {
        final analysis = BudgetAnalysis(
          monthlyBudget: 100000,
          currentCost: 60000,
          remaining: 40000,
          usagePercentage: 60,
          isOverBudget: false,
        );

        final message = CostPredictionUtils.getBudgetWarning(analysis);
        expect(message, contains('적절한 범위'));
      });

      test('shows all clear for <50% usage', () {
        final analysis = BudgetAnalysis(
          monthlyBudget: 100000,
          currentCost: 30000,
          remaining: 70000,
          usagePercentage: 30,
          isOverBudget: false,
        );

        final message = CostPredictionUtils.getBudgetWarning(analysis);
        expect(message, contains('여유 있음'));
      });
    });

    group('getDailyAverageExpense', () {
      test('returns 0 for empty list', () {
        expect(CostPredictionUtils.getDailyAverageExpense([]), 0);
      });

      test('calculates daily average', () {
        final items = createItems(prices: [30000]); // 총 30,000원
        final result = CostPredictionUtils.getDailyAverageExpense(items);
        expect(result, 1000); // 30000 / 30일
      });
    });

    group('getCategorySpending', () {
      test('returns empty map for empty list', () {
        expect(CostPredictionUtils.getCategorySpending([]), isEmpty);
      });

      test('groups spending by category', () {
        final items = [
          ...createItems(prices: [1000, 2000], category: '과일'),
          ...createItems(prices: [3000], category: '채소'),
        ];

        final result = CostPredictionUtils.getCategorySpending(items);

        expect(result['과일'], 3000);
        expect(result['채소'], 3000);
      });
    });

    group('getCategorySpendingAdvice', () {
      test('returns no data message for empty map', () {
        final result = CostPredictionUtils.getCategorySpendingAdvice({}, 100000);
        expect(result, contains('데이터가 없습니다'));
      });

      test('identifies top spending category', () {
        final spending = {'과일': 30000.0, '채소': 20000.0};
        final result = CostPredictionUtils.getCategorySpendingAdvice(spending, 100000);
        expect(result, contains('과일'));
      });
    });

    group('getAffordableAlternatives', () {
      test('filters items under threshold', () {
        final items = createItems(prices: [1000, 3000, 5000]);
        final result = CostPredictionUtils.getAffordableAlternatives(items, 3000);

        expect(result.length, 2);
        expect(result.first.price, 1000); // 정렬됨
      });

      test('returns empty list when no affordable items', () {
        final items = createItems(prices: [5000, 6000]);
        final result = CostPredictionUtils.getAffordableAlternatives(items, 1000);
        expect(result, isEmpty);
      });
    });

    group('calculatePotentialSavings', () {
      test('calculates savings potential', () {
        final items = createItems(prices: [3000, 4000, 5000]); // 총 12,000원
        final result = CostPredictionUtils.calculatePotentialSavings(items, 2000);
        // 현재 12,000 - (3개 * 2000) = 12,000 - 6,000 = 6,000원 절약 가능
        expect(result, 6000);
      });
    });
  });

  group('BudgetAnalysis', () {
    test('creates with all fields', () {
      final analysis = BudgetAnalysis(
        monthlyBudget: 500000,
        currentCost: 250000,
        remaining: 250000,
        usagePercentage: 50,
        isOverBudget: false,
      );

      expect(analysis.monthlyBudget, 500000);
      expect(analysis.currentCost, 250000);
      expect(analysis.remaining, 250000);
      expect(analysis.usagePercentage, 50);
      expect(analysis.isOverBudget, isFalse);
    });
  });
}
