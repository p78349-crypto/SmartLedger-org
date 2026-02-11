// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

/// Ingredient matching, formatting, and utility helpers.
extension FoodExpiryHelpersExt on _FoodExpiryItemsScreenState {
  List<String> _normalizeIngredientNames(List<String>? raw) {
    if (raw == null || raw.isEmpty) return const <String>[];
    final seen = <String>{};
    final out = <String>[];
    for (final v in raw) {
      final name = v.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.add(key)) out.add(name);
    }
    return out;
  }

  bool _ingredientMatchesItem(String ingredient, FoodExpiryItem item) {
    final ing = ingredient.trim().toLowerCase();
    if (ing.isEmpty) return false;
    final n = item.name.trim().toLowerCase();
    final c = item.category.trim().toLowerCase();
    return n.contains(ing) || ing.contains(n) || c.contains(ing);
  }

  List<FoodExpiryItem> _matchAllItemsForIngredient(
    String ingredient,
    List<FoodExpiryItem> items,
  ) {
    final matched =
        items.where((it) => _ingredientMatchesItem(ingredient, it)).toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return matched;
  }

  List<FoodExpiryItem> _matchAvailableItemsForIngredient(
    String ingredient,
    List<FoodExpiryItem> items,
  ) {
    return _matchAllItemsForIngredient(
      ingredient,
      items,
    ).where((it) => it.quantity > 0).toList();
  }

  String _formatQuantityValue(double quantity, String unit) {
    final isInt = quantity == quantity.toInt();
    final value = isInt ? quantity.toInt().toString() : '$quantity';
    return '$value$unit';
  }

  String _formatMatchedTotal(List<FoodExpiryItem> matched) {
    if (matched.isEmpty) return '0';
    final unit = matched.first.unit;
    final sameUnit = matched.every((it) => it.unit == unit);
    if (!sameUnit) return '${matched.length}개 항목';
    final sum = matched.fold<double>(0.0, (acc, it) => acc + it.quantity);
    return _formatQuantityValue(sum, unit);
  }

  void _showIngredientMatchesDetail(
    BuildContext context, {
    required String ingredientName,
    required List<FoodExpiryItem> matched,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$ingredientName 재고 (${matched.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: matched.length,
            itemBuilder: (ctx, i) {
              final it = matched[i];
              final left = it.daysLeft(DateTime.now());
              final expiry = DateFormat('yyyy-MM-dd').format(it.expiryDate);
              final leftText = left < 0 ? '지남 ${-left}일' : '$left일 남음';
              return ListTile(
                title: Text(it.name.trim().isEmpty ? '(이름 없음)' : it.name),
                subtitle: Text(
                  '${it.category} | ${it.location} | ${_formatQuantity(it)}\n'
                  '기한: $expiry ($leftText)',
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

  String _formatQuantity(FoodExpiryItem item) {
    String formatQty(double value) {
      if (!value.isFinite) return '0';
      final rounded = value.roundToDouble();
      if ((value - rounded).abs() < 0.000001) {
        return rounded.toStringAsFixed(0);
      }
      return value.toStringAsFixed(1);
    }

    return '${formatQty(item.quantity)}${item.unit}';
  }

  String _formatInventoryQuantity(ConsumableInventoryItem item) {
    String formatQty(double value) {
      if (!value.isFinite) return '0';
      final rounded = value.roundToDouble();
      if ((value - rounded).abs() < 0.000001) {
        return rounded.toStringAsFixed(0);
      }
      return value.toStringAsFixed(1);
    }

    return '${formatQty(item.currentStock)}${item.unit}';
  }

  int _daysLeftForInventory(ConsumableInventoryItem item, DateTime now) {
    final expiryDate = item.expiryDate;
    if (expiryDate == null) return 99999;
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return end.difference(start).inDays;
  }

  String _itemSubtitleText(FoodExpiryItem item) {
    final purchase = DateFormat('yyyy-MM-dd').format(item.purchaseDate);
    final expiry = DateFormat('yyyy-MM-dd').format(item.expiryDate);

    String base = '구매: $purchase / 기한: $expiry';
    if (item.location.isNotEmpty) {
      base += '\n위치: ${item.location}';
    }
    if (item.price > 0) {
      base += ' / 가격: ${NumberFormat('#,###').format(item.price)}원';
    }

    final memo = item.memo.trim();
    if (memo.isEmpty) return base;
    return '$base\n메모: $memo';
  }
}
