part of 'app_router.dart';

class _TransactionRoutes {
  static Route<dynamic>? resolve(
    RouteSettings settings,
    String name,
    Object? args,
  ) {
    switch (name) {
      case AppRoutes.transactionAdd:
        final a = args as TransactionAddArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TransactionAddScreen(
            accountName: a.accountName,
            initialTransaction: a.initialTransaction as Transaction?,
            learnCategoryHintFromDescription:
                a.learnCategoryHintFromDescription,
            confirmBeforeSave: a.confirmBeforeSave,
            treatAsNew: a.treatAsNew,
            closeAfterSave: a.closeAfterSave,
            autoSubmit: a.autoSubmit,
            openReceiptScannerOnStart: a.openReceiptScannerOnStart,
          ),
        );

      case AppRoutes.transactionAddDetailed:
        final a = args as TransactionAddArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TransactionAddDetailedScreen(
            accountName: a.accountName,
            initialTransaction: a.initialTransaction as Transaction?,
            learnCategoryHintFromDescription:
                a.learnCategoryHintFromDescription,
            confirmBeforeSave: a.confirmBeforeSave,
            treatAsNew: a.treatAsNew,
            closeAfterSave: a.closeAfterSave,
            autoSubmit: a.autoSubmit,
          ),
        );

      case AppRoutes.transactionAddIncome:
        final a = args as TransactionAddArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TransactionAddScreen(
            accountName: a.accountName,
            initialTransaction: a.initialTransaction as Transaction?,
            learnCategoryHintFromDescription:
                a.learnCategoryHintFromDescription,
            confirmBeforeSave: a.confirmBeforeSave,
            treatAsNew: a.treatAsNew,
            closeAfterSave: a.closeAfterSave,
            autoSubmit: a.autoSubmit,
            openReceiptScannerOnStart: a.openReceiptScannerOnStart,
          ),
        );

      case AppRoutes.transactionDetail:
        final a = args as TransactionDetailArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TransactionDetailScreen(
            accountName: a.accountName,
            initialType: a.initialType as TransactionType,
          ),
        );

      case AppRoutes.transactionDetailIncome:
        final a = args as TransactionDetailArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TransactionDetailScreen(
            accountName: a.accountName,
            initialType: a.initialType as TransactionType,
          ),
        );

      case AppRoutes.monthEndCarryover:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MonthEndCarryoverScreen(
            accountName: a.accountName,
          ),
        );

      case AppRoutes.dailyTransactions:
        final a = args as DailyTransactionsArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DailyTransactionsScreen(
            accountName: a.accountName,
            initialDay: a.initialDay,
            savedCount: a.savedCount,
            showShoppingPointsInputCta: a.showShoppingPointsInputCta,
          ),
        );

      case AppRoutes.refundTransactions:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RefundTransactionsScreen(
            accountName: a.accountName,
            initialDay: DateTime.now(),
          ),
        );

      case AppRoutes.quickSimpleExpenseInput:
        final a = args as QuickSimpleExpenseInputArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => QuickSimpleExpenseInputScreen(
            accountName: a.accountName,
            initialDate: a.initialDate,
            initialLine: a.initialLine,
            autoSubmitOnStart: a.autoSubmit,
          ),
        );

      case AppRoutes.storeMerge:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => UserAccountAuthGate(
            child: StoreMergeScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.emergencyFund:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => EmergencyFundScreen(
            accountName: a.accountName,
          ),
        );

      case AppRoutes.emergencyServices:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const EmergencyScreen(),
        );

      case AppRoutes.trash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TrashScreen(),
        );

      case AppRoutes.backup:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BackupScreen(accountName: a.accountName),
        );

      default:
        return null;
    }
  }
}
