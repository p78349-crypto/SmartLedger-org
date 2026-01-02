import 'package:flutter/material.dart';

import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/shopping_cart_bulk_ledger_utils.dart';
import 'package:smart_ledger/utils/shopping_cart_next_prep_utils.dart';
import 'package:smart_ledger/widgets/zero_quick_buttons.dart';
import 'package:smart_ledger/widgets/one_ui_input_field.dart';
import 'package:smart_ledger/screens/nutrition_report_screen.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({
    super.key,
    required this.accountName,
    this.openPrepOnStart = false,
  });

  final String accountName;
  final bool openPrepOnStart;

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

  final Map<String, FocusNode> _qtyFocusNodes = {};
  final Map<String, FocusNode> _unitPriceFocusNodes = {}; 

  String _unitPriceTextForInlineEditor(double unitPrice) {
    if (unitPrice <= 0) return '';
    return unitPrice == unitPrice.roundToDouble()
        ? CurrencyFormatter.format(unitPrice, showUnit: false)
        : CurrencyFormatter.formatWithDecimals(unitPrice, showUnit: false);
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
    for (final n in _qtyFocusNodes.values) {
      n.dispose();
    }
    for (final n in _unitPriceFocusNodes.values) {
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

    final unitFocusRemoved = _unitPriceFocusNodes.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in unitFocusRemoved.toList(growable: false)) {
      _unitPriceFocusNodes.remove(k)?.dispose();
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

    final parsedQty = int.tryParse(qtyRaw);
    final parsedUnit = CurrencyFormatter.parse(unitRaw);

    final nextQty = (parsedQty == null)
        ? item.quantity
        : (parsedQty <= 0 ? 1 : parsedQty);
    final nextUnit = (parsedUnit == null) ? item.unitPrice : parsedUnit;

    if (nextQty == item.quantity && nextUnit == item.unitPrice) {
      return;
    }

    final now = DateTime.now();
    final updated = item.copyWith(
      quantity: nextQty,
      unitPrice: nextUnit,
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
        content: OneUiInputField(
          hint: '특이사항을 적어두세요',
          controller: controller,
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
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

    final parsedQty = int.tryParse(qtyRaw);
    final parsedUnit = CurrencyFormatter.parse(unitRaw);

    final nextQty = (parsedQty == null)
        ? item.quantity
        : (parsedQty <= 0 ? 1 : parsedQty);
    final nextUnit = (parsedUnit == null) ? item.unitPrice : parsedUnit;

    if (nextQty == item.quantity && nextUnit == item.unitPrice) {
      return;
    }

    final updated = item.copyWith(
      quantity: nextQty,
      unitPrice: nextUnit,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _items = _items.map((i) => i.id == item.id ? updated : i).toList();
    });
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

  Widget _buildModeSwitchBar({required ThemeData theme}) {
    final isPrep = widget.openPrepOnStart;

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
      isPlanned: true,
      isChecked: false,
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

  Future<void> _confirmAndDeleteItem(ShoppingCartItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('"${item.name}"을(를) 삭제할까요?'),
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

    if (confirmed != true) return;
    await _deleteItem(item);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        centerTitle: true,
        title: _buildModeSwitchBar(theme: theme),
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
                IconButton(
                  tooltip: '영양 분석',
                  icon: const Icon(Icons.restaurant_menu),
                  onPressed: () {
                    final raw = _items
                        .map((i) => i.name.trim())
                        .where((s) => s.isNotEmpty)
                        .join('\n');

                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NutritionReportScreen(
                          rawText: raw,
                          onAddIngredient: (ingredient) async {
                            if (!mounted) return;
                            _nameController.text = ingredient;
                            await _addItem(keepKeyboardOpen: false);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ]
            : const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: nameFieldHeight,
                    child: OneUiInputField(
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
                  height: nameFieldHeight,
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
                          _qtyFocusNodes.putIfAbsent(item.id, FocusNode.new);
                          _unitPriceFocusNodes.putIfAbsent(
                            item.id,
                            FocusNode.new,
                          );

                          final isCartMode = !widget.openPrepOnStart;
                          final isSelected = isCartMode && item.isChecked;

                          final qtyController = _qtyControllers[item.id]!;
                          final unitController =
                              _unitPriceControllers[item.id]!;
                          final qtyFocusNode = _qtyFocusNodes[item.id]!;
                          final unitFocusNode = _unitPriceFocusNodes[item.id]!;
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
                                    foregroundColor:
                                        item.memo.trim().isNotEmpty
                                            ? theme.colorScheme.tertiary
                                            : theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                    textStyle: theme.textTheme.labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  child: const Text('ㅁ'),
                                ),
                              ),
                            );
                          }

                          final screenWidth = MediaQuery.sizeOf(context).width;
                          // Keep enough room for the item name on narrow
                          // devices by constraining the trailing editor width.
                          final maxTrailingWidth = (screenWidth * 0.55).clamp(
                            200.0,
                            290.0,
                          );

                          final tile = ListTile(
                            contentPadding:
                                const EdgeInsetsDirectional.fromSTEB(
                                  12,
                                  0,
                                  8,
                                  0,
                                ),
                            dense: true,
                            visualDensity: const VisualDensity(
                              horizontal: -2,
                              vertical: -2,
                            ),
                            minVerticalPadding: 0,
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
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ),
                                  ),
                            horizontalTitleGap: 6,
                            minLeadingWidth: 40,
                            title: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                item.name,
                                maxLines: isPortrait ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            subtitle: null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!widget.openPrepOnStart) ...[
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: maxTrailingWidth,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 96,
                                                child: TextField(
                                                  controller: unitController,
                                                  focusNode: unitFocusNode,
                                                  textAlign: TextAlign.end,
                                                  keyboardType: unitKeyboardType,
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  decoration:
                                                      const InputDecoration(
                                                        isDense: true,
                                                        hintText: '가격',
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                  onChanged: (_) =>
                                                      _previewInlineEdits(item),
                                                  onTapOutside: (_) {
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
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
                                                      unitFocusNode
                                                          .requestFocus();
                                                      unitController
                                                              .selection =
                                                          TextSelection(
                                                            baseOffset: 0,
                                                            extentOffset:
                                                                unitController
                                                                    .text
                                                                    .length,
                                                          );
                                                      return;
                                                    }

                                                    _applyInlineEdits(item);

                                                    // Fast-entry: always move to
                                                    // quantity after entering the
                                                    // unit price.
                                                    qtyFocusNode.requestFocus();
                                                    // Make sure the focused field is visible above the keyboard
                                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                                      if (!mounted) return;
                                                      try {
                                                        Scrollable.ensureVisible(
                                                          context,
                                                          alignment: 0.2,
                                                          duration: const Duration(milliseconds: 160),
                                                          curve: Curves.easeOut,
                                                        );
                                                      } catch (_) {}
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 48,
                                                child: TextField(
                                                  controller: qtyController,
                                                  focusNode: qtyFocusNode,
                                                  textAlign: TextAlign.end,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  decoration:
                                                      const InputDecoration(
                                                        isDense: true,
                                                        hintText: '수량',
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                  onChanged: (_) =>
                                                      _previewInlineEdits(item),
                                                  onTapOutside: (_) {
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                    _applyInlineEdits(item);
                                                  },
                                                  onEditingComplete: () =>
                                                      _applyInlineEdits(item),
                                                  onSubmitted: (_) {
                                                    final isQtyOk =
                                                        _isQtyOkForSubmit(
                                                          qtyController.text,
                                                        );
                                                    if (!isQtyOk) {
                                                      qtyFocusNode
                                                          .requestFocus();
                                                      qtyController
                                                              .selection =
                                                          TextSelection(
                                                            baseOffset: 0,
                                                            extentOffset:
                                                                qtyController
                                                                    .text
                                                                    .length,
                                                          );
                                                      return;
                                                    }

                                                    _applyInlineEdits(item);

                                                    if (index + 1 <
                                                        ordered.length) {
                                                      final nextItem =
                                                          ordered[index + 1];
                                                      final nextId =
                                                          nextItem.id;
                                                      final nodes =
                                                          _unitPriceFocusNodes;
                                                      final nextNode =
                                                          nodes[nextId];
                                                      if (nextNode != null) {
                                                        nextNode.requestFocus();
                                                        // Ensure the next item is visible (scroll into view)
                                                        WidgetsBinding.instance
                                                            .addPostFrameCallback(
                                                                (_) {
                                                          final liveCtx =
                                                              _itemTileKeys[nextId]
                                                                  ?.currentContext;
                                                          if (liveCtx == null) return;
                                                          try {
                                                            Scrollable.ensureVisible(
                                                              liveCtx,
                                                              alignment: 0.2,
                                                              duration: const Duration(
                                                                  milliseconds:
                                                                      180),
                                                              curve: Curves.easeOut,
                                                            );
                                                          } catch (_) {}
                                                        });
                                                      } else {
                                                        qtyFocusNode
                                                            .requestFocus();
                                                      }
                                                    } else {
                                                      qtyFocusNode
                                                          .requestFocus();
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                          ),
                                        ),
                                        buildMemoButton(),
                                        IconButton(
                                          tooltip: '삭제',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 44,
                                            minHeight: 44,
                                          ),
                                          onPressed: () =>
                                              _confirmAndDeleteItem(item),
                                          icon: const Icon(
                                            IconCatalog.deleteOutline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else
                                  IconButton(
                                    tooltip: '삭제',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 44,
                                      minHeight: 44,
                                    ),
                                    onPressed: () =>
                                        _confirmAndDeleteItem(item),
                                    icon: const Icon(
                                      IconCatalog.deleteOutline,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: (!widget.openPrepOnStart)
                                ? () => _toggleCheckedFast(item)
                                : null,
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
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
                      child: Text('체크 항목', style: theme.textTheme.bodyMedium),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (!widget.openPrepOnStart && checkedCount > 0)
                      ? _addCheckedItemsToLedgerBulk
                      : null,
                  child: Text('체크 항목 거래 입력 ($checkedCount)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

