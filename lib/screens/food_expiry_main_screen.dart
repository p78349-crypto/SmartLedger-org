import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/models/food_expiry_item.dart';
import 'package:smart_ledger/models/recipe.dart';
import 'package:smart_ledger/models/shopping_cart_history_entry.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/services/food_expiry_notification_service.dart';
import 'package:smart_ledger/services/food_expiry_prediction_engine.dart';
import 'package:smart_ledger/services/food_expiry_service.dart';
import 'package:smart_ledger/services/recipe_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/interaction_blockers.dart';
import 'package:smart_ledger/navigation/app_routes.dart';

/// 식품 유통기한 관리 전용 메인 네비게이션 화면
class FoodExpiryMainScreen extends StatefulWidget {
  final List<String>? initialIngredients;
  final bool autoUsageMode;

  const FoodExpiryMainScreen({
    super.key,
    this.initialIngredients,
    this.autoUsageMode = false,
  });

  @override
  State<FoodExpiryMainScreen> createState() => _FoodExpiryMainScreenState();
}

class _RecipePickerDialog extends StatefulWidget {
  const _RecipePickerDialog();

  @override
  State<_RecipePickerDialog> createState() => _RecipePickerDialogState();
}

class _RecipePickerDialogState extends State<_RecipePickerDialog> {
  String _selectedCuisine = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    super.dispose();
  }

  List<FoodExpiryItem> _getMatchedItems(
    Recipe recipe,
    List<FoodExpiryItem> inventory,
  ) {
    final matched = <FoodExpiryItem>[];
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allRecipes = RecipeService.instance.recipes.value;
    final inventory = FoodExpiryService.instance.items.value;

    final filteredRecipes = allRecipes.where((r) {
      final matchesCuisine =
          _selectedCuisine == 'All' || r.cuisine == _selectedCuisine;
      if (!matchesCuisine) return false;

      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final matchesName = r.name.toLowerCase().contains(query);
      final matchesIngredient = r.ingredients.any(
        (ing) => ing.name.toLowerCase().contains(query),
      );
      return matchesName || matchesIngredient;
    }).toList();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('레시피 선택'),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '새 레시피 추가',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (c) => const _RecipeUpsertDialog(),
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
                hintText: '레시피 또는 식재료 검색',
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
              onChanged: (v) => setState(() => _searchQuery = v),
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
                  ? const Center(child: Text('검색 결과가 없습니다.'))
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
                                    _RecipeUpsertDialog(existing: r),
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
    List<FoodExpiryItem> items,
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
              return ListTile(
                title: Text(it.name),
                subtitle: Text(
                  '${it.category} | ${it.location} | ${it.quantity}${it.unit}',
                ),
                trailing: Text(
                  '${it.daysLeft(DateTime.now())}일 남음',
                  style: TextStyle(
                    fontSize: 11,
                    color: it.daysLeft(DateTime.now()) <= 2
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
}

class _RecipeUpsertDialog extends StatefulWidget {
  final Recipe? existing;
  const _RecipeUpsertDialog({this.existing});

  @override
  State<_RecipeUpsertDialog> createState() => _RecipeUpsertDialogState();
}

class _RecipeUpsertDialogState extends State<_RecipeUpsertDialog> {
  late TextEditingController _nameController;
  final List<RecipeIngredient> _ingredients = [];
  String _cuisine = 'Korean';
  final List<String> _cuisines = [
    'Korean',
    'Western',
    'Japanese',
    'Chinese',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _cuisine = widget.existing?.cuisine ?? 'Korean';
    if (widget.existing != null) {
      _ingredients.addAll(widget.existing!.ingredients);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (ctx) => _IngredientUpsertDialog(
        onAdd: (ingredient) {
          setState(() {
            _ingredients.add(ingredient);
          });
        },
      ),
    );
  }

  Future<void> _importFromHistory() async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) return;

    final history = await UserPrefService.getShoppingCartHistory(
      accountName: accountName,
    );
    if (!mounted) return;

    final selected = await showModalBottomSheet<List<ShoppingCartHistoryEntry>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RecipeHistoryPicker(history: history),
    );

    if (selected != null) {
      setState(() {
        for (var item in selected) {
          _ingredients.add(
            RecipeIngredient(name: item.name, quantity: 1, unit: '개'),
          );
        }
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final recipe = Recipe(
      id: widget.existing?.id ?? 'r_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      cuisine: _cuisine,
      ingredients: _ingredients,
    );

    if (widget.existing == null) {
      await RecipeService.instance.addRecipe(recipe);
    } else {
      await RecipeService.instance.updateRecipe(recipe);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? '새 레시피 추가' : '레시피 수정',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '레시피 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _cuisines.contains(_cuisine) ? _cuisine : 'Other',
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
              items: _cuisines
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _cuisine = v);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('식재료 목록'),
                Row(
                  children: [
                    IconButton(
                      onPressed: _importFromHistory,
                      icon: const Icon(Icons.history),
                      tooltip: '쇼핑 기록에서 가져오기',
                    ),
                    IconButton(
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add),
                      tooltip: '식재료 직접 추가',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _ingredients.length,
                  itemBuilder: (context, index) {
                    final ing = _ingredients[index];
                    return ListTile(
                      title: Text(ing.name),
                      subtitle: Text('${ing.quantity} ${ing.unit}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _ingredients.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.existing != null)
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('레시피 삭제'),
                          content: Text(
                            "'${widget.existing!.name}' 레시피를 삭제하시겠습니까?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                '삭제',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await RecipeService.instance.deleteRecipe(
                          widget.existing!.id,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('삭제'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _save, child: const Text('저장')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientUpsertDialog extends StatefulWidget {
  final Function(RecipeIngredient) onAdd;
  const _IngredientUpsertDialog({required this.onAdd});

  @override
  State<_IngredientUpsertDialog> createState() =>
      _IngredientUpsertDialogState();
}

class _IngredientUpsertDialogState extends State<_IngredientUpsertDialog> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: '개');
  List<String> _suggestions = [];
  List<String> _allPossibleNames = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final inventory = FoodExpiryService.instance.items.value
        .map((e) => e.name)
        .toList();
    final accountName = await UserPrefService.getLastAccountName();
    List<String> history = [];
    if (accountName != null) {
      final h = await UserPrefService.getShoppingCartHistory(
        accountName: accountName,
      );
      history = h.map((e) => e.name).toList();
    }
    setState(() {
      _allPossibleNames = {...inventory, ...history}.toList();
    });
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _suggestions = _allPossibleNames
          .where((name) => name.toLowerCase().contains(q))
          .take(5)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('식재료 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '이름',
              hintText: '예: 아몬드 분말',
            ),
            autofocus: true,
            onChanged: _updateSuggestions,
          ),
          if (_suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (ctx, i) {
                  final name = _suggestions[i];
                  return ListTile(
                    title: Text(name),
                    dense: true,
                    onTap: () {
                      setState(() {
                        _nameController.text = name;
                        _suggestions = [];
                      });
                    },
                  );
                },
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  decoration: const InputDecoration(labelText: '수량'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: '단위'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final qty = double.tryParse(_qtyController.text) ?? 0;
            final unit = _unitController.text.trim();
            if (name.isNotEmpty && qty > 0) {
              widget.onAdd(
                RecipeIngredient(name: name, quantity: qty, unit: unit),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}

class _RecipeHistoryPicker extends StatefulWidget {
  final List<ShoppingCartHistoryEntry> history;
  const _RecipeHistoryPicker({required this.history});

  @override
  State<_RecipeHistoryPicker> createState() => _RecipeHistoryPickerState();
}

class _RecipeHistoryPickerState extends State<_RecipeHistoryPicker> {
  final Set<ShoppingCartHistoryEntry> _selected = {};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: const Text('Select from History'),
              automaticallyImplyLeading: false,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, _selected.toList()),
                  child: const Text('Done'),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.history.length,
                itemBuilder: (context, index) {
                  final item = widget.history[index];
                  final isSelected = _selected.contains(item);
                  return ListTile(
                    title: Text(item.name),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.circle_outlined),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selected.remove(item);
                        } else {
                          _selected.add(item);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FoodExpiryMainScreenState extends State<FoodExpiryMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    FoodExpiryService.instance.load();
    RecipeService.instance.load();
  }

  late final List<Widget> _screens = <Widget>[
    _FoodExpiryItemsScreen(
      onUpsert: _openUpsertDialog,
      initialIngredients: widget.initialIngredients,
      autoUsageMode: widget.autoUsageMode,
    ),
    const _FoodExpiryNotificationsScreen(),
    const _FoodExpiryPlaceholderScreen(title: '소비 기록'),
    const _FoodExpiryPlaceholderScreen(title: '통계'),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(IconCatalog.shoppingCart),
      label: '상품 관리',
    ),
    BottomNavigationBarItem(icon: Icon(IconCatalog.warningAmber), label: '알림'),
    BottomNavigationBarItem(icon: Icon(IconCatalog.history), label: '소비 기록'),
    BottomNavigationBarItem(icon: Icon(IconCatalog.barChart), label: '통계'),
    BottomNavigationBarItem(icon: Icon(IconCatalog.addCircle), label: '추가'),
  ];

  Future<void> _openUpsertDialog(
    BuildContext context, {
    FoodExpiryItem? existing,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => _FoodExpiryUpsertDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: InteractionBlockers.gateValue<int>((index) {
          final addIndex = _navItems.length - 1;
          if (index == addIndex) {
            _openUpsertDialog(context);
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        }),
        items: _navItems,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class _FoodExpiryUpsertDialog extends StatefulWidget {
  final FoodExpiryItem? existing;
  const _FoodExpiryUpsertDialog({this.existing});

  @override
  State<_FoodExpiryUpsertDialog> createState() =>
      _FoodExpiryUpsertDialogState();
}

class _FoodExpiryUpsertDialogState extends State<_FoodExpiryUpsertDialog> {
  late TextEditingController _nameController;
  late TextEditingController _memoController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _priceController;
  late TextEditingController _supplierController;
  late DateTime _purchaseDate;
  DateTime? _pickedExpiryDate;

  String _category = '기타';
  String _location = '냉장';
  bool _addToShoppingList = false;

  final List<String> _categories = [
    '채소',
    '과일',
    '육류',
    '수산물',
    '유제품',
    '냉동식품',
    '가공식품',
    '음료',
    '양념/소스',
    '기타',
  ];

  final List<String> _locations = ['냉장', '냉동', '실온', '팬트리'];

  // Adjustment fields for existing items
  final TextEditingController _addQtyController = TextEditingController();
  final TextEditingController _subQtyController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _memoFocus = FocusNode();

  // Import Queue State
  List<ShoppingCartHistoryEntry> _importQueue = [];
  int _importTotal = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _memoController = TextEditingController(text: widget.existing?.memo ?? '');
    _quantityController = TextEditingController(
      text: widget.existing?.quantity.toString() ?? '1',
    );
    _unitController = TextEditingController(text: widget.existing?.unit ?? '개');
    _priceController = TextEditingController(
      text: widget.existing?.price.toString() ?? '0',
    );
    _supplierController = TextEditingController(
      text: widget.existing?.supplier ?? '',
    );
    _purchaseDate = widget.existing?.purchaseDate ?? DateTime.now();
    _pickedExpiryDate = widget.existing?.expiryDate;
    _category = widget.existing?.category ?? '기타';
    _location = widget.existing?.location ?? '냉장';

    if (widget.existing != null) {
      _addQtyController.addListener(_updateTotal);
      _subQtyController.addListener(_updateTotal);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    _addQtyController.dispose();
    _subQtyController.dispose();
    _nameFocus.dispose();
    _memoFocus.dispose();
    super.dispose();
  }

  String _historySubtitle(ShoppingCartHistoryEntry item) {
    final timeLabel = DateFormat('HH:mm').format(item.at);
    return '${item.quantity}개 / $timeLabel';
  }

  String _expiryButtonLabel(DateTime? suggestedDate) {
    if (_pickedExpiryDate == null) {
      if (suggestedDate == null) return '날짜 선택';
      final predicted = DateFormat('yyyy-MM-dd').format(suggestedDate);
      return '예측: $predicted';
    }

    final manual = DateFormat('yyyy-MM-dd').format(_pickedExpiryDate!);
    return '수동: $manual';
  }

  void _updateTotal() {
    if (widget.existing == null) return;
    final double current = widget.existing!.quantity;
    final double add = double.tryParse(_addQtyController.text) ?? 0;
    final double sub = double.tryParse(_subQtyController.text) ?? 0;
    double result = current + add - sub;
    if (result < 0) result = 0;

    final String text = result == result.toInt()
        ? result.toInt().toString()
        : result.toString();

    // Avoid cursor jumps when editing directly by updating only when needed.
    // (We may later disable direct edit if this mode remains confusing.)
    if (_quantityController.text != text) {
      _quantityController.text = text;
    }
  }

  Future<void> _showHistoryPicker() async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) return;

    final history = await UserPrefService.getShoppingCartHistory(
      accountName: accountName,
    );

    if (!mounted) return;

    // Group by date
    final grouped = <String, List<ShoppingCartHistoryEntry>>{};
    for (final entry in history) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.at);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '쇼핑 기록에서 가져오기',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: sortedKeys.length,
                    itemBuilder: (ctx, i) {
                      final dateKey = sortedKeys[i];
                      final items = grouped[dateKey]!;
                      return ExpansionTile(
                        title: Text('$dateKey (${items.length}개)'),
                        children: [
                          ...items.map((item) {
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text(_historySubtitle(item)),
                              trailing: IconButton(
                                icon: const Icon(Icons.playlist_add),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _startImport(
                                    items,
                                    startIndex: items.indexOf(item),
                                  );
                                },
                              ),
                            );
                          }),
                          ListTile(
                            title: const Text(
                              '이 날짜의 모든 항목 가져오기',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            leading: const Icon(Icons.playlist_play),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _startImport(items);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startImport(
    List<ShoppingCartHistoryEntry> items, {
    int startIndex = 0,
  }) {
    if (items.isEmpty) return;
    setState(() {
      _importQueue = items.sublist(startIndex);
      _importTotal = _importQueue.length;
    });
    _loadNextFromQueue();
  }

  void _loadNextFromQueue() {
    if (_importQueue.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('모든 항목을 가져왔습니다.')));
      }
      return;
    }

    final item = _importQueue.removeAt(0);
    setState(() {
      _nameController.text = item.name;
      _purchaseDate = item.at;
      _pickedExpiryDate = null; // Reset expiry for new item
      _memoController.clear();
      _quantityController.text = item.quantity.toString();
      _unitController.text = '개'; // Default unit for imported items
    });
  }

  void _skipCurrentImport() {
    _loadNextFromQueue();
  }

  void _stopImport() {
    setState(() {
      _importQueue.clear();
      _importTotal = 0;
    });
  }

  FoodExpiryPrediction? _prediction() {
    return FoodExpiryPredictionEngine.predict(
      name: _nameController.text,
      memo: _memoController.text,
      purchaseDate: _purchaseDate,
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final p = _prediction();
    final effective = _pickedExpiryDate ?? p?.suggestedExpiryDate;
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final unit = _unitController.text.trim().isEmpty
        ? '개'
        : _unitController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final supplier = _supplierController.text.trim();

    if (name.isEmpty || effective == null) {
      return;
    }

    if (widget.existing == null) {
      await FoodExpiryService.instance.addItem(
        name: name,
        purchaseDate: _purchaseDate,
        expiryDate: effective,
        memo: _memoController.text,
        quantity: quantity,
        unit: unit,
        category: _category,
        location: _location,
        price: price,
        supplier: supplier,
      );
    } else {
      await FoodExpiryService.instance.updateItem(
        id: widget.existing!.id,
        name: name,
        purchaseDate: _purchaseDate,
        expiryDate: effective,
        memo: _memoController.text,
        quantity: quantity,
        unit: unit,
        category: _category,
        location: _location,
        price: price,
        supplier: supplier,
      );
    }

    // Handle "Add to shopping list" if checked
    if (_addToShoppingList) {
      final accountName = await UserPrefService.getLastAccountName();
      if (accountName != null) {
        final currentItems = await UserPrefService.getShoppingCartItems(
          accountName: accountName,
        );
        final now = DateTime.now();
        final newItem = ShoppingCartItem(
          id: 'sc_${now.microsecondsSinceEpoch}',
          name: name,
          quantity: quantity.toInt(),
          unitPrice: price,
          createdAt: now,
          updatedAt: now,
        );
        await UserPrefService.setShoppingCartItems(
          accountName: accountName,
          items: [newItem, ...currentItems],
        );
      }
    }

    if (_importQueue.isNotEmpty) {
      _loadNextFromQueue();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Widget _buildFieldLabel(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  InputDecoration _formInputDecoration({
    String? hintText,
    Widget? suffixIcon,
    EdgeInsets? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2),
      ),
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _prediction();

    final isImporting = _importQueue.isNotEmpty || _importTotal > 0;
    final remaining = _importQueue.length;
    final currentImportIndex = _importTotal - remaining;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      widget.existing == null ? '식재료 등록' : '식재료 정보 수정',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isImporting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Chip(
                    label: Text(
                      '가져오기 중 ${currentImportIndex + 1} / $_importTotal',
                    ),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),
                ),

              // Item Name
              _buildFieldLabel('품목명', theme),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      decoration: _formInputDecoration(
                        hintText: '품목명을 입력하세요',
                        suffixIcon: const Icon(Icons.edit_note, size: 20),
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: _showHistoryPicker,
                    icon: const Icon(IconCatalog.history),
                    tooltip: '쇼핑 기록 불러오기',
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

              // Category
              _buildFieldLabel('카테고리', theme),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _formInputDecoration(),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),

              // Quantity & Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('수량', theme),
                        TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _formInputDecoration(hintText: '0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('단위', theme),
                        TextField(
                          controller: _unitController,
                          decoration: _formInputDecoration(
                            hintText: '단위 (예: 개, g, kg)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Location
              _buildFieldLabel('보관 위치', theme),
              DropdownButtonFormField<String>(
                initialValue: _location,
                decoration: _formInputDecoration(),
                items: _locations.map((l) {
                  return DropdownMenuItem(value: l, child: Text(l));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _location = val);
                },
              ),

              // Expiration Date
              _buildFieldLabel('유통기한', theme),
              InkWell(
                onTap: () async {
                  final initial =
                      _pickedExpiryDate ??
                      p?.suggestedExpiryDate ??
                      DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) {
                    setState(() => _pickedExpiryDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _expiryButtonLabel(p?.suggestedExpiryDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, size: 18),
                    ],
                  ),
                ),
              ),

              // Price
              _buildFieldLabel('가격', theme),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _formInputDecoration(hintText: '0'),
              ),

              // Supplier
              _buildFieldLabel('구입처', theme),
              TextField(
                controller: _supplierController,
                decoration: _formInputDecoration(
                  hintText: '구입처를 입력하세요',
                  suffixIcon: const Icon(Icons.keyboard_arrow_down),
                ),
              ),

              const SizedBox(height: 16),
              // Add to shopping list checkbox
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _addToShoppingList,
                      onChanged: (val) =>
                          setState(() => _addToShoppingList = val ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '장바구니에 추가',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.existing == null ? '등록하기' : '수정하기',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              if (isImporting) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _skipCurrentImport,
                        child: const Text('Skip This Item'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: _stopImport,
                        child: const Text(
                          'Stop Import',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodExpiryPlaceholderScreen extends StatelessWidget {
  final String title;

  const _FoodExpiryPlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$title 화면은 준비 중입니다.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _FoodExpiryItemsScreen extends StatefulWidget {
  final Future<void> Function(BuildContext, {FoodExpiryItem? existing})?
  onUpsert;
  final List<String>? initialIngredients;
  final bool autoUsageMode;

  const _FoodExpiryItemsScreen({
    this.onUpsert,
    this.initialIngredients,
    this.autoUsageMode = false,
  });

  @override
  State<_FoodExpiryItemsScreen> createState() => _FoodExpiryItemsScreenState();
}

class _FoodExpiryItemsScreenState extends State<_FoodExpiryItemsScreen> {
  bool _isUsageMode = false;
  final Map<String, double> _usageMap = {};
  final Set<String> _activeUsageItems = {};

  @override
  void initState() {
    super.initState();
    if (widget.autoUsageMode) {
      _isUsageMode = true;
    }
  }

  Future<void> _addToCart(BuildContext context, FoodExpiryItem item) async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('계정 정보를 불러올 수 없습니다.')));
      }
      return;
    }

    final currentItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'shop_${now.microsecondsSinceEpoch}',
      name: item.name,
      createdAt: now,
      updatedAt: now,
    );

    final nextItems = [newItem, ...currentItems];
    await UserPrefService.setShoppingCartItems(
      accountName: accountName,
      items: nextItems,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name}을(를) 장바구니에 담았습니다.'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editQuantity(BuildContext context, FoodExpiryItem item) async {
    final controller = TextEditingController(
      text: item.quantity == item.quantity.toInt()
          ? item.quantity.toInt().toString()
          : item.quantity.toString(),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.name} 수량 변경'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            suffixText: item.unit,
            border: const OutlineInputBorder(),
            labelText: '수량 입력',
          ),
          onSubmitted: (val) {
            final parsed = double.tryParse(val);
            if (parsed != null && parsed >= 0) {
              Navigator.of(ctx).pop(parsed);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != null && result != item.quantity) {
      if (result == 0) {
        if (!context.mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('재고 소진'),
            content: Text('${item.name} 재고가 0이 되었습니다.\n목록에서 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('아니오 (0으로 유지)'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('삭제'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await FoodExpiryService.instance.deleteById(item.id);
          return;
        }
      }

      await FoodExpiryService.instance.updateItem(
        id: item.id,
        name: item.name,
        purchaseDate: item.purchaseDate,
        expiryDate: item.expiryDate,
        memo: item.memo,
        quantity: result,
        unit: item.unit,
      );
    }
  }

  Future<void> _adjustQuantity(
    BuildContext context,
    FoodExpiryItem item,
    double delta,
  ) async {
    final newQty = item.quantity + delta;
    if (newQty < 0) return; // Prevent negative

    if (newQty == 0) {
      // Ask to delete if 0
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('재고 소진'),
          content: Text('${item.name} 재고가 0이 되었습니다.\n목록에서 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('아니오 (0으로 유지)'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('삭제'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await FoodExpiryService.instance.deleteById(item.id);
        return;
      }
    }

    await FoodExpiryService.instance.updateItem(
      id: item.id,
      name: item.name,
      purchaseDate: item.purchaseDate,
      expiryDate: item.expiryDate,
      memo: item.memo,
      quantity: newQty,
      unit: item.unit,
      category: item.category,
      location: item.location,
      price: item.price,
      supplier: item.supplier,
    );
  }

  Future<void> _addMissingToCart(List<String> names) async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) return;

    final currentItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );

    final now = DateTime.now();
    final List<ShoppingCartItem> newItems = [];

    for (var name in names) {
      newItems.add(
        ShoppingCartItem(
          id: 'shop_${now.microsecondsSinceEpoch}_${newItems.length}',
          name: name,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await UserPrefService.setShoppingCartItems(
      accountName: accountName,
      items: [...newItems, ...currentItems],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newItems.length}개의 재료를 장바구니에 담았습니다.'),
          action: SnackBarAction(
            label: '장바구니 이동',
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.shoppingCart,
                arguments: ShoppingCartArgs(accountName: accountName),
              );
            },
          ),
        ),
      );
    }
  }

  void _showItemDetail(BuildContext context, FoodExpiryItem item) {
    final theme = Theme.of(context);
    final left = item.daysLeft(DateTime.now());
    final leftColor = left < 0
        ? theme.colorScheme.error
        : (left <= 2 ? theme.colorScheme.tertiary : theme.colorScheme.primary);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('카테고리', item.category, Icons.category_outlined, theme),
            _detailRow(
              '보관위치',
              item.location,
              Icons.location_on_outlined,
              theme,
            ),
            _detailRow(
              '수량',
              '${_formatQuantity(item)} ${item.unit}',
              Icons.inventory_2_outlined,
              theme,
            ),
            _detailRow(
              '가격',
              '${CurrencyFormatter.format(item.price)}원',
              Icons.payments_outlined,
              theme,
            ),
            _detailRow(
              '구매처',
              item.supplier.isEmpty ? '-' : item.supplier,
              Icons.storefront_outlined,
              theme,
            ),
            const Divider(),
            _detailRow(
              '구매일',
              DateFormat('yyyy-MM-dd').format(item.purchaseDate),
              Icons.calendar_today_outlined,
              theme,
            ),
            _detailRow(
              '유통기한',
              '${DateFormat('yyyy-MM-dd').format(item.expiryDate)} ($left일 남음)',
              Icons.event_available_outlined,
              theme,
              valueColor: leftColor,
            ),
            if (item.memo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '메모',
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item.memo, style: theme.textTheme.bodyMedium),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onUpsert?.call(context, existing: item);
            },
            child: const Text('수정'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleUsageMode() {
    setState(() {
      _isUsageMode = !_isUsageMode;
      _usageMap.clear();
      _activeUsageItems.clear();
    });
  }

  void _toggleItemUsage(String id) {
    setState(() {
      if (_activeUsageItems.contains(id)) {
        _activeUsageItems.remove(id);
        _usageMap.remove(id);
      } else {
        _activeUsageItems.add(id);
      }
    });
  }

  Future<void> _applyBulkUsage() async {
    if (_usageMap.isEmpty) return;

    int updatedCount = 0;
    final items = FoodExpiryService.instance.items.value;
    final List<String> itemsToRemove = [];

    for (var entry in _usageMap.entries) {
      if (entry.value <= 0) continue;

      final item = items.firstWhere(
        (i) => i.id == entry.key,
        orElse: () => items.first,
      );
      if (item.id != entry.key) continue;

      final newQty = (item.quantity - entry.value).clamp(0.0, double.infinity);

      if (newQty <= 0) {
        itemsToRemove.add(item.id);
      } else {
        await FoodExpiryService.instance.updateItem(
          id: item.id,
          name: item.name,
          purchaseDate: item.purchaseDate,
          expiryDate: item.expiryDate,
          memo: item.memo,
          quantity: newQty,
          unit: item.unit,
          category: item.category,
          location: item.location,
          price: item.price,
          supplier: item.supplier,
        );
      }
      updatedCount++;
    }

    if (itemsToRemove.isNotEmpty) {
      for (final id in itemsToRemove) {
        await FoodExpiryService.instance.deleteById(id);
      }
    }

    setState(() {
      _isUsageMode = false;
      _usageMap.clear();
      _activeUsageItems.clear();
    });

    if (mounted) {
      String msg = '$updatedCount개의 항목 사용량이 기록되었습니다.';
      if (itemsToRemove.isNotEmpty) {
        msg += '\n(${itemsToRemove.length}개 항목 소진되어 삭제됨)';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _showRecipePicker() async {
    final items = FoodExpiryService.instance.items.value;

    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (ctx) => const _RecipePickerDialog(),
    );

    if (selectedRecipe != null) {
      final List<String> missingIngredients = [];
      final List<String> matchedInfo = [];

      setState(() {
        _isUsageMode = true;
        _usageMap.clear();

        for (var ingredient in selectedRecipe.ingredients) {
          try {
            final item = items.firstWhere(
              (i) =>
                  i.name.contains(ingredient.name) ||
                  ingredient.name.contains(i.name),
            );
            _usageMap[item.id] = ingredient.quantity;
            matchedInfo.add('${item.name} (재고: ${_formatQuantity(item)})');
          } catch (e) {
            missingIngredients.add(ingredient.name);
          }
        }

        if (matchedInfo.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${selectedRecipe.name}: ${matchedInfo.length}개 항목 매칭됨\n'
                '${matchedInfo.take(3).join(", ")}'
                '${matchedInfo.length > 3 ? " 등" : ""}',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (missingIngredients.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('일치하는 재고 항목이 없습니다.')));
        }
      });

      if (missingIngredients.isNotEmpty && mounted) {
        _promptAddMissingToCart(missingIngredients);
      }
    }
  }

  Future<void> _promptAddMissingToCart(List<String> missingNames) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('부족한 식재료 안내'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('다음 재료는 현재 재고 정보가 없습니다.'),
            const Text('장바구니에 추가하여 구매를 준비할까요?'),
            const SizedBox(height: 16),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: missingNames
                    .map(
                      (name) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $name (정보없음)',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('장바구니 추가'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final accountName = await UserPrefService.getLastAccountName();
      if (accountName == null) return;

      final currentItems = await UserPrefService.getShoppingCartItems(
        accountName: accountName,
      );

      final now = DateTime.now();
      final List<ShoppingCartItem> newItems = [];

      for (var name in missingNames) {
        newItems.add(
          ShoppingCartItem(
            id: 'shop_${now.microsecondsSinceEpoch}_${newItems.length}',
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await UserPrefService.setShoppingCartItems(
        accountName: accountName,
        items: [...newItems, ...currentItems],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newItems.length}개의 재료를 장바구니에 담았습니다.'),
            action: SnackBarAction(
              label: '장바구니 이동',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.shoppingCart,
                  arguments: ShoppingCartArgs(accountName: accountName),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              child: Text(
                '유통기한 관리',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: '다음',
              icon: Icon(
                Icons.arrow_forward,
                color: theme.colorScheme.primary,
              ),
              onPressed: () async {
                final accountName = await UserPrefService.getLastAccountName();
                if (!context.mounted) return;
                if (accountName != null) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.shoppingCart,
                    arguments: ShoppingCartArgs(accountName: accountName),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          if (_isUsageMode)
            IconButton(
              onPressed: _showRecipePicker,
              icon: const Icon(Icons.menu_book),
              tooltip: '요리 불러오기',
            ),
          IconButton(
            onPressed: _toggleUsageMode,
            icon: Icon(_isUsageMode ? Icons.close : Icons.soup_kitchen),
            tooltip: _isUsageMode ? '사용량 입력 종료' : '요리/사용 모드 (일괄 입력)',
          ),
          if (!_isUsageMode)
            IconButton(
              onPressed: FoodExpiryService.instance.load,
              icon: const Icon(IconCatalog.refresh),
              tooltip: '새로고침',
            ),
        ],
      ),
      floatingActionButton:
          (_isUsageMode || _activeUsageItems.isNotEmpty) && _usageMap.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _applyBulkUsage,
              icon: const Icon(Icons.check),
              label: Text('${_usageMap.length}개 적용'),
            )
          : null,
      body: ValueListenableBuilder<List<FoodExpiryItem>>(
        valueListenable: FoodExpiryService.instance.items,
        builder: (context, items, child) {
          final missingIngredients = <String>[];
          if (widget.initialIngredients != null) {
            for (final ing in widget.initialIngredients!) {
              final hasMatch = items.any(
                (it) =>
                    it.name.contains(ing) ||
                    ing.contains(it.name) ||
                    it.category.contains(ing),
              );
              if (!hasMatch) {
                missingIngredients.add(ing);
              }
            }
          }

          if (items.isEmpty && missingIngredients.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '등록된 유통기한 항목이 없습니다.\n하단 버튼으로 추가하세요.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              if (missingIngredients.isNotEmpty)
                Container(
                  width: double.maxFinite,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '부족한 식재료 (${missingIngredients.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () =>
                                _addMissingToCart(missingIngredients),
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 16,
                            ),
                            label: const Text('장바구니 담기'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: missingIngredients
                            .map(
                              (ing) => Chip(
                                label: Text(ing),
                                visualDensity: VisualDensity.compact,
                                labelStyle: const TextStyle(fontSize: 12),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final it = items[i];
                    final left = it.daysLeft(DateTime.now());
                    final leftText = left < 0
                        ? '지남 ${-left}일'
                        : '남음 $left'
                              '일';
                    final color = left < 0
                        ? theme.colorScheme.error
                        : (left <= 2
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.primary);

                    final isMatched =
                        widget.initialIngredients?.any(
                          (ing) =>
                              it.name.contains(ing) ||
                              ing.contains(it.name) ||
                              it.category.contains(ing),
                        ) ??
                        false;

                    final isItemUsageActive =
                        _isUsageMode || _activeUsageItems.contains(it.id);

                    return Container(
                      color: isMatched
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.2,
                            )
                          : null,
                      child: ListTile(
                        onTap: () => _showItemDetail(context, it),
                        title: Row(
                          children: [
                            if (it.category.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    it.category,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .onSecondaryContainer,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      it.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isItemUsageActive) ...[
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    _adjustQuantity(context, it, -1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: InkWell(
                                  onTap: () => _editQuantity(context, it),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      _formatQuantity(it),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationStyle:
                                                TextDecorationStyle.dotted,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    _adjustQuantity(context, it, 1),
                              ),
                            ] else ...[
                              // Usage Mode: Improved UI
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '잔량: ${_formatQuantity(it)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _UsageInput(
                                    initialValue: _usageMap[it.id],
                                    max: it.quantity,
                                    unit: it.unit,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == null || val <= 0) {
                                          _usageMap.remove(it.id);
                                        } else {
                                          _usageMap[it.id] = val;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          _itemSubtitleText(it),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _isUsageMode
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isItemUsageActive)
                                    Text(
                                      leftText,
                                      style: TextStyle(color: color),
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      isItemUsageActive
                                          ? Icons.close
                                          : Icons.soup_kitchen,
                                      size: 20,
                                      color: isItemUsageActive
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.primary,
                                    ),
                                    tooltip: isItemUsageActive
                                        ? '입력 취소'
                                        : '사용량 입력',
                                    onPressed: () => _toggleItemUsage(it.id),
                                  ),
                                  if (!isItemUsageActive) ...[
                                    IconButton(
                                      icon: const Icon(
                                        IconCatalog.shoppingCart,
                                      ),
                                      tooltip: '장바구니 담기',
                                      onPressed: () => _addToCart(context, it),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        IconCatalog.deleteOutline,
                                      ),
                                      tooltip: '삭제',
                                      onPressed: () => FoodExpiryService
                                          .instance
                                          .deleteById(it.id),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatQuantity(FoodExpiryItem item) {
    final isInt = item.quantity == item.quantity.toInt();
    final value = isInt ? item.quantity.toInt().toString() : '${item.quantity}';
    return '$value${item.unit}';
  }

  String _itemSubtitleText(FoodExpiryItem item) {
    final purchase = DateFormat('yyyy-MM-dd').format(item.purchaseDate);
    final expiry = DateFormat('yyyy-MM-dd').format(item.expiryDate);

    String base = '구매: $purchase / 기한: $expiry';
    if (item.location.isNotEmpty) {
      base += '\n위치: ${item.location}';
    }
    if (item.price > 0) {
      base += ' / 가격: ${NumberFormat('#,###').format(item.price)}원';
    }

    final memo = item.memo.trim();
    if (memo.isEmpty) return base;
    return '$base\n메모: $memo';
  }
}

class _UsageInput extends StatefulWidget {
  final double? initialValue;
  final double max;
  final String unit;
  final ValueChanged<double?> onChanged;

  const _UsageInput({
    this.initialValue,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<_UsageInput> createState() => _UsageInputState();
}

class _UsageInputState extends State<_UsageInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(_UsageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      final nextText = widget.initialValue?.toString() ?? '';
      if (_controller.text != nextText) {
        _controller.text = nextText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(double? val) {
    widget.onChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            final current = double.tryParse(_controller.text) ?? 0.0;
            if (current > 0) {
              final next = (current - 0.1).clamp(0.0, widget.max);
              final rounded = double.parse(next.toStringAsFixed(1));
              _update(rounded == 0 ? null : rounded);
            }
          },
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 60,
          height: 32,
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: '0.0',
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (val) {
              final v = double.tryParse(val);
              _update(v);
            },
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            final current = double.tryParse(_controller.text) ?? 0.0;
            final next = (current + 0.1).clamp(0.0, widget.max);
            final rounded = double.parse(next.toStringAsFixed(1));
            _update(rounded);
          },
        ),
        const SizedBox(width: 8),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
          ),
          onPressed: () => _update(widget.max),
          child: Text(
            '전부',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodExpiryNotificationsScreen extends StatefulWidget {
  const _FoodExpiryNotificationsScreen();

  @override
  State<_FoodExpiryNotificationsScreen> createState() =>
      _FoodExpiryNotificationsScreenState();
}

class _FoodExpiryNotificationsScreenState
    extends State<_FoodExpiryNotificationsScreen> {
  FoodExpiryNotificationSettings? _settings;
  int? _lastScheduledCount;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await FoodExpiryNotificationService.instance.loadSettings();
    if (!mounted) return;
    setState(() {
      _settings = s;
    });
    await _reschedule();
  }

  Future<void> _update(FoodExpiryNotificationSettings next) async {
    setState(() {
      _settings = next;
      _saving = true;
    });
    await FoodExpiryNotificationService.instance.saveSettings(next);
    await _reschedule();
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
  }

  Future<void> _reschedule() async {
    final items = FoodExpiryService.instance.items.value;
    final count = await FoodExpiryNotificationService.instance
        .rescheduleFromPrefs(items);
    if (!mounted) return;
    setState(() {
      _lastScheduledCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _settings;

    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('유통기한 알림'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _load,
            icon: const Icon(IconCatalog.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('알림 사용'),
            subtitle: const Text('유통기한 임박 시 로컬 알림을 표시합니다.'),
            value: s.enabled,
            onChanged: _saving ? null : (v) => _update(s.copyWith(enabled: v)),
          ),
          ListTile(
            enabled: s.enabled && !_saving,
            title: const Text('며칠 전 알림'),
            subtitle: Text('현재: ${s.daysBefore}일 전'),
            trailing: DropdownButton<int>(
              value: s.daysBefore,
              items: List.generate(
                8,
                (i) => DropdownMenuItem<int>(value: i, child: Text('$i일')),
              ),
              onChanged: (!s.enabled || _saving)
                  ? null
                  : (v) {
                      if (v == null) return;
                      _update(s.copyWith(daysBefore: v));
                    },
            ),
          ),
          ListTile(
            enabled: s.enabled && !_saving,
            title: const Text('알림 시각'),
            subtitle: Text(s.time.format(context)),
            trailing: const Icon(IconCatalog.chevronRight),
            onTap: (!s.enabled || _saving)
                ? null
                : () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: s.time,
                    );
                    if (picked == null) return;
                    await _update(s.copyWith(time: picked));
                  },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _lastScheduledCount == null
                  ? '스케줄을 계산 중입니다.'
                  : s.enabled
                  ? '예약된 알림: $_lastScheduledCount건'
                  : '알림이 꺼져 있어 예약된 알림이 없습니다.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '참고: 알림 권한을 거부하면 알림이 예약되지 않습니다.\n'
              '항목 추가/수정/삭제 시 알림은 자동으로 다시 예약됩니다.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
