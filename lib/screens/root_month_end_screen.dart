import 'package:flutter/material.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/widgets/month_end_carryover_dialog.dart';
import 'package:smart_ledger/widgets/root_auth_gate.dart';

/// ROOT 전용 - 전체 계정 월말 정산
class RootMonthEndScreen extends StatefulWidget {
  const RootMonthEndScreen({super.key});

  @override
  State<RootMonthEndScreen> createState() => _RootMonthEndScreenState();
}

class _RootMonthEndScreenState extends State<RootMonthEndScreen> {
  @override
  Widget build(BuildContext context) {
    return RootAuthGate(
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(IconCatalog.calendarToday, color: Colors.amber),
              SizedBox(width: 8),
              Text('ROOT 월말 정산'),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  IconCatalog.eventAvailable,
                  size: 80,
                  color: Colors.amber,
                ),
                const SizedBox(height: 24),
                Text(
                  '전체 계정 월말 정산',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '모든 계정의 이월 금액을 다음 달로 넘깁니다',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _showMonthEndDialogForAllAccounts,
                  icon: const Icon(IconCatalog.navigateNext),
                  label: const Text('월말 정산 시작'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthEndDialogForAllAccounts() async {
    final accounts = AccountService().accounts;
    if (accounts.isEmpty) return;

    for (final account in accounts) {
      if (!mounted) break;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => MonthEndCarryoverDialog(
          account: account,
          onSaved: () {
            // 간단히 reload나 피드백 처리
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${account.name} 월말 정산 완료')),
              );
            }
          },
        ),
      );
    }
  }
}

