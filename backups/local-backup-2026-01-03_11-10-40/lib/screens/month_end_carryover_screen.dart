import 'package:flutter/material.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/widgets/month_end_carryover_dialog.dart';

class MonthEndCarryoverScreen extends StatefulWidget {
  const MonthEndCarryoverScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<MonthEndCarryoverScreen> createState() =>
      _MonthEndCarryoverScreenState();
}

class _MonthEndCarryoverScreenState extends State<MonthEndCarryoverScreen> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final account = AccountService().getAccountByName(widget.accountName);

      if (!mounted) return;

      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정을 찾을 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) =>
            MonthEndCarryoverDialog(account: account, onSaved: () {}),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
