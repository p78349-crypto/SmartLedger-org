import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';

/// Show dialog displaying matched inventory items for a recipe
void showMatchedItemsDetail(
  BuildContext context,
  List<ConsumableInventoryItem> items,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('매칭된 재고 상세'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final it = items[i];
            final daysLeft = _daysLeft(it);
            return ListTile(
              title: Text(it.name),
              subtitle: Text(
                '${it.category} | ${it.location} | '
                '${it.currentStock}${it.unit}',
              ),
              trailing: Text(
                daysLeft == null ? '기한 없음' : '$daysLeft일 남음',
                style: TextStyle(
                  fontSize: 11,
                  color: daysLeft != null && daysLeft <= 2
                      ? Colors.red
                      : Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
}

/// Calculate days left before expiry for an inventory item
int? _daysLeft(ConsumableInventoryItem item) {
  final expiryDate = item.expiryDate;
  if (expiryDate == null) return null;
  return expiryDate.difference(DateTime.now()).inDays;
}
