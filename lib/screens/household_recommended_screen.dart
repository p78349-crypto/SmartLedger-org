import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shopping_cart_item.dart';
import '../services/user_pref_service.dart';
import 'household_add_item_dialog.dart';
import 'household_item.dart';
import 'shopping_cart_screen.dart';

/// 나의 생활용품 (사용자 입력 기반) 화면
class HouseholdRecommendedScreen extends StatefulWidget {
  const HouseholdRecommendedScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<HouseholdRecommendedScreen> createState() =>
      _HouseholdRecommendedScreenState();
}

class _HouseholdRecommendedScreenState
    extends State<HouseholdRecommendedScreen> {
  bool _loading = true;
  bool _sending = false;
  List<HouseholdItem> _myItems = [];
  final Map<String, bool> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _loadMyItems();
  }

  Future<void> _loadMyItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('my_household_items_${widget.accountName}');
      if (saved != null && saved.isNotEmpty) {
        final jsonList = (jsonDecode(saved) as List)
            .map((e) => HouseholdItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _myItems = jsonList;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터 로드 실패: $e')));
      }
    }
  }

  Future<void> _saveMyItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'my_household_items_${widget.accountName}',
      jsonEncode(_myItems.map((e) => e.toJson()).toList()),
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) => HouseholdAddItemDialog(
        onAdd: (name, unit, qty) async {
          final newItem = HouseholdItem(
            id: '${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            unit: unit,
            quantity: qty,
          );
          setState(() {
            _myItems.add(newItem);
          });
          await _saveMyItems();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('항목이 추가되었습니다')));
          }
        },
      ),
    );
  }

  void _removeItem(String id) {
    setState(() {
      _myItems.removeWhere((item) => item.id == id);
      _selectedItems.remove(id);
    });
    _saveMyItems();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('항목이 제거되었습니다')));
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

      for (final item in _myItems) {
        if (_selectedItems[item.id] != true) continue;

        final cartItem = ShoppingCartItem(
          id: '${now.millisecondsSinceEpoch}_$index',
          name: item.name,
          quantity: item.quantity.toInt().clamp(1, 999),
          unitLabel: item.unit,
          memo: '나의생활용품',
          createdAt: now,
          updatedAt: now,
        );

        newItems.add(cartItem);
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
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: _myItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 48),
                      const SizedBox(height: 16),
                      const Text('나의 생활용품이 없습니다'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('추가하기'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _myItems.length,
                  itemBuilder: (context, index) {
                    final item = _myItems[index];
                    final isSelected = _selectedItems[item.id] ?? false;

                    return HouseholdItemCard(
                      item: item,
                      isSelected: isSelected,
                      onSelectedChanged: (value) {
                        setState(() {
                          _selectedItems[item.id] = value ?? false;
                        });
                      },
                      onIncrement: () {
                        setState(() {
                          item.quantity =
                              (item.quantity + 1).clamp(1, 999).toDouble();
                        });
                        _saveMyItems();
                      },
                      onDecrement: () {
                        setState(() {
                          item.quantity =
                              (item.quantity - 1).clamp(1, 999).toDouble();
                        });
                        _saveMyItems();
                      },
                      onDelete: () => _removeItem(item.id),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_myItems.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('항목 추가'),
                    ),
                  ),
                if (_myItems.isNotEmpty) const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sending || _selectedCount == 0
                        ? null
                        : _sendToCart,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.shopping_cart),
                    label: Text(
                      _selectedCount == 0
                          ? '항목을 선택해주세요'
                          : '$_selectedCount개 항목 '
                                '장바구니에 추가',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


