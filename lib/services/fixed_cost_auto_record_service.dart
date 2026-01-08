import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ledger/models/fixed_cost.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/fixed_cost_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/date_formatter.dart';

class FixedCostAutoRecordService {
  static const String _stampPrefix = 'fixed_cost_auto_recorded_v1';

  /// Runs the monthly auto-record routine.
  ///
  /// [backfillMonths] will also attempt creation for previous months
  /// (e.g. 1 = last month + this month). This is best-effort and uses
  /// stamps/duplicate detection to prevent re-creating entries.
  Future<void> runForAllAccounts({DateTime? now, int backfillMonths = 0}) async {
    await AccountService().loadAccounts();
    await FixedCostService().loadFixedCosts();
    await TransactionService().loadTransactions();

    final accounts = AccountService().accounts;
    for (final account in accounts) {
      await runForAccount(
        account.name,
        now: now,
        backfillMonths: backfillMonths,
      );
    }
  }

  Future<int> runForAccount(
    String accountName, {
    DateTime? now,
    int backfillMonths = 0,
  }) async {
    await FixedCostService().loadFixedCosts();
    await TransactionService().loadTransactions();

    final current = DateFormatter.stripTime(now ?? DateTime.now());

    final prefs = await SharedPreferences.getInstance();

    final costs = FixedCostService().getFixedCosts(accountName);
    if (costs.isEmpty) return 0;

    final transactionService = TransactionService();

    var created = 0;

    // Iterate from oldest -> newest to keep a natural order.
    for (var offset = backfillMonths; offset >= 0; offset -= 1) {
      final targetMonth = DateTime(current.year, current.month - offset);
      final ym = _yearMonthKey(targetMonth);

      // Refresh transactions per month in case we created some in the loop.
      final existingTransactions = transactionService.getTransactions(
        accountName,
      );

      for (final cost in costs) {
        // Only auto-record when the user set a monthly due day.
        if (cost.dueDay == null) continue;

        final scheduledDate = _scheduledDateForMonth(
          year: targetMonth.year,
          month: targetMonth.month,
          dueDay: cost.dueDay!,
        );

        // For the current month, wait until we reach the due day.
        if (targetMonth.year == current.year &&
            targetMonth.month == current.month &&
            current.isBefore(scheduledDate)) {
          continue;
        }

        final stampKey = '$_stampPrefix|$accountName|${cost.id}|$ym';
        final alreadyStamped = prefs.getBool(stampKey) ?? false;
        if (alreadyStamped) {
          continue;
        }

        final duplicates = _findDuplicateTransactions(
          existingTransactions,
          cost,
          scheduledDate,
        );
        if (duplicates.isNotEmpty) {
          await prefs.setBool(stampKey, true);
          continue;
        }

        final memoBuffer = StringBuffer('[고정비 자동기록]');
        final trimmedMemo = cost.memo?.trim();
        if (trimmedMemo != null && trimmedMemo.isNotEmpty) {
          memoBuffer.write(' ');
          memoBuffer.write(trimmedMemo);
        }

        final transaction = Transaction(
          id: 'fixed_${cost.id}_${targetMonth.year}${targetMonth.month.toString().padLeft(2, '0')}',
          type: TransactionType.expense,
          description: cost.name,
          amount: cost.amount,
          date: scheduledDate,
          unitPrice: cost.amount,
          paymentMethod: cost.paymentMethod,
          memo: memoBuffer.toString(),
        );

        await transactionService.addTransaction(accountName, transaction);
        created += 1;
        await prefs.setBool(stampKey, true);
      }
    }

    return created;
  }

  static String _yearMonthKey(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    return '${date.year}-$mm';
  }

  static DateTime _scheduledDateForMonth({
    required int year,
    required int month,
    required int dueDay,
  }) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final targetDay = dueDay.clamp(1, lastDay);
    return DateFormatter.stripTime(DateTime(year, month, targetDay));
  }

  static List<Transaction> _findDuplicateTransactions(
    List<Transaction> transactions,
    FixedCost cost,
    DateTime targetDate,
  ) {
    return transactions.where((tx) {
      final sameDay = DateFormatter.isSameDay(tx.date, targetDate);
      final sameAmount = (tx.amount - cost.amount).abs() < 0.01;
      return tx.type == TransactionType.expense &&
          sameDay &&
          sameAmount &&
          tx.description.trim() == cost.name.trim();
    }).toList();
  }
}
