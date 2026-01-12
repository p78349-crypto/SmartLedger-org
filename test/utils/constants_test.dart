import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/constants.dart';

void main() {
  group('AppConstants', () {
    group('SharedPreferences Keys', () {
      test('lastAccountNameKey is defined', () {
        expect(AppConstants.lastAccountNameKey, 'last_account_name');
      });

      test('accountsKey is defined', () {
        expect(AppConstants.accountsKey, 'accounts');
      });
    });

    group('Limits', () {
      test('maxFavoritesCount is 10', () {
        expect(AppConstants.maxFavoritesCount, 10);
      });

      test('maxTrashSizeBytes is 60MB', () {
        expect(AppConstants.maxTrashSizeBytes, 60 * 1024 * 1024);
      });

      test('autoBackupIntervalDays is 7', () {
        expect(AppConstants.autoBackupIntervalDays, 7);
      });
    });

    group('Default values', () {
      test('defaultCurrency is 원', () {
        expect(AppConstants.defaultCurrency, '원');
      });

      test('defaultAccountName is defined', () {
        expect(AppConstants.defaultAccountName, '임시 계정');
      });
    });

    group('File extensions', () {
      test('backupFileExtension is .json', () {
        expect(AppConstants.backupFileExtension, '.json');
      });

      test('exportCsvExtension is .csv', () {
        expect(AppConstants.exportCsvExtension, '.csv');
      });

      test('exportExcelExtension is .xlsx', () {
        expect(AppConstants.exportExcelExtension, '.xlsx');
      });
    });

    group('UI constants', () {
      test('defaultPadding is 16', () {
        expect(AppConstants.defaultPadding, 16.0);
      });

      test('defaultBorderRadius is 8', () {
        expect(AppConstants.defaultBorderRadius, 8.0);
      });
    });

    group('Animation durations', () {
      test('shortAnimationDuration is 200ms', () {
        expect(
          AppConstants.shortAnimationDuration,
          const Duration(milliseconds: 200),
        );
      });

      test('mediumAnimationDuration is 300ms', () {
        expect(
          AppConstants.mediumAnimationDuration,
          const Duration(milliseconds: 300),
        );
      });
    });

    group('Stats periods', () {
      test('statsMonthsPeriod is 1', () {
        expect(AppConstants.statsMonthsPeriod, 1);
      });

      test('statsYearPeriod is 12', () {
        expect(AppConstants.statsYearPeriod, 12);
      });
    });

    group('Messages', () {
      test('noDataMessage is defined', () {
        expect(AppConstants.noDataMessage, '데이터가 없습니다');
      });

      test('loadingMessage is defined', () {
        expect(AppConstants.loadingMessage, '불러오는 중...');
      });
    });

    group('Transaction types', () {
      test('incomeTypeName is 수입', () {
        expect(AppConstants.incomeTypeName, '수입');
      });

      test('expenseTypeName is 지출', () {
        expect(AppConstants.expenseTypeName, '지출');
      });

      test('savingsTypeName is 예금', () {
        expect(AppConstants.savingsTypeName, '예금');
      });
    });

    group('Asset categories', () {
      test('defaultAssetCategories has 5 items', () {
        expect(AppConstants.defaultAssetCategories.length, 5);
      });

      test('includes 현금', () {
        expect(AppConstants.defaultAssetCategories.contains('현금'), isTrue);
      });
    });

    group('Fixed cost cycles', () {
      test('fixedCostCycles has 4 items', () {
        expect(AppConstants.fixedCostCycles.length, 4);
      });

      test('includes 매월', () {
        expect(AppConstants.fixedCostCycles.contains('매월'), isTrue);
      });
    });
  });
}
