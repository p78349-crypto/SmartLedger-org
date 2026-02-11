// ignore_for_file: invalid_use_of_protected_member

part of 'ingredient_search_list_screen.dart';

/// 데이터 처리 관련 메서드
extension IngredientSearchData on _IngredientSearchListScreenState {
  void _initializeData() {
    if (widget.customIngredients != null &&
        widget.customIngredients!.isNotEmpty) {
      // 1. 커스텀 리스트 모드
      _mainIngredient = null;
      _cookingList = _buildFromCustomList(widget.customIngredients!);
    } else if (widget.searchQuery.isNotEmpty) {
      // 2. 검색어 기반 모드
      _mainIngredient = NutritionFoodKnowledge.lookup(widget.searchQuery);
      _cookingList = _getPairingIngredients(_mainIngredient);
    } else {
      // 3. Fallback
      _mainIngredient = null;
      _cookingList = [];
    }

    if (widget.dessertIngredients != null &&
        widget.dessertIngredients!.isNotEmpty) {
      _dessertList = _buildFromCustomList(widget.dessertIngredients!);
    } else {
      _dessertList = [];
    }
  }

  List<PairingIngredient> _buildFromCustomList(List<String> names) {
    if (names.isEmpty) return [];

    // 1. 입력된 이름 정제 (중복 제거)
    final uniqueNames = names
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    // 2. 현재 재고 목록 가져오기
    final inventoryItems = ConsumableInventoryService.instance.items.value;

    // 3. 매칭 로직 및 그룹화
    // (InventoryID -> List<String>) : 재고와 매칭된 이름들
    final Map<String, List<String>> matchedGroups = {};
    // (String) : 매칭되지 않은 이름들
    final List<String> unmatchedNames = [];

    // 매칭 헬퍼 함수
    ConsumableInventoryItem? findMatch(String rawName) {
      try {
        return inventoryItems.firstWhere(
          (item) =>
              item.name.contains(rawName) || rawName.contains(item.name),
        );
      } catch (_) {
        return null; // 매칭 실패
      }
    }

    for (final name in uniqueNames) {
      final match = findMatch(name);
      if (match != null) {
        matchedGroups.putIfAbsent(match.id, () => []).add(name);
      } else {
        unmatchedNames.add(name);
      }
    }

    final results = <PairingIngredient>[];

    // 4. 매칭된 그룹 처리 (합치기)
    for (final entry in matchedGroups.entries) {
      final itemId = entry.key;
      final rawNames = entry.value; // 예: ["양파", "양파 1개"]

      // 재고 아이템 찾기 (ID로 확실하게)
      final inventoryItem =
          inventoryItems.firstWhere((it) => it.id == itemId);

      String bestRequiredAmount = '-';
      String displayName = inventoryItem.name; // 기본값: 재고명

      // 가장 정보량이 많은(긴) 수량 정보 찾기
      for (final raw in rawNames) {
        final (pName, pAmount) =
            IngredientParsingUtils.parseNameAndAmount(raw);

        // 유의미한 수량 정보가 있다면 업데이트 (더 긴 정보를 선호)
        if (pAmount != '(정보 없음)' &&
            pAmount.length > bestRequiredAmount.length) {
          bestRequiredAmount = pAmount;

          if (pName.contains(inventoryItem.name) &&
              pName.length > displayName.length) {
            displayName = pName;
          }
        }
      }

      results.add(
        PairingIngredient(
          name: displayName,
          reason: '검색/리포트 결과',
          inventory: inventoryItem,
          requiredAmount: bestRequiredAmount == '-'
              ? '(정보 없음)'
              : bestRequiredAmount,
        ),
      );
    }

    // 5. 매칭되지 않은 항목 처리
    for (final name in unmatchedNames) {
      final (pName, pAmount) =
          IngredientParsingUtils.parseNameAndAmount(name);
      results.add(
        PairingIngredient(
          name: pName,
          reason: '검색/리포트 결과',
          requiredAmount: pAmount,
        ),
      );
    }

    // 이름순 정렬
    results.sort((a, b) => a.name.compareTo(b.name));

    return results;
  }

  List<PairingIngredient> _getPairingIngredients(FoodKnowledgeEntry? entry) {
    if (entry == null) return [];

    // 현재 재고 목록 가져오기
    final inventoryItems = ConsumableInventoryService.instance.items.value;

    // pairings에서 ingredient만 추출하고 중복 제거
    final ingredients = <String>{};
    for (final pairing in entry.pairings) {
      ingredients.add(pairing.ingredient);
    }

    return ingredients.map((ing) {
      // 현재 재고에서 같은 식재료 찾기
      ConsumableInventoryItem? matchingItem;
      try {
        matchingItem = inventoryItems.firstWhere(
          (item) => item.name.contains(ing) || ing.contains(item.name),
        );
      } catch (e) {
        matchingItem = null;
      }

      // 레시피에서 해당 식재료의 필요량 찾기
      String bestRequiredAmount = '(정보 없음)';
      for (final suggestion in entry.quantitySuggestions) {
        if (suggestion.contains(ing)) {
          final (_, pAmount) =
              IngredientParsingUtils.parseNameAndAmount(suggestion);
          if (pAmount != '(정보 없음)') {
            bestRequiredAmount = pAmount;
            break;
          }
        }
      }

      return PairingIngredient(
        name: ing,
        reason: entry.pairings.firstWhere((p) => p.ingredient == ing).why,
        inventory: matchingItem,
        requiredAmount: bestRequiredAmount,
      );
    }).toList();
  }
}

/// 페어링 식재료 정보
class PairingIngredient {
  final String name;
  final String reason;
  final ConsumableInventoryItem? inventory; // 현재 재고 정보
  final String requiredAmount; // 필요량 (e.g., "1~2개", "3~5쪽")

  PairingIngredient({
    required this.name,
    required this.reason,
    this.inventory,
    required this.requiredAmount,
  });

  /// 재고 상태 판단
  InventoryStatus get status {
    if (inventory == null) {
      return InventoryStatus.noStock; // 재고 없음
    }
    // 수량이 0.5 이하이면 부족
    if (inventory!.currentStock <= 0.5) {
      return InventoryStatus.lowStock; // 재고 부족
    }
    return InventoryStatus.sufficient; // 충분
  }

  /// 재고 표시 텍스트
  String get inventoryText {
    if (inventory == null) {
      return '재고 없음';
    }
    final qty = inventory!.currentStock;
    final unit = inventory!.unit;
    return '현재고: $qty $unit';
  }

  /// 유통기한 표시 텍스트
  String get expiryText {
    if (inventory == null) {
      return '';
    }
    final expiry = inventory!.expiryDate;
    if (expiry == null) {
      return '유통기한 없음';
    }
    final now = DateTime.now();
    final daysLeft = expiry.difference(now).inDays;
    if (daysLeft < 0) {
      return '🔴 유통기한 지남';
    } else if (daysLeft == 0) {
      return '⚠️ 오늘 만료';
    } else if (daysLeft <= 3) {
      return '⚠️ $daysLeft일 남음';
    } else {
      return '${expiry.year}-'
          '${expiry.month.toString().padLeft(2, '0')}-'
          '${expiry.day.toString().padLeft(2, '0')}';
    }
  }

  /// 필요량 표시 텍스트
  String get requiredText => '필요량: $requiredAmount';
}

enum InventoryStatus {
  sufficient, // 🟢 충분
  lowStock, // 🟡 부족
  noStock, // 🔴 없음
}
