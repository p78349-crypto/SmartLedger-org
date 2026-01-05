import 'package:flutter/material.dart';
import 'package:smart_ledger/models/food_expiry_item.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/food_expiry_service.dart';
import 'package:smart_ledger/utils/nutrition_food_knowledge.dart';

/// 식재료 검색 결과 화면
/// 검색어에 정확하게 매칭되는 식재료를 찾고,
/// 그 식재료와 함께 요리하면 좋은 모든 재료를 리스트로 표시
class IngredientSearchListScreen extends StatefulWidget {
  const IngredientSearchListScreen({
    super.key,
    required this.searchQuery,
    this.onSelect,
  });

  final String searchQuery;
  final ValueChanged<String>? onSelect;

  @override
  State<IngredientSearchListScreen> createState() =>
      _IngredientSearchListScreenState();
}

class _IngredientSearchListScreenState
    extends State<IngredientSearchListScreen> {
  late FoodKnowledgeEntry? _mainIngredient;
  late List<PairingIngredient> _pairingList;
  bool _isSelectionMode = false; // 선택 모드 활성화 여부
  final Set<int> _selectedIndices = {}; // 선택된 인덱스들

  @override
  void initState() {
    super.initState();
    // 검색어와 정확하게 매칭되는 주 식재료 찾기
    _mainIngredient = NutritionFoodKnowledge.lookup(widget.searchQuery);
    
    // 주 식재료의 페어링 정보 추출
    _pairingList = _getPairingIngredients(_mainIngredient);
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIndices.clear();
      }
    });
  }

  void _toggleItemSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _sendToShoppingPrep() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택된 식재료가 없습니다.')),
      );
      return;
    }

    final selectedItems = _selectedIndices
        .map((i) => _pairingList[i].name)
        .toList();

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
  }

  List<PairingIngredient> _getPairingIngredients(FoodKnowledgeEntry? entry) {
    if (entry == null) return [];
    
    // 현재 재고 목록 가져오기
    final inventoryItems = FoodExpiryService.instance.items.value;
    
    // pairings에서 ingredient만 추출하고 중복 제거
    final ingredients = <String>{};
    for (final pairing in entry.pairings) {
      ingredients.add(pairing.ingredient);
    }
    
    return ingredients
        .map((ing) {
          // 현재 재고에서 같은 식재료 찾기
          FoodExpiryItem? matchingItem;
          try {
            matchingItem = inventoryItems.firstWhere(
              (item) => item.name.contains(ing) || ing.contains(item.name),
            );
          } catch (e) {
            matchingItem = null;
          }

          // 레시피에서 해당 식재료의 필요량 찾기
          String requiredAmount = '';
          for (final suggestion in entry.quantitySuggestions) {
            if (suggestion.contains(ing)) {
              requiredAmount = suggestion;
              break;
            }
          }
          // 필요량을 찾지 못한 경우 기본값
          if (requiredAmount.isEmpty) {
            requiredAmount = '(정보 없음)';
          }

          return PairingIngredient(
            name: ing,
            reason: entry.pairings
                .firstWhere((p) => p.ingredient == ing)
                .why,
            inventory: matchingItem,
            requiredAmount: requiredAmount,
          );
        })
        .toList();
  }

  /// 후식/디저트 메뉴 데이터 반환
  List<DessertItem> _getDessertMenus() {
    return [
      DessertItem(
        name: '카카오 분말(100% 무가당)',
        description: '건강한 초콜렛 음료 후식',
      ),
      DessertItem(
        name: '아몬드 분말(100% 무가당)',
        description: '건강한 견과류 요구르트 후식',
      ),
      DessertItem(
        name: '플레인 요구르트',
        description: '가볍고 부드러운 유산균 후식',
      ),
      DessertItem(
        name: '베리류(블루베리/딸기)',
        description: '상큼한 베리 후식',
      ),
    ];
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

    // 주 식재료를 찾지 못한 경우
    if (_mainIngredient == null) {
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

    // 페어링 재료가 없는 경우
    if (_pairingList.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _mainIngredient!.primaryName,
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
                '${_mainIngredient!.primaryName} 요리에 필요한\n재료 정보가 아직 없습니다.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 페어링 재료 리스트 표시
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: '이전',
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_mainIngredient!.primaryName} 요리',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '필요한 재료 (${_pairingList.length}개)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '다음',
              icon: Icon(
                Icons.arrow_forward,
                color: theme.colorScheme.primary,
              ),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.foodInventoryCheck,
                );
              },
            ),
          ],
        ),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        itemCount: _pairingList.length + 1 + _getDessertMenus().length + 1,
        itemBuilder: (context, index) {
          // 페어링 재료 섹션
          if (index < _pairingList.length) {
            final pairing = _pairingList[index];
            final statusColor = _getStatusColor(theme, pairing.status);
            final statusIcon = _getStatusIcon(pairing.status);
            final isSelected = _selectedIndices.contains(index);

            return GestureDetector(
              onTap:
                  _isSelectionMode
                      ? () => _toggleItemSelection(index)
                      : null,
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
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
                          onChanged: (_) => _toggleItemSelection(index),
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
                      // 필요량 / 현재고 / 구입량
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
                      ? Icon(
                          Icons.add_circle_outline,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                  onTap: !_isSelectionMode
                      ? () {
                          widget.onSelect?.call(pairing.name);
                          Navigator.pop(context, pairing.name);
                        }
                      : null,
                ),
              ),
            );
          }

          // 섹션 구분선
          if (index == _pairingList.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      '🍰 후식 메뉴 추천',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // 후식 메뉴 섹션
          final desserts = _getDessertMenus();
          final dessertIndex = index - _pairingList.length - 1;
          if (dessertIndex < desserts.length) {
            final dessert = desserts[dessertIndex];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: theme.colorScheme.surfaceContainerLow,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: Icon(
                  Icons.cake_outlined,
                  color: theme.colorScheme.secondary,
                ),
                title: Text(
                  dessert.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dessert.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing: Icon(
                  Icons.add_circle_outline,
                  color: theme.colorScheme.secondary,
                ),
                onTap: () {
                  widget.onSelect?.call(dessert.name);
                  Navigator.pop(context, dessert.name);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
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
                  _selectedIndices.isEmpty
                      ? '쇼핑준비 보내기'
                      : '${_selectedIndices.length}개 보내기',
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
  final FoodExpiryItem? inventory; // 현재 재고 정보
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
    if (inventory!.quantity <= 0.5) {
      return InventoryStatus.lowStock; // 재고 부족
    }
    return InventoryStatus.sufficient; // 충분
  }

  /// 재고 표시 텍스트
  String get inventoryText {
    if (inventory == null) {
      return '재고 없음';
    }
    final qty = inventory!.quantity;
    final unit = inventory!.unit;
    return '현재고: $qty $unit';
  }

  /// 유통기한 표시 텍스트
  String get expiryText {
    if (inventory == null) {
      return '';
    }
    final expiry = inventory!.expiryDate;
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

/// 후식/디저트 메뉴
class DessertItem {
  final String name;
  final String description;

  DessertItem({
    required this.name,
    required this.description,
  });
}
