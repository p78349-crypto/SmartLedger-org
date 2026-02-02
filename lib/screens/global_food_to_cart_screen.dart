import 'package:flutter/material.dart';
import '../models/shopping_cart_item.dart';
import '../services/user_pref_service.dart';
import '../utils/global_food_data_utils.dart';
import 'shopping_cart_screen.dart';

/// 글로벌 식료품 → 장바구니 화면
class GlobalFoodToCartScreen extends StatefulWidget {
  const GlobalFoodToCartScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<GlobalFoodToCartScreen> createState() => _GlobalFoodToCartScreenState();
}

class _GlobalFoodToCartScreenState extends State<GlobalFoodToCartScreen> {
  bool _loading = true;
  bool _sending = false;
  String? _selectedCategory;
  String? _selectedType;

  List<String> _categories = [];
  List<GlobalFoodItem> _displayItems = [];

  final Map<String, bool> _selectedItems = {};
  final Map<String, double> _quantities = {};

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

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
    setState(() => _loading = true);
    final cats = await GlobalFoodDataUtils.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _loading = false;
        if (cats.isNotEmpty) {
          _selectedCategory = cats.first;
          _loadItems();
        }
      });
    }
  }

  Future<void> _loadItems() async {
    if (_selectedCategory == null) return;

    List<GlobalFoodItem> items;
    if (_selectedType != null) {
      items = await GlobalFoodDataUtils.getItemsByType(_selectedType!);
      items = items.where((i) => i.category == _selectedCategory).toList();
    } else {
      items = await GlobalFoodDataUtils.getItemsByCategory(_selectedCategory!);
    }

    if (mounted) {
      setState(() {
        _displayItems = items;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _loadItems();
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await GlobalFoodDataUtils.searchItems(query);
    if (mounted) {
      setState(() {
        _displayItems = results;
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
          memo: '글로벌식료품',
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
      appBar: AppBar(title: const Text('글로벌 식료품'), centerTitle: true),
      body: Column(
        children: [
          _buildSearchBar(theme),
          if (!_isSearching) _buildFilters(theme),
          Expanded(child: _buildItemList()),
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
          hintText: '식료품 검색 (영문)',
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

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: '카테고리'),
                  items: _categories
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedCategory = v;
                      _loadItems();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: '타입'),
                  items: const [
                    DropdownMenuItem(child: Text('전체')),
                    DropdownMenuItem(value: 'foundation', child: Text('기본식품')),
                    DropdownMenuItem(value: 'branded', child: Text('브랜드')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedType = v;
                      _loadItems();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    if (_displayItems.isEmpty) {
      return const Center(child: Text('항목이 없습니다'));
    }

    return ListView.builder(
      itemCount: _displayItems.length,
      itemBuilder: (context, index) {
        final item = _displayItems[index];
        final itemKey = '${item.fdcId}_${item.name}';
        final selected = _selectedItems[itemKey] ?? false;
        final quantity = _quantities[itemKey] ?? 1.0;

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
                      _selectedItems[itemKey] = value ?? false;
                      if (value == true) {
                        _quantities[itemKey] ??= 1.0;
                      }
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          decoration: selected
                              ? null
                              : TextDecoration.lineThrough,
                          color: selected ? null : Colors.grey,
                        ),
                      ),
                      Text(
                        '${item.type} • ${item.category}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (item.brand != null)
                        Text(
                          item.brand!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected) ...[
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: quantity > 1
                        ? () {
                            setState(() {
                              _quantities[itemKey] = quantity - 1;
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
                        _quantities[itemKey] = quantity + 1;
                      });
                    },
                  ),
                ],
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
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
