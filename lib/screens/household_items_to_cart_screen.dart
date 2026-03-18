import 'package:flutter/material.dart';
import '../models/shopping_cart_item.dart';
import '../services/user_pref_service.dart';
import '../utils/household_items_utils.dart';
import 'household_items_to_cart_widgets.dart';
import 'shopping_cart_screen.dart';

/// 생활용품 → 장바구니 화면
class HouseholdItemsToCartScreen extends StatefulWidget {
  const HouseholdItemsToCartScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<HouseholdItemsToCartScreen> createState() =>
      _HouseholdItemsToCartScreenState();
}

class _HouseholdItemsToCartScreenState
    extends State<HouseholdItemsToCartScreen> {
  bool _loading = true;
  bool _sending = false;
  String? _selectedCategory1;
  String? _selectedCategory2;

  List<String> _categories1 = [];
  List<String> _categories2 = [];
  List<String> _categories4 = [];

  final Map<String, bool> _selectedItems = {};
  final Map<String, double> _quantities = {};

  final TextEditingController _searchController = TextEditingController();
  List<HouseholdItem> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    final cats = await HouseholdItemsUtils.getCategory1List();
    if (mounted) {
      setState(() {
        _categories1 = cats;
        _loading = false;
        if (cats.isNotEmpty) {
          _selectedCategory1 = cats.first;
          _loadCategory2();
        }
      });
    }
  }

  Future<void> _loadCategory2() async {
    if (_selectedCategory1 == null) return;
    final cats = await HouseholdItemsUtils.getCategory2List(
      _selectedCategory1!,
    );
    if (mounted) {
      setState(() {
        _categories2 = cats;
        _selectedCategory2 = cats.isNotEmpty ? cats.first : null;
        _loadCategory4();
      });
    }
  }

  Future<void> _loadCategory4() async {
    if (_selectedCategory1 == null || _selectedCategory2 == null) {
      return;
    }
    final cats = await HouseholdItemsUtils.getCategory4List(
      _selectedCategory1!,
      _selectedCategory2!,
      _selectedCategory2!, // Use category2 as category3
    );
    if (mounted) {
      setState(() {
        _categories4 = cats;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await HouseholdItemsUtils.searchItems(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  int get _selectedCount => _selectedItems.values.where((v) => v).length;

  void _onItemSelectedChanged(String name, bool? value) {
    setState(() {
      _selectedItems[name] = value ?? false;
      if (value == true) {
        _quantities[name] ??= 1.0;
      }
    });
  }

  void _onItemQuantityChanged(String name, double quantity) {
    setState(() {
      _quantities[name] = quantity;
    });
  }

  Future<void> _sendToCart() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 1개 이상 선택해주세요')));
      return;
    }

    setState(() => _sending = true);

    try {
      final existingItems = await UserPrefService.getShoppingCartItems(
        accountName: widget.accountName,
      );

      final now = DateTime.now();
      final newItems = <ShoppingCartItem>[];
      var index = 0;

      for (final entry in _selectedItems.entries) {
        if (entry.value != true) continue;

        final quantity = _quantities[entry.key] ?? 1;
        final item = ShoppingCartItem(
          id: '${now.millisecondsSinceEpoch}_$index',
          name: entry.key,
          quantity: quantity.toInt().clamp(1, 999),
          unitLabel: '개',
          memo: '생활용품',
          createdAt: now,
          updatedAt: now,
        );

        newItems.add(item);
        index++;
      }

      final allItems = [...existingItems, ...newItems];

      await UserPrefService.setShoppingCartItems(
        accountName: widget.accountName,
        items: allItems,
      );

      if (mounted) {
        await Navigator.of(context).pushReplacement(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('장바구니 추가 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('생활용품 선택'), centerTitle: true),
      body: Column(
        children: [
          HouseholdSearchBar(controller: _searchController, onSearch: _search),
          if (_isSearching) ...[
            Expanded(child: _buildSearchResults()),
          ] else ...[
            HouseholdCategorySelectors(
              categories1: _categories1,
              categories2: _categories2,
              selectedCategory1: _selectedCategory1,
              selectedCategory2: _selectedCategory2,
              onCategory1Changed: (v) {
                setState(() {
                  _selectedCategory1 = v;
                  _loadCategory2();
                });
              },
              onCategory2Changed: (v) {
                setState(() {
                  _selectedCategory2 = v;
                  _loadCategory4();
                });
              },
            ),
            Expanded(child: _buildItemList()),
          ],
          HouseholdCartBottomButton(
            sending: _sending,
            selectedCount: _selectedCount,
            onPressed: _sendToCart,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('검색 결과 없음'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        final selected = _selectedItems[item.name] ?? false;
        final quantity = _quantities[item.name] ?? 1.0;

        return HouseholdItemTile(
          name: item.name,
          selected: selected,
          quantity: quantity,
          onSelectedChanged: (v) => _onItemSelectedChanged(item.name, v),
          onQuantityChanged: (q) => _onItemQuantityChanged(item.name, q),
        );
      },
    );
  }

  Widget _buildItemList() {
    if (_categories4.isEmpty) {
      return const Center(child: Text('항목이 없습니다'));
    }

    return ListView.builder(
      itemCount: _categories4.length,
      itemBuilder: (context, index) {
        final itemName = _categories4[index];
        final selected = _selectedItems[itemName] ?? false;
        final quantity = _quantities[itemName] ?? 1.0;

        return HouseholdItemTile(
          name: itemName,
          selected: selected,
          quantity: quantity,
          onSelectedChanged: (v) => _onItemSelectedChanged(itemName, v),
          onQuantityChanged: (q) => _onItemQuantityChanged(itemName, q),
        );
      },
    );
  }
}
