import 'package:flutter/material.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/utils/household_consumables_utils.dart';

class HouseholdConsumablesScreen extends StatelessWidget {
  final String accountName;

  const HouseholdConsumablesScreen({
    super.key,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    const items = HouseholdConsumablesUtils.defaultItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('생활용품 소모품 입력'),
        actions: [
          IconButton(
            tooltip: '재고 관리',
            icon: const Icon(Icons.inventory),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.consumableInventory,
                arguments: AccountArgs(accountName: accountName),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => _onItemTap(context, item),
            borderRadius: BorderRadius.circular(12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subCategory,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onItemTap(BuildContext context, HouseholdConsumableItem item) {
    Navigator.of(context).pushNamed(
      AppRoutes.transactionAdd,
      arguments: TransactionAddArgs(
        accountName: accountName,
        initialTransaction: Transaction(
          id: 'tmp_${DateTime.now().microsecondsSinceEpoch}',
          type: TransactionType.expense,
          description: item.name,
          amount: 0,
          date: DateTime.now(),
          mainCategory: item.mainCategory,
          subCategory: item.subCategory,
          detailCategory: item.detailCategory,
        ),
      ),
    );
  }
}
