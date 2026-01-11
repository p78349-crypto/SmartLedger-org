import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

void main() {
  group('PrefKeys', () {
    group('Transaction and Account Keys', () {
      test('transactions key is defined', () {
        expect(PrefKeys.transactions, 'transactions');
      });

      test('accounts key is defined', () {
        expect(PrefKeys.accounts, 'accounts');
      });

      test('accountsList key is defined', () {
        expect(PrefKeys.accountsList, 'accounts_list');
      });
    });

    group('Storage Backend Keys', () {
      test('txStorageBackendV1 is defined', () {
        expect(PrefKeys.txStorageBackendV1, 'tx_storage_backend_v1');
      });

      test('txDbMigratedV1 is defined', () {
        expect(PrefKeys.txDbMigratedV1, 'tx_db_migrated_v1');
      });
    });

    group('Budget Keys', () {
      test('budgets key is defined', () {
        expect(PrefKeys.budgets, 'budgets');
      });

      test('categoryBudgets key is defined', () {
        expect(PrefKeys.categoryBudgets, 'category_budgets');
      });
    });

    group('Fixed Cost Keys', () {
      test('fixedCosts key is defined', () {
        expect(PrefKeys.fixedCosts, 'fixed_costs');
      });
    });

    group('Savings Plan Keys', () {
      test('savingsPlans key is defined', () {
        expect(PrefKeys.savingsPlans, 'savings_plans');
      });

      test('savingsPlansList key is defined', () {
        expect(PrefKeys.savingsPlansList, 'savings_plans_list');
      });
    });

    group('UI State Keys', () {
      test('selectedAccount key is defined', () {
        expect(PrefKeys.selectedAccount, 'selected_account');
      });

      test('viewPreferences key is defined', () {
        expect(PrefKeys.viewPreferences, 'view_preferences');
      });
    });

    group('Recent Input Keys', () {
      test('recentMemos key is defined', () {
        expect(PrefKeys.recentMemos, 'recent_memos');
      });

      test('recentPaymentMethods key is defined', () {
        expect(PrefKeys.recentPaymentMethods, 'recent_payment_methods');
      });

      test('recentCategories key is defined', () {
        expect(PrefKeys.recentCategories, 'recent_categories');
      });
    });

    group('Stock Use Keys', () {
      test('stockUseAutoAddDepletionDaysV1 is defined', () {
        expect(
          PrefKeys.stockUseAutoAddDepletionDaysV1,
          'stock_use_auto_add_depletion_days_v1',
        );
      });
    });
  });
}
