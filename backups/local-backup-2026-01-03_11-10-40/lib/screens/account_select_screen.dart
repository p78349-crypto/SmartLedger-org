import 'package:flutter/material.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/account_service.dart';

class AccountSelectScreen extends StatelessWidget {
  final List<String> accounts;
  const AccountSelectScreen({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    final accountService = AccountService();

    final labels = <String, String>{};
    int userIndex = 0;
    for (final name in accounts) {
      if (name.trim().toUpperCase() == 'ROOT') {
        labels[name] = 'ROOT';
        continue;
      }
      userIndex++;
      if (userIndex == 1) {
        labels[name] = '유저1';
      } else if (userIndex == 2) {
        labels[name] = '유저2';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('기존 계정 선택'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24.0),
        itemCount: accounts.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final accountName = accounts[index];
          final label = labels[accountName];

          return ListTile(
            title: Text(accountName),
            trailing: label == null
                ? null
                : Text(label, style: Theme.of(context).textTheme.labelMedium),
            onTap: () {
              final account = accountService.getAccountByName(accountName);
              if (account != null) {
                Navigator.of(context).pushNamed(
                  AppRoutes.accountMain,
                  arguments: AccountMainArgs(accountName: account.name),
                );
              }
            },
          );
        },
      ),
    );
  }
}
