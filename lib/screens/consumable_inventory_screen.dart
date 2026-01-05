import 'package:flutter/material.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/services/consumable_inventory_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';

class ConsumableInventoryScreen extends StatefulWidget {
  final String accountName;

  const ConsumableInventoryScreen({
    super.key,
    required this.accountName,
  });

  @override
  State<ConsumableInventoryScreen> createState() =>
      _ConsumableInventoryScreenState();
}

class _ConsumableInventoryScreenState extends State<ConsumableInventoryScreen> {
  String _locationFilter = '전체'; // 로케이션 필터 상태

  @override
  void initState() {
    super.initState();
    ConsumableInventoryService.instance.load();
  }

  // 로케이션 필터 옵션 (전체 + 기본 옵션들)
  List<String> get _locationOptions =>
      ['전체', ...ConsumableInventoryItem.locationOptions];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('생활용품 재고 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddItemDialog,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<ConsumableInventoryItem>>(
        valueListenable: ConsumableInventoryService.instance.items,
        builder: (context, items, _) {
          // 로케이션 필터 적용
          final filteredItems = _locationFilter == '전체'
              ? items
              : items.where((e) => e.location == _locationFilter).toList();

          return Column(
            children: [
              // 로케이션 필터 칩
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: _locationOptions.map((loc) {
                    final isSelected = _locationFilter == loc;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(loc),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _locationFilter = loc);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              // 아이템 목록
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          _locationFilter == '전체'
                              ? '등록된 소모품이 없습니다.\n우측 상단 + 버튼으로 추가하세요.'
                              : '$_locationFilter에 등록된 소모품이 없습니다.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isLow = item.currentStock <= item.threshold;

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isLow
                                    ? Colors.orange.withValues(alpha: 0.5)
                                    : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                width: isLow ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '📍 ${item.location}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isLow)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            '재고 부족',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '현재고: ${item.currentStock} ${item.unit}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isLow ? Colors.orange : null,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '알림 기준: ${item.threshold} ${item.unit} 이하',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _ActionButton(
                                        icon: Icons.remove,
                                        label: '사용',
                                        onPressed: () => _useItem(item),
                                      ),
                                      const SizedBox(width: 8),
                                      _ActionButton(
                                        icon: Icons.add,
                                        label: '추가',
                                        onPressed: () => _refillItem(item),
                                      ),
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        onPressed: () => _sendToCart(item),
                                        icon: const Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('장바구니'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20),
                                        onPressed: () =>
                                            _showEditItemDialog(item),
                                      ),
                                    ],
                                  ),
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

  void _showAddItemDialog() {
    _showItemDialog();
  }

  void _showEditItemDialog(ConsumableInventoryItem item) {
    _showItemDialog(item: item);
  }

  void _showItemDialog({ConsumableInventoryItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final stockController =
        TextEditingController(text: item?.currentStock.toString() ?? '0');
    final thresholdController =
        TextEditingController(text: item?.threshold.toString() ?? '1');
    final bundleSizeController =
        TextEditingController(text: item?.bundleSize.toString() ?? '1');
    final unitController = TextEditingController(text: item?.unit ?? '개');
    String selectedLocation = item?.location ?? '기타';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(item == null ? '재고 추가' : '재고 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: '품목명 (예: 휴지)'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            decoration:
                                const InputDecoration(labelText: '현재고'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: '단위 (예: 롤, 개)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 로케이션 선택 드롭다운
                    DropdownButtonFormField<String>(
                      initialValue: selectedLocation,
                      decoration: const InputDecoration(
                        labelText: '보관 위치',
                        border: OutlineInputBorder(),
                      ),
                      items: ConsumableInventoryItem.locationOptions
                          .map((loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedLocation = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: thresholdController,
                      decoration: const InputDecoration(
                        labelText: '알림 기준 (이하일 때 알림)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    TextField(
                      controller: bundleSizeController,
                      decoration: const InputDecoration(
                        labelText: '묶음 단위 (예: 30롤 묶음이면 30)',
                        hintText: '휴지 대형 묶음은 보통 30입니다.',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (item != null)
                  TextButton(
                    onPressed: () {
                      ConsumableInventoryService.instance.deleteItem(item.id);
                      Navigator.pop(context);
                    },
                    child:
                        const Text('삭제', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final stock =
                        double.tryParse(stockController.text) ?? 0.0;
                    final threshold =
                        double.tryParse(thresholdController.text) ?? 1.0;
                    final bundleSize =
                        double.tryParse(bundleSizeController.text) ?? 1.0;
                    final unit = unitController.text.trim();

                    if (item == null) {
                      ConsumableInventoryService.instance.addItem(
                        name: name,
                        currentStock: stock,
                        threshold: threshold,
                        bundleSize: bundleSize,
                        unit: unit,
                        location: selectedLocation,
                      );
                    } else {
                      ConsumableInventoryService.instance.updateItem(
                        item.copyWith(
                          name: name,
                          currentStock: stock,
                          threshold: threshold,
                          bundleSize: bundleSize,
                          unit: unit,
                          location: selectedLocation,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _useItem(ConsumableInventoryItem item) {
    _showAmountDialog(
      title: '사용량 입력',
      item: item,
      onConfirm: (amount) {
        ConsumableInventoryService.instance.useItem(item.id, amount);
      },
    );
  }

  void _refillItem(ConsumableInventoryItem item) {
    _showAmountDialog(
      title: '추가량 입력',
      item: item,
      onConfirm: (amount) {
        ConsumableInventoryService.instance.updateItem(
          item.copyWith(currentStock: item.currentStock + amount),
        );
      },
    );
  }

  void _showAmountDialog({
    required String title,
    required ConsumableInventoryItem item,
    required Function(double) onConfirm,
  }) {
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(suffixText: item.unit),
            ),
            const SizedBox(height: 16),
            const Text(
              '빠른 선택',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.bundleSize > 1)
                  ActionChip(
                    label: Text(
                      '1묶음 (${item.bundleSize.toInt()}${item.unit})',
                    ),
                    onPressed: () =>
                        controller.text = item.bundleSize.toString(),
                  ),
                ActionChip(
                  label: const Text('9개'),
                  onPressed: () => controller.text = '9',
                ),
                ActionChip(
                  label: const Text('10개'),
                  onPressed: () => controller.text = '10',
                ),
                ActionChip(
                  label: const Text('30개'),
                  onPressed: () => controller.text = '30',
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
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                onConfirm(val);
                Navigator.pop(context);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToCart(ConsumableInventoryItem item) async {
    final current = await UserPrefService.getShoppingCartItems(
      accountName: widget.accountName,
    );

    // Check if already in cart
    if (current.any((i) => i.name == item.name)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name}은(는) 이미 장바구니에 있습니다.')),
        );
      }
      return;
    }

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'cart_${now.microsecondsSinceEpoch}',
      name: item.name,
      memo: '재고 부족으로 자동 추가',
      createdAt: now,
      updatedAt: now,
    );

    final next = List<ShoppingCartItem>.from(current)..add(newItem);
    await UserPrefService.setShoppingCartItems(
      accountName: widget.accountName,
      items: next,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name}을(를) 장바구니에 담았습니다.')),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
