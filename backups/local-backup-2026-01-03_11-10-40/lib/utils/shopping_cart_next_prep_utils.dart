import 'package:flutter/material.dart';

import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/shopping_cart_history_entry.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/models/shopping_template_item.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/store_alias_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/shopping_cart_next_prep_dialog_utils.dart';
import 'package:smart_ledger/utils/shopping_prep_utils.dart';
import 'package:smart_ledger/utils/store_memo_utils.dart';

class ShoppingCartNextPrepUtils {
  ShoppingCartNextPrepUtils._();

  static Future<void> run({
    required BuildContext context,
    required String accountName,
    required List<ShoppingCartItem> Function() getItems,
    required Map<String, CategoryHint> Function() getCategoryHints,
    required Future<void> Function(List<ShoppingCartItem> next) saveItems,
    required Future<void> Function() reload,
    bool showChooser = true,
    ShoppingCartNextPrepAction defaultAction =
        ShoppingCartNextPrepAction.recentPurchases20,
  }) async {
    final ShoppingCartNextPrepAction? choice;
    if (showChooser) {
      choice = await ShoppingCartNextPrepDialogUtils.show(
        context,
        defaultAction: defaultAction,
      );
    } else {
      choice = defaultAction;
    }
    if (!context.mounted || choice == null) return;

    switch (choice) {
      case ShoppingCartNextPrepAction.recentPurchases20:
        await _addFromRecentPurchases(
          context: context,
          accountName: accountName,
          existingItems: getItems(),
          saveItems: saveItems,
        );
        return;
      case ShoppingCartNextPrepAction.recommendFrequent20:
        await _recommendFromPurchaseHistoryFrequency(
          context: context,
          accountName: accountName,
          existingItems: getItems(),
          saveItems: saveItems,
          categoryHints: getCategoryHints(),
        );
        return;
      case ShoppingCartNextPrepAction.recommendFrequent20ByStoreMemo:
        await _recommendFromTransactionsFrequencyByStoreMemo(
          context: context,
          accountName: accountName,
          existingItems: getItems(),
          saveItems: saveItems,
          categoryHints: getCategoryHints(),
        );
        return;
    }
  }

  static Future<String?> _askStoreMemo(
    BuildContext context, {
    required String initialValue,
    required List<String> suggestions,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('마트명(메모) 입력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '예: 대형마트, 창고형마트, 회원제마트',
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
              onPressed: () => Navigator.of(dialogContext).pop(null),
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

  static String _normalizeMemoForMatch(String raw) {
    return StoreMemoUtils.normalizeMemoForMatch(raw);
  }

  static bool _isShoppingExpenseTx(Transaction t) {
    if (t.type != TransactionType.expense) return false;
    if (t.isRefund) return false;

    final main = t.mainCategory.trim();
    if (main == '식비') return true;
    if (main == '식품·음료비') return true;
    if (main == '생활용품비') return true;
    return false;
  }

  static bool _matchesStoreKey(
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

  static String _suggestInitialStoreMemo(
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

  static List<String> _suggestStoreMemoChips(
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

  static Future<void> _recommendFromTransactionsFrequencyByStoreMemo({
    required BuildContext context,
    required String accountName,
    required List<ShoppingCartItem> existingItems,
    required Future<void> Function(List<ShoppingCartItem> next) saveItems,
    required Map<String, CategoryHint> categoryHints,
  }) async {
    final service = TransactionService();
    await service.loadTransactions();
    if (!context.mounted) return;

    final aliasMap = await StoreAliasService.loadMap(accountName);
    if (!context.mounted) return;

    final all = service.getTransactions(accountName);
    final initial = _suggestInitialStoreMemo(all, aliasMap);
    final suggestions = _suggestStoreMemoChips(all, aliasMap);
    final storeMemo = await _askStoreMemo(
      context,
      initialValue: initial,
      suggestions: suggestions,
    );
    if (!context.mounted) return;
    if (storeMemo == null || storeMemo.trim().isEmpty) return;

    final now = DateTime.now();
    final storeKey = StoreMemoUtils.extractStoreKey(storeMemo) ?? storeMemo;
    final canonical = StoreAliasService.resolve(storeKey, aliasMap);
    final targetStoreNorm = _normalizeMemoForMatch(canonical);
    final scanStart = now.subtract(const Duration(days: 183));

    const maxTxScan = 1500;
    final recent = all.length <= maxTxScan
        ? all
        : all.sublist(all.length - maxTxScan);
    final recentSorted = List<Transaction>.from(recent)
      ..sort((a, b) => b.date.compareTo(a.date));

    final filtered = recentSorted
        .where(_isShoppingExpenseTx)
        .where((t) => !t.date.isBefore(scanStart))
        .where((t) => _matchesStoreKey(t, targetStoreNorm, aliasMap))
        .toList(growable: false);

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해당 메모로 기록된 구매 이력이 없습니다: $storeMemo')),
      );
      return;
    }

    const maxStaleDays = 180;
    const maxStaleDaysForFruit = 90;

    final countsByKey = <String, int>{};
    final latestByKey = <String, Transaction>{};

    for (final t in filtered) {
      final key = ShoppingPrepUtils.normalizeName(t.description);
      if (key.isEmpty) continue;
      countsByKey[key] = (countsByKey[key] ?? 0) + 1;

      final prev = latestByKey[key];
      if (prev == null || t.date.isAfter(prev.date)) {
        latestByKey[key] = t;
      }
    }

    bool matchAny(String normalized, Iterable<String> keywords) {
      for (final k in keywords) {
        if (normalized.contains(k)) return true;
      }
      return false;
    }

    bool isFruitKey(String key) {
      final hint = categoryHints[key];
      final sub = (hint?.subCategory ?? '').trim();
      if (sub == '과일') return true;

      final fruitKeywords = <String>{
        '과일',
        '사과',
        '바나나',
        '오렌지',
        '귤',
        '포도',
        '배',
        '키위',
        '파인애플',
        '멜론',
        '수박',
        '복숭아',
        '자두',
        '레몬',
        '망고',
        '블루베리',
        '딸기',
      };
      return matchAny(key, fruitKeywords);
    }

    double freshnessScore(String key, String rawName) {
      final hint = categoryHints[key];
      final sub = (hint?.subCategory ?? '').trim();
      final freshSubs = <String>{
        '채소',
        '야채',
        '정육',
        '육류',
        '수산',
        '해산물',
        '반찬',
        '두부',
        '계란',
        '유제품',
      };
      final fruitSubs = <String>{'과일'};

      final key0 = ShoppingPrepUtils.normalizeName(rawName);

      final freshKeywords = <String>{
        '상추',
        '깻잎',
        '시금치',
        '부추',
        '대파',
        '쪽파',
        '파',
        '양파',
        '감자',
        '오이',
        '당근',
        '버섯',
        '토마토',
        '고추',
        '마늘',
        '돼지',
        '소고기',
        '닭',
        '생선',
        '오징어',
        '새우',
        '조개',
        '두부',
        '계란',
        '우유',
      };

      final fruitKeywords = <String>{
        '과일',
        '사과',
        '바나나',
        '오렌지',
        '귤',
        '포도',
        '배',
        '키위',
        '파인애플',
        '멜론',
        '수박',
        '복숭아',
        '자두',
        '레몬',
        '망고',
        '블루베리',
        '딸기',
      };

      final isFresh = freshSubs.contains(sub) || matchAny(key0, freshKeywords);
      if (isFresh) return 1.25;

      final isFruit = fruitSubs.contains(sub) || matchAny(key0, fruitKeywords);
      if (isFruit) return 0.85;

      return 1.0;
    }

    final eligibleKeys = countsByKey.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .where((key) {
          final latest = latestByKey[key];
          if (latest == null) return false;
          final days = now.difference(latest.date).inDays;
          final cutoff = isFruitKey(key) ? maxStaleDaysForFruit : maxStaleDays;
          return days <= cutoff;
        })
        .toList(growable: false);

    if (eligibleKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추천 기준(2회 이상 구매)에 해당하는 이력이 없습니다.')),
      );
      return;
    }

    eligibleKeys.sort((a, b) {
      final ac = countsByKey[a] ?? 0;
      final bc = countsByKey[b] ?? 0;
      final byCount = bc.compareTo(ac);
      if (byCount != 0) return byCount;

      final ad = latestByKey[a]?.date;
      final bd = latestByKey[b]?.date;
      if (ad != null && bd != null) {
        final byDate = bd.compareTo(ad);
        if (byDate != 0) return byDate;
      }
      return a.compareTo(b);
    });

    final candidates = <ShoppingTemplateItem>[];
    final metaFresh = <String, double>{};
    final metaCount = <String, int>{};
    final metaLast = <String, DateTime>{};

    for (final key in eligibleKeys) {
      final latest = latestByKey[key];
      if (latest == null) continue;
      final name = latest.description.trim();
      if (name.isEmpty) continue;
      final count = countsByKey[key] ?? 0;

      candidates.add(
        ShoppingTemplateItem(
          name: name,
          quantity: latest.quantity <= 0 ? 1 : latest.quantity,
          unitPrice: latest.unitPrice,
        ),
      );

      metaFresh[key] = freshnessScore(key, name);
      metaCount[key] = count;
      metaLast[key] = latest.date;

      if (candidates.length >= 60) break;
    }

    candidates.sort((a, b) {
      final ak = ShoppingPrepUtils.normalizeName(a.name);
      final bk = ShoppingPrepUtils.normalizeName(b.name);

      final af = metaFresh[ak] ?? 1.0;
      final bf = metaFresh[bk] ?? 1.0;
      final byFresh = bf.compareTo(af);
      if (byFresh != 0) return byFresh;

      final ac = metaCount[ak] ?? 0;
      final bc = metaCount[bk] ?? 0;
      final byCount = bc.compareTo(ac);
      if (byCount != 0) return byCount;

      final ad = metaLast[ak];
      final bd = metaLast[bk];
      if (ad != null && bd != null) {
        return bd.compareTo(ad);
      }
      return ak.compareTo(bk);
    });

    final top = candidates.take(20).toList(growable: false);
    if (top.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('추천할 항목이 없습니다.')));
      return;
    }

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
                  quantity: item.quantity <= 0 ? 1 : item.quantity,
                  unitPrice: item.unitPrice,
                  isPlanned: true,
                  isChecked: false,
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
                    title: const Text('마트별 추천'),
                    subtitle: Text('메모(마트명): $storeMemo'),
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

  static Future<void> _addFromRecentPurchases({
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
            quantity: c.quantity <= 0 ? 1 : c.quantity,
            unitPrice: c.unitPrice,
            isPlanned: true,
            isChecked: false,
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

  static Future<void> _recommendFromPurchaseHistoryFrequency({
    required BuildContext context,
    required String accountName,
    required List<ShoppingCartItem> existingItems,
    required Future<void> Function(List<ShoppingCartItem> next) saveItems,
    required Map<String, CategoryHint> categoryHints,
  }) async {
    final history = await UserPrefService.getShoppingCartHistory(
      accountName: accountName,
      limit: 2000,
    );
    if (!context.mounted) return;

    const maxStaleDays = 180;
    const maxStaleDaysForFruit = 90;
    final now = DateTime.now();

    final countsByKey = <String, int>{};
    final latestByKey = <String, ShoppingCartHistoryEntry>{};
    for (final h in history) {
      if (h.action != ShoppingCartHistoryAction.addToLedger) continue;
      final key = ShoppingPrepUtils.normalizeName(h.name);
      if (key.isEmpty) continue;
      countsByKey[key] = (countsByKey[key] ?? 0) + 1;

      final prev = latestByKey[key];
      if (prev == null || h.at.isAfter(prev.at)) {
        latestByKey[key] = h;
      }
    }

    bool matchAny(String normalized, Iterable<String> keywords) {
      for (final k in keywords) {
        if (normalized.contains(k)) return true;
      }
      return false;
    }

    double freshnessScore(String key, String rawName) {
      final hint = categoryHints[key];
      final sub = (hint?.subCategory ?? '').trim();
      final freshSubs = <String>{
        '채소',
        '야채',
        '정육',
        '육류',
        '수산',
        '해산물',
        '반찬',
        '두부',
        '계란',
        '유제품',
      };
      final fruitSubs = <String>{'과일'};
      final freshKeywords = <String>{
        '상추',
        '깻잎',
        '시금치',
        '부추',
        '대파',
        '쪽파',
        '파',
        '양파',
        '감자',
        '오이',
        '당근',
        '버섯',
        '토마토',
        '고추',
        '마늘',
        '돼지',
        '소고기',
        '닭',
        '생선',
        '오징어',
        '새우',
        '조개',
        '두부',
        '계란',
        '우유',
      };
      final fruitKeywords = <String>{
        '과일',
        '사과',
        '바나나',
        '오렌지',
        '귤',
        '포도',
        '배',
        '키위',
        '파인애플',
        '멜론',
        '수박',
        '복숭아',
        '자두',
        '레몬',
        '망고',
        '블루베리',
        '딸기',
      };

      final isFresh = freshSubs.contains(sub) || matchAny(key, freshKeywords);
      if (isFresh) return 1.25;

      final isFruit = fruitSubs.contains(sub) || matchAny(key, fruitKeywords);
      if (isFruit) return 0.85;

      return 1.0;
    }

    bool isFruitKey(String key) {
      final hint = categoryHints[key];
      final sub = (hint?.subCategory ?? '').trim();
      if (sub == '과일') return true;

      final fruitKeywords = <String>{
        '과일',
        '사과',
        '바나나',
        '오렌지',
        '귤',
        '포도',
        '배',
        '키위',
        '파인애플',
        '멜론',
        '수박',
        '복숭아',
        '자두',
        '레몬',
        '망고',
        '블루베리',
        '딸기',
      };
      return matchAny(key, fruitKeywords);
    }

    final eligibleKeys = countsByKey.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .where((key) {
          final latest = latestByKey[key];
          if (latest == null) return false;
          final days = now.difference(latest.at).inDays;
          final cutoff = isFruitKey(key) ? maxStaleDaysForFruit : maxStaleDays;
          return days <= cutoff;
        })
        .toList(growable: false);

    if (eligibleKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추천 기준(2회 이상 구매)에 해당하는 이력이 없습니다.')),
      );
      return;
    }

    eligibleKeys.sort((a, b) {
      final ac = countsByKey[a] ?? 0;
      final bc = countsByKey[b] ?? 0;
      final byCount = bc.compareTo(ac);
      if (byCount != 0) return byCount;

      final ad = latestByKey[a]?.at;
      final bd = latestByKey[b]?.at;
      if (ad != null && bd != null) {
        final byDate = bd.compareTo(ad);
        if (byDate != 0) return byDate;
      }
      return a.compareTo(b);
    });

    final candidates = <ShoppingTemplateItem>[];
    final metaFresh = <String, double>{};
    final metaCount = <String, int>{};
    final metaLast = <String, DateTime>{};

    for (final key in eligibleKeys) {
      final latest = latestByKey[key];
      if (latest == null) continue;
      final name = latest.name.trim();
      if (name.isEmpty) continue;
      final count = countsByKey[key] ?? 0;

      candidates.add(
        ShoppingTemplateItem(
          name: name,
          quantity: latest.quantity <= 0 ? 1 : latest.quantity,
          unitPrice: latest.unitPrice,
        ),
      );

      metaFresh[key] = freshnessScore(key, name);
      metaCount[key] = count;
      metaLast[key] = latest.at;

      if (candidates.length >= 60) break;
    }

    candidates.sort((a, b) {
      final ak = ShoppingPrepUtils.normalizeName(a.name);
      final bk = ShoppingPrepUtils.normalizeName(b.name);

      final af = metaFresh[ak] ?? 1.0;
      final bf = metaFresh[bk] ?? 1.0;
      final byFresh = bf.compareTo(af);
      if (byFresh != 0) return byFresh;

      final ac = metaCount[ak] ?? 0;
      final bc = metaCount[bk] ?? 0;
      final byCount = bc.compareTo(ac);
      if (byCount != 0) return byCount;

      final ad = metaLast[ak];
      final bd = metaLast[bk];
      if (ad != null && bd != null) {
        return bd.compareTo(ad);
      }
      return ak.compareTo(bk);
    });

    final top = candidates.take(20).toList(growable: false);
    if (top.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('추천할 항목이 없습니다.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final lines = top.take(10).map((c) => '• ${c.name}').toList();
        if (top.length > 10) {
          lines.add('…외 ${top.length - 10}개');
        }

        return AlertDialog(
          title: const Text('추천 품목 20개'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('추가할 추천 항목: ${top.length}개'),
              const SizedBox(height: 8),
              const Text('기준: 가계부 입력 이력에서 동일 품목 2회 이상 구매'),
              const Text('동일 품목 판정: 공백 제거 + 소문자(예: "대파"="대 파")'),
              const SizedBox(height: 4),
              const Text('추가 필터: 오래된 품목은 제외(과일은 더 엄격)'),
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
    final incoming = top
        .map((c) {
          final key = ShoppingPrepUtils.normalizeName(c.name);
          return ShoppingCartItem(
            id: 'freq_${now.microsecondsSinceEpoch}_$key',
            name: c.name,
            quantity: c.quantity <= 0 ? 1 : c.quantity,
            unitPrice: c.unitPrice,
            isPlanned: true,
            isChecked: false,
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
        content: Text('추천 추가: +${result.added}개 (중복 ${result.skipped}개)'),
      ),
    );
  }
}
