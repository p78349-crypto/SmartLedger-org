import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../models/shopping_cart_item.dart';
import '../repositories/app_repositories.dart';
import '../services/consumable_inventory_service.dart';
import '../services/user_pref_service.dart';
import '../utils/wms_data_gateway.dart';
import 'consumable_inventory_dialogs.dart';
import 'consumable_inventory_widgets.dart';
import 'wms_io_screen.dart';

class ConsumableInventoryScreen extends StatefulWidget {
  final String accountName;

  const ConsumableInventoryScreen({super.key, required this.accountName});

  @override
  State<ConsumableInventoryScreen> createState() =>
      _ConsumableInventoryScreenState();
}

class _ConsumableInventoryScreenState
  extends State<ConsumableInventoryScreen> {
  String _locationFilter = '전체';
  String _expiryFilter = '전체';

  Set<String> _countLikeUnits =
    UserPrefService.defaultCountLikeUnitsV1.toSet();

  String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  bool _isCountLikeUnit(String unit) {
    final u = unit.trim();
    if (u.isEmpty) return false;
    return _countLikeUnits.contains(u);
  }

  Future<void> _loadCountLikeUnits() async {
    try {
      final units = await UserPrefService.getCountLikeUnitsV1();
      if (!mounted) return;
      setState(() {
        _countLikeUnits = units
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet();
      });
    } catch (_) {
      // Best-effort
    }
  }

  Future<void> _showCountLikeUnitsDialog() async {
    final result = await ConsumableInventoryDialogs
      .showCountLikeUnitsDialog(
        context: context,
        currentUnits: _countLikeUnits,
      );

    if (result == null) return;
    await UserPrefService.setCountLikeUnitsV1(result);
    await _loadCountLikeUnits();
  }

  Future<void> _quickDecrementOne(ConsumableInventoryItem item) async {
    final warning = await ConsumableInventoryService.instance.useItem(
      item.id,
      1.0,
    );
    if (!mounted) return;
    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(warning.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // ✅ Gateway를 통한 초기 로드 (캐싱 적용)
    WmsInventoryGateway.instance.getItems();
    _loadCountLikeUnits();
  }

  // 로케이션 필터 옵션 (전체 + 기본 옵션들)
  List<String> get _locationOptions => [
    '전체',
    ...ConsumableInventoryItem.locationOptions,
  ];

  List<String> get _expiryOptions => [
    '전체',
    '임박',
    '경과',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식료품/생활용품 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '개수형 단위 설정',
            onPressed: _showCountLikeUnitsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddItemDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WmsIoScreen(
                accountName: widget.accountName,
              ),
            ),
          );
        },
        tooltip: 'WMS 입출고',
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<List<ConsumableInventoryItem>>(
        // ✅ Gateway 캐싱 적용 후에도 실시간 업데이트 유지
        valueListenable: ConsumableInventoryService.instance.items,
        builder: (context, items, _) {
            // 로케이션 필터 적용
            final filteredItems = _locationFilter == '전체'
                ? items
                : items.where((e) => e.location == _locationFilter).toList();

          final expiryFilteredItems = _expiryFilter == '전체'
            ? filteredItems
            : _expiryFilter == '임박'
              ? filteredItems.where((e) => e.isExpiringWithin()).toList()
              : filteredItems.where((e) => e.isExpired()).toList();

          return Column(
            children: [
              // 로케이션 필터 칩
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
              // 유통기한 필터 칩
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: _expiryOptions.map((opt) {
                    final isSelected = _expiryFilter == opt;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(opt),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _expiryFilter = opt);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              // 아이템 목록
              Expanded(
                child: expiryFilteredItems.isEmpty
                    ? Center(
                        child: Text(
                          _locationFilter == '전체'
                              ? _expiryFilter == '전체'
                                  ? '등록된 항목이 없습니다.\n우측 상단 + 버튼으로 추가하세요.'
                                  : '$_expiryFilter 항목이 없습니다.'
                              : '$_locationFilter에 등록된 항목이 없습니다.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: expiryFilteredItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = expiryFilteredItems[index];
                          final isLow = item.currentStock <= item.threshold;
                          final isEmpty = item.currentStock <= 0;

                          final theme = Theme.of(context);
                          final accentColor = isEmpty
                              ? theme.colorScheme.error
                              : (isLow
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.primary);

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isEmpty || isLow
                                    ? accentColor.withValues(alpha: 0.5)
                                    : theme.colorScheme.outlineVariant,
                                width: (isEmpty || isLow) ? 2 : 1,
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
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
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
                                            color: isEmpty
                                                ? theme
                                                      .colorScheme
                                                      .errorContainer
                                                : theme
                                                      .colorScheme
                                                      .tertiaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            isEmpty ? '재고 없음' : '재고 부족',
                                            style: TextStyle(
                                              color: isEmpty
                                                  ? theme
                                                        .colorScheme
                                                        .onErrorContainer
                                                  : theme
                                                        .colorScheme
                                                        .onTertiaryContainer,
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
                                        '현재고: '
                                        '${_formatQty(item.currentStock)}'
                                        '${item.unit}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: (isEmpty || isLow)
                                              ? accentColor
                                              : null,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '알림 기준: '
                                        '${_formatQty(item.threshold)}'
                                        '${item.unit} 이하',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      if (_isCountLikeUnit(item.unit)) ...[
                                        FilledButton.tonal(
                                          onPressed: () =>
                                              _quickDecrementOne(item),
                                          style: FilledButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.standard,
                                            padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                          ),
                                          child: const Text(
                                            '-1',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      ActionButton(
                                        icon: Icons.remove,
                                        label: '사용',
                                        onPressed: () => _useItem(item),
                                      ),
                                      const SizedBox(width: 8),
                                      ActionButton(
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
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          foregroundColor: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                        ),
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
    ConsumableInventoryDialogs.showItemDialog(context: context);
  }

  void _showEditItemDialog(ConsumableInventoryItem item) {
    ConsumableInventoryDialogs.showItemDialog(
      context: context,
      item: item,
    );
  }

  void _useItem(ConsumableInventoryItem item) {
    ConsumableInventoryDialogs.showAmountDialog(
      context: context,
      title: '사용량 입력',
      item: item,
      onConfirm: (amount) async {
        final warning = await ConsumableInventoryService
          .instance.useItem(item.id, amount);
        if (!mounted) return;
        if (warning != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(warning.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _refillItem(ConsumableInventoryItem item) {
    ConsumableInventoryDialogs.showAmountDialog(
      context: context,
      title: '추가량 입력',
      item: item,
      onConfirm: (amount) async {
        await ConsumableInventoryService.instance.updateItem(
          item.copyWith(
            currentStock: item.currentStock + amount,
          ),
        );
      },
    );
  }

  Future<void> _sendToCart(ConsumableInventoryItem item) async {
    final current = await AppRepositories.shoppingCart.getItems(
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
    await AppRepositories.shoppingCart.setItems(
      accountName: widget.accountName,
      items: next,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name}을(를) 장바구니에 담았습니다.'),
        ),
      );
    }
  }
}
