import 'package:flutter/material.dart';

import 'package:smart_ledger/screens/fixed_cost_tab_screen.dart';

class FixedCostInputScreen extends StatelessWidget {
  final String accountName;
  const FixedCostInputScreen({super.key, required this.accountName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('정기지출 관리'), leading: const BackButton()),
      body: FixedCostTabScreen(accountName: accountName),
    );
  }
}
