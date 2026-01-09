import '../models/shopping_cart_item.dart';

class ShoppingPrepUtils {
  ShoppingPrepUtils._();

  static String normalizeName(String raw) {
    return raw.trim().toLowerCase().replaceAll(' ', '');
  }

  static ({List<ShoppingCartItem> merged, int added, int skipped}) mergeByName({
    required List<ShoppingCartItem> existing,
    required List<ShoppingCartItem> incoming,
  }) {
    final existingKeys = <String>{
      for (final i in existing) normalizeName(i.name),
    };

    final addedItems = <ShoppingCartItem>[];
    var added = 0;
    var skipped = 0;

    for (final item in incoming) {
      final key = normalizeName(item.name);
      if (key.isEmpty) continue;
      if (existingKeys.contains(key)) {
        skipped++;
        continue;
      }
      existingKeys.add(key);
      addedItems.add(item);
      added++;
    }

    return (
      merged: [...addedItems, ...existing],
      added: added,
      skipped: skipped,
    );
  }
}
