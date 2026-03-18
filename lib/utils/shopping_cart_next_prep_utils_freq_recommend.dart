part of 'shopping_cart_next_prep_utils.dart';

/// 구매 이력 빈도 기반 추천
Future<void> _recommendFromPurchaseHistoryFrequency({
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

  final trend = await ActivityHouseholdEstimatorService.compareTrend();
  final qtyFactor = _resolveQuantityFactorFromTrend(trend);

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
    SnackBar(content: Text('추천 추가: +${result.added}개 (중복 ${result.skipped}개)')),
  );
}
