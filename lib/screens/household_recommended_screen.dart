import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shopping_cart_item.dart';
import '../services/user_pref_service.dart';
import 'shopping_cart_screen.dart';

/// 나의 생활용품 (사용자 입력 기반) 화면
class HouseholdRecommendedScreen extends StatefulWidget {
  const HouseholdRecommendedScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<HouseholdRecommendedScreen> createState() =>
      _HouseholdRecommendedScreenState();
}

class _HouseholdItem {
  final String id;
  String name;
  String unit;
  double quantity;

  _HouseholdItem({
    required this.id,
    required this.name,
    this.unit = '',
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'quantity': quantity,
  };

  factory _HouseholdItem.fromJson(Map<String, dynamic> j) => _HouseholdItem(
    id: j['id'],
    name: j['name'],
    unit: j['unit'] ?? '',
    quantity: (j['quantity'] ?? 1).toDouble(),
  );
}

class _HouseholdRecommendedScreenState
    extends State<HouseholdRecommendedScreen> {
  bool _loading = true;
  bool _sending = false;
  List<_HouseholdItem> _myItems = [];
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
            .map((e) => _HouseholdItem.fromJson(e as Map<String, dynamic>))
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
      builder: (ctx) => _AddItemDialog(
        onAdd: (name, unit, qty) async {
          final newItem = _HouseholdItem(
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

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              _selectedItems[item.id] = value ?? false;
                            });
                          },
                        ),
                        title: Text(item.name),
                        subtitle: Text(item.unit),
                        trailing: SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: () {
                                  setState(() {
                                    item.quantity = (item.quantity - 1)
                                        .clamp(1, 999)
                                        .toDouble();
                                  });
                                  _saveMyItems();
                                },
                              ),
                              Text(item.quantity.toInt().toString()),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () {
                                  setState(() {
                                    item.quantity = (item.quantity + 1)
                                        .clamp(1, 999)
                                        .toDouble();
                                  });
                                  _saveMyItems();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeItem(item.id),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _AddItemDialog extends StatefulWidget {
  final Function(String, String, double) onAdd;
  const _AddItemDialog({required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController(text: '');
  final _qtyController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('생활용품 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '상품명',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: const [
                          TextSpan(text: '단위'),
                          TextSpan(text: ' '),
                          TextSpan(
                            text: '(개수)',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  decoration: const InputDecoration(
                    labelText: '수량',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
            final unit = _unitController.text.trim();
            final qty = double.tryParse(_qtyController.text) ?? 1;
            if (name.isNotEmpty) {
              widget.onAdd(name, unit, qty);
              Navigator.pop(context);
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
