import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../models/shopping_cart_item.dart';
import '../navigation/app_routes.dart';
import '../services/consumable_inventory_service.dart';
import '../services/user_pref_service.dart';
import '../utils/ingredient_parsing_utils.dart';
import '../utils/nutrition_food_knowledge.dart';
import '../utils/shopping_prep_utils.dart';

/// 식재료 검색 결과 화면
/// 검색어에 정확하게 매칭되는 식재료를 찾고,
/// 그 식재료와 함께 요리하면 좋은 모든 재료를 리스트로 표시
class IngredientSearchListScreen extends StatefulWidget {
  const IngredientSearchListScreen({
    super.key,
    this.searchQuery = '',
    this.customIngredients,
    this.dessertIngredients,
    this.onSelect,
  });

  final String searchQuery;
  final List<String>? customIngredients;
  final List<String>? dessertIngredients;
  final ValueChanged<String>? onSelect;

  @override
  State<IngredientSearchListScreen> createState() =>
      _IngredientSearchListScreenState();
}

class _IngredientSearchListScreenState
    extends State<IngredientSearchListScreen> {
  FoodKnowledgeEntry? _mainIngredient;
  List<PairingIngredient> _cookingList = [];
  List<PairingIngredient> _dessertList = [];
  bool _isSelectionMode = false; // 선택 모드 활성화 여부
  final Set<String> _selectedNames = {}; // 선택된 식재료 이름

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

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

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNames.clear();
      }
    });
  }

  void _selectAll() {
    setState(() {
      final totalItems = _cookingList.length + _dessertList.length;
      if (_selectedNames.length == totalItems) {
        // 이미 모두 선택된 경우 해제
        _selectedNames.clear();
      } else {
        // 모두 선택
        _selectedNames.clear();
        for (final item in _cookingList) {
          _selectedNames.add(item.name);
        }
        for (final item in _dessertList) {
          _selectedNames.add(item.name);
        }
      }
    });
  }

  void _toggleItemSelection(String name) {
    setState(() {
      if (_selectedNames.contains(name)) {
        _selectedNames.remove(name);
      } else {
        _selectedNames.add(name);
      }
    });
  }

  Future<void> _addSingleToCart(String itemName) async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('계정이 선택되지 않았습니다.')));
      }
      return;
    }

    final currentItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'shop_${now.microsecondsSinceEpoch}',
      name: itemName,
      createdAt: now,
      updatedAt: now,
    );

    final merged = ShoppingPrepUtils.mergeByName(
      existing: currentItems,
      incoming: [newItem],
    );

    await UserPrefService.setShoppingCartItems(
      accountName: accountName,
      items: merged.merged,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$itemName을(를) 쇼핑준비에 추가했습니다.'),
          action: SnackBarAction(
            label: '쇼핑준비 이동',
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.shoppingPrep,
                arguments: ShoppingCartArgs(accountName: accountName),
              );
            },
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendToShoppingPrep() async {
    if (_selectedNames.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선택된 식재료가 없습니다.')));
      return;
    }

    final selectedItems = _selectedNames.toList();

    if (widget.onSelect != null) {
      // 쇼핑준비로 보내기 (각 항목을 callbacks으로 전송)
      for (final item in selectedItems) {
        widget.onSelect?.call(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedItems.length}개 식재료를 쇼핑준비에 추가했습니다.'),
          ),
        );
        Navigator.pop(context);
      }
      return;
    } else {
      // Default behavior: add directly to shopping prep/cart.
      final accountName = await UserPrefService.getLastAccountName();
      if (accountName == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('계정이 선택되지 않았습니다.')));
        }
        return;
      }

      final currentItems = await UserPrefService.getShoppingCartItems(
        accountName: accountName,
      );

      final now = DateTime.now();
      final incoming = <ShoppingCartItem>[];
      for (var i = 0; i < selectedItems.length; i++) {
        final name = selectedItems[i].trim();
        if (name.isEmpty) continue;
        incoming.add(
          ShoppingCartItem(
            id: 'shop_${now.microsecondsSinceEpoch}_$i',
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final merged = ShoppingPrepUtils.mergeByName(
        existing: currentItems,
        incoming: incoming,
      );

      await UserPrefService.setShoppingCartItems(
        accountName: accountName,
        items: merged.merged,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${merged.added}개 식재료를 쇼핑준비에 추가했습니다.'),
            action: SnackBarAction(
              label: '쇼핑준비 이동',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.shoppingPrep,
                  arguments: ShoppingCartArgs(accountName: accountName),
                );
              },
            ),
          ),
        );
        Navigator.pop(context);
      }

      return;
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
          (item) => item.name.contains(rawName) || rawName.contains(item.name),
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
      final inventoryItem = inventoryItems.firstWhere((it) => it.id == itemId);

      String bestRequiredAmount = '-';
      String displayName = inventoryItem.name; // 기본값: 재고명

      // 가장 정보량이 많은(긴) 수량 정보 찾기
      for (final raw in rawNames) {
        // 이미 파싱된 이름과 수량을 확인
        // 예: "닭고기(적은 것) 1마리" -> name="닭고기(적은 것)", amount="1마리"
        // 예: "가지 1개" -> name="가지", amount="1개"
        final (pName, pAmount) = IngredientParsingUtils.parseNameAndAmount(raw);

        // 유의미한 수량 정보가 있다면 업데이트 (더 긴 정보를 선호)
        if (pAmount != '(정보 없음)' &&
            pAmount.length > bestRequiredAmount.length) {
          bestRequiredAmount = pAmount;

          // 수량 정보가 있는 소스의 이름을 디스플레이 네임으로 사용할지 결정
          // 재고명("닭고기")보다 상세한 이름("닭고기(적은 것)")이라면 사용 고려
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
      final (pName, pAmount) = IngredientParsingUtils.parseNameAndAmount(name);
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
          final (_, pAmount) = IngredientParsingUtils.parseNameAndAmount(
            suggestion,
          );
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

  SliverList _buildSliverList(ThemeData theme, List<PairingIngredient> list) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final pairing = list[index];
        final statusColor = _getStatusColor(theme, pairing.status);
        final statusIcon = _getStatusIcon(pairing.status);
        final isSelected = _selectedNames.contains(pairing.name);

        return GestureDetector(
          onTap: _isSelectionMode
              ? () => _toggleItemSelection(pairing.name)
              : null,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: isSelected
                ? statusColor.withValues(alpha: 0.15)
                : statusColor.withValues(alpha: 0.08),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: _isSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleItemSelection(pairing.name),
                    )
                  : null,
              title: Text(
                pairing.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      pairing.reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pairing.requiredText} | ${pairing.inventoryText}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pairing.expiryText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: !_isSelectionMode
                  ? IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        if (widget.onSelect != null) {
                          widget.onSelect?.call(pairing.name);
                          Navigator.pop(context, pairing.name);
                        } else {
                          _addSingleToCart(pairing.name);
                        }
                      },
                    )
                  : null,
              onTap: !_isSelectionMode
                  ? () {
                      if (widget.onSelect != null) {
                        widget.onSelect?.call(pairing.name);
                        Navigator.pop(context, pairing.name);
                      } else {
                        _addSingleToCart(pairing.name);
                      }
                    }
                  : null,
            ),
          ),
        );
      }, childCount: list.length),
    );
  }

  /// 재고 상태에 따른 색상 반환
  Color _getStatusColor(ThemeData theme, InventoryStatus status) {
    switch (status) {
      case InventoryStatus.sufficient:
        return Colors.green; // 🟢
      case InventoryStatus.lowStock:
        return Colors.orange; // 🟡
      case InventoryStatus.noStock:
        return Colors.red; // 🔴
    }
  }

  /// 재고 상태에 따른 아이콘 반환
  IconData _getStatusIcon(InventoryStatus status) {
    switch (status) {
      case InventoryStatus.sufficient:
        return Icons.check_circle;
      case InventoryStatus.lowStock:
        return Icons.warning;
      case InventoryStatus.noStock:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustomMode = widget.customIngredients != null;

    // 주 식재료를 찾지 못한 경우 (검색 모드일 때만 체크)
    if (!isCustomMode && _mainIngredient == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '검색 결과',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '"${widget.searchQuery}" 데이터 없음',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 목록이 비어있는 경우
    if (_cookingList.isEmpty && _dessertList.isEmpty) {
      final title = isCustomMode ? '식재료 목록' : _mainIngredient!.primaryName;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isCustomMode
                    ? '표시할 식재료가 없습니다.'
                    : '$title 요리에 필요한\n재료 정보가 아직 없습니다.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final mainTitle = isCustomMode
        ? '재고 확인 및 선택'
        : '${_mainIngredient!.primaryName} 요리';
    final totalCount = _cookingList.length + _dessertList.length;
    final subTitle = isCustomMode
        ? '식재료 $totalCount개'
        : '필요한 재료 ($totalCount개)';

    // 페어링 재료 리스트 표시
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mainTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          // 전체 선택/해제 버튼 (선택 모드일 때만 표시하거나 항상 표시)
          if (_isSelectionMode)
            TextButton(
              onPressed: _selectAll,
              child: Text(_selectedNames.length == totalCount ? '해제' : '전체'),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 0. 파싱 로직 안내 (간단한 헤더)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '상품명과 수량이 자동으로 분리되어 표시됩니다.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 1. 요리 재료 섹션
          if (_cookingList.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '🍳 요리 식재료',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            _buildSliverList(theme, _cookingList),
          ],

          // 2. 후식 섹션
          if (_dessertList.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🍰 후식 메뉴 추천',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildSliverList(theme, _dessertList),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            // 왼쪽: 선택 모드 토글 버튼
            FloatingActionButton.small(
              heroTag: 'selection_mode',
              onPressed: _toggleSelectionMode,
              backgroundColor: _isSelectionMode
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: _isSelectionMode
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              child: Icon(
                _isSelectionMode
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
              ),
            ),
            const SizedBox(width: 12),
            // 오른쪽: 쇼핑준비 보내기 버튼
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sendToShoppingPrep,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: Text(
                  _selectedNames.isEmpty
                      ? '쇼핑준비 보내기'
                      : '${_selectedNames.length}개 보내기',
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
