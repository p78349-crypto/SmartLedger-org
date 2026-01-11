import 'package:flutter/material.dart';
import '../models/category_hint.dart';
import '../models/shopping_cart_item.dart';
import '../navigation/app_routes.dart';
import '../services/product_location_service.dart';
import '../services/user_pref_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/shopping_cart_bulk_ledger_utils.dart';
import '../widgets/smart_input_field.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({
    super.key,
    required this.accountName,
    this.openPrepOnStart = false,
    this.initialItems,
  });

  final String accountName;
  final bool openPrepOnStart;
  final List<ShoppingCartItem>? initialItems;

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  static const double _inlineFieldHeight = 36.0;
  static const BorderRadius _inlineFieldRadius = BorderRadius.all(
    Radius.circular(12),
  );
  static const Color _inlineFieldBorderColor = Color(0xFFD8C5CA);
  static const Color _inlineFieldFocusedBorderColor = Color(0xFF884A5E);
  static const Color _inlineFieldFillColor = Color(0xFFF8EFF2);

  bool _isLoading = true;
  List<ShoppingCartItem> _items = const [];
  Map<String, CategoryHint> _categoryHints = <String, CategoryHint>{};

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _unitPriceControllers = {};
  final Map<String, TextEditingController> _bundleSizeControllers = {};
  final Map<String, TextEditingController> _memoControllers = {};

  final Map<String, FocusNode> _qtyFocusNodes = {};
  final Map<String, FocusNode> _unitPriceFocusNodes = {};
  final Map<String, FocusNode> _bundleSizeFocusNodes = {};
  final Map<String, FocusNode> _memoFocusNodes = {};

  String _unitPriceTextForInlineEditor(double unitPrice) {
    if (unitPrice <= 0) return '';
    return unitPrice == unitPrice.roundToDouble()
        ? CurrencyFormatter.format(unitPrice, showUnit: false)
        : CurrencyFormatter.formatWithDecimals(unitPrice, showUnit: false);
  }

  InputDecoration _inlineFieldDecoration(ThemeData theme, String hint) {
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final borderColor = isDark
        ? scheme.outlineVariant.withValues(alpha: 0.6)
        : _inlineFieldBorderColor;
    final focusedBorderColor = isDark
        ? scheme.primary
        : _inlineFieldFocusedBorderColor;
    final fillColor = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
        : _inlineFieldFillColor;
    final hintColor = isDark
        ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
        : scheme.onSurfaceVariant.withValues(alpha: 0.6);

    return InputDecoration(
      isDense: true,
      hintText: hint,
      filled: true,
      fillColor: fillColor,
      hintStyle: TextStyle(color: hintColor),
      border: OutlineInputBorder(
        borderRadius: _inlineFieldRadius,
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _inlineFieldRadius,
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _inlineFieldRadius,
        borderSide: BorderSide(color: focusedBorderColor, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  @override
  void initState() {
    super.initState();

    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        _nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _nameController.text.length,
        );
      }
    });

    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final c in _unitPriceControllers.values) {
      c.dispose();
    }
    for (final c in _bundleSizeControllers.values) {
      c.dispose();
    }
    for (final c in _memoControllers.values) {
      c.dispose();
    }
    for (final n in _qtyFocusNodes.values) {
      n.dispose();
    }
    for (final n in _unitPriceFocusNodes.values) {
      n.dispose();
    }
    for (final n in _bundleSizeFocusNodes.values) {
      n.dispose();
    }
    for (final n in _memoFocusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _syncInlineControllers(List<ShoppingCartItem> next) {
    final ids = next.map((e) => e.id).toSet();

    final qtyRemoved = _qtyControllers.keys.where((k) => !ids.contains(k));
    for (final k in qtyRemoved.toList(growable: false)) {
      _qtyControllers.remove(k)?.dispose();
    }

    final qtyFocusRemoved = _qtyFocusNodes.keys.where((k) => !ids.contains(k));
    for (final k in qtyFocusRemoved.toList(growable: false)) {
      _qtyFocusNodes.remove(k)?.dispose();
    }

    final unitRemoved = _unitPriceControllers.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in unitRemoved.toList(growable: false)) {
      _unitPriceControllers.remove(k)?.dispose();
    }

    final bundleSizeRemoved = _bundleSizeControllers.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in bundleSizeRemoved.toList(growable: false)) {
      _bundleSizeControllers.remove(k)?.dispose();
    }

    final memoRemoved = _memoControllers.keys.where((k) => !ids.contains(k));
    for (final k in memoRemoved.toList(growable: false)) {
      _memoControllers.remove(k)?.dispose();
    }

    final unitFocusRemoved = _unitPriceFocusNodes.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in unitFocusRemoved.toList(growable: false)) {
      _unitPriceFocusNodes.remove(k)?.dispose();
    }

    final bundleSizeFocusRemoved = _bundleSizeFocusNodes.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in bundleSizeFocusRemoved.toList(growable: false)) {
      _bundleSizeFocusNodes.remove(k)?.dispose();
    }

    final memoFocusRemoved = _memoFocusNodes.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in memoFocusRemoved.toList(growable: false)) {
      _memoFocusNodes.remove(k)?.dispose();
    }

    for (final item in next) {
      final qtyText = (item.bundleCount < 0 ? 0 : item.bundleCount).toString();
      final qtyC = _qtyControllers[item.id];
      if (qtyC == null) {
        _qtyControllers[item.id] = TextEditingController(text: qtyText);
      } else {
        final hasFocus = _qtyFocusNodes[item.id]?.hasFocus ?? false;
        if (!hasFocus && qtyC.text != qtyText) {
          qtyC.text = qtyText;
        }
      }

      _qtyFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        node.addListener(() {
          if (node.hasFocus) {
            final c = _qtyControllers[item.id];
            if (c != null) {
              c.selection = TextSelection(
                baseOffset: 0,
                extentOffset: c.text.length,
              );
            }
          }
          if (mounted) setState(() {});
        });
        return node;
      });

      final perBundleText = (item.unitsPerBundle < 0 ? 0 : item.unitsPerBundle)
          .toString();
      final perBundleController = _bundleSizeControllers[item.id];
      if (perBundleController == null) {
        _bundleSizeControllers[item.id] = TextEditingController(
          text: perBundleText,
        );
      } else {
        final hasFocus = _bundleSizeFocusNodes[item.id]?.hasFocus ?? false;
        if (!hasFocus && perBundleController.text != perBundleText) {
          perBundleController.text = perBundleText;
        }
      }

      _bundleSizeFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        node.addListener(() {
          if (node.hasFocus) {
            final c = _bundleSizeControllers[item.id];
            if (c != null) {
              c.selection = TextSelection(
                baseOffset: 0,
                extentOffset: c.text.length,
              );
            }
          }
          if (mounted) setState(() {});
        });
        return node;
      });

      final unitText = _unitPriceTextForInlineEditor(item.unitPrice);
      final unitC = _unitPriceControllers[item.id];
      if (unitC == null) {
        _unitPriceControllers[item.id] = TextEditingController(text: unitText);
      } else {
        final hasFocus = _unitPriceFocusNodes[item.id]?.hasFocus ?? false;
        if (!hasFocus && unitC.text != unitText) {
          unitC.text = unitText;
        }
      }

      _unitPriceFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        node.addListener(() {
          if (node.hasFocus) {
            final c = _unitPriceControllers[item.id];
            if (c != null) {
              c.selection = TextSelection(
                baseOffset: 0,
                extentOffset: c.text.length,
              );
            }
          }
          if (mounted) setState(() {});
        });
        return node;
      });
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final items = List<ShoppingCartItem>.from(
      await UserPrefService.getShoppingCartItems(
        accountName: widget.accountName,
      ),
    );

    // Merge initial items if provided (e.g. from Recipe Picker)
    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      for (final initItem in widget.initialItems!) {
        final exists = items.any(
          (e) =>
              e.name.trim().toLowerCase() == initItem.name.trim().toLowerCase(),
        );
        if (!exists) {
          items.add(initItem);
        }
      }
      // Save merged list back to prefs
      await UserPrefService.setShoppingCartItems(
        accountName: widget.accountName,
        items: items,
      );
    }

    final hints = await UserPrefService.getShoppingCategoryHints(
      accountName: widget.accountName,
    );

    if (!mounted) return;
    setState(() {
      _items = items;
      _categoryHints = hints;
      _isLoading = false;
    });

    _syncInlineControllers(items);
  }

  Future<void> _save(List<ShoppingCartItem> next) async {
    setState(() => _items = next);
    _syncInlineControllers(next);
    await UserPrefService.setShoppingCartItems(
      accountName: widget.accountName,
      items: next,
    );
  }

  Future<void> _applyInlineEdits(ShoppingCartItem item) async {
    final bundleRaw = _qtyControllers[item.id]?.text.trim() ?? '';
    final perBundleRaw = _bundleSizeControllers[item.id]?.text.trim() ?? '';
    final unitRaw = _unitPriceControllers[item.id]?.text.trim() ?? '';
    final memoRaw = _memoControllers[item.id]?.text.trim() ?? item.memo;

    final parsedBundle = int.tryParse(bundleRaw);
    final parsedPerBundle = int.tryParse(perBundleRaw);
    final parsedUnit = CurrencyFormatter.parse(unitRaw);

    final nextBundle = (parsedBundle == null)
        ? item.bundleCount
        : (parsedBundle < 0 ? 0 : parsedBundle);
    final nextPerBundle = (parsedPerBundle == null)
        ? item.unitsPerBundle
        : (parsedPerBundle < 0 ? 0 : parsedPerBundle);
    final nextQty = nextBundle * nextPerBundle;
    final nextUnit = (parsedUnit == null) ? item.unitPrice : parsedUnit;
    final nextMemo = memoRaw;

    if (nextBundle == item.bundleCount &&
        nextPerBundle == item.unitsPerBundle &&
        nextUnit == item.unitPrice &&
        nextMemo == item.memo) {
      return;
    }

    final now = DateTime.now();
    final updated = item.copyWith(
      bundleCount: nextBundle,
      unitsPerBundle: nextPerBundle,
      quantity: nextQty,
      unitPrice: nextUnit,
      memo: nextMemo,
      updatedAt: now,
    );
    final next = _items.map((i) => i.id == item.id ? updated : i).toList();
    await _save(next);
  }

  void _previewInlineEdits(ShoppingCartItem item) {
    final bundleRaw = _qtyControllers[item.id]?.text.trim() ?? '';
    final perBundleRaw = _bundleSizeControllers[item.id]?.text.trim() ?? '';
    final unitRaw = _unitPriceControllers[item.id]?.text.trim() ?? '';
    final memoRaw = _memoControllers[item.id]?.text.trim() ?? item.memo;

    final parsedBundle = int.tryParse(bundleRaw);
    final parsedPerBundle = int.tryParse(perBundleRaw);
    final parsedUnit = CurrencyFormatter.parse(unitRaw);

    final nextBundle = (parsedBundle == null)
        ? item.bundleCount
        : (parsedBundle < 0 ? 0 : parsedBundle);
    final nextPerBundle = (parsedPerBundle == null)
        ? item.unitsPerBundle
        : (parsedPerBundle < 0 ? 0 : parsedPerBundle);
    final nextQty = nextBundle * nextPerBundle;
    final nextUnit = (parsedUnit == null) ? item.unitPrice : parsedUnit;
    final nextMemo = memoRaw;

    if (nextBundle == item.bundleCount &&
        nextPerBundle == item.unitsPerBundle &&
        nextUnit == item.unitPrice &&
        nextMemo == item.memo) {
      return;
    }

    final updated = item.copyWith(
      bundleCount: nextBundle,
      unitsPerBundle: nextPerBundle,
      quantity: nextQty,
      unitPrice: nextUnit,
      memo: nextMemo,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _items = _items.map((i) => i.id == item.id ? updated : i).toList();
    });
  }

  Future<void> _confirmResetAll() async {
    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('초기화'),
        content: const Text('등록된 항목을 모두 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) return;
    _nameController.clear();
    await _save(const <ShoppingCartItem>[]);
  }

  Widget _buildWideItemTile({
    required BuildContext context,
    required ShoppingCartItem item,
    required TextEditingController qtyController,
    required TextEditingController bundleSizeController,
    required TextEditingController unitController,
    required TextEditingController memoController,
    required FocusNode qtyFocusNode,
    required FocusNode bundleSizeFocusNode,
    required FocusNode unitFocusNode,
    required FocusNode memoFocusNode,
    required ThemeData theme,
  }) {
    final isCartMode = !widget.openPrepOnStart;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: (isCartMode && item.isChecked)
          ? theme.colorScheme.primaryContainer
          : Colors.transparent,
      child: Row(
        children: [
          if (isCartMode) ...[
            SizedBox(
              width: 40,
              child: Center(
                child: Transform.scale(
                  scale: 0.85,
                  child: Checkbox(
                    value: item.isChecked,
                    onChanged: (_) => _toggleChecked(item),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 3,
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            height: _inlineFieldHeight,
            child: TextField(
              key: ValueKey('sc_price_${item.id}'),
              controller: unitController,
              focusNode: unitFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodySmall,
              decoration: _inlineFieldDecoration(theme, '가격'),
              onChanged: (_) => _previewInlineEdits(item),
              onSubmitted: (_) => _applyInlineEdits(item),
              onEditingComplete: () => _applyInlineEdits(item),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            height: _inlineFieldHeight,
            child: TextField(
              key: ValueKey('sc_qty_${item.id}'),
              controller: qtyController,
              focusNode: qtyFocusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: _inlineFieldDecoration(theme, '수량'),
              onChanged: (_) => _previewInlineEdits(item),
              onSubmitted: (_) => _applyInlineEdits(item),
              onEditingComplete: () => _applyInlineEdits(item),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            height: _inlineFieldHeight,
            child: TextField(
              key: ValueKey('sc_units_${item.id}'),
              controller: bundleSizeController,
              focusNode: bundleSizeFocusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: _inlineFieldDecoration(theme, '개수'),
              onChanged: (_) => _previewInlineEdits(item),
              onSubmitted: (_) => _applyInlineEdits(item),
              onEditingComplete: () => _applyInlineEdits(item),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: memoController,
              focusNode: memoFocusNode,
              style: theme.textTheme.bodySmall,
              decoration: _inlineFieldDecoration(theme, '메모'),
              onChanged: (_) => _previewInlineEdits(item),
              onEditingComplete: () => _applyInlineEdits(item),
            ),
          ),
          const SizedBox(width: 8),
          // 위치 버튼 추가
          Tooltip(
            message: item.storeLocation.isEmpty
                ? '위치 입력'
                : '위치: ${item.storeLocation}',
            child: InkWell(
              onTap: () => _editItemLocation(item),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: item.storeLocation.isEmpty
                      ? Colors.grey.shade200
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: item.storeLocation.isEmpty
                          ? Colors.grey.shade600
                          : theme.colorScheme.primary,
                    ),
                    if (item.storeLocation.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        item.storeLocation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              CurrencyFormatter.format(
                item.unitPrice * (item.quantity < 0 ? 0 : item.quantity),
              ),
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            tooltip: '삭제',
            onPressed: () => _deleteItemWithUndo(item),
            icon: const Icon(IconCatalog.deleteOutline),
          ),
        ],
      ),
    );
  }

  List<ShoppingCartItem> _orderedItems(List<ShoppingCartItem> list) {
    if (widget.openPrepOnStart) return list;
    final unChecked = <ShoppingCartItem>[];
    final checked = <ShoppingCartItem>[];
    for (final item in list) {
      (item.isChecked ? checked : unChecked).add(item);
    }
    return [...unChecked, ...checked];
  }

  Future<void> _toggleChecked(ShoppingCartItem item) async {
    final updated = item.copyWith(
      isChecked: !item.isChecked,
      updatedAt: DateTime.now(),
    );
    final next = _items.map((i) => i.id == item.id ? updated : i).toList();
    await _save(next);
  }

  Future<void> _openTransactionAdd() async {
    await ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk(
      context: context,
      accountName: widget.accountName,
      items: _items,
      categoryHints: _categoryHints,
      saveItems: _save,
      reload: _load,
    );
  }

  Widget _buildCheckedSummaryBar({
    required ThemeData theme,
    required int checkedCount,
  }) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final checkedTotal = _items.where((i) => i.isChecked).fold<double>(0, (
      sum,
      item,
    ) {
      final qty = item.quantity < 0 ? 0 : item.quantity;
      return sum + (item.unitPrice * qty);
    });

    return SafeArea(
      top: false,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Text('체크 항목', style: theme.textTheme.bodyMedium),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  CurrencyFormatter.format(checkedTotal),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              FilledButton.tonal(
                onPressed: checkedCount > 0 ? _openTransactionAdd : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text('지출입력 ($checkedCount)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addItem({bool keepKeyboardOpen = false}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // 이전 위치 조회
    final previousLocation = await ProductLocationService.instance.getLocation(
      accountName: widget.accountName,
      productName: name,
    );

    final now = DateTime.now();
    final item = ShoppingCartItem(
      id: 'shop_${now.microsecondsSinceEpoch}',
      name: name,
      storeLocation: previousLocation ?? '',
      createdAt: now,
      updatedAt: now,
    );

    final next = [item, ..._items];
    _nameController.clear();
    await _save(next);

    if (!mounted) return;
    if (keepKeyboardOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _nameFocusNode.requestFocus();
      });
    }
  }

  Future<void> _deleteItem(ShoppingCartItem item) async {
    final next = _items.where((i) => i.id != item.id).toList();
    await _save(next);
  }

  Future<void> _deleteItemWithUndo(ShoppingCartItem item) async {
    final prev = List<ShoppingCartItem>.from(_items);
    await _deleteItem(item);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('삭제됨: ${item.name}'),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () async {
            await _save(prev);
          },
        ),
      ),
    );
  }

  Future<void> _editItemLocation(ShoppingCartItem item) async {
    FocusScope.of(context).unfocus();

    final controller = TextEditingController(text: item.storeLocation);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_on, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('${item.name} 위치')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmartInputField(
                hint: '예: 3번 통로, 냉장고, 1층 입구',
                controller: controller,
                maxLines: 2,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              const Text(
                '자주 사용하는 위치:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ProductLocationService.commonLocations
                    .take(15)
                    .map(
                      (loc) => ActionChip(
                        label: Text(loc, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          controller.text = loc;
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(controller.text.trim());
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == null) return;

    final now = DateTime.now();
    final updated = item.copyWith(storeLocation: result, updatedAt: now);
    final next = _items.map((i) => i.id == item.id ? updated : i).toList();
    await _save(next);

    // 위치 학습에 저장
    if (result.isNotEmpty) {
      await ProductLocationService.instance.saveLocation(
        accountName: widget.accountName,
        productName: item.name,
        location: result,
      );
    }
  }

  Future<void> _startShoppingGuide() async {
    FocusScope.of(context).unfocus();

    await Navigator.of(context).pushNamed(
      AppRoutes.shoppingGuide,
      arguments: ShoppingGuideArgs(
        accountName: widget.accountName,
        items: _items,
      ),
    );

    // 가이드에서 돌아온 후 새로고침
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isPrep = widget.openPrepOnStart;
    const nameFieldHeight = 48.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final ordered = _orderedItems(_items);
    final checkedCount = _items.where((i) => i.isChecked).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPrep ? '쇼핑준비' : '장바구니'),
        actions: [
          if (!isPrep && _items.isNotEmpty)
            IconButton(
              tooltip: '쇼핑 안내 시작',
              onPressed: _startShoppingGuide,
              icon: const Icon(Icons.map),
            ),
          IconButton(
            tooltip: '초기화',
            onPressed: _isLoading ? null : _confirmResetAll,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isPortrait ? 72 : 56),
          child: Padding(
            padding: isPortrait
                ? const EdgeInsets.fromLTRB(16, 6, 10, 10)
                : const EdgeInsets.fromLTRB(16, 6, 10, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: isPortrait ? nameFieldHeight : 44,
                    child: SmartInputField(
                      compact: true,
                      label: '물품 이름',
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _addItem(keepKeyboardOpen: true),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: isPortrait ? nameFieldHeight : 44,
                  child: FilledButton(
                    onPressed: () => _addItem(keepKeyboardOpen: true),
                    child: const Text('추가'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: (!_isLoading && !isPrep)
          ? _buildCheckedSummaryBar(theme: theme, checkedCount: checkedCount)
          : null,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (ordered.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    '구매 예정 물품을 등록하세요.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.only(bottom: bottomInset + 24),
                        itemCount: ordered.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        itemBuilder: (context, index) {
                          final item = ordered[index];

                          // Ensure inline editors exist even if controllers
                          // temporarily go out-of-sync (e.g. fast rebuilds).
                          _qtyControllers.putIfAbsent(
                            item.id,
                            () => TextEditingController(
                              text:
                                  (item.bundleCount < 0 ? 0 : item.bundleCount)
                                      .toString(),
                            ),
                          );
                          _unitPriceControllers.putIfAbsent(
                            item.id,
                            () => TextEditingController(
                              text: _unitPriceTextForInlineEditor(
                                item.unitPrice,
                              ),
                            ),
                          );
                          _bundleSizeControllers.putIfAbsent(
                            item.id,
                            () => TextEditingController(
                              text:
                                  (item.unitsPerBundle < 0
                                          ? 0
                                          : item.unitsPerBundle)
                                      .toString(),
                            ),
                          );
                          _memoControllers.putIfAbsent(
                            item.id,
                            () => TextEditingController(text: item.memo),
                          );
                          _qtyFocusNodes.putIfAbsent(item.id, FocusNode.new);
                          _bundleSizeFocusNodes.putIfAbsent(
                            item.id,
                            FocusNode.new,
                          );
                          _unitPriceFocusNodes.putIfAbsent(
                            item.id,
                            FocusNode.new,
                          );
                          _memoFocusNodes.putIfAbsent(item.id, FocusNode.new);

                          final qtyController = _qtyControllers[item.id]!;
                          final bundleSizeController =
                              _bundleSizeControllers[item.id]!;
                          final unitController =
                              _unitPriceControllers[item.id]!;
                          final memoController = _memoControllers[item.id]!;
                          final qtyFocusNode = _qtyFocusNodes[item.id]!;
                          final bundleSizeFocusNode =
                              _bundleSizeFocusNodes[item.id]!;
                          final unitFocusNode = _unitPriceFocusNodes[item.id]!;
                          final memoFocusNode = _memoFocusNodes[item.id]!;
                          const unitKeyboardType =
                              TextInputType.numberWithOptions(decimal: true);
                          const tapTargetSize =
                              MaterialTapTargetSize.shrinkWrap;

                          final isPortrait =
                              MediaQuery.of(context).orientation ==
                              Orientation.portrait;

                          final tile = isPortrait
                              ? Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    child: Container(
                                      color: (!isPrep && item.isChecked)
                                          ? theme.colorScheme.primaryContainer
                                          : Colors.transparent,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (!isPrep) ...[
                                                  SizedBox(
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(
                                                      child: Transform.scale(
                                                        scale: 0.85,
                                                        child: Checkbox(
                                                          value: item.isChecked,
                                                          onChanged: (_) =>
                                                              _toggleChecked(
                                                                item,
                                                              ),
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                          materialTapTargetSize:
                                                              tapTargetSize,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    item.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: '삭제',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 36,
                                                        minHeight: 36,
                                                      ),
                                                  onPressed: () =>
                                                      _deleteItemWithUndo(item),
                                                  icon: const Icon(
                                                    IconCatalog.deleteOutline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 100,
                                                  height: _inlineFieldHeight,
                                                  child: TextField(
                                                    key: ValueKey(
                                                      'sc_price_${item.id}',
                                                    ),
                                                    controller: unitController,
                                                    focusNode: unitFocusNode,
                                                    keyboardType:
                                                        unitKeyboardType,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall,
                                                    decoration:
                                                        _inlineFieldDecoration(
                                                          theme,
                                                          '가격',
                                                        ),
                                                    onChanged: (_) =>
                                                        _previewInlineEdits(
                                                          item,
                                                        ),
                                                    onTapOutside: (_) {
                                                      FocusScope.of(
                                                        context,
                                                      ).unfocus();
                                                      _applyInlineEdits(item);
                                                    },
                                                    onSubmitted: (_) =>
                                                        _applyInlineEdits(item),
                                                    onEditingComplete: () =>
                                                        _applyInlineEdits(item),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 56,
                                                  height: _inlineFieldHeight,
                                                  child: TextField(
                                                    key: ValueKey(
                                                      'sc_qty_${item.id}',
                                                    ),
                                                    controller: qtyController,
                                                    focusNode: qtyFocusNode,
                                                    textAlign: TextAlign.center,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                    decoration:
                                                        _inlineFieldDecoration(
                                                          theme,
                                                          '수량',
                                                        ),
                                                    onChanged: (_) =>
                                                        _previewInlineEdits(
                                                          item,
                                                        ),
                                                    onSubmitted: (_) =>
                                                        _applyInlineEdits(item),
                                                    onEditingComplete: () =>
                                                        _applyInlineEdits(item),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 56,
                                                  height: _inlineFieldHeight,
                                                  child: TextField(
                                                    key: ValueKey(
                                                      'sc_units_${item.id}',
                                                    ),
                                                    controller:
                                                        bundleSizeController,
                                                    focusNode:
                                                        bundleSizeFocusNode,
                                                    textAlign: TextAlign.center,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textInputAction:
                                                        TextInputAction.done,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                    decoration:
                                                        _inlineFieldDecoration(
                                                          theme,
                                                          '개수',
                                                        ),
                                                    onChanged: (_) =>
                                                        _previewInlineEdits(
                                                          item,
                                                        ),
                                                    onSubmitted: (_) =>
                                                        _applyInlineEdits(item),
                                                    onEditingComplete: () =>
                                                        _applyInlineEdits(item),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : _buildWideItemTile(
                                  context: context,
                                  item: item,
                                  qtyController: qtyController,
                                  bundleSizeController: bundleSizeController,
                                  unitController: unitController,
                                  memoController: memoController,
                                  qtyFocusNode: qtyFocusNode,
                                  bundleSizeFocusNode: bundleSizeFocusNode,
                                  unitFocusNode: unitFocusNode,
                                  memoFocusNode: memoFocusNode,
                                  theme: theme,
                                );

                          return tile;
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
