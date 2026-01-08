import 'package:flutter/material.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/theme/app_colors.dart';
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.iconBackgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      size: 32,
                      color: AppColors.consumableIconColors[index % AppColors.consumableIconColors.length],
                    ),
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 선택 항목 표시
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // 구입 기록
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              leading: Icon(
                Icons.shopping_cart,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('🛒 구입 기록'),
              subtitle: const Text('거래 입력 화면'),
              onTap: () {
                Navigator.pop(ctx);
                _goToPurchaseInput(context, item);
              },
            ),
            const SizedBox(height: 12),

            // 사용량 입력
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              leading: Icon(
                Icons.trending_down,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('📉 사용량 입력'),
              subtitle: const Text('현재고 감소'),
              onTap: () {
                Navigator.pop(ctx);
                _goToUsageInput(context, item);
              },
            ),
            const SizedBox(height: 12),

            // 재고 관리
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              leading: Icon(
                Icons.inventory,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('📦 재고 관리'),
              subtitle: const Text('전체 재고 보기'),
              onTap: () {
                Navigator.pop(ctx);
                _goToInventory(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _goToPurchaseInput(BuildContext context, HouseholdConsumableItem item) {
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
        treatAsNew: true,
      ),
    );
  }

  void _goToUsageInput(BuildContext context, HouseholdConsumableItem item) {
    Navigator.of(context).pushNamed(
      AppRoutes.quickStockUse,
      arguments: QuickStockUseArgs(
        accountName: accountName,
        initialProductName: item.name,
      ),
    );
  }

  void _goToInventory(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.consumableInventory,
      arguments: AccountArgs(accountName: accountName),
    );
  }
}
