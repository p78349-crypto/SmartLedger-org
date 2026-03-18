import 'package:flutter/material.dart';
import '../models/household_product.dart';
import '../models/shopping_cart_item.dart';
import '../navigation/app_routes.dart';
import '../services/household_data_service.dart';
import '../services/user_pref_service.dart';
import '../services/consumable_inventory_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/snackbar_utils.dart';
import 'shopping_cart_screen.dart';

class HouseholdQuickPickScreen extends StatefulWidget {
  final String accountName;

  const HouseholdQuickPickScreen({super.key, required this.accountName});

  @override
  State<HouseholdQuickPickScreen> createState() =>
      _HouseholdQuickPickScreenState();
}

class _HouseholdQuickPickScreenState extends State<HouseholdQuickPickScreen> {
  bool _isLoading = true;
  String? _selectedCategory;
  List<HouseholdProduct> _displayProducts = [];
  final Set<String> _selectedCodes = {};
  final Map<String, int> _quantities = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await HouseholdDataService.instance.init();
    final cats = HouseholdDataService.instance.getMainCategories();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (cats.isNotEmpty) {
          _selectedCategory = cats.first;
          _displayProducts = HouseholdDataService.instance
              .getProductsByCategory(_selectedCategory!);
        }
      });
    }
  }

  void _onCategoryChanged(String? category) {
    if (category == null) return;
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      _displayProducts = HouseholdDataService.instance.getProductsByCategory(
        category,
      );
    });
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty && _selectedCategory != null) {
        _displayProducts = HouseholdDataService.instance.getProductsByCategory(
          _selectedCategory!,
        );
      } else {
        _displayProducts = HouseholdDataService.instance.search(query);
      }
    });
  }

  void _toggleSelection(HouseholdProduct product) {
    setState(() {
      if (_selectedCodes.contains(product.code)) {
        _selectedCodes.remove(product.code);
        _quantities.remove(product.code);
      } else {
        _selectedCodes.add(product.code);
        _quantities[product.code] = product.defaultQuantity;
      }
    });
  }

  Future<void> _addToCart() async {
    if (_selectedCodes.isEmpty) {
      SnackbarUtils.showInfo(context, '항목을 먼저 선택해주세요.');
      return;
    }

    try {
      final existingItems = await UserPrefService.getShoppingCartItems(
        accountName: widget.accountName,
      );

      final now = DateTime.now();
      final newItems = <ShoppingCartItem>[];

      final productsToAdd = _displayProducts
          .where((p) => _selectedCodes.contains(p.code))
          .toList();
      // Handle searchable products that might not be in _displayProducts currently
      // simplified: if they were selected and not in _displayProducts, we might need to search again or cache them
      // For now, assume they are in _displayProducts or we can get them from service

      for (var i = 0; i < productsToAdd.length; i++) {
        final p = productsToAdd[i];
        newItems.add(
          ShoppingCartItem(
            id: 'quick_${now.millisecondsSinceEpoch}_$i',
            name: p.name,
            quantity: _quantities[p.code] ?? 1,
            unitLabel: p.unit,
            memo: '${p.category1} > ${p.category4}',
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await UserPrefService.setShoppingCartItems(
        accountName: widget.accountName,
        items: [...existingItems, ...newItems],
      );

      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          '${newItems.length}개 항목이 장바구니에 추가되었습니다.',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => ShoppingCartScreen(
              accountName: widget.accountName,
              initialItems: newItems,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '장바구니 추가 중 오류: $e');
      }
    }
  }

  Future<void> _addToInventory() async {
    if (_selectedCodes.isEmpty) {
      SnackbarUtils.showInfo(context, '항목을 먼저 선택해주세요.');
      return;
    }

    try {
      final productsToAdd = _displayProducts
          .where((p) => _selectedCodes.contains(p.code))
          .toList();

      for (final p in productsToAdd) {
        final qty = _quantities[p.code]?.toDouble() ?? 1.0;
        await ConsumableInventoryService.instance.addItem(
          name: p.name,
          currentStock: qty,
          unit: p.unit,
          category: p.category1,
          detailCategory: p.category4,
        );
      }

      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          '${productsToAdd.length}개 항목이 내 생활용품(재고)에 추가되었습니다.',
        );
        setState(() {
          _selectedCodes.clear();
          _quantities.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '생활용품 추가 중 오류: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final categories = HouseholdDataService.instance.getMainCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('식료품/생활용품 퀵픽'),
        actions: [
          IconButton(
            tooltip: '내 생활용품(재고) 보기',
            icon: const Icon(IconCatalog.inventory),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.consumableInventory,
                arguments: AccountArgs(accountName: widget.accountName),
              );
            },
          ),
          if (_selectedCodes.isNotEmpty)
            TextButton(
              onPressed: () => setState(_selectedCodes.clear),
              child: const Text('선택해제', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: '분류',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: _onCategoryChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: '검색',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: _onSearch,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _displayProducts.length,
              itemBuilder: (context, index) {
                final product = _displayProducts[index];
                final isSelected = _selectedCodes.contains(product.code);

                return ListTile(
                  selected: isSelected,
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(product),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${product.categoryPath} > ${product.category4}',
                  ),
                  trailing: isSelected
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                final q = _quantities[product.code] ?? 1;
                                if (q > 1) {
                                  setState(
                                    () => _quantities[product.code] = q - 1,
                                  );
                                }
                              },
                            ),
                            Text('${_quantities[product.code] ?? 1}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                final q = _quantities[product.code] ?? 1;
                                setState(
                                  () => _quantities[product.code] = q + 1,
                                );
                              },
                            ),
                          ],
                        )
                      : Text(product.unit),
                  onTap: () => _toggleSelection(product),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      icon: const Icon(IconCatalog.shoppingCart),
                      label: Text('장바구니 (${_selectedCodes.length})'),
                      onPressed: _selectedCodes.isEmpty ? null : _addToCart,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      icon: const Icon(IconCatalog.inventory2),
                      label: Text('내 생품 추가 (${_selectedCodes.length})'),
                      onPressed: _selectedCodes.isEmpty
                          ? null
                          : _addToInventory,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
