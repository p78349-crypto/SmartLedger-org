part of 'quick_stock_use_utils.dart';

DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _formatQty(double value) {
  if (!value.isFinite) return '0';
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.000001) return rounded.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

double? _resolveQuantityFactorFromTrend(
  ActivityHouseholdTrendComparison? trend,
) {
  if (trend == null) return null;
  final r = trend.ratio;
  if (!r.isFinite || r <= 0) return null;
  if (r >= 0.9 && r <= 1.1) return null;
  return r.clamp(0.7, 1.5);
}

int _applyFactorToIntQuantity(int baseQty, double? factor) {
  final b = baseQty <= 0 ? 1 : baseQty;
  if (factor == null) return b;
  final next = (b * factor).round();
  return next < 1 ? 1 : next;
}

/// Returns expected depletion days from today based on usage history.
int? _calculateExpectedDepletionDays(ConsumableInventoryItem item) {
  if (item.currentStock <= 0) return null;
  if (item.usageHistory.length < 2) return null;

  final sorted = [...item.usageHistory]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  final first = sorted.first.timestamp;
  final last = sorted.last.timestamp;
  final spanDays = _startOfDay(
    last,
  ).difference(_startOfDay(first)).inDays.abs();
  final denomDays = spanDays < 1 ? 1 : spanDays;
  final totalUsed = sorted.fold<double>(0.0, (sum, r) => sum + r.amount);
  final avgPerDay = totalUsed / denomDays;
  if (avgPerDay <= 0) return null;

  return (item.currentStock / avgPerDay).ceil();
}

/// 장바구니에 부족분 추가
Future<void> _addToShoppingCart({
  required String accountName,
  required String itemName,
  required double shortage,
  required String unit,
  int quantity = 1,
}) async {
  final current = await AppRepositories.shoppingCart.getItems(
    accountName: accountName,
  );

  // 이미 장바구니에 있으면 추가하지 않음
  final existingIndex = current.indexWhere((i) => i.name == itemName);
  if (existingIndex >= 0) return;

  final now = DateTime.now();
  final newItem = ShoppingCartItem(
    id: 'cart_${now.microsecondsSinceEpoch}',
    name: itemName,
    quantity: quantity <= 0 ? 1 : quantity,
    memo: '재고 부족 (${_formatQty(shortage)}$unit 필요)',
    createdAt: now,
    updatedAt: now,
  );

  final next = List<ShoppingCartItem>.from(current)..add(newItem);
  await AppRepositories.shoppingCart.setItems(
    accountName: accountName,
    items: next,
  );
}

Future<bool> _addToShoppingCartWithMemo({
  required String accountName,
  required String itemName,
  required String memo,
  int quantity = 1,
}) async {
  final current = await AppRepositories.shoppingCart.getItems(
    accountName: accountName,
  );

  final existingIndex = current.indexWhere((i) => i.name == itemName);
  if (existingIndex >= 0) return false;

  final now = DateTime.now();
  final newItem = ShoppingCartItem(
    id: 'cart_${now.microsecondsSinceEpoch}',
    name: itemName,
    quantity: quantity <= 0 ? 1 : quantity,
    memo: memo,
    createdAt: now,
    updatedAt: now,
  );

  final next = List<ShoppingCartItem>.from(current)..add(newItem);
  await AppRepositories.shoppingCart.setItems(
    accountName: accountName,
    items: next,
  );
  return true;
}
