import 'package:flutter/material.dart';
import 'package:smart_ledger/screens/account_main_screen.dart';
import 'package:smart_ledger/screens/account_stats_screen.dart';
import 'package:smart_ledger/screens/fixed_cost_input_screen.dart';
import 'package:smart_ledger/screens/income_input_screen.dart';
import 'package:smart_ledger/screens/transaction_add_screen.dart';

class MainScreen extends StatelessWidget {
  final String accountName;
  const MainScreen({super.key, required this.accountName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('메인화면')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          ElevatedButton(
            child: const Text('자산 관리'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  // ONE UI: 페이지 5 (자산)
                  builder: (_) => AccountMainScreen(
                    accountName: accountName,
                    initialIndex: 5,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('지출 입력'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      TransactionAddScreen(accountName: accountName),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('고정비용 입력'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      FixedCostInputScreen(accountName: accountName),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('수입내역 입력'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => IncomeInputScreen(accountName: accountName),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('통계'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AccountStatsScreen(accountName: accountName),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

