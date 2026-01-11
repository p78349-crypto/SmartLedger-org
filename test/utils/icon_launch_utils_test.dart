import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/utils/icon_launch_utils.dart';

void main() {
  group('IconLaunchUtils', () {
    const accountName = 'acc1';

    test('buildRequest returns null for known no-args routes', () {
      final req = IconLaunchUtils.buildRequest(
        routeName: AppRoutes.settings,
        accountName: accountName,
      );

      expect(req, isNotNull);
      expect(req!.routeName, AppRoutes.settings);
      expect(req.arguments, isNull);
    });

    test('buildRequest builds TransactionAddArgs for transaction add', () {
      final req = IconLaunchUtils.buildRequest(
        routeName: AppRoutes.transactionAdd,
        accountName: accountName,
      );

      expect(req, isNotNull);
      expect(req!.arguments, isA<TransactionAddArgs>());
      final args = req.arguments as TransactionAddArgs;
      expect(args.accountName, accountName);
      expect(args.treatAsNew, isFalse);
    });

    test('buildRequest builds income template for transactionAddIncome', () {
      final req = IconLaunchUtils.buildRequest(
        routeName: AppRoutes.transactionAddIncome,
        accountName: accountName,
      );

      expect(req, isNotNull);
      expect(req!.arguments, isA<TransactionAddArgs>());
      final args = req.arguments as TransactionAddArgs;
      expect(args.accountName, accountName);
      expect(args.treatAsNew, isTrue);
      expect(args.initialTransaction, isA<Transaction>());
      final tx = args.initialTransaction as Transaction;
      expect(tx.type, TransactionType.income);
    });

    test('buildRequest falls back to AccountArgs when route expects account', () {
      final req = IconLaunchUtils.buildRequest(
        routeName: AppRoutes.accountMain,
        accountName: accountName,
      );

      expect(req, isNotNull);
      expect(req!.arguments, isA<AccountArgs>());
      final args = req.arguments as AccountArgs;
      expect(args.accountName, accountName);
    });
  });
}
