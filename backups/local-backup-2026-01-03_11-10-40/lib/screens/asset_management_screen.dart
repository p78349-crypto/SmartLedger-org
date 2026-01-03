import 'package:flutter/material.dart';
import 'package:smart_ledger/screens/asset_input_screen.dart';
import 'package:smart_ledger/screens/asset_tab_screen.dart';

class AssetManagementScreen extends StatelessWidget {
  final String accountName;
  const AssetManagementScreen({super.key, required this.accountName});

  void _openAssetInput(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssetInputScreen(accountName: accountName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 관리'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'asset') {
                _openAssetInput(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'asset',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.green),
                    SizedBox(width: 12),
                    Text('자산'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: AssetTabScreen(accountName: accountName),
    );
  }
}
