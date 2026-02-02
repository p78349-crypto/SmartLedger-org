import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import '../utils/household_consumables_utils.dart';

/// 생활용품 독립 화면 - 생활용품만 표시
class HouseholdItemsScreen extends StatelessWidget {
  final String accountName;

  const HouseholdItemsScreen({
    super.key,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('생활용품'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory),
            tooltip: '재고 관리',
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.consumableInventory,
                arguments: AccountArgs(accountName: accountName),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: HouseholdConsumablesUtils.defaultItems.length,
          itemBuilder: (context, index) {
            final item =
                HouseholdConsumablesUtils.defaultItems[index];
            return Card(
              elevation: 2,
              child: InkWell(
                onTap: () {
                  final now = DateTime.now();
                  Navigator.of(context).pushNamed(
                    AppRoutes.transactionAdd,
                    arguments: TransactionAddArgs(
                      accountName: accountName,
                      initialTransaction: Transaction(
                        id: '',
                        type: TransactionType.expense,
                        amount: 0.0,
                        date: now,
                        description: item.name,
                        mainCategory: item.mainCategory,
                        subCategory: item.subCategory,
                        detailCategory: item.detailCategory,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subCategory,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
