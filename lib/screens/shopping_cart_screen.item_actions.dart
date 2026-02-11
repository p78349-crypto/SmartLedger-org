// ignore_for_file: invalid_use_of_protected_member
part of 'shopping_cart_screen.dart';

/// Extension: stock lookup, location edit, reset-all dialog.
extension ShoppingCartItemActions on _ShoppingCartScreenState {
  String _getStockQuantity(String itemName) {
    final inventory = ConsumableInventoryService.instance.items.value;
    final trimmedName = itemName.trim().toLowerCase();

    for (final item in inventory) {
      final stockName = item.name.trim().toLowerCase();
      if (stockName == trimmedName ||
          stockName.contains(trimmedName) ||
          trimmedName.contains(stockName)) {
        if (item.currentStock == item.currentStock.toInt()) {
          return '${item.currentStock.toInt()}';
        }
        return '${item.currentStock}';
      }
    }
    return '-';
  }

  Future<void> _editItemLocation(ShoppingCartItem item) async {
    FocusScope.of(context).unfocus();

    final controller = TextEditingController(text: item.storeLocation);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_on, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('${item.name} 위치')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmartInputField(
                hint: '예: 3번 통로, 냉장고, 1층 입구',
                controller: controller,
                maxLines: 2,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              const Text(
                '자주 사용하는 위치:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ProductLocationService.commonLocations
                    .take(15)
                    .map(
                      (loc) => ActionChip(
                        label: Text(loc, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          controller.text = loc;
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(controller.text.trim());
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == null) return;

    final now = DateTime.now();
    final updated = item.copyWith(storeLocation: result, updatedAt: now);
    final next = _items.map((i) => i.id == item.id ? updated : i).toList();
    await _save(next);

    if (result.isNotEmpty) {
      await ProductLocationService.instance.saveLocation(
        accountName: widget.accountName,
        productName: item.name,
        location: result,
      );
    }
  }

  Future<void> _confirmResetAll() async {
    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('초기화'),
        content: const Text('등록된 항목을 모두 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) return;
    _nameController.clear();
    await _save(const <ShoppingCartItem>[]);
  }
}
