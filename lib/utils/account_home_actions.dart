import 'package:flutter/material.dart';
import 'package:smart_ledger/navigation/app_routes.dart';

/// Navigation helpers for actions triggered from the user main
/// (AccountHomeScreen).
///
/// Keeps AccountHomeScreen UI-focused by extracting navigation wiring into
/// utils.
class AccountHomeActions {
  const AccountHomeActions._();

  static Future<void> openTransactionAdd(
    BuildContext context, {
    required String accountName,
  }) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.transactionAdd,
      arguments: TransactionAddArgs(accountName: accountName),
    );
  }
}

