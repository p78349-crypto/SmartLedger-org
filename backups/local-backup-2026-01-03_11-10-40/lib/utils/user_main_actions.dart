import 'package:flutter/material.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/backup_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/backup_password_bootstrapper.dart';

/// Navigation + persistence helpers for the user main UI
/// (AccountMainScreen -> HomeTabScreen).
///
/// Goal: keep HomeTabScreen UI-focused and avoid scattering route names,
/// arguments, and persistence wiring across the screen.
class UserMainActions {
  const UserMainActions._();

  static void openSearch(NavigatorState navigator, {required String account}) {
    navigator.pushNamed(
      AppRoutes.accountStatsSearch,
      arguments: AccountArgs(accountName: account),
    );
  }

  static void openTrash(NavigatorState navigator) {
    navigator.pushNamed(AppRoutes.trash);
  }

  static Future<bool?> openTransactionDetail(
    NavigatorState navigator, {
    required String account,
    required TransactionType initialType,
  }) {
    return navigator.pushNamed<bool>(
      AppRoutes.transactionDetail,
      arguments: TransactionDetailArgs(
        accountName: account,
        initialType: initialType,
      ),
    );
  }

  static Future<void> openIncomeSplit(
    NavigatorState navigator, {
    required String account,
  }) {
    return navigator.pushNamed(
      AppRoutes.incomeSplit,
      arguments: AccountArgs(accountName: account),
    );
  }

  static Future<void> openSavingsPlanList(
    NavigatorState navigator, {
    required String account,
  }) {
    return navigator.pushNamed(
      AppRoutes.savingsPlanList,
      arguments: AccountArgs(accountName: account),
    );
  }

  static Future<void> openBackup(
    NavigatorState navigator, {
    required String account,
  }) {
    return navigator.pushNamed(
      AppRoutes.backup,
      arguments: AccountArgs(accountName: account),
    );
  }

  /// Persist selected account and run auto-backup if needed.
  ///
  /// Keep navigation out of this method so the caller can handle `mounted`
  /// checks safely.
  static Future<void> persistAccountSelection(
    BuildContext context,
    String accountName,
  ) async {
    await BackupPasswordBootstrapper.ensureBackupPasswordConfiguredOnEntry(
      context,
    );

    await BackupService().autoBackupIfNeeded(accountName);
    await UserPrefService.setLastAccountName(accountName);
  }
}
