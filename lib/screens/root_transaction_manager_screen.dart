library root_transaction_manager_screen;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import '../services/account_service.dart';
import '../services/transaction_service.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/interaction_blockers.dart';
import '../utils/number_formats.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/root_auth_gate.dart';

part 'root_transaction_manager_screen_ui.dart';

class RootTransactionManagerScreen extends StatefulWidget {
  const RootTransactionManagerScreen({super.key});

  @override
  State<RootTransactionManagerScreen> createState() =>
      _RootTransactionManagerScreenState();
}

class _RootTransactionManagerScreenState
    extends State<RootTransactionManagerScreen> {
  bool _loading = true;
  String? _error;

  final NumberFormat _currency = NumberFormats.currency;
  final DateFormat _date = DateFormatter.defaultDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([
        AccountService().loadAccounts(),
        TransactionService().loadTransactions(),
      ]);

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  List<_RootTxEntry> _buildEntries() {
    final service = TransactionService();
    final entries = <_RootTxEntry>[];

    for (final accountName in service.getAllAccountNames()) {
      for (final tx in service.getTransactions(accountName)) {
        entries.add(_RootTxEntry(accountName: accountName, tx: tx));
      }
    }

    entries.sort((a, b) {
      final dateCompare = b.tx.date.compareTo(a.tx.date);
      if (dateCompare != 0) return dateCompare;
      return b.tx.amount.abs().compareTo(a.tx.amount.abs());
    });

    return entries;
  }

  Future<void> _edit(_RootTxEntry entry) async {
    await InteractionBlockers.run(() async {
      await Navigator.of(context).pushNamed(
        AppRoutes.transactionAdd,
        arguments: TransactionAddArgs(
          accountName: entry.accountName,
          initialTransaction: entry.tx,
        ),
      );
      if (!mounted) return;
      await _load();
    });
  }

  Future<void> _delete(_RootTxEntry entry) async {
    await InteractionBlockers.run(() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('거래 삭제'),
          content: Text(
            '${entry.accountName} 계정의 “${entry.tx.description}” 거래를 삭제할까요?\n'
            '(휴지통으로 이동됩니다)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('삭제'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (confirmed != true) return;

      try {
        await TransactionService().deleteTransaction(
          entry.accountName,
          entry.tx.id,
        );
        if (!mounted) return;
        SnackbarUtils.showSuccess(context, '삭제했습니다.');
        await _load();
      } catch (e) {
        if (!mounted) return;
        SnackbarUtils.showError(context, '삭제 실패: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }
}
