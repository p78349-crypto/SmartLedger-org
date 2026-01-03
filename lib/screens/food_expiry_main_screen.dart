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
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/interaction_blockers.dart';

/// 식품 유통기한 관리 전용 메인 네비게이션 화면
class FoodExpiryMainScreen extends StatefulWidget {
  const FoodExpiryMainScreen({super.key});

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
  final List<String> _cuisines = [
    'All',
    'Korean',
    'Western',
    'Japanese',
    'Chinese',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final allRecipes = RecipeService.instance.recipes.value;
    final filteredRecipes = _selectedCuisine == 'All'
        ? allRecipes
        : allRecipes.where((r) => r.cuisine == _selectedCuisine).toList();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Select Recipe'),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Recipe',
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
                  ? const Center(child: Text('No recipes in this category.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredRecipes.length,
                      itemBuilder: (ctx, i) {
                        final r = filteredRecipes[i];
                        return ListTile(
                          title: Text(r.name),
                          subtitle: Text(
                            r.ingredients.map((e) => e.name).join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
          child: const Text('Cancel'),
        ),
      ],
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
            RecipeIngredient(
              name: item.name,
              quantity: 1, // Default
              unit: 'ea', // Default
            ),
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
              widget.existing == null ? 'Add New Recipe' : 'Edit Recipe',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Recipe Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _cuisines.contains(_cuisine) ? _cuisine : 'Other',
              decoration: const InputDecoration(
                labelText: 'Category',
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
                const Text('Ingredients'),
                Row(
                  children: [
                    IconButton(
                      onPressed: _importFromHistory,
                      icon: const Icon(Icons.history),
                      tooltip: 'Import from History',
                    ),
                    IconButton(
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Ingredient',
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
                          title: const Text('Delete Recipe'),
                          content: Text("Delete '${widget.existing!.name}'?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Delete',
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
                    child: const Text('Delete'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _save, child: const Text('Save')),
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
  final _unitController = TextEditingController(text: 'ea');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Ingredient'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: true,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
          child: const Text('Add'),
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
    _FoodExpiryItemsScreen(onUpsert: _openUpsertDialog),
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
  late DateTime _purchaseDate;
  DateTime? _pickedExpiryDate;

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
    _purchaseDate = widget.existing?.purchaseDate ?? DateTime.now();
    _pickedExpiryDate = widget.existing?.expiryDate;

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

  String _riskLabel(FoodExpiryRisk r) {
    switch (r) {
      case FoodExpiryRisk.safe:
        return 'Safe';
      case FoodExpiryRisk.caution:
        return 'Caution';
      case FoodExpiryRisk.danger:
        return 'Danger';
      case FoodExpiryRisk.stable:
        return 'Stable';
    }
  }

  Color _riskColor(ThemeData theme, FoodExpiryRisk r) {
    switch (r) {
      case FoodExpiryRisk.danger:
        return theme.colorScheme.error;
      case FoodExpiryRisk.caution:
        return theme.colorScheme.tertiary;
      case FoodExpiryRisk.safe:
      case FoodExpiryRisk.stable:
        return theme.colorScheme.primary;
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final p = _prediction();
    final effective = _pickedExpiryDate ?? p?.suggestedExpiryDate;
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final unit = _unitController.text.trim().isEmpty
        ? '개'
        : _unitController.text.trim();

    if (name.isEmpty || effective == null) {
      // If in import mode, maybe just skip? But user clicked Save.
      // Let's just return and let user fix it.
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
      );
    }

    if (_importQueue.isNotEmpty) {
      _loadNextFromQueue();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _prediction();
    final suggestedText = p == null
        ? null
        : '${DateFormat('yyyy-MM-dd').format(p.suggestedExpiryDate)} '
              '(+${p.adjustedDays}일, ${p.category})';

    final isImporting = _importQueue.isNotEmpty || _importTotal > 0;
    final remaining = _importQueue.length;
    final currentImportIndex =
        _importTotal -
        remaining; // 1-based index for display? No, 0 items done.
    // If queue has 4 items, total 5. 1 is current.
    // Display: "Importing 1 / 5"

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.maxFinite,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existing == null ? '유통기한 추가' : '유통기한 수정',
                      style: theme.textTheme.titleLarge,
                    ),
                    if (isImporting)
                      Chip(
                        label: Text(
                          '${currentImportIndex + 1} / $_importTotal',
                        ),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        decoration: const InputDecoration(
                          labelText: '상품명',
                          hintText: '예: 우유, 계란, 두부',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _memoFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _memoFocus.requestFocus,
                      icon: const Icon(Icons.arrow_downward),
                      tooltip: '다음 입력',
                    ),
                    const SizedBox(width: 4),
                    IconButton.outlined(
                      onPressed: _showHistoryPicker,
                      icon: const Icon(IconCatalog.history),
                      tooltip: '쇼핑 기록 불러오기',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: '수량',
                          hintText: '숫자만 입력 (예: 1)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: '단위',
                          hintText: 'g, kg, ml 등',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                if (widget.existing != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addQtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: '추가 (+)',
                            hintText: '0',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(Icons.add, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _subQtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: '사용 (-)',
                            hintText: '0',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(Icons.remove, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _memoController,
                  focusNode: _memoFocus,
                  decoration: const InputDecoration(
                    labelText: '메모(선택)',
                    hintText: '예: 냉동 / 임박 / 마감세일',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                Text('구매일', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _purchaseDate,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 10),
                          );
                          if (d != null) {
                            setState(() => _purchaseDate = d);
                          }
                        },
                        icon: const Icon(IconCatalog.calendarToday, size: 18),
                        label: Text(
                          DateFormat('yyyy-MM-dd').format(_purchaseDate),
                        ),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('오늘'),
                            onPressed: () {
                              setState(() => _purchaseDate = DateTime.now());
                            },
                          ),
                          ActionChip(
                            label: const Text('어제'),
                            onPressed: () {
                              setState(() {
                                _purchaseDate = DateTime.now().subtract(
                                  const Duration(days: 1),
                                );
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('2일전'),
                            onPressed: () {
                              setState(() {
                                _purchaseDate = DateTime.now().subtract(
                                  const Duration(days: 2),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (p != null) ...[
                  Card(
                    color: theme.colorScheme.surfaceContainerHighest,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'AI Prediction',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _riskLabel(p.risk),
                                style: TextStyle(
                                  color: _riskColor(theme, p.risk),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(suggestedText ?? ''),
                          const SizedBox(height: 6),
                          ...p.reasons
                              .take(3)
                              .map(
                                (e) => Text(
                                  '• $e',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('유통기한', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final d = await showDatePicker(
                            context: context,
                            initialDate:
                                _pickedExpiryDate ??
                                p?.suggestedExpiryDate ??
                                now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 10),
                          );
                          if (d != null) {
                            setState(() => _pickedExpiryDate = d);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text(_expiryButtonLabel(p?.suggestedExpiryDate)),
                      ),
                    ),
                    if (p != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _pickedExpiryDate = p.suggestedExpiryDate;
                          });
                        },
                        child: const Text('예측 적용'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isImporting) ...[
                      TextButton(
                        onPressed: _stopImport,
                        child: const Text('가져오기 중단'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _skipCurrentImport,
                        child: const Text('건너뛰기'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _save,
                        child: Text(
                          remaining > 0 ? '저장 후 다음($remaining개)' : '저장 및 완료',
                        ),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: Navigator.of(context).pop,
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _save,
                        child: Text(widget.existing == null ? '등록' : '저장'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
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

  const _FoodExpiryItemsScreen({this.onUpsert});

  @override
  State<_FoodExpiryItemsScreen> createState() => _FoodExpiryItemsScreenState();
}

class _FoodExpiryItemsScreenState extends State<_FoodExpiryItemsScreen> {
  bool _isUsageMode = false;
  final Map<String, double> _usageMap = {};

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
      isPlanned: true,
      isChecked: false,
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
    );
  }

  void _toggleUsageMode() {
    setState(() {
      _isUsageMode = !_isUsageMode;
      _usageMap.clear();
    });
  }

  Future<void> _applyBulkUsage() async {
    if (_usageMap.isEmpty) return;

    int updatedCount = 0;
    final items = FoodExpiryService.instance.items.value;

    for (var entry in _usageMap.entries) {
      if (entry.value <= 0) continue;

      final item = items.firstWhere(
        (i) => i.id == entry.key,
        orElse: () => items.first,
      );
      if (item.id != entry.key) continue;

      final newQty = item.quantity - entry.value;
      if (newQty <= 0) {
        await FoodExpiryService.instance.updateItem(
          id: item.id,
          name: item.name,
          purchaseDate: item.purchaseDate,
          expiryDate: item.expiryDate,
          memo: item.memo,
          quantity: 0,
          unit: item.unit,
        );
      } else {
        await FoodExpiryService.instance.updateItem(
          id: item.id,
          name: item.name,
          purchaseDate: item.purchaseDate,
          expiryDate: item.expiryDate,
          memo: item.memo,
          quantity: newQty,
          unit: item.unit,
        );
      }
      updatedCount++;
    }

    setState(() {
      _isUsageMode = false;
      _usageMap.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usage recorded for $updatedCount items.')),
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
      setState(() {
        _isUsageMode = true;
        _usageMap.clear();

        int matchedCount = 0;
        for (var ingredient in selectedRecipe.ingredients) {
          // Simple name matching
          try {
            final item = items.firstWhere(
              (i) =>
                  i.name.contains(ingredient.name) ||
                  ingredient.name.contains(i.name),
            );
            _usageMap[item.id] = ingredient.quantity;
            matchedCount++;
          } catch (e) {
            // Not found in inventory
          }
        }

        if (matchedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${selectedRecipe.name} 재료 $matchedCount개가 입력되었습니다.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일치하는 재고 항목을 찾을 수 없습니다.')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('유통기한 관리'),
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
      floatingActionButton: _isUsageMode && _usageMap.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _applyBulkUsage,
              icon: const Icon(Icons.check),
              label: Text('${_usageMap.length}개 적용'),
            )
          : null,
      body: ValueListenableBuilder<List<FoodExpiryItem>>(
        valueListenable: FoodExpiryService.instance.items,
        builder: (context, items, child) {
          if (items.isEmpty) {
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

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
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

              return ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        it.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!_isUsageMode) ...[
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _adjustQuantity(context, it, -1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
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
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dotted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _adjustQuantity(context, it, 1),
                      ),
                    ] else ...[
                      // Usage Mode: Show input field directly
                      Text(
                        '현재: ${_formatQuantity(it)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        height: 36,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: '사용',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final v = double.tryParse(val);
                            if (v != null && v > 0) {
                              setState(() {
                                _usageMap[it.id] = v;
                              });
                            } else {
                              setState(() {
                                _usageMap.remove(it.id);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  _itemSubtitleText(it),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  if (!_isUsageMode) {
                    widget.onUpsert?.call(context, existing: it);
                  }
                },
                trailing: _isUsageMode
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(leftText, style: TextStyle(color: color)),
                          IconButton(
                            icon: const Icon(IconCatalog.shoppingCart),
                            tooltip: '장바구니 담기',
                            onPressed: () => _addToCart(context, it),
                          ),
                          IconButton(
                            icon: const Icon(IconCatalog.deleteOutline),
                            tooltip: '삭제',
                            onPressed: () =>
                                FoodExpiryService.instance.deleteById(it.id),
                          ),
                        ],
                      ),
              );
            },
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
    final base = '구매일: $purchase  /  유통기한: $expiry';
    final memo = item.memo.trim();
    if (memo.isEmpty) return base;
    return '$base\n메모: $memo';
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
