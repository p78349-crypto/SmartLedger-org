import 'package:flutter/material.dart';
import '../models/category_hint.dart';
import '../models/shopping_cart_history_entry.dart';
import '../models/shopping_cart_item.dart';
import '../navigation/app_routes.dart';
import '../services/food_expiry_service.dart';
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

  final Map<String, bool> _qtyFirstFocus = {};
  final Map<String, bool> _unitPriceFirstFocus = {};
  final Map<String, bool> _bundleSizeFirstFocus = {};

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
      final qtyVal = item.bundleCount < 0 ? 0 : item.bundleCount;
      final qtyText = qtyVal == 0 ? '' : qtyVal.toString();
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
        _qtyFirstFocus[item.id] = true;
        node.addListener(() {
          if (node.hasFocus && (_qtyFirstFocus[item.id] ?? false)) {
            _qtyFirstFocus[item.id] = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (node.hasFocus) {
                final c = _qtyControllers[item.id];
                if (c != null) {
                  c.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: c.text.length,
                  );
                }
              }
            });
          }
          if (mounted) setState(() {});
        });
        return node;
      });

      final perBundleVal = item.unitsPerBundle < 0 ? 0 : item.unitsPerBundle;
      final perBundleText = perBundleVal == 0 ? '' : perBundleVal.toString();
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
        _bundleSizeFirstFocus[item.id] = true;
        node.addListener(() {
          if (node.hasFocus && (_bundleSizeFirstFocus[item.id] ?? false)) {
            _bundleSizeFirstFocus[item.id] = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (node.hasFocus) {
                final c = _bundleSizeControllers[item.id];
                if (c != null) {
                  c.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: c.text.length,
                  );
                }
              }
            });
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
        _unitPriceFirstFocus[item.id] = true;
        node.addListener(() {
          if (node.hasFocus && (_unitPriceFirstFocus[item.id] ?? false)) {
            _unitPriceFirstFocus[item.id] = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (node.hasFocus) {
                final c = _unitPriceControllers[item.id];
                if (c != null) {
                  c.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: c.text.length,
                  );
                }
              }
            });
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
          items.insert(0, initItem);
        }
      }
      // Save merged list back to prefs
      final limited = items.take(30).toList();
      await UserPrefService.setShoppingCartItems(
        accountName: widget.accountName,
        items: limited,
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
    // 30건으로 제한 (최근 등록 순)
    final limited = next.take(30).toList();
    setState(() => _items = limited);
    _syncInlineControllers(limited);
    await UserPrefService.setShoppingCartItems(
      accountName: widget.accountName,
      items: limited,
    );
  }

  String _formatDateLabel(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _navigateToDetailedInput() {
    Navigator.of(context).pushNamed(
      AppRoutes.transactionAddDetailed,
      arguments: TransactionAddArgs(accountName: widget.accountName),
    );
  }

  Future<void> _openRecentPurchasePicker() async {
    final history = await UserPrefService.getShoppingCartHistory(
      accountName: widget.accountName,
      limit: 500,
    );

    if (!mounted) return;

    final cutoff = DateTime.now().subtract(const Duration(days: 10));
    final recent = history.where((e) => e.at.isAfter(cutoff)).toList();
    if (recent.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최근 10일 구매 내역이 없습니다.')));
      return;
    }

    recent.sort((a, b) => b.at.compareTo(a.at));
    final selected = <String, bool>{};

    // 날짜별 그룹화
    final grouped = <String, List<ShoppingCartHistoryEntry>>{};
    for (final entry in recent) {
      final dateKey = _formatDateLabel(entry.at);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final picked = await showModalBottomSheet<List<ShoppingCartHistoryEntry>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, controller) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                final selectedCount = selected.values.where((v) => v).length;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Text(
                            '최근 10일 구매 리스트',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text('$selectedCount개 선택'),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: sortedDates.length,
                        itemBuilder: (ctx, dateIndex) {
                          final dateStr = sortedDates[dateIndex];
                          final dateItems = grouped[dateStr]!;
                          final allChecked = dateItems.every(
                            (e) => selected[e.id] == true,
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${dateItems.length}개 항목',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setSheetState(() {
                                        for (final entry in dateItems) {
                                          selected[entry.id] = !allChecked;
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      allChecked
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 20,
                                    ),
                                    label: Text(allChecked ? '선택해제' : '전체선택'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                              children: dateItems.map((entry) {
                                final isChecked = selected[entry.id] ?? false;
                                final qtyLabel = '${entry.quantity}개';
                                final priceLabel = CurrencyFormatter.format(
                                  entry.unitPrice,
                                );
                                return CheckboxListTile(
                                  value: isChecked,
                                  onChanged: (v) {
                                    setSheetState(() {
                                      selected[entry.id] = v ?? false;
                                    });
                                  },
                                  title: Text(entry.name),
                                  subtitle: Text('$qtyLabel · $priceLabel'),
                                  dense: true,
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('취소'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: selectedCount == 0
                                  ? null
                                  : () {
                                      final picked = recent
                                          .where((e) => selected[e.id] == true)
                                          .toList();
                                      Navigator.pop(ctx, picked);
                                    },
                              child: const Text('장바구니 추가'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (picked == null || picked.isEmpty) return;

    final now = DateTime.now();
    final nextItems = List<ShoppingCartItem>.from(_items);

    for (var i = 0; i < picked.length; i++) {
      final entry = picked[i];
      final item = ShoppingCartItem(
        id: 'shop_${now.microsecondsSinceEpoch}_$i',
        name: entry.name,
        quantity: entry.quantity <= 0 ? 1 : entry.quantity,
        unitPrice: entry.unitPrice,
        createdAt: now,
        updatedAt: now,
      );
      nextItems.insert(0, item);
    }

    await _save(nextItems);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${picked.length}개 항목을 장바구니에 추가했습니다.')),
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
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
            width: 140,
            height: _inlineFieldHeight,
            child: TextField(
              key: ValueKey('sc_price_${item.id}'),
              controller: unitController,
              focusNode: unitFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
          // 재고수량 표시
          SizedBox(
            width: 60,
            height: _inlineFieldHeight,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '재고',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _getStockQuantity(item.name),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
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
                      ? theme.colorScheme.surfaceContainerHighest
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
                          ? theme.colorScheme.onSurfaceVariant
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
    await _flushInlineEdits();
    if (!mounted) return;
    await ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk(
      context: context,
      accountName: widget.accountName,
      items: _items,
      categoryHints: _categoryHints,
      saveItems: _save,
      reload: _load,
    );
  }

  Future<void> _flushInlineEdits() async {
    bool changed = false;
    final next = _items
        .map((item) {
          final bundleRaw = _qtyControllers[item.id]?.text.trim() ?? '';
          final perBundleRaw =
              _bundleSizeControllers[item.id]?.text.trim() ?? '';
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
            return item;
          }

          changed = true;
          return item.copyWith(
            bundleCount: nextBundle,
            unitsPerBundle: nextPerBundle,
            quantity: nextQty,
            unitPrice: nextUnit,
            memo: nextMemo,
            updatedAt: DateTime.now(),
          );
        })
        .toList(growable: false);

    if (changed) {
      await _save(next);
    }
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
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // 레시피 메뉴로 돌아가기 버튼
              IconButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.recipeManagement,
                  arguments: RecipeManagementArgs(
                    accountName: widget.accountName,
                  ),
                ),
                icon: const Icon(Icons.restaurant_menu),
                tooltip: '레시피 메뉴',
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  foregroundColor: theme.colorScheme.onTertiaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('체크 항목', style: theme.textTheme.labelSmall),
                    Text(
                      CurrencyFormatter.format(checkedTotal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: checkedCount > 0 ? _openTransactionAdd : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  disabledBackgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

  /// 재고에서 해당 품목의 수량을 가져옴
  String _getStockQuantity(String itemName) {
    final inventory = FoodExpiryService.instance.items.value;
    final trimmedName = itemName.trim().toLowerCase();

    for (final item in inventory) {
      final stockName = item.name.trim().toLowerCase();
      if (stockName == trimmedName ||
          stockName.contains(trimmedName) ||
          trimmedName.contains(stockName)) {
        // 정수일 경우 소수점 없이 표시
        if (item.quantity == item.quantity.toInt()) {
          return '${item.quantity.toInt()}';
        }
        return '${item.quantity}';
      }
    }
    return '-';
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
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(controller.text.trim());
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
          if (!isPrep)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _navigateToDetailedInput,
                  child: Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.pink, width: 2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.pink,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: '초기화',
            onPressed: _isLoading ? null : _confirmResetAll,
            icon: const Icon(Icons.restart_alt),
          ),
          if (!isPrep)
            TextButton(
              onPressed: _isLoading ? null : _openRecentPurchasePicker,
              child: const Text('최근 구매'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isPortrait ? 72 : 56),
          child: Padding(
            padding: isPortrait
                ? const EdgeInsets.fromLTRB(56, 6, 10, 10)
                : const EdgeInsets.fromLTRB(56, 6, 10, 6),
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
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                          _qtyControllers.putIfAbsent(item.id, () {
                            final val = item.bundleCount < 0
                                ? 0
                                : item.bundleCount;
                            return TextEditingController(
                              text: val == 0 ? '' : val.toString(),
                            );
                          });
                          _unitPriceControllers.putIfAbsent(
                            item.id,
                            () => TextEditingController(
                              text: _unitPriceTextForInlineEditor(
                                item.unitPrice,
                              ),
                            ),
                          );
                          _bundleSizeControllers.putIfAbsent(item.id, () {
                            final val = item.unitsPerBundle < 0
                                ? 0
                                : item.unitsPerBundle;
                            return TextEditingController(
                              text: val == 0 ? '' : val.toString(),
                            );
                          });
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
                                                  width: 140,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '가격',
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      SizedBox(
                                                        height:
                                                            _inlineFieldHeight,
                                                        child: TextField(
                                                          key: ValueKey(
                                                            'sc_price_${item.id}',
                                                          ),
                                                          controller:
                                                              unitController,
                                                          focusNode:
                                                              unitFocusNode,
                                                          keyboardType:
                                                              unitKeyboardType,
                                                          textInputAction:
                                                              TextInputAction
                                                                  .next,
                                                          style: theme
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                          decoration:
                                                              _inlineFieldDecoration(
                                                                theme,
                                                                '',
                                                              ),
                                                          onChanged: (_) =>
                                                              _previewInlineEdits(
                                                                item,
                                                              ),
                                                          onTapOutside: (_) {
                                                            FocusScope.of(
                                                              context,
                                                            ).unfocus();
                                                            _applyInlineEdits(
                                                              item,
                                                            );
                                                          },
                                                          onSubmitted: (_) {
                                                            _applyInlineEdits(
                                                              item,
                                                            );
                                                            // 가격 → 수량으로 이동
                                                            qtyFocusNode
                                                                .requestFocus();
                                                          },
                                                          onEditingComplete: () {
                                                            _applyInlineEdits(
                                                              item,
                                                            );
                                                            qtyFocusNode
                                                                .requestFocus();
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 56,
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        '수량',
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      SizedBox(
                                                        height:
                                                            _inlineFieldHeight,
                                                        child: TextField(
                                                          key: ValueKey(
                                                            'sc_qty_${item.id}',
                                                          ),
                                                          controller:
                                                              qtyController,
                                                          focusNode:
                                                              qtyFocusNode,
                                                          textAlign:
                                                              TextAlign.center,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          textInputAction:
                                                              TextInputAction
                                                                  .next,
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                          decoration:
                                                              _inlineFieldDecoration(
                                                                theme,
                                                                '',
                                                              ),
                                                          onChanged: (_) =>
                                                              _previewInlineEdits(
                                                                item,
                                                              ),
                                                          onSubmitted: (_) {
                                                            _applyInlineEdits(
                                                              item,
                                                            );
                                                            // 수량 → 개수로 이동
                                                            bundleSizeFocusNode
                                                                .requestFocus();
                                                          },
                                                          onEditingComplete: () {
                                                            _applyInlineEdits(
                                                              item,
                                                            );
                                                            bundleSizeFocusNode
                                                                .requestFocus();
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 56,
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        '개수',
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      SizedBox(
                                                        height:
                                                            _inlineFieldHeight,
                                                        child: TextField(
                                                          key: ValueKey(
                                                            'sc_units_${item.id}',
                                                          ),
                                                          controller:
                                                              bundleSizeController,
                                                          focusNode:
                                                              bundleSizeFocusNode,
                                                          textAlign:
                                                              TextAlign.center,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          textInputAction:
                                                              TextInputAction
                                                                  .done,
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                          decoration:
                                                              _inlineFieldDecoration(
                                                                theme,
                                                                '',
                                                              ),
                                                          onChanged: (_) =>
                                                              _previewInlineEdits(
                                                                item,
                                                              ),
                                                          onSubmitted: (_) {
                                                            _applyInlineEdits(
                                                              item,
                                                            );
                                                            // 개수 → 다음 아이템의 가격으로 이동
                                                            if (index + 1 <
                                                                ordered
                                                                    .length) {
                                                              final nextItem =
                                                                  ordered[index +
                                                                      1];
                                                              _unitPriceFocusNodes[nextItem
                                                                      .id]
                                                                  ?.requestFocus();
                                                            } else {
                                                              FocusScope.of(
                                                                context,
                                                              ).unfocus();
                                                            }
                                                          },
                                                          onEditingComplete: () =>
                                                              _applyInlineEdits(
                                                                item,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // 재고수량 표시
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 50,
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        '재고',
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        height:
                                                            _inlineFieldHeight,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration: BoxDecoration(
                                                          color: Colors.teal
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          border: Border.all(
                                                            color: Colors.teal,
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          _getStockQuantity(
                                                            item.name,
                                                          ),
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: theme
                                                                    .colorScheme
                                                                    .secondary,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
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
