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
    final entries = _loading ? const <_RootTxEntry>[] : _buildEntries();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return RootAuthGate(
      child: Scaffold(
        appBar: AppBar(title: const Text('거래관리')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('불러오기 실패: $_error'),
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('거래가 없습니다.')),
                )
              else if (isLandscape)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: Text(
                          '계정 · 내용',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '날짜',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: Text(
                          '유형 · 결제',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '금액',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 88),
                    ],
                  ),
                ),
              if (isLandscape) const Divider(height: 1),
              ...entries.expand((entry) {
                final tx = entry.tx;
                final sign = tx.sign;
                final amountText = '$sign${_currency.format(tx.amount.abs())}';
                final typeLabel = tx.type == TransactionType.savings
                    ? (tx.savingsAllocation?.label ?? tx.type.label)
                    : tx.type.label;
                final dateLabel = _date.format(tx.date);

                final actions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '수정',
                      icon: const Icon(IconCatalog.editOutlined),
                      onPressed: () => _edit(entry),
                    ),
                    IconButton(
                      tooltip: '삭제',
                      icon: const Icon(IconCatalog.deleteOutline),
                      onPressed: () => _delete(entry),
                    ),
                  ],
                );

                if (!isLandscape) {
                  return [
                    ListTile(
                      title: Text('${entry.accountName} · ${tx.description}'),
                      subtitle: Text(
                        '$dateLabel · $typeLabel · ${tx.paymentMethod}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            amountText,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          actions,
                        ],
                      ),
                      onTap: () => _edit(entry),
                    ),
                  ];
                }

                final title = '${entry.accountName} · ${tx.description}';
                final detail = '$typeLabel · ${tx.paymentMethod}';

                return [
                  InkWell(
                    onTap: () => _edit(entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Text(
                              dateLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 5,
                            child: Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                amountText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          actions,
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                ];
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _RootTxEntry {
  const _RootTxEntry({required this.accountName, required this.tx});

  final String accountName;
  final Transaction tx;
}
