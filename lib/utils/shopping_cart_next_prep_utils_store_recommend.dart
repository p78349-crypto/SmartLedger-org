part of 'shopping_cart_next_prep_utils.dart';

/// 마트/쇼핑몰별 추천 (거래 이력 빈도 기반)
Future<void> _recommendFromTransactionsFrequencyByStoreMemo({
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

  final trend = await ActivityHouseholdEstimatorService.compareTrend();
  final qtyFactor = _resolveQuantityFactorFromTrend(trend);

  if (!context.mounted) return;

  await _showStoreRecommendSheet(
    context: context,
    storeMemo: storeMemo,
    top: top,
    existingItems: existingItems,
    saveItems: saveItems,
    qtyFactor: qtyFactor,
  );
}
