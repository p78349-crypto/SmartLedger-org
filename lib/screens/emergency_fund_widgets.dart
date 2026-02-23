import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../models/emergency_transaction.dart';
import '../services/asset_service.dart';
import '../utils/utils.dart';

class EmergencyBalanceCard extends StatelessWidget {
  final double balance;
  const EmergencyBalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '현재 잔액',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.purple[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(balance),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmergencyTransactionCard extends StatelessWidget {
  final EmergencyTransaction transaction;
  final VoidCallback onTap;
  const EmergencyTransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction.amount > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDeposit ? Colors.green[100] : Colors.red[100],
          child: Icon(
            isDeposit ? Icons.add : Icons.remove,
            color: isDeposit ? Colors.green : Colors.red,
          ),
        ),
        title: Text(transaction.description),
        subtitle: Text(DateFormatter.formatDate(transaction.date)),
        trailing: Text(
          CurrencyFormatter.formatSigned(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDeposit ? Colors.green : Colors.red,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

Future<String?> showCashAssetPicker(
  BuildContext context,
  String accountName,
) async {
  await AssetService().loadAssets();
  if (!context.mounted) return null;

  final assets = AssetService().getAssets(accountName);
  final cashAssets = assets.where((a) => a.category == AssetCategory.cash);
  final items = cashAssets.toList();

  if (items.isEmpty) {
    SnackbarUtils.showWarning(context, '현금 자산이 없어 자산 순환을 적용할 수 없습니다');
    return null;
  }

  if (items.length == 1) {
    return items.first.id;
  }

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('현금 자산 선택'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final asset = items[index];
            return ListTile(
              title: Text(asset.name),
              subtitle: Text(CurrencyFormatter.format(asset.amount)),
              onTap: () => Navigator.of(ctx).pop(asset.id),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('취소'),
        ),
      ],
    ),
  );
}
