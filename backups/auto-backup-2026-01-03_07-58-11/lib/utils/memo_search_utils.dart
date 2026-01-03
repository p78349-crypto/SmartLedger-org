import 'package:flutter/material.dart';
import 'package:smart_ledger/screens/account_stats_screen.dart';

class MemoSearchUtils {
  const MemoSearchUtils._();

  static Future<void> openMemoOnlySearch(
    BuildContext context, {
    required String accountName,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AccountStatsSearchScreen(accountName: accountName, memoOnly: true),
      ),
    );
  }
}

