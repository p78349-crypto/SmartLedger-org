part of 'shopping_cart_next_prep_utils.dart';

/// 최근 구매 기반 장바구니 추가
Future<void> _addFromRecentPurchases({
  required BuildContext context,
  required String accountName,
  required List<ShoppingCartItem> existingItems,
  required Future<void> Function(List<ShoppingCartItem> next) saveItems,
}) async {
  final history = await UserPrefService.getShoppingCartHistory(
    accountName: accountName,
    limit: 300,
  );
  if (!context.mounted) return;

  final trend = await ActivityHouseholdEstimatorService.compareTrend();
  final qtyFactor = _resolveQuantityFactorFromTrend(trend);

  if (!context.mounted) return;

  final candidates = <ShoppingTemplateItem>[];
  final seen = <String>{};
  for (final h in history) {
    if (h.action != ShoppingCartHistoryAction.addToLedger) continue;
    final key = ShoppingPrepUtils.normalizeName(h.name);
    if (key.isEmpty || seen.contains(key)) continue;
    seen.add(key);
    candidates.add(
      ShoppingTemplateItem(
        name: h.name,
        quantity: h.quantity <= 0 ? 1 : h.quantity,
        unitPrice: h.unitPrice,
      ),
    );
    if (candidates.length >= 20) break;
  }

  if (candidates.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('최근 구매 기록이 없습니다.')));
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final lines = candidates
          .take(10)
          .map((c) => '• ${c.name} (수량 ${c.quantity})')
          .toList();
      if (candidates.length > 10) {
        lines.add('…외 ${candidates.length - 10}개');
      }

      return AlertDialog(
        title: const Text('최근 구매 20개'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('추가할 항목: ${candidates.length}개'),
            const SizedBox(height: 12),
            ...lines.map(Text.new),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('추가'),
          ),
        ],
      );
    },
  );

  if (!context.mounted || confirmed != true) return;

  final now = DateTime.now();
  final incoming = candidates
      .map((c) {
        final key = ShoppingPrepUtils.normalizeName(c.name);
        return ShoppingCartItem(
          id: 'recent_${now.microsecondsSinceEpoch}_$key',
          name: c.name,
          quantity: _applyFactorToIntQuantity(
            c.quantity <= 0 ? 1 : c.quantity,
            qtyFactor,
          ),
          unitPrice: c.unitPrice,
          memo: _appendFactorMemo(null, qtyFactor),
          createdAt: now,
          updatedAt: now,
        );
      })
      .toList(growable: false);

  final result = ShoppingPrepUtils.mergeByName(
    existing: existingItems,
    incoming: incoming,
  );
  await saveItems(result.merged);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('최근 구매 추가: +${result.added}개 (중복 ${result.skipped}개)'),
    ),
  );
}
