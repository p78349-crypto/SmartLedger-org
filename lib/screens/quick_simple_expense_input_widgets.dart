import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';

/// Displayed-item record used by the quick-expense input screen.
typedef QuickExpenseDisplayedItem = ({
  String id,
  String description,
  double amount,
  String payment,
  String store,
});

/// Bottom action bar with "최근 입력" and "지출 상위20" buttons.
class QuickExpenseBottomBar extends StatelessWidget {
  const QuickExpenseBottomBar({
    super.key,
    required this.onOpenHistory,
    required this.onOpenTop20,
  });

  final VoidCallback onOpenHistory;
  final VoidCallback onOpenTop20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 8),
      minimumSize: const Size(0, 56),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: style,
                      onPressed: onOpenHistory,
                      child: const Text(
                        '최근 입력',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: style,
                      onPressed: onOpenTop20,
                      child: const Text(
                        '지출 상위20',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numeric shortcut row (0, 00, 000) for the quick-expense text field.
class QuickExpenseNumPad extends StatelessWidget {
  const QuickExpenseNumPad({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => controller.text += '0',
              child: const Text('0'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => controller.text += '00',
              child: const Text('00'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => controller.text += '000',
              child: const Text('000'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable list of already-entered expense items with edit support.
class QuickExpenseItemList extends StatelessWidget {
  const QuickExpenseItemList({
    super.key,
    required this.items,
    required this.editingIndex,
    required this.onEdit,
  });

  final List<QuickExpenseDisplayedItem> items;
  final int? editingIndex;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final amountLabel = CurrencyFormatter.format(item.amount);
        final paymentLabel = item.payment != '미지정' ? ' · ${item.payment}' : '';
        final storeLabel = item.store != '미지정' ? ' · ${item.store}' : '';
        final itemText =
            '${item.description} · $amountLabel$paymentLabel$storeLabel';
        return Card(
          color: editingIndex == index
              ? theme.colorScheme.primaryContainer
              : null,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onEdit(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      itemText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.edit, size: 16, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
