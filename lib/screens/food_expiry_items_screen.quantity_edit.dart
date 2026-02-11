// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

/// Quantity editing and adjustment methods.
extension FoodExpiryQuantityEditExt on _FoodExpiryItemsScreenState {
  Future<void> _editQuantity(BuildContext context, FoodExpiryItem item) async {
    final controller = TextEditingController(
      text: item.quantity == item.quantity.toInt()
          ? item.quantity.toInt().toString()
          : item.quantity.toString(),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.name} 수량 변경'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            suffixText: item.unit,
            border: const OutlineInputBorder(),
            labelText: '수량 입력',
          ),
          onSubmitted: (val) {
            final parsed = double.tryParse(val);
            if (parsed != null && parsed >= 0) {
              Navigator.of(ctx).pop(parsed);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != null && result != item.quantity) {
      final used = item.quantity - result;
      if (used > 0) {
        final warning = await HealthGuardrailService.recordUsageAndCheck(
          itemName: item.name,
          amount: used,
          tags: item.healthTags,
        );
        try {
          await ReplacementCycleNotificationService.instance
              .rescheduleFromPrefs();
        } catch (_) {
          // ignore
        }
        if (context.mounted && warning != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(warning.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      if (!context.mounted) return;

      if (result == 0) {
        if (!context.mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('재고 소진'),
            content: Text('${item.name} 재고가 0이 되었습니다.\n목록에서 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('아니오 (0으로 유지)'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('삭제'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await ConsumableInventoryService.instance.deleteItem(item.id);
          return;
        }
      }

      await ConsumableInventoryService.instance.updateItem(
        ConsumableInventoryItem(
          id: item.id,
          name: item.name,
          currentStock: result,
          unit: item.unit,
          category: item.category,
          location: item.location,
          createdAt: item.createdAt,
          lastUpdated: DateTime.now(),
          healthTags: item.healthTags,
          expiryDate: item.expiryDate,
          purchaseDate: item.purchaseDate,
        ),
      );
    }
  }

  Future<void> _adjustQuantity(
    BuildContext context,
    FoodExpiryItem item,
    double delta,
  ) async {
    final newQty = item.quantity + delta;
    if (newQty < 0) return; // Prevent negative

    final used = delta < 0 ? -delta : 0.0;
    if (used > 0) {
      final warning = await HealthGuardrailService.recordUsageAndCheck(
        itemName: item.name,
        amount: used,
        tags: item.healthTags,
      );
      try {
        await ReplacementCycleNotificationService.instance
            .rescheduleFromPrefs();
      } catch (_) {
        // ignore
      }
      if (context.mounted && warning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(warning.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (!context.mounted) return;

    if (newQty == 0) {
      // Ask to delete if 0
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('재고 소진'),
          content: Text('${item.name} 재고가 0이 되었습니다.\n목록에서 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('아니오 (0으로 유지)'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('삭제'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ConsumableInventoryService.instance.deleteItem(item.id);
        return;
      }
    }

    await ConsumableInventoryService.instance.updateItem(
      ConsumableInventoryItem(
        id: item.id,
        name: item.name,
        currentStock: newQty,
        unit: item.unit,
        category: item.category,
        location: item.location,
        createdAt: item.createdAt,
        lastUpdated: DateTime.now(),
        healthTags: item.healthTags,
        expiryDate: item.expiryDate,
        purchaseDate: item.purchaseDate,
        price: item.price,
        supplier: item.supplier,
      ),
    );
  }
}
