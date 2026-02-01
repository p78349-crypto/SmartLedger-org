import 'package:flutter/material.dart';
import '../models/shopping_cart_item.dart';
import '../services/user_pref_service.dart';
import '../utils/household_items_utils.dart';
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
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('생활용품 선택'), centerTitle: true),
      body: Column(
        children: [
          _buildSearchBar(theme),
          if (_isSearching) ...[
            Expanded(child: _buildSearchResults()),
          ] else ...[
            _buildCategorySelectors(theme),
            Expanded(child: _buildItemList()),
          ],
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '상품 검색',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: _search,
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

        return _buildItemTile(item.name, selected, quantity);
      },
    );
  }

  Widget _buildCategorySelectors(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (_categories1.isNotEmpty)
            _buildDropdown('대분류', _selectedCategory1, _categories1, (v) {
              setState(() {
                _selectedCategory1 = v;
                _loadCategory2();
              });
            }),
          if (_categories2.isNotEmpty) const SizedBox(height: 8),
          if (_categories2.isNotEmpty)
            _buildDropdown('중분류', _selectedCategory2, _categories2, (v) {
              setState(() {
                _selectedCategory2 = v;
                _loadCategory4();
              });
            }),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? currentValue,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
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

        return _buildItemTile(itemName, selected, quantity);
      },
    );
  }

  Widget _buildItemTile(String name, bool selected, double quantity) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (value) {
                setState(() {
                  _selectedItems[name] = value ?? false;
                  if (value == true) {
                    _quantities[name] ??= 1.0;
                  }
                });
              },
            ),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  decoration: selected ? null : TextDecoration.lineThrough,
                  color: selected ? null : Colors.grey,
                ),
              ),
            ),
            if (selected) ...[
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: quantity > 1
                    ? () {
                        setState(() {
                          _quantities[name] = quantity - 1;
                        });
                      }
                    : null,
              ),
              Text(
                '${quantity.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  setState(() {
                    _quantities[name] = quantity + 1;
                  });
                },
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _sending || _selectedCount == 0 ? null : _sendToCart,
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.shopping_cart),
            label: Text(
              _selectedCount == 0
                  ? '항목을 선택해주세요'
                  : '$_selectedCount개 항목 장바구니에 추가',
            ),
          ),
        ),
      ),
    );
  }
}
