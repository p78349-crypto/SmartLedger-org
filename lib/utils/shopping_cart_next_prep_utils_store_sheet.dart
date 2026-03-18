part of 'shopping_cart_next_prep_utils.dart';

Future<void> _showStoreRecommendSheet({
  required BuildContext context,
  required String storeMemo,
  required List<ShoppingTemplateItem> top,
  required List<ShoppingCartItem> existingItems,
  required Future<void> Function(List<ShoppingCartItem> next) saveItems,
  required double? qtyFactor,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      var current = existingItems;
      final addedKeys = <String>{};
      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> addOne(ShoppingTemplateItem item) async {
            final key = ShoppingPrepUtils.normalizeName(item.name);
            if (key.isEmpty) return;
            if (addedKeys.contains(key)) return;

            final createdAt = DateTime.now();
            final incoming = <ShoppingCartItem>[
              ShoppingCartItem(
                id: 'store_${createdAt.microsecondsSinceEpoch}_$key',
                name: item.name,
                quantity: _applyFactorToIntQuantity(
                  item.quantity <= 0 ? 1 : item.quantity,
                  qtyFactor,
                ),
                unitPrice: item.unitPrice,
                memo: _appendFactorMemo(null, qtyFactor),
                createdAt: createdAt,
                updatedAt: createdAt,
              ),
            ];

            final result = ShoppingPrepUtils.mergeByName(
              existing: current,
              incoming: incoming,
            );
            if (result.added <= 0) {
              ScaffoldMessenger.of(
                sheetContext,
              ).showSnackBar(const SnackBar(content: Text('이미 목록에 있습니다.')));
              setSheetState(() {
                addedKeys.add(key);
              });
              return;
            }

            await saveItems(result.merged);
            if (!sheetContext.mounted) return;

            setSheetState(() {
              current = result.merged;
              addedKeys.add(key);
            });

            ScaffoldMessenger.of(
              sheetContext,
            ).showSnackBar(SnackBar(content: Text('추가됨: ${item.name}')));
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('마트/쇼핑몰별 추천'),
                  subtitle: Text('메모(마트/쇼핑몰명): $storeMemo'),
                  trailing: IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(IconCatalog.close),
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: top.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = top[index];
                      final key = ShoppingPrepUtils.normalizeName(item.name);
                      final isAdded = addedKeys.contains(key);
                      return ListTile(
                        title: Text(item.name),
                        subtitle: isAdded
                            ? const Text('추가됨')
                            : const Text('탭해서 추가'),
                        trailing: Icon(
                          isAdded ? IconCatalog.check : IconCatalog.add,
                        ),
                        enabled: !isAdded,
                        onTap: isAdded ? null : () => addOne(item),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
