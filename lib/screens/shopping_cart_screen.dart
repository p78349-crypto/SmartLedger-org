import 'package:flutter/material.dart';
import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/shopping_cart_bulk_ledger_utils.dart';
import 'package:smart_ledger/utils/shopping_cart_next_prep_utils.dart';
import 'package:smart_ledger/widgets/smart_input_field.dart';
import 'package:smart_ledger/widgets/zero_quick_buttons.dart';
// import 'package:smart_ledger/screens/nutrition_report_screen.dart';
// Feature connections removed per request.

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
  bool _isLoading = true;
  List<ShoppingCartItem> _items = const [];
  Map<String, CategoryHint> _categoryHints = const <String, CategoryHint>{};

  final ScrollController _listController = ScrollController();
  final Map<String, GlobalKey> _itemTileKeys = <String, GlobalKey>{};

  bool _zeroQuickEnabled = false;

  bool _didAutoOpenPrep = false;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _unitPriceControllers = {};
  final Map<String, TextEditingController> _memoControllers = {};

  final Map<String, FocusNode> _qtyFocusNodes = {};
  final Map<String, FocusNode> _unitPriceFocusNodes = {};
  final Map<String, FocusNode> _memoFocusNodes = {};

  String _unitPriceTextForInlineEditor(double unitPrice) {
    if (unitPrice <= 0) return '';
    return unitPrice == unitPrice.roundToDouble()
        ? CurrencyFormatter.format(unitPrice, showUnit: false)
        : CurrencyFormatter.formatWithDecimals(unitPrice, showUnit: false);
  }

  InputDecoration _inlineFieldDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  BuildContext? _itemContext(String id) {
    return _itemTileKeys[id]?.currentContext;
  }

  void _ensureVisible(
    BuildContext? context, {
    double alignment = 0.2,
    int durationMs = 160,
  }) {
    if (context == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        Scrollable.ensureVisible(
          context,
          alignment: alignment,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    });
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

  Future<void> _loadZeroQuickSetting() async {
    final lang = await UserPrefService.getLanguageCode();
    final enabled = await UserPrefService.getZeroQuickButtonsEnabled();
    if (!mounted) return;
    // Apply this feature only for Korean locale.
    setState(() => _zeroQuickEnabled = (lang == 'ko') && enabled);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _listController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final c in _unitPriceControllers.values) {
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

    final memoFocusRemoved = _memoFocusNodes.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in memoFocusRemoved.toList(growable: false)) {
      _memoFocusNodes.remove(k)?.dispose();
    }

    for (final item in next) {
      final qty = item.quantity <= 0 ? 1 : item.quantity;
      final qtyText = qty.toString();
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

    // Settings are global and can be loaded in parallel.
    await _loadZeroQuickSetting();

    final items = await UserPrefService.getShoppingCartItems(
      accountName: widget.accountName,
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

    if (!mounted) return;
    if (widget.openPrepOnStart && !_didAutoOpenPrep) {
      _didAutoOpenPrep = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ShoppingCartNextPrepUtils.run(
          context: context,
          accountName: widget.accountName,
          getItems: () => _items,
          getCategoryHints: () => _categoryHints,
          saveItems: _save,
          reload: _load,
          showChooser: false,
        );
      });
    }
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
    final qtyRaw = _qtyControllers[item.id]?.text.trim() ?? '';
    final unitRaw = _unitPriceControllers[item.id]?.text.trim() ?? '';
    final memoRaw = _memoControllers[item.id]?.text.trim() ?? item.memo;

    final parsedQty = int.tryParse(qtyRaw);
    final parsedUnit = CurrencyFormatter.parse(unitRaw);

    final nextQty = (parsedQty == null)
        ? item.quantity
        : (parsedQty <= 0 ? 1 : parsedQty);
    final nextUnit = (parsedUnit == null) ? item.unitPrice : parsedUnit;
    final nextMemo = memoRaw;

    if (nextQty == item.quantity &&
        nextUnit == item.unitPrice &&
        nextMemo == item.memo) {
      return;
    }

    final now = DateTime.now();
    final updated = item.copyWith(
      quantity: nextQty,
      unitPrice: nextUnit,
      memo: nextMemo,
      updatedAt: now,
    );
    final next = _items.map((i) => i.id == item.id ? updated : i).toList();
    await _save(next);
  }

  Future<void> _editItemMemo(ShoppingCartItem item) async {
    FocusScope.of(context).unfocus();

    final controller = TextEditingController(text: item.memo);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('메모'),
        content: SmartInputField(
          hint: '특이사항을 적어두세요',
          controller: controller,
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (!mounted) return;
    if (result == null) return;

    final nextMemo = result;
    if (nextMemo == item.memo) return;

    final updated = item.copyWith(memo: nextMemo, updatedAt: DateTime.now());
    final next = _items.map((i) => i.id == item.id ? updated : i).toList();
    await _save(next);
  }

  void _previewInlineEdits(ShoppingCartItem item) {
    final qtyRaw = _qtyControllers[item.id]?.text.trim() ?? '';
    final unitRaw = _unitPriceControllers[item.id]?.text.trim() ?? '';
    final memoRaw = _memoControllers[item.id]?.text.trim() ?? item.memo;

    final parsedQty = int.tryParse(qtyRaw);
    final parsedUnit = CurrencyFormatter.parse(unitRaw);

    final nextQty = (parsedQty == null)
        ? item.quantity
        : (parsedQty <= 0 ? 1 : parsedQty);
    final nextUnit = (parsedUnit == null) ? item.unitPrice : parsedUnit;
    final nextMemo = memoRaw;

    if (nextQty == item.quantity &&
        nextUnit == item.unitPrice &&
        nextMemo == item.memo) {
      return;
    }

    final updated = item.copyWith(
      quantity: nextQty,
      unitPrice: nextUnit,
      memo: nextMemo,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _items = _items.map((i) => i.id == item.id ? updated : i).toList();
    });
  }

  Future<void> _navigateToQuickTransaction(
    ShoppingCartItem item, {
    required String qtyText,
    required String unitText,
  }) async {
    final parsedQty = int.tryParse(qtyText) ?? item.quantity;
    final parsedUnit = CurrencyFormatter.parse(unitText) ?? item.unitPrice;
    final amount = parsedUnit * (parsedQty <= 0 ? 1 : parsedQty);

    final result = await Navigator.of(context).pushNamed(
      AppRoutes.shoppingCartQuickTransaction,
      arguments: ShoppingCartQuickTransactionArgs(
        accountName: widget.accountName,
        title: '지출 입력',
        description: item.name,
        total: amount,
        quantity: parsedQty <= 0 ? 1 : parsedQty,
        unitPrice: parsedUnit,
        previewLines: [item.name],
      ),
    );

    if (result == true) {
      _deleteItem(item);
    }
  }

  void _switchToCart() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.shoppingCart,
      arguments: ShoppingCartArgs(accountName: widget.accountName),
    );
  }

  void _switchToPrep() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.shoppingPrep,
      arguments: ShoppingCartArgs(accountName: widget.accountName),
    );
  }

  void _showInlineInputWarning(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isUnitOkForSubmit(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return true;

    final parsed = CurrencyFormatter.parse(raw);
    if (parsed == null) {
      _showInlineInputWarning('가격 형식이 올바르지 않습니다');
      return false;
    }
    if (parsed < 0) {
      _showInlineInputWarning('가격은 0 이상이어야 합니다');
      return false;
    }
    return true;
  }

  bool _isQtyOkForSubmit(String text) {
    final raw = text.trim();
    if (raw.isEmpty) {
      _showInlineInputWarning('수량을 입력하세요');
      return false;
    }

    final parsed = int.tryParse(raw);
    if (parsed == null) {
      _showInlineInputWarning('수량 형식이 올바르지 않습니다');
      return false;
    }
    if (parsed <= 0) {
      _showInlineInputWarning('수량은 1 이상이어야 합니다');
      return false;
    }
    return true;
  }

  Widget _buildWideItemTile({
    required BuildContext context,
    required ShoppingCartItem item,
    required bool isSelected,
    required TextEditingController qtyController,
    required TextEditingController unitController,
    required TextEditingController memoController,
    required FocusNode qtyFocusNode,
    required FocusNode unitFocusNode,
    required FocusNode memoFocusNode,
    required ThemeData theme,
    required Widget memoButton,
  }) {
    final isPrep = widget.openPrepOnStart;
    const unitKeyboardType = TextInputType.numberWithOptions(decimal: true);

    return InkWell(
      onTap: !isPrep ? () => _toggleCheckedFast(item) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: isSelected ? theme.colorScheme.primaryContainer : null,
        child: Row(
          children: [
            if (!isPrep)
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: item.isChecked,
                  onChanged: (_) => _toggleCheckedFast(item),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: TextField(
                controller: unitController,
                focusNode: unitFocusNode,
                keyboardType: unitKeyboardType,
                style: theme.textTheme.bodySmall,
                decoration: _inlineFieldDecoration('가격'),
                onChanged: (_) => _previewInlineEdits(item),
                onEditingComplete: () => _applyInlineEdits(item),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 45,
              child: TextField(
                controller: qtyController,
                focusNode: qtyFocusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: theme.textTheme.bodySmall,
                decoration: _inlineFieldDecoration('수량'),
                onChanged: (_) => _previewInlineEdits(item),
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
                decoration: _inlineFieldDecoration('메모'),
                onChanged: (_) => _previewInlineEdits(item),
                onEditingComplete: () => _applyInlineEdits(item),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: Text(
                CurrencyFormatter.format(
                  (CurrencyFormatter.parse(unitController.text) ?? 0) *
                      (int.tryParse(qtyController.text) ?? 1),
                ),
                textAlign: TextAlign.end,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            if (!isPrep) ...[
              IconButton(
                tooltip: '지출 입력으로 이동',
                onPressed: () => _navigateToQuickTransaction(
                  item,
                  qtyText: qtyController.text,
                  unitText: unitController.text,
                ),
                icon: const Icon(Icons.open_in_new, size: 20),
              ),
              memoButton,
            ] else
              IconButton(
                tooltip: '삭제',
                onPressed: () => _deleteItemWithUndo(item),
                icon: const Icon(IconCatalog.deleteOutline),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitchBar({required ThemeData theme}) {
    final isPrep = widget.openPrepOnStart;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      final activeStyle = theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      );
      final inactiveStyle = theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      );

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _switchToPrep,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('쇼핑준비', style: isPrep ? activeStyle : inactiveStyle),
            ),
          ),
          Text(
            '/',
            style: TextStyle(
              color: theme.colorScheme.outlineVariant,
              fontSize: 12,
            ),
          ),
          GestureDetector(
            onTap: _switchToCart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('장바구니', style: !isPrep ? activeStyle : inactiveStyle),
            ),
          ),
        ],
      );
    }

    const height = 36.0;
    const radius = 18.0;

    final activeTextStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onPrimary,
    );
    final inactiveTextStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget segment({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      required BorderRadius borderRadius,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: selected ? activeTextStyle : inactiveTextStyle,
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              segment(
                label: '쇼핑준비',
                selected: isPrep,
                onTap: _switchToPrep,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(radius),
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: theme.colorScheme.outlineVariant,
              ),
              segment(
                label: '장바구니',
                selected: !isPrep,
                onTap: _switchToCart,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(radius),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ShoppingCartItem> _orderedItems(List<ShoppingCartItem> list) {
    // Keep list order, but group by purchase state:
    // - 미구매(체크 안 됨) 먼저
    // - 구매완료(체크됨) 나중
    // Within each group, preserve the original order (stable).
    final unChecked = <ShoppingCartItem>[];
    final checked = <ShoppingCartItem>[];
    for (final item in list) {
      (item.isChecked ? checked : unChecked).add(item);
    }
    return [...unChecked, ...checked];
  }

  Future<void> _addItem({bool keepKeyboardOpen = false}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final now = DateTime.now();
    final item = ShoppingCartItem(
      id: 'shop_${now.microsecondsSinceEpoch}',
      name: name,
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

  Future<void> _toggleCheckedFast(ShoppingCartItem item) async {
    // Fast toggle for in-store usage: tap item name to mark/unmark without
    // confirmation, then keep the user's scroll position focused on the next
    // item around the same index.
    final beforeOrdered = _orderedItems(_items);
    final beforeIndex = beforeOrdered.indexWhere((i) => i.id == item.id);

    final now = DateTime.now();
    final updated = item.copyWith(isChecked: !item.isChecked, updatedAt: now);
    final next = _items.map((i) => i.id == item.id ? updated : i).toList();
    await _save(next);

    if (!mounted) return;

    final afterOrdered = _orderedItems(next);
    if (afterOrdered.isEmpty) return;

    final targetIndex = (beforeIndex < 0)
        ? 0
        : beforeIndex.clamp(0, afterOrdered.length - 1);
    final targetId = afterOrdered[targetIndex].id;
    final ctx = _itemTileKeys[targetId]?.currentContext;
    if (ctx == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final liveCtx = _itemTileKeys[targetId]?.currentContext;
      if (liveCtx == null) return;
      Scrollable.ensureVisible(
        liveCtx,
        alignment: 0.2,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
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

  Future<void> _deleteCheckedItems() async {
    final checked = _items.where((i) => i.isChecked).toList();
    if (checked.isEmpty) {
      _showInlineInputWarning('삭제할 항목을 선택하세요');
      return;
    }

    final prev = List<ShoppingCartItem>.from(_items);
    final next = _items.where((i) => !i.isChecked).toList();
    await _save(next);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${checked.length}개 항목이 삭제되었습니다'),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () async {
            await _save(prev);
          },
        ),
      ),
    );
  }

  Future<void> _clearAllWithUndo() async {
    if (_items.isEmpty) return;
    final prev = List<ShoppingCartItem>.from(_items);
    await _save(const []);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('장바구니를 비웠습니다'),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () async {
            await _save(prev);
          },
        ),
      ),
    );
  }

  Future<void> _addCheckedItemsToLedgerBulk() async {
    await ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk(
      context: context,
      accountName: widget.accountName,
      items: _items,
      categoryHints: _categoryHints,
      saveItems: _save,
      reload: _load,
    );
  }

  Future<void> _addCheckedItemsToLedgerMartShopping() async {
    await ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerMartShopping(
      context: context,
      accountName: widget.accountName,
      items: _items,
      categoryHints: _categoryHints,
      saveItems: _save,
      reload: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isPrep = widget.openPrepOnStart;
    const nameFieldHeight = 48.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    void runShoppingPrep({required bool showChooser}) {
      ShoppingCartNextPrepUtils.run(
        context: context,
        accountName: widget.accountName,
        getItems: () => _items,
        getCategoryHints: () => _categoryHints,
        saveItems: _save,
        reload: _load,
        showChooser: showChooser,
      );
    }

    final ordered = _orderedItems(_items);
    final checkedCount = _items.where((i) => i.isChecked).length;
    TextEditingController? activeNumericController() {
      if (!_zeroQuickEnabled) return null;
      if (widget.openPrepOnStart) return null;

      for (final item in ordered) {
        final unitNode = _unitPriceFocusNodes[item.id];
        if (unitNode?.hasFocus ?? false) {
          return _unitPriceControllers[item.id];
        }
        final qtyNode = _qtyFocusNodes[item.id];
        if (qtyNode?.hasFocus ?? false) {
          return _qtyControllers[item.id];
        }
      }
      return null;
    }

    final activeController = activeNumericController();
    final quickButtonsHeight = (activeController != null) ? 64.0 : 0.0;

    return Scaffold(
      backgroundColor: isPrep
          ? theme.colorScheme.surfaceContainerLowest
          : theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            _buildModeSwitchBar(theme: theme),
            if (!isPrep) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: '선택 항목 삭제',
                onPressed: _isLoading ? null : _deleteCheckedItems,
                icon: Icon(
                  IconCatalog.deleteOutline,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: widget.openPrepOnStart
            ? [
                Tooltip(
                  message: '쇼핑 준비 (탭: 빠른 실행, 길게: 메뉴)',
                  child: GestureDetector(
                    onLongPress: _isLoading
                        ? null
                        : () => runShoppingPrep(showChooser: true),
                    child: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => runShoppingPrep(showChooser: false),
                      icon: const Icon(IconCatalog.eventRepeat),
                    ),
                  ),
                ),
              ]
            : [
                IconButton(
                  tooltip: '남은 항목 모두 삭제',
                  onPressed: (_isLoading || _items.isEmpty)
                      ? null
                      : _clearAllWithUndo,
                  icon: const Icon(IconCatalog.deleteSweepOutlined),
                ),
              ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isPortrait ? 68 : 56),
          child: Padding(
            padding: isPortrait
                ? const EdgeInsets.fromLTRB(16, 0, 10, 10)
                : const EdgeInsets.fromLTRB(16, 0, 10, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: isPortrait ? nameFieldHeight : 44,
                    child: SmartInputField(
                      compact: true,
                      label: '물품 이름',
                      hint: isPrep ? null : '장바구니 모드',
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
      bottomNavigationBar: (!_isLoading)
          ? (widget.openPrepOnStart
                ? null
                : _buildCheckedSummaryBar(
                    theme: theme,
                    checkedCount: checkedCount,
                  ))
          : null,
      bottomSheet: (activeController != null)
          ? SafeArea(
              top: false,
              child: Material(
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: ZeroQuickButtons(
                    controller: activeController,
                    formatThousands: true,
                    onChanged: () {
                      // Preview only; persistence happens on submit/unfocus.
                      setState(() {});
                    },
                  ),
                ),
              ),
            )
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
                        controller: _listController,
                        padding: EdgeInsets.only(
                          bottom:
                              bottomInset +
                              (isPrep ? 24 : 240) +
                              quickButtonsHeight,
                        ),
                        itemCount: ordered.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = ordered[index];

                          final tileKey = _itemTileKeys.putIfAbsent(
                            item.id,
                            GlobalKey.new,
                          );

                          // Ensure inline editors exist even if controllers
                          // temporarily go out-of-sync (e.g. fast rebuilds).
                          _qtyControllers.putIfAbsent(
                            item.id,
                            () => TextEditingController(
                              text: (item.quantity <= 0 ? 1 : item.quantity)
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
                          _memoControllers.putIfAbsent(
                            item.id,
                            () => TextEditingController(text: item.memo),
                          );
                          _qtyFocusNodes.putIfAbsent(item.id, FocusNode.new);
                          _unitPriceFocusNodes.putIfAbsent(
                            item.id,
                            FocusNode.new,
                          );
                          _memoFocusNodes.putIfAbsent(item.id, FocusNode.new);

                          final isCartMode = !widget.openPrepOnStart;
                          final isSelected = isCartMode && item.isChecked;

                          final qtyController = _qtyControllers[item.id]!;
                          final unitController =
                              _unitPriceControllers[item.id]!;
                          final memoController = _memoControllers[item.id]!;
                          final qtyFocusNode = _qtyFocusNodes[item.id]!;
                          final unitFocusNode = _unitPriceFocusNodes[item.id]!;
                          final memoFocusNode = _memoFocusNodes[item.id]!;
                          const unitKeyboardType =
                              TextInputType.numberWithOptions(decimal: true);

                          final isPortrait =
                              MediaQuery.of(context).orientation ==
                              Orientation.portrait;

                          Widget buildMemoButton() {
                            return SizedBox(
                              width: 28,
                              height: 28,
                              child: Tooltip(
                                message: '메모',
                                child: TextButton(
                                  onPressed: () => _editItemMemo(item),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(28, 28),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: item.memo.trim().isNotEmpty
                                        ? theme.colorScheme.tertiary
                                        : theme.colorScheme.onSurfaceVariant,
                                    textStyle: theme.textTheme.labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  child: const Text('ㅁ'),
                                ),
                              ),
                            );
                          }

                          final tile = isPortrait
                              ? ListTile(
                                  contentPadding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                        12,
                                        4,
                                        8,
                                        4,
                                      ),
                                  selected: isSelected,
                                  selectedTileColor:
                                      theme.colorScheme.primaryContainer,
                                  leading: widget.openPrepOnStart
                                      ? null
                                      : SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: Center(
                                            child: Transform.scale(
                                              scale: 0.85,
                                              child: Checkbox(
                                                value: item.isChecked,
                                                onChanged: (_) =>
                                                    _toggleCheckedFast(item),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            ),
                                          ),
                                        ),
                                  horizontalTitleGap: 6,
                                  minLeadingWidth: 40,
                                  title: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? theme
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                : theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: TextField(
                                            controller: unitController,
                                            focusNode: unitFocusNode,
                                            keyboardType: unitKeyboardType,
                                            textInputAction:
                                                TextInputAction.next,
                                            style: theme.textTheme.bodySmall,
                                            decoration: _inlineFieldDecoration(
                                              '가격',
                                            ),
                                            onChanged: (_) =>
                                                _previewInlineEdits(item),
                                            onTapOutside: (_) {
                                              FocusScope.of(context).unfocus();
                                              _applyInlineEdits(item);
                                            },
                                            onEditingComplete: () =>
                                                _applyInlineEdits(item),
                                            onSubmitted: (_) {
                                              final isUnitOk =
                                                  _isUnitOkForSubmit(
                                                    unitController.text,
                                                  );
                                              if (!isUnitOk) {
                                                unitFocusNode.requestFocus();
                                                unitController
                                                    .selection = TextSelection(
                                                  baseOffset: 0,
                                                  extentOffset: unitController
                                                      .text
                                                      .length,
                                                );
                                                return;
                                              }
                                              _applyInlineEdits(item);
                                              qtyFocusNode.requestFocus();
                                              _ensureVisible(context);
                                            },
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          CurrencyFormatter.format(
                                            (CurrencyFormatter.parse(
                                                      unitController.text,
                                                    ) ??
                                                    0) *
                                                (int.tryParse(
                                                      qtyController.text,
                                                    ) ??
                                                    1),
                                          ),
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!widget.openPrepOnStart) ...[
                                        SizedBox(
                                          width: 45,
                                          child: TextField(
                                            controller: qtyController,
                                            focusNode: qtyFocusNode,
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            textInputAction:
                                                TextInputAction.next,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            decoration:
                                                _inlineFieldDecoration(
                                                  '수량',
                                                ).copyWith(
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 4,
                                                        vertical: 8,
                                                      ),
                                                ),
                                            onChanged: (_) =>
                                                _previewInlineEdits(item),
                                            onTapOutside: (_) {
                                              FocusScope.of(context).unfocus();
                                              _applyInlineEdits(item);
                                            },
                                            onEditingComplete: () =>
                                                _applyInlineEdits(item),
                                            onSubmitted: (_) {
                                              final isQtyOk = _isQtyOkForSubmit(
                                                qtyController.text,
                                              );
                                              if (!isQtyOk) {
                                                qtyFocusNode.requestFocus();
                                                qtyController
                                                    .selection = TextSelection(
                                                  baseOffset: 0,
                                                  extentOffset:
                                                      qtyController.text.length,
                                                );
                                                return;
                                              }
                                              _applyInlineEdits(item);
                                              if (index + 1 < ordered.length) {
                                                final nextItem =
                                                    ordered[index + 1];
                                                final nextId = nextItem.id;
                                                final nodes =
                                                    _unitPriceFocusNodes;
                                                final nextNode = nodes[nextId];
                                                if (nextNode != null) {
                                                  nextNode.requestFocus();
                                                  final liveCtx = _itemContext(
                                                    nextId,
                                                  );
                                                  _ensureVisible(
                                                    liveCtx,
                                                    durationMs: 180,
                                                  );
                                                } else {
                                                  qtyFocusNode.requestFocus();
                                                }
                                              } else {
                                                qtyFocusNode.requestFocus();
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: memoController,
                                            focusNode: memoFocusNode,
                                            style: theme.textTheme.bodySmall,
                                            decoration: _inlineFieldDecoration(
                                              '메모',
                                            ),
                                            onChanged: (_) =>
                                                _previewInlineEdits(item),
                                            onTapOutside: (_) {
                                              FocusScope.of(context).unfocus();
                                              _applyInlineEdits(item);
                                            },
                                            onEditingComplete: () =>
                                                _applyInlineEdits(item),
                                            onSubmitted: (_) =>
                                                _applyInlineEdits(item),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: '지출 입력으로 이동',
                                          onPressed: () =>
                                              _navigateToQuickTransaction(
                                                item,
                                                qtyText: qtyController.text,
                                                unitText: unitController.text,
                                              ),
                                          icon: const Icon(
                                            Icons.open_in_new,
                                            size: 20,
                                          ),
                                        ),
                                        buildMemoButton(),
                                      ] else
                                        IconButton(
                                          tooltip: '삭제',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 44,
                                            minHeight: 44,
                                          ),
                                          onPressed: () =>
                                              _deleteItemWithUndo(item),
                                          icon: const Icon(
                                            IconCatalog.deleteOutline,
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: (!widget.openPrepOnStart)
                                      ? () => _toggleCheckedFast(item)
                                      : null,
                                )
                              : _buildWideItemTile(
                                  context: context,
                                  item: item,
                                  isSelected: isSelected,
                                  qtyController: qtyController,
                                  unitController: unitController,
                                  memoController: memoController,
                                  qtyFocusNode: qtyFocusNode,
                                  unitFocusNode: unitFocusNode,
                                  memoFocusNode: memoFocusNode,
                                  theme: theme,
                                  memoButton: buildMemoButton(),
                                );

                          return KeyedSubtree(key: tileKey, child: tile);
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

  Widget _buildCheckedSummaryBar({
    required ThemeData theme,
    required int checkedCount,
  }) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final cartTotal = _items.fold<double>(0, (sum, item) {
      final qty = item.quantity <= 0 ? 1 : item.quantity;
      return sum + (item.unitPrice * qty);
    });

    final checkedTotal = _items.where((i) => i.isChecked).fold<double>(0, (
      sum,
      item,
    ) {
      final qty = item.quantity <= 0 ? 1 : item.quantity;
      return sum + (item.unitPrice * qty);
    });

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

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
          padding: isPortrait
              ? const EdgeInsets.fromLTRB(16, 14, 16, 16)
              : const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: isPortrait
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '장바구니 합계',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(cartTotal),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '체크 항목',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '총액 ${CurrencyFormatter.format(checkedTotal)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$checkedCount개',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                (!widget.openPrepOnStart && checkedCount > 0)
                                ? _addCheckedItemsToLedgerMartShopping
                                : null,
                            child: const Text('마트 쇼핑 입력'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed:
                                (!widget.openPrepOnStart && checkedCount > 0)
                                ? _addCheckedItemsToLedgerBulk
                                : null,
                            child: Text('일괄 입력 ($checkedCount)'),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '합계: ${CurrencyFormatter.format(cartTotal)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '체크: ${CurrencyFormatter.format(checkedTotal)} '
                            '($checkedCount개)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: (!widget.openPrepOnStart && checkedCount > 0)
                          ? _addCheckedItemsToLedgerMartShopping
                          : null,
                      child: const Text('마트 쇼핑'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: (!widget.openPrepOnStart && checkedCount > 0)
                          ? _addCheckedItemsToLedgerBulk
                          : null,
                      child: Text('일괄 입력 ($checkedCount)'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
