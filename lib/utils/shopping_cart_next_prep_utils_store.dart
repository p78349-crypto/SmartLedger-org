part of 'shopping_cart_next_prep_utils.dart';

/// 매장 메모, 거래 필터, 매장 제안 관련 유틸리티
Future<void> _openRecipeSearch({
  required BuildContext context,
  required String accountName,
  required List<ShoppingCartItem> existingItems,
  required Future<void> Function(List<ShoppingCartItem> next) saveItems,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => NutritionReportScreen(
        rawText: '',
        onAddIngredient: (ingredient) async {
          final now = DateTime.now();
          final newItem = ShoppingCartItem(
            id: 'sc_${now.microsecondsSinceEpoch}',
            name: ingredient,
            memo: '레시피에서 추가됨',
            createdAt: now,
            updatedAt: now,
          );
          final current = existingItems;
          await saveItems([...current, newItem]);
        },
      ),
    ),
  );
}

Future<String?> _askStoreMemo(
  BuildContext context, {
  required String initialValue,
  required List<String> suggestions,
}) async {
  final controller = TextEditingController(text: initialValue);
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('마트/쇼핑몰명(메모) 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '예: 대형마트, 온라인 쇼핑몰, 창고형마트',
                border: OutlineInputBorder(),
              ),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in suggestions)
                    ActionChip(
                      label: Text(s),
                      onPressed: () {
                        controller.text = s;
                        controller.selection = TextSelection.collapsed(
                          offset: controller.text.length,
                        );
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('확인'),
          ),
        ],
      );
    },
  );

  controller.dispose();
  if (!context.mounted) return null;

  final store = StoreMemoUtils.extractStoreKey(result);
  if (store == null || store.isEmpty) return null;
  return store;
}

String _normalizeMemoForMatch(String raw) {
  return StoreMemoUtils.normalizeMemoForMatch(raw);
}

bool _isShoppingExpenseTx(Transaction t) {
  if (t.type != TransactionType.expense) return false;
  if (t.isRefund) return false;

  final main = t.mainCategory.trim();
  if (main == '식비') return true;
  if (main == '식품·음료비') return true;
  if (main == '생활용품비') return true;
  return false;
}

bool _matchesStoreKey(
  Transaction t,
  String targetStoreNorm,
  Map<String, String> aliasMap,
) {
  final txStore = t.store?.trim();
  if (txStore != null && txStore.isNotEmpty) {
    final canonical = StoreAliasService.resolve(txStore, aliasMap);
    return _normalizeMemoForMatch(canonical) == targetStoreNorm;
  }

  final memo = t.memo.trim();
  if (memo.isEmpty) return false;

  final firstLine = memo.split(RegExp(r'[\r\n]+')).first.trim();
  final extracted = StoreMemoUtils.extractStoreKey(firstLine);
  if (extracted != null && extracted.isNotEmpty) {
    final canonical = StoreAliasService.resolve(extracted, aliasMap);
    return _normalizeMemoForMatch(canonical) == targetStoreNorm;
  }

  final memoNorm = _normalizeMemoForMatch(memo);
  if (memoNorm.isEmpty) return false;
  return memoNorm.contains(targetStoreNorm);
}

String _suggestInitialStoreMemo(
  List<Transaction> transactions,
  Map<String, String> aliasMap,
) {
  final candidates = transactions
      .where(_isShoppingExpenseTx)
      .where((t) => t.memo.trim().isNotEmpty)
      .toList(growable: false);

  if (candidates.isEmpty) return '';
  candidates.sort((a, b) => b.date.compareTo(a.date));
  final first = candidates.first;
  final store = first.store?.trim();
  if (store != null && store.isNotEmpty) {
    return StoreAliasService.resolve(store, aliasMap);
  }

  final memo = first.memo.trim();
  final firstLine = memo.split(RegExp(r'[\r\n]+')).first.trim();
  final extracted = StoreMemoUtils.extractStoreKey(firstLine);
  if (extracted == null || extracted.isEmpty) return '';
  return StoreAliasService.resolve(extracted, aliasMap);
}

List<String> _suggestStoreMemoChips(
  List<Transaction> transactions,
  Map<String, String> aliasMap,
) {
  final now = DateTime.now();
  final scanStart = now.subtract(const Duration(days: 183));

  const maxTxScan = 1500;
  final recentSorted = List<Transaction>.from(transactions)
    ..sort((a, b) => b.date.compareTo(a.date));
  final recent = recentSorted.take(maxTxScan);

  final counts = <String, int>{};
  final latest = <String, DateTime>{};

  for (final t in recent) {
    if (!_isShoppingExpenseTx(t)) continue;
    if (t.date.isBefore(scanStart)) continue;

    final txStore = t.store?.trim();
    final store = (txStore != null && txStore.isNotEmpty)
        ? StoreAliasService.resolve(txStore, aliasMap)
        : (() {
            final memo = t.memo.trim();
            if (memo.isEmpty) return null;
            final firstLine = memo.split(RegExp(r'[\r\n]+')).first.trim();
            final extracted = StoreMemoUtils.extractStoreKey(firstLine);
            if (extracted == null || extracted.isEmpty) return null;
            return StoreAliasService.resolve(extracted, aliasMap);
          })();
    if (store == null || store.isEmpty) continue;

    counts[store] = (counts[store] ?? 0) + 1;
    final prev = latest[store];
    if (prev == null || t.date.isAfter(prev)) {
      latest[store] = t.date;
    }
  }

  final ranked = counts.keys.toList(growable: false)
    ..sort((a, b) {
      final ca = counts[a] ?? 0;
      final cb = counts[b] ?? 0;
      if (ca != cb) return cb.compareTo(ca);
      final da = latest[a] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = latest[b] ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

  return ranked.take(6).toList(growable: false);
}
