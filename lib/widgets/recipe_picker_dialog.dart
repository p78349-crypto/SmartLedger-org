import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../models/recipe.dart';
import '../services/consumable_inventory_service.dart';
import '../services/recipe_service.dart';
import '../utils/debounce_utils.dart';
import '../utils/korean_search_utils.dart';
import 'recipe_upsert_dialog.dart';

class RecipePickerDialog extends StatefulWidget {
  final bool onlyCookable;

  const RecipePickerDialog({super.key, this.onlyCookable = false});

  @override
  State<RecipePickerDialog> createState() => _RecipePickerDialogState();
}

class _RecipePickerDialogState extends State<RecipePickerDialog> {
  String _selectedCuisine = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 180),
  );

  final List<String> _cuisines = [
    'All',
    'Korean',
    'Western',
    'Japanese',
    'Chinese',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  List<ConsumableInventoryItem> _getMatchedItems(
    Recipe recipe,
    List<ConsumableInventoryItem> inventory,
  ) {
    final matched = <ConsumableInventoryItem>[];
    for (var ing in recipe.ingredients) {
      final matches = inventory.where(
        (it) => it.name.contains(ing.name) || ing.name.contains(it.name),
      );
      matched.addAll(matches);
    }
    // Remove duplicates
    final seen = <String>{};
    return matched.where((it) => seen.add(it.id)).toList();
  }

  bool _isCookable(Recipe recipe, List<ConsumableInventoryItem> inventory) {
    if (recipe.ingredients.isEmpty) return false;
    return recipe.ingredients.every(
      (ing) => inventory.any(
        (it) => it.name.contains(ing.name) || ing.name.contains(it.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allRecipes = RecipeService.instance.recipes.value;
    final inventory = ConsumableInventoryService.instance.items.value;

    final filteredRecipes = allRecipes.where((r) {
      final matchesCuisine =
          _selectedCuisine == 'All' || r.cuisine == _selectedCuisine;
      if (!matchesCuisine) return false;

      if (widget.onlyCookable && !_isCookable(r, inventory)) return false;

      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery;
      final matchesName = MultilingualSearchUtils.matches(r.name, query);
      final matchesIngredient = r.ingredients.any(
        (ing) => MultilingualSearchUtils.matches(ing.name, query),
      );
      return matchesName || matchesIngredient;
    }).toList();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.onlyCookable ? '가능 레시피' : '레시피 선택'),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '새 레시피 추가',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (c) => const RecipeUpsertDialog(),
              );
              setState(() {});
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '레시피 또는 식료품/생활용품 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(),
              ),
              onChanged: (v) {
                _searchDebouncer.run(() {
                  if (!mounted) return;
                  setState(() => _searchQuery = v);
                });
              },
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _cuisines.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _selectedCuisine == c,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCuisine = c);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredRecipes.isEmpty
                  ? Center(
                      child: Text(
                        widget.onlyCookable
                            ? '보관 중인 재료로 가능한 레시피가 없습니다.'
                            : '검색 결과가 없습니다.',
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredRecipes.length,
                      itemBuilder: (ctx, i) {
                        final r = filteredRecipes[i];
                        final matchedItems = _getMatchedItems(r, inventory);
                        final inStock = r.ingredients
                            .where(
                              (ing) => inventory.any(
                                (it) =>
                                    it.name.contains(ing.name) ||
                                    ing.name.contains(it.name),
                              ),
                            )
                            .length;
                        final total = r.ingredients.length;
                        final allInStock = inStock == total && total > 0;

                        return ListTile(
                          title: Text(
                            r.name,
                            style: TextStyle(
                              fontWeight: allInStock
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.ingredients.map((e) => e.name).join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '재고: $inStock / $total',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: allInStock
                                          ? Colors.green
                                          : (inStock > 0
                                                ? Colors.orange
                                                : Colors.grey),
                                    ),
                                  ),
                                  if (matchedItems.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _showMatchedItemsDetail(
                                        context,
                                        matchedItems,
                                      ),
                                      child: Text(
                                        '[상세보기]',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          onTap: () => Navigator.pop(ctx, r),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (c) =>
                                    RecipeUpsertDialog(existing: r),
                              );
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }

  void _showMatchedItemsDetail(
    BuildContext context,
    List<ConsumableInventoryItem> items,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('매칭된 재고 상세'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final it = items[i];
              final daysLeft = _daysLeft(it);
              return ListTile(
                title: Text(it.name),
                subtitle: Text(
                  '${it.category} | ${it.location} | ${it.currentStock}${it.unit}',
                ),
                trailing: Text(
                  daysLeft == null ? '기한 없음' : '$daysLeft일 남음',
                  style: TextStyle(
                    fontSize: 11,
                    color: daysLeft != null && daysLeft <= 2
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  int? _daysLeft(ConsumableInventoryItem item) {
    final expiryDate = item.expiryDate;
    if (expiryDate == null) return null;
    return expiryDate.difference(DateTime.now()).inDays;
  }
}
