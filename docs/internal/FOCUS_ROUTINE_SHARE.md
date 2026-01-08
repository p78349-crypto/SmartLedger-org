# 자동 포커스 이동 루틴 공유

아래에 관련 코드를 그대로 붙여넣어 주세요.

## 1) 문제가 나는 입력칸 코드
- 특히 `수량` TextField/SmartInputField 부분
- `textInputAction`, `onSubmitted`, `onEditingComplete`, `focusNode` 포함

```dart
// 여기에 붙여넣기
```

## 2) 포커스 이동 함수/헬퍼
- 예: `_focusNextInlineField`, `nextFocus`, `ensureVisible` 관련

```dart
// 여기에 붙여넣기
```

## 3) FocusNode/Controller 생성·정리
- 예: `_qtyFocusNodes`, `_unitPriceFocusNodes`, `_unitLabelFocusNodes`
- 생성/리스너/dispose 포함

```dart
// 여기에 붙여넣기
```

## 4) (선택) 초기 버전(잘 되던 시점) 코드
가능하면 이전 버전 코드도 같이 붙여넣어 주세요.

```dart
// 여기에 붙여넣기
```


import 'package:flutter/material.dart';

enum ShoppingCartNextPrepAction {
  recentPurchases20,
  recommendFrequent20,
}

class ShoppingCartNextPrepDialogUtils {
  ShoppingCartNextPrepDialogUtils._();

  static Future<ShoppingCartNextPrepAction?> show(
    BuildContext context, {
    required ShoppingCartNextPrepAction defaultAction,
  }) async {
    final actions = <ShoppingCartNextPrepAction>[
      ...ShoppingCartNextPrepAction.values,
    ];
    actions
      ..remove(defaultAction)
      ..insert(0, defaultAction);

    IconData iconOf(ShoppingCartNextPrepAction a) {
      switch (a) {
        case ShoppingCartNextPrepAction.recentPurchases20:
          return Icons.history;
        case ShoppingCartNextPrepAction.recommendFrequent20:
          return Icons.auto_awesome;
      }
    }

    String titleOf(ShoppingCartNextPrepAction a) {
      switch (a) {
        case ShoppingCartNextPrepAction.recentPurchases20:
          return '최근 구매 20개';
        case ShoppingCartNextPrepAction.recommendFrequent20:
          return '추천 품목 20개';
      }
    }

    String subtitleOf(ShoppingCartNextPrepAction a) {
      switch (a) {
        case ShoppingCartNextPrepAction.recentPurchases20:
          return '가장 최근 구매한 품목을 최대 20개 추가합니다.';
        case ShoppingCartNextPrepAction.recommendFrequent20:
          return '가계부 입력 이력에서 2회 이상 구매한 품목만 추천합니다.';
      }
    }

    return showModalBottomSheet<ShoppingCartNextPrepAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('쇼핑 준비'),
                subtitle: Text('원하는 준비 방식을 선택하세요.'),
              ),
              const Divider(height: 1),
              ...actions.map((a) {
                final isDefault = a == defaultAction;
                final title =
                    isDefault ? '${titleOf(a)} (추천)' : titleOf(a);
                return ListTile(
                  leading: Icon(iconOf(a)),
                  title: Text(title),
                  subtitle: Text(subtitleOf(a)),
                  onTap: () => Navigator.of(sheetContext).pop(a),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

}

//////////////////////////


import 'package:flutter/material.dart';

import 'package:vccode1/models/category_hint.dart';
import 'package:vccode1/models/shopping_cart_history_entry.dart';
import 'package:vccode1/models/shopping_cart_item.dart';
import 'package:vccode1/models/shopping_template_item.dart';
import 'package:vccode1/services/user_pref_service.dart';
import 'package:vccode1/utils/shopping_cart_next_prep_dialog_utils.dart';
import 'package:vccode1/utils/shopping_prep_utils.dart';

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
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최근 구매 기록이 없습니다.')),
      );
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
    final incoming = candidates.map((c) {
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
    }).toList(growable: false);

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
      final fruitSubs = <String>{
        '과일',
      };
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
        const SnackBar(
          content: Text('추천 기준(2회 이상 구매)에 해당하는 이력이 없습니다.'),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추천할 항목이 없습니다.')),
      );
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
              const Text(
                '기준: 가계부 입력 이력에서 동일 품목 2회 이상 구매',
              ),
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
    final incoming = top.map((c) {
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
    }).toList(growable: false);

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

//////////////////////
typedef ShoppingCategoryPair = ({String mainCategory, String? subCategory});

/// SSOT keyword rules for shopping item → category suggestion.
///
/// Add more keywords by editing these maps.
class ShoppingCategoryRules {
  const ShoppingCategoryRules._();

  static const ShoppingCategoryPair foodGrocery = (
    mainCategory: '식비',
    subCategory: '식자재 구매',
  );

  static const ShoppingCategoryPair foodSnack = (
    mainCategory: '식비',
    subCategory: '간식',
  );

  static const ShoppingCategoryPair foodDrink = (
    mainCategory: '식비',
    subCategory: '음료',
  );

  static const ShoppingCategoryPair suppliesHygiene = (
    mainCategory: '생활용품비',
    subCategory: '위생용품',
  );

  static const ShoppingCategoryPair suppliesPaper = (
    mainCategory: '생활용품비',
    subCategory: '종이용품',
  );

  static const ShoppingCategoryPair suppliesConsumable = (
    mainCategory: '생활용품비',
    subCategory: '생활소모품',
  );

  static const ShoppingCategoryPair suppliesBaby = (
    mainCategory: '생활용품비',
    subCategory: '유아용품',
  );

  // --- Templates (expand by filling keywords) ---
  // Tip: 키워드는 짧게(부분일치) 넣는 게 유지보수에 유리합니다.
  // 예) '타이레놀', '감기약', '주차', '버스', '셔츠'

  static const ShoppingCategoryPair medicalPharmacy = (
    mainCategory: '의료비',
    subCategory: '약국 의약품',
  );

  static const ShoppingCategoryPair medicalHospital = (
    mainCategory: '의료비',
    subCategory: '병원 진료비',
  );

  static const ShoppingCategoryPair transportPublic = (
    mainCategory: '교통비',
    subCategory: '대중교통',
  );

  static const ShoppingCategoryPair transportParking = (
    mainCategory: '교통비',
    subCategory: '주차',
  );

  static const ShoppingCategoryPair housingUtilities = (
    mainCategory: '주거비',
    subCategory: '관리비',
  );

  static const ShoppingCategoryPair clothing = (
    mainCategory: '의류/잡화',
    subCategory: '의류',
  );

  /// 식자재 구매 (과일/유제품/계란/주식류)
  static const Map<String, ShoppingCategoryPair> groceryKeywords = {
    '사과': foodGrocery,
    '배': foodGrocery,
    '바나나': foodGrocery,
    '우유': foodGrocery,
    '치즈': foodGrocery,
    '요거': foodGrocery,
    '계란': foodGrocery,
    '달걀': foodGrocery,
    '빵': foodGrocery,
    '라면': foodGrocery,
    '김치': foodGrocery,
  };

  /// 간식
  static const Map<String, ShoppingCategoryPair> snackKeywords = {
    '과자': foodSnack,
    '초콜릿': foodSnack,
    '아이스': foodSnack,
    '간식': foodSnack,
  };

  /// 음료
  static const Map<String, ShoppingCategoryPair> drinkKeywords = {
    '커피': foodDrink,
    '음료': foodDrink,
    '콜라': foodDrink,
    '주스': foodDrink,
  };

  /// 위생용품
  static const Map<String, ShoppingCategoryPair> hygieneKeywords = {
    '샴푸': suppliesHygiene,
    '린스': suppliesHygiene,
    '비누': suppliesHygiene,
    '치약': suppliesHygiene,
    '칫솔': suppliesHygiene,
  };

  /// 종이용품
  static const Map<String, ShoppingCategoryPair> paperKeywords = {
    '휴지': suppliesPaper,
    '물티슈': suppliesPaper,
    '키친타월': suppliesPaper,
  };

  /// 생활소모품
  static const Map<String, ShoppingCategoryPair> consumableKeywords = {
    '세제': suppliesConsumable,
    '섬유유연제': suppliesConsumable,
    '락스': suppliesConsumable,
  };

  /// 유아용품
  static const Map<String, ShoppingCategoryPair> babyKeywords = {
    '기저귀': suppliesBaby,
    '분유': suppliesBaby,
    '젖병': suppliesBaby,
  };

  /// 의료(약국)
  static const Map<String, ShoppingCategoryPair> medicalPharmacyKeywords = {
    // '타이레놀': medicalPharmacy,
    // '감기약': medicalPharmacy,
    // '파스': medicalPharmacy,
  };

  /// 의료(병원)
  static const Map<String, ShoppingCategoryPair> medicalHospitalKeywords = {
    // '진료': medicalHospital,
    // '검사': medicalHospital,
  };

  /// 교통(대중교통)
  static const Map<String, ShoppingCategoryPair> transportPublicKeywords = {
    // '버스': transportPublic,
    // '지하철': transportPublic,
    // '택시': transportPublic,
  };

  /// 교통(주차)
  static const Map<String, ShoppingCategoryPair> transportParkingKeywords = {
    // '주차': transportParking,
  };

  /// 주거(공과금/관리비 등)
  static const Map<String, ShoppingCategoryPair> housingKeywords = {
    // '관리비': housingUtilities,
    // '전기': (mainCategory: '주거비', subCategory: '전기요금'),
    // '가스': (mainCategory: '주거비', subCategory: '가스요금'),
    // '수도': (mainCategory: '주거비', subCategory: '수도요금'),
  };

  /// 의류/잡화
  static const Map<String, ShoppingCategoryPair> clothingKeywords = {
    // '셔츠': clothing,
    // '바지': clothing,
    // '양말': (mainCategory: '의류/잡화', subCategory: '속옷'),
  };

  /// Ordered groups. First match wins.
  static const List<Map<String, ShoppingCategoryPair>> groups = [
    groceryKeywords,
    snackKeywords,
    drinkKeywords,
    hygieneKeywords,
    paperKeywords,
    consumableKeywords,
    babyKeywords,
    medicalPharmacyKeywords,
    medicalHospitalKeywords,
    transportPublicKeywords,
    transportParkingKeywords,
    housingKeywords,
    clothingKeywords,
  ];
}


import 'package:vccode1/models/category_hint.dart';
import 'package:vccode1/models/shopping_cart_item.dart';
import 'package:vccode1/models/transaction.dart';
import 'package:vccode1/utils/category_definitions.dart';
import 'package:vccode1/utils/shopping_category_rules.dart';

/// Shopping-category suggestion utilities.
///
/// SSOT: keep rules/normalization in one place so screens/services can reuse.
class ShoppingCategoryUtils {
  const ShoppingCategoryUtils._();

  static String normalizeHintKey(String raw) {
    return raw.trim().toLowerCase().replaceAll(' ', '');
  }

  static ({String mainCategory, String? subCategory}) validateSuggestion(
    ({String mainCategory, String? subCategory}) suggestion,
  ) {
    const options = CategoryDefinitions.categoryOptions;
    final main = suggestion.mainCategory;
    if (!options.containsKey(main)) {
      return (
        mainCategory: Transaction.defaultMainCategory,
        subCategory: null,
      );
    }

    final subs = options[main] ?? const <String>[];
    final sub = suggestion.subCategory;

    if (sub == null || sub.trim().isEmpty) {
      return (mainCategory: main, subCategory: null);
    }
    if (!subs.contains(sub)) {
      return (mainCategory: main, subCategory: null);
    }
    return (mainCategory: main, subCategory: sub);
  }

  static ({String mainCategory, String? subCategory})? hintFromLearned(
    ShoppingCartItem item,
    Map<String, CategoryHint> learnedHints,
  ) {
    final normalized = normalizeHintKey(item.name);
    if (normalized.isEmpty) return null;

    final exact = learnedHints[normalized];
    if (exact != null) {
      return (
        mainCategory: exact.mainCategory,
        subCategory: exact.subCategory,
      );
    }

    for (final entry in learnedHints.entries) {
      final key = entry.key;
      if (key.isEmpty) continue;
      if (normalized.contains(key) || key.contains(normalized)) {
        final hint = entry.value;
        return (mainCategory: hint.mainCategory, subCategory: hint.subCategory);
      }
    }

    return null;
  }

  static ({String mainCategory, String? subCategory}) suggestBuiltIn(
    ShoppingCartItem item,
  ) {
    final name = item.name.trim();
    if (name.isEmpty) {
      return (
        mainCategory: Transaction.defaultMainCategory,
        subCategory: null,
      );
    }

    for (final group in ShoppingCategoryRules.groups) {
      for (final entry in group.entries) {
        if (name.contains(entry.key)) {
          return validateSuggestion(
            (
              mainCategory: entry.value.mainCategory,
              subCategory: entry.value.subCategory,
            ),
          );
        }
      }
    }

    return (
      mainCategory: Transaction.defaultMainCategory,
      subCategory: null,
    );
  }

  static ({String mainCategory, String? subCategory}) suggest(
    ShoppingCartItem item, {
    required Map<String, CategoryHint> learnedHints,
  }) {
    final learned = hintFromLearned(item, learnedHints);
    if (learned != null) return validateSuggestion(learned);
    return suggestBuiltIn(item);
  }
}
import 'package:vccode1/models/category_hint.dart';
import 'package:vccode1/models/shopping_cart_item.dart';
import 'package:vccode1/models/transaction.dart';
import 'package:vccode1/utils/category_definitions.dart';
import 'package:vccode1/utils/shopping_category_rules.dart';

/// Shopping-category suggestion utilities.
///
/// SSOT: keep rules/normalization in one place so screens/services can reuse.
class ShoppingCategoryUtils {
  const ShoppingCategoryUtils._();

  static String normalizeHintKey(String raw) {
    return raw.trim().toLowerCase().replaceAll(' ', '');
  }

  static ({String mainCategory, String? subCategory}) validateSuggestion(
    ({String mainCategory, String? subCategory}) suggestion,
  ) {
    const options = CategoryDefinitions.categoryOptions;
    final main = suggestion.mainCategory;
    if (!options.containsKey(main)) {
      return (
        mainCategory: Transaction.defaultMainCategory,
        subCategory: null,
      );
    }

    final subs = options[main] ?? const <String>[];
    final sub = suggestion.subCategory;

    if (sub == null || sub.trim().isEmpty) {
      return (mainCategory: main, subCategory: null);
    }
    if (!subs.contains(sub)) {
      return (mainCategory: main, subCategory: null);
    }
    return (mainCategory: main, subCategory: sub);
  }

  static ({String mainCategory, String? subCategory})? hintFromLearned(
    ShoppingCartItem item,
    Map<String, CategoryHint> learnedHints,
  ) {
    final normalized = normalizeHintKey(item.name);
    if (normalized.isEmpty) return null;

    final exact = learnedHints[normalized];
    if (exact != null) {
      return (
        mainCategory: exact.mainCategory,
        subCategory: exact.subCategory,
      );
    }

    for (final entry in learnedHints.entries) {
      final key = entry.key;
      if (key.isEmpty) continue;
      if (normalized.contains(key) || key.contains(normalized)) {
        final hint = entry.value;
        return (mainCategory: hint.mainCategory, subCategory: hint.subCategory);
      }
    }

    return null;
  }

  static ({String mainCategory, String? subCategory}) suggestBuiltIn(
    ShoppingCartItem item,
  ) {
    final name = item.name.trim();
    if (name.isEmpty) {
      return (
        mainCategory: Transaction.defaultMainCategory,
        subCategory: null,
      );
    }

    for (final group in ShoppingCategoryRules.groups) {
      for (final entry in group.entries) {
        if (name.contains(entry.key)) {
          return validateSuggestion(
            (
              mainCategory: entry.value.mainCategory,
              subCategory: entry.value.subCategory,
            ),
          );
        }
      }
    }

    return (
      mainCategory: Transaction.defaultMainCategory,
      subCategory: null,
    );
  }

  static ({String mainCategory, String? subCategory}) suggest(
    ShoppingCartItem item, {
    required Map<String, CategoryHint> learnedHints,
  }) {
    final learned = hintFromLearned(item, learnedHints);
    if (learned != null) return validateSuggestion(learned);
    return suggestBuiltIn(item);
  }
}

import 'package:flutter/material.dart';

import 'package:vccode1/models/category_hint.dart';
import 'package:vccode1/models/shopping_cart_item.dart';
import 'package:vccode1/navigation/app_routes.dart';
import 'package:vccode1/services/user_pref_service.dart';
import 'package:vccode1/utils/currency_formatter.dart';
import 'package:vccode1/utils/shopping_cart_bulk_ledger_utils.dart';
import 'package:vccode1/utils/shopping_cart_next_prep_utils.dart';
import 'package:vccode1/widgets/zero_quick_buttons.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({
    super.key,
    required this.accountName,
    this.openPrepOnStart = false,
  });

  final String accountName;
  final bool openPrepOnStart;

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  bool _isLoading = true;
  List<ShoppingCartItem> _items = const [];
  Map<String, CategoryHint> _categoryHints = const <String, CategoryHint>{};

  bool _didAutoOpenPrep = false;

  final TextEditingController _nameController = TextEditingController();

  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _unitPriceControllers = {};

  final Map<String, FocusNode> _qtyFocusNodes = {};
  final Map<String, FocusNode> _unitPriceFocusNodes = {};

  String _unitPriceTextForInlineEditor(double unitPrice) {
    if (unitPrice <= 0) return '';
    return unitPrice == unitPrice.roundToDouble()
        ? CurrencyFormatter.format(unitPrice, showUnit: false)
        : CurrencyFormatter.formatWithDecimals(unitPrice, showUnit: false);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final c in _unitPriceControllers.values) {
      c.dispose();
    }
    for (final n in _qtyFocusNodes.values) {
      n.dispose();
    }
    for (final n in _unitPriceFocusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _syncInlineControllers(List<ShoppingCartItem> next) {
    final ids = next.map((e) => e.id).toSet();

    final qtyRemoved = _qtyControllers.keys.where((k) => !ids.contains(k));
    for (final k in qtyRemoved.toList(growable: false)) {
      _qtyControllers.remove(k)?.dispose();
    }

    final qtyFocusRemoved = _qtyFocusNodes.keys.where((k) => !ids.contains(k));
    for (final k in qtyFocusRemoved.toList(growable: false)) {
      _qtyFocusNodes.remove(k)?.dispose();
    }

    final unitRemoved = _unitPriceControllers.keys
        .where((k) => !ids.contains(k));
    for (final k in unitRemoved.toList(growable: false)) {
      _unitPriceControllers.remove(k)?.dispose();
    }

    final unitFocusRemoved = _unitPriceFocusNodes.keys
        .where((k) => !ids.contains(k));
    for (final k in unitFocusRemoved.toList(growable: false)) {
      _unitPriceFocusNodes.remove(k)?.dispose();
    }

    for (final item in next) {
      final qty = item.quantity <= 0 ? 1 : item.quantity;
      final qtyText = qty.toString();
      final qtyC = _qtyControllers[item.id];
      if (qtyC == null) {
        _qtyControllers[item.id] = TextEditingController(text: qtyText);
      } else {
        final hasFocus = _qtyFocusNodes[item.id]?.hasFocus ?? false;
        if (!hasFocus && qtyC.text != qtyText) {
          qtyC.text = qtyText;
        }
      }

      _qtyFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        node.addListener(() {
          if (mounted) setState(() {});
        });
        return node;
      });

      final unitText = _unitPriceTextForInlineEditor(item.unitPrice);
      final unitC = _unitPriceControllers[item.id];
      if (unitC == null) {
        _unitPriceControllers[item.id] = TextEditingController(text: unitText);
      } else {
        final hasFocus = _unitPriceFocusNodes[item.id]?.hasFocus ?? false;
        if (!hasFocus && unitC.text != unitText) {
          unitC.text = unitText;
        }
      }

      _unitPriceFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        node.addListener(() {
          if (mounted) setState(() {});
        });
        return node;
      });
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await UserPrefService.getShoppingCartItems(
      accountName: widget.accountName,
    );
    final hints = await UserPrefService.getShoppingCategoryHints(
      accountName: widget.accountName,
    );
    if (!mounted) return;
    setState(() {
      _items = items;
      _categoryHints = hints;
      _isLoading = false;
    });

    _syncInlineControllers(items);

    if (!mounted) return;
    if (widget.openPrepOnStart && !_didAutoOpenPrep) {
      _didAutoOpenPrep = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ShoppingCartNextPrepUtils.run(
          context: context,
          accountName: widget.accountName,
          getItems: () => _items,
          getCategoryHints: () => _categoryHints,
          saveItems: _save,
          reload: _load,
          showChooser: false,
        );
      });
    }
  }

  Future<void> _save(List<ShoppingCartItem> next) async {
    setState(() => _items = next);
    _syncInlineControllers(next);
    await UserPrefService.setShoppingCartItems(
      accountName: widget.accountName,
      items: next,
    );
  }

  Future<void> _applyInlineEdits(ShoppingCartItem item) async {
    final qtyRaw = _qtyControllers[item.id]?.text.trim() ?? '';
    final unitRaw = _unitPriceControllers[item.id]?.text.trim() ?? '';

    final parsedQty = int.tryParse(qtyRaw);
    final parsedUnit = CurrencyFormatter.parse(unitRaw);

    final nextQty = (parsedQty == null)
        ? item.quantity
        : (parsedQty <= 0 ? 1 : parsedQty);
    final nextUnit = (parsedUnit == null) ? item.unitPrice : parsedUnit;

    if (nextQty == item.quantity && nextUnit == item.unitPrice) {
      return;
    }

    final now = DateTime.now();
    final updated = item.copyWith(
      quantity: nextQty,
      unitPrice: nextUnit,
      updatedAt: now,
    );
    final next = _items.map((i) => i.id == item.id ? updated : i).toList();
    await _save(next);
  }

  void _previewInlineEdits(ShoppingCartItem item) {
    final qtyRaw = _qtyControllers[item.id]?.text.trim() ?? '';
    final unitRaw = _unitPriceControllers[item.id]?.text.trim() ?? '';

    final parsedQty = int.tryParse(qtyRaw);
    final parsedUnit = CurrencyFormatter.parse(unitRaw);

    final nextQty = (parsedQty == null)
        ? item.quantity
        : (parsedQty <= 0 ? 1 : parsedQty);
    final nextUnit = (parsedUnit == null) ? item.unitPrice : parsedUnit;

    if (nextQty == item.quantity && nextUnit == item.unitPrice) {
      return;
    }

    final updated = item.copyWith(
      quantity: nextQty,
      unitPrice: nextUnit,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _items = _items.map((i) => i.id == item.id ? updated : i).toList();
    });
  }

  void _switchToCart() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.shoppingCart,
      arguments: ShoppingCartArgs(accountName: widget.accountName),
    );
  }

  void _switchToPrep() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.shoppingPrep,
      arguments: ShoppingCartArgs(accountName: widget.accountName),
    );
  }

  Widget _buildModeSwitchBar({required ThemeData theme}) {
    final isPrep = widget.openPrepOnStart;

    const height = 36.0;
    const radius = 18.0;

    final activeTextStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onPrimary,
    );
    final inactiveTextStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget segment({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      required BorderRadius borderRadius,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: selected ? activeTextStyle : inactiveTextStyle,
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              segment(
                label: '쇼핑준비',
                selected: isPrep,
                onTap: _switchToPrep,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(radius),
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: theme.colorScheme.outlineVariant,
              ),
              segment(
                label: '장바구니',
                selected: !isPrep,
                onTap: _switchToCart,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(radius),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ShoppingCartItem> _orderedItems(List<ShoppingCartItem> list) {
    // Keep list order, but group by purchase state:
    // - 미구매(체크 안 됨) 먼저
    // - 구매완료(체크됨) 나중
    // Within each group, preserve the original order (stable).
    final unChecked = <ShoppingCartItem>[];
    final checked = <ShoppingCartItem>[];
    for (final item in list) {
      (item.isChecked ? checked : unChecked).add(item);
    }
    return [...unChecked, ...checked];
  }

  Future<void> _addItem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final now = DateTime.now();
    final item = ShoppingCartItem(
      id: 'shop_${now.microsecondsSinceEpoch}',
      name: name,
      isPlanned: true,
      isChecked: false,
      createdAt: now,
      updatedAt: now,
    );

    final next = [item, ..._items];
    _nameController.clear();
    await _save(next);
  }

  Future<void> _toggleChecked(ShoppingCartItem item) async {
    if (item.isChecked) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('카트에서 뺄까요?'),
          content: Text('"${item.name}"을(를) 카트에서 뺄까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('빼기'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    final now = DateTime.now();
    final updated = item.copyWith(
      isChecked: !item.isChecked,
      updatedAt: now,
    );
    final next = _items.map((i) => i.id == item.id ? updated : i).toList();
    await _save(next);
  }

  Future<void> _deleteItem(ShoppingCartItem item) async {
    final next = _items.where((i) => i.id != item.id).toList();
    await _save(next);
  }

  Future<void> _confirmAndDeleteItem(ShoppingCartItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('"${item.name}"을(를) 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _deleteItem(item);
  }

  Future<void> _addCheckedItemsToLedgerBulk() async {
    await ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk(
      context: context,
      accountName: widget.accountName,
      items: _items,
      categoryHints: _categoryHints,
      saveItems: _save,
      reload: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrep = widget.openPrepOnStart;
    const nameFieldHeight = 48.0;

    void runShoppingPrep({required bool showChooser}) {
      ShoppingCartNextPrepUtils.run(
        context: context,
        accountName: widget.accountName,
        getItems: () => _items,
        getCategoryHints: () => _categoryHints,
        saveItems: _save,
        reload: _load,
        showChooser: showChooser,
      );
    }

    final ordered = _orderedItems(_items);
    final checkedCount = _items.where((i) => i.isChecked).length;
    int qtyOf(ShoppingCartItem i) => i.quantity <= 0 ? 1 : i.quantity;

    final isInlineEditing =
      _qtyFocusNodes.values.any((n) => n.hasFocus) ||
      _unitPriceFocusNodes.values.any((n) => n.hasFocus);

    return Scaffold(
      backgroundColor: isPrep
          ? theme.colorScheme.surfaceContainerLowest
          : theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
      centerTitle: true,
        title: _buildModeSwitchBar(theme: theme),
        actions: widget.openPrepOnStart
            ? [
                Tooltip(
                  message: '쇼핑 준비 (탭: 빠른 실행, 길게: 메뉴)',
                  child: GestureDetector(
                    onLongPress: _isLoading
                        ? null
                        : () => runShoppingPrep(showChooser: true),
                    child: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => runShoppingPrep(showChooser: false),
                      icon: const Icon(Icons.event_repeat),
                    ),
                  ),
                ),
              ]
            : const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: nameFieldHeight,
                    child: TextField(
                      controller: _nameController,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: '물품 이름',
                        hintText: isPrep ? null : '장바구니 모드',
                        border: const OutlineInputBorder(),
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: nameFieldHeight,
                  child: FilledButton(
                    onPressed: _addItem,
                    child: const Text('추가'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: (!_isLoading)
          ? (widget.openPrepOnStart
              ? null
              : _buildCheckedSummaryBar(
                  theme: theme,
                  checkedCount: checkedCount,
                ))
          : null,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (ordered.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    '구매 예정 물품을 등록하세요.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        physics:
                            isInlineEditing
                                ? const NeverScrollableScrollPhysics()
                                : null,
                        itemCount: ordered.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = ordered[index];

                          // Ensure inline editors exist even if controllers
                          // temporarily go out-of-sync (e.g. fast rebuilds).
                          _qtyControllers.putIfAbsent(
                            item.id,
                            () => TextEditingController(
                              text: (item.quantity <= 0 ? 1 : item.quantity)
                                  .toString(),
                            ),
                          );
                          _unitPriceControllers.putIfAbsent(
                            item.id,
                            () => TextEditingController(
                              text: _unitPriceTextForInlineEditor(
                                item.unitPrice,
                              ),
                            ),
                          );
                          _qtyFocusNodes.putIfAbsent(item.id, FocusNode.new);
                          _unitPriceFocusNodes.putIfAbsent(
                            item.id,
                            FocusNode.new,
                          );

                          final isCartMode = !widget.openPrepOnStart;
                          final isSelected = isCartMode && item.isChecked;

                          final qtyController = _qtyControllers[item.id]!;
                            final unitController =
                              _unitPriceControllers[item.id]!;
                          final qtyFocusNode = _qtyFocusNodes[item.id]!;
                          final unitFocusNode =
                              _unitPriceFocusNodes[item.id]!;
                          const unitKeyboardType =
                              TextInputType.numberWithOptions(decimal: true);

                          return ListTile(
                            contentPadding:
                                const EdgeInsetsDirectional.fromSTEB(
                              12,
                              0,
                              0,
                              0,
                            ),
                            dense: true,
                            visualDensity: const VisualDensity(
                              horizontal: -2,
                              vertical: -2,
                            ),
                            minVerticalPadding: 0,
                            selected: isSelected,
                            selectedTileColor:
                                theme.colorScheme.primaryContainer,
                            leading: null,
                            title: Row(
                              children: [
                                if (!widget.openPrepOnStart) ...[
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Center(
                                      child: Transform.scale(
                                        scale: 0.85,
                                        child: Checkbox(
                                          value: item.isChecked,
                                          onChanged: (_) =>
                                              _toggleChecked(item),
                                          visualDensity:
                                              VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      '${item.name} × ${qtyOf(item)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? theme.colorScheme
                                                .onPrimaryContainer
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!widget.openPrepOnStart) ...[
                                  SizedBox(
                                    width: 180,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: TextField(
                                                controller: unitController,
                                                focusNode: unitFocusNode,
                                                textAlign: TextAlign.end,
                                                keyboardType: unitKeyboardType,
                                                textInputAction:
                                                    TextInputAction.next,
                                                decoration:
                                                    const InputDecoration(
                                                  isDense: true,
                                                  hintText: '가격',
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                                ),
                                                onChanged: (_) =>
                                                    _previewInlineEdits(item),
                                                onTapOutside: (_) {
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();
                                                  _applyInlineEdits(item);
                                                },
                                                onEditingComplete: () =>
                                                    _applyInlineEdits(item),
                                                onSubmitted: (_) {
                                                  FocusScope.of(
                                                    context,
                                                  ).nextFocus();
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 1,
                                              child: TextField(
                                                controller: qtyController,
                                                focusNode: qtyFocusNode,
                                                textAlign: TextAlign.end,
                                                keyboardType:
                                                    TextInputType.number,
                                                textInputAction:
                                                    TextInputAction.done,
                                                decoration:
                                                    const InputDecoration(
                                                  isDense: true,
                                                  hintText: '수량',
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                                ),
                                                onChanged: (_) =>
                                                    _previewInlineEdits(item),
                                                onTapOutside: (_) {
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();
                                                  _applyInlineEdits(item);
                                                },
                                                onEditingComplete: () =>
                                                    _applyInlineEdits(item),
                                                onSubmitted: (_) {
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();
                                                  _applyInlineEdits(item);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (unitFocusNode.hasFocus ||
                                            qtyFocusNode.hasFocus) ...[
                                          const SizedBox(height: 6),
                                          ZeroQuickButtons(
                                            controller: unitFocusNode.hasFocus
                                                ? unitController
                                                : qtyController,
                                            formatThousands:
                                                unitFocusNode.hasFocus,
                                            onChanged: () => setState(() {}),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                IconButton(
                                  tooltip: '삭제',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  onPressed: () => _confirmAndDeleteItem(item),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            onTap: null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckedSummaryBar({
    required ThemeData theme,
    required int checkedCount,
  }) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final checkedTotal = _items.where((i) => i.isChecked).fold<double>(
      0,
      (sum, item) {
        final qty = item.quantity <= 0 ? 1 : item.quantity;
        return sum + (item.unitPrice * qty);
      },
    );

    return SafeArea(
      top: false,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '체크 항목',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '총액 ${CurrencyFormatter.format(checkedTotal)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$checkedCount개',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (!widget.openPrepOnStart && checkedCount > 0)
                      ? _addCheckedItemsToLedgerBulk
                      : null,
                  child: Text('체크 항목 거래 입력 ($checkedCount)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
