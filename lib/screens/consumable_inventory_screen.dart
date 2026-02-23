import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../models/shopping_cart_item.dart';
import '../repositories/app_repositories.dart';
import '../services/consumable_inventory_service.dart';
import '../services/user_pref_service.dart';
import '../utils/wms_data_gateway.dart';
import '../utils/snackbar_utils.dart';
import 'consumable_inventory_dialogs.dart';
import 'consumable_inventory_screen_widgets.dart';
import 'wms_io_screen.dart';

class ConsumableInventoryScreen extends StatefulWidget {
  final String accountName;

  const ConsumableInventoryScreen({super.key, required this.accountName});

  @override
  State<ConsumableInventoryScreen> createState() =>
      _ConsumableInventoryScreenState();
}

class _ConsumableInventoryScreenState
    extends State<ConsumableInventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  String _locationFilter = '전체';
  String _categoryFilter = '전체';
  String _expiryFilter = '전체';
  bool _isCartSelectionMode = false;
  final Set<String> _selectedForCartIds = {};

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
    await ConsumableInventoryService.instance.useItem(
      item.id,
      1.0,
    );
    // Warning removed as per Diet UI
  }

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      if (_mainTabController.indexIsChanging) {
        setState(() {
          _locationFilter = '전체';
        });
      }
    });

    // ✅ Gateway를 통한 초기 로드 (캐싱 적용)
    WmsInventoryGateway.instance.getItems();
    _loadCountLikeUnits();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  // 로케이션 필터 옵션 (전체 + 실제 데이터에 존재하는 위치들)
  List<String> get _locationOptions {
    final items = ConsumableInventoryService.instance.items.value;
    final isWarehouseTab = _mainTabController.index == 1;

    final locs = items
        .where((e) => isWarehouseTab ? (e.location == '창고') : (e.location != '창고'))
        .map((e) => e.location)
        .toSet()
        .toList()
      ..sort();

    if (isWarehouseTab) return ['전체']; // 창고 탭은 사실상 단일 위치라 필터가 필요없을 수 있음
    return ['전체', ...locs];
  }

  List<String> get _categoryOptions {
    final items = ConsumableInventoryService.instance.items.value;
    final cats = items.map((e) => e.category).toSet().toList()..sort();
    return ['전체', ...cats];
  }

  List<String> get _expiryOptions => ['전체', '임박', '경과'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCartSelectionMode ? '장바구니 담기 선택' : '식료품/생활용품 관리'),
        bottom: _isCartSelectionMode
            ? null
            : TabBar(
                controller: _mainTabController,
                tabs: const [
                  Tab(icon: Icon(Icons.home), text: '집안 물품'),
                  Tab(icon: Icon(Icons.warehouse), text: '창고 보관'),
                ],
              ),
        actions: [
          if (!_isCartSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.shopping_cart_checkout),
              tooltip: '장바구니 퀵 추가 모드',
              onPressed: () => setState(() => _isCartSelectionMode = true),
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: '개수형 단위 설정',
              onPressed: _showCountLikeUnitsDialog,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddItemDialog,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: '전체 선택',
              onPressed: _selectAll,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isCartSelectionMode = false;
                  _selectedForCartIds.clear();
                });
              },
            ),
          ],
        ],
      ),
      floatingActionButton: _isCartSelectionMode 
          ? null 
          : FloatingActionButton(
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
          // 0: 집안 (창고 제외), 1: 창고 (창고 전용)
          final isWarehouseTab = _mainTabController.index == 1;
          final tabItems = items.where((e) {
            if (isWarehouseTab) {
              return e.location == '창고';
            } else {
              return e.location != '창고';
            }
          }).toList();

          final locFiltered = _locationFilter == '전체'
              ? tabItems
              : tabItems.where((e) => e.location == _locationFilter).toList();

          final filteredItems = _categoryFilter == '전체'
              ? locFiltered
              : locFiltered
                  .where((e) => e.category == _categoryFilter)
                  .toList();

          final expiryFilteredItems = _expiryFilter == '전체'
              ? filteredItems
              : _expiryFilter == '임박'
                  ? filteredItems
                      .where((e) => e.isExpiringWithin())
                      .toList()
                  : filteredItems
                      .where((e) => e.isExpired())
                      .toList();

          final finalItems = expiryFilteredItems;

          return Column(
            children: [
              // 통합 필터 라인 (가로 스크롤)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // 1. 장소 필터 (집안 탭일 때만)
                    if (!isWarehouseTab) ...[
                      ..._locationOptions.map((v) => _buildCompactFilterChip(
                            label: v,
                            selected: _locationFilter == v,
                            onSelected: (sel) => setState(() => _locationFilter = v),
                            color: Colors.blue.withValues(alpha: 0.1),
                          )),
                      _buildDivider(),
                    ],
                    // 2. 분류 필터
                    ..._categoryOptions.map((v) => _buildCompactFilterChip(
                          label: v,
                          selected: _categoryFilter == v,
                          onSelected: (sel) => setState(() => _categoryFilter = v),
                          color: Colors.green.withValues(alpha: 0.1),
                        )),
                    _buildDivider(),
                    // 3. 상태 필터
                    ..._expiryOptions.map((v) => _buildCompactFilterChip(
                          label: v,
                          selected: _expiryFilter == v,
                          onSelected: (sel) => setState(() => _expiryFilter = v),
                          color: Colors.orange.withValues(alpha: 0.1),
                        )),
                  ],
                ),
              ),
              Expanded(
                child: finalItems.isEmpty
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
                        itemCount: finalItems.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = finalItems[index];
                          return ConsumableItemCard(
                            item: item,
                            isCountLikeUnit:
                                _isCountLikeUnit(item.unit),
                            formatQty: _formatQty,
                            isSelected: _selectedForCartIds.contains(item.id),
                            onSelected: _isCartSelectionMode 
                                ? (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedForCartIds.add(item.id);
                                      } else {
                                        _selectedForCartIds.remove(item.id);
                                      }
                                    });
                                  }
                                : null,
                            onQuickDecrement: () =>
                                _quickDecrementOne(item),
                            onUse: () => _useItem(item),
                            onRefill: () => _refillItem(item),
                            onSendToCart: () => _sendToCart(item),
                            onEdit: () =>
                                _showEditItemDialog(item),
                          );
                        },
                      ),
              ),
              if (_isCartSelectionMode)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.shopping_cart),
                        label: Text('${_selectedForCartIds.length}개 항목 장바구니에 추가'),
                        onPressed: _selectedForCartIds.isEmpty ? null : _addSelectedToCart,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _selectAll() {
    final items = ConsumableInventoryService.instance.items.value;
    setState(() {
      if (_selectedForCartIds.length == items.length) {
        _selectedForCartIds.clear();
      } else {
        _selectedForCartIds.addAll(items.map((e) => e.id));
      }
    });
  }

  Future<void> _addSelectedToCart() async {
    final inventoryItems = ConsumableInventoryService.instance.items.value;
    final selectedItems = inventoryItems.where((e) => _selectedForCartIds.contains(e.id)).toList();
    
    if (selectedItems.isEmpty) return;

    final current = await AppRepositories.shoppingCart.getItems(
      accountName: widget.accountName,
    );

    final now = DateTime.now();
    final newCartItems = <ShoppingCartItem>[];
    int skippedCount = 0;

    for (var i = 0; i < selectedItems.length; i++) {
      final item = selectedItems[i];
      if (current.any((c) => c.name == item.name)) {
        skippedCount++;
        continue;
      }

      newCartItems.add(ShoppingCartItem(
        id: 'cart_${now.microsecondsSinceEpoch}_$i',
        name: item.name,
        memo: '나의 생활용품에서 추가',
        createdAt: now,
        updatedAt: now,
      ));
    }

    if (newCartItems.isNotEmpty) {
      final next = List<ShoppingCartItem>.from(current)..addAll(newCartItems);
      await AppRepositories.shoppingCart.setItems(
        accountName: widget.accountName,
        items: next,
      );
    }

    if (mounted) {
      String msg = '${newCartItems.length}개 항목을 장바구니에 담았습니다.';
      if (skippedCount > 0) {
        msg += ' ($skippedCount개 이미 있음)';
      }
      SnackbarUtils.showSuccess(context, msg);
      setState(() {
        _isCartSelectionMode = false;
        _selectedForCartIds.clear();
      });
    }
  }

  void _showAddItemDialog() {
    final isWarehouseTab = _mainTabController.index == 1;
    ConsumableInventoryDialogs.showItemDialog(
      context: context,
      initialLocation: isWarehouseTab ? '창고' : '주방',
    );
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
        await ConsumableInventoryService
            .instance.useItem(item.id, amount);
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

    if (current.any((i) => i.name == item.name)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.name}은(는) 이미 장바구니에 있습니다.',
            ),
          ),
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

  Widget _buildCompactFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: selected,
        onSelected: onSelected,
        visualDensity: VisualDensity.compact,
        backgroundColor: color,
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }
}
