import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/food_expiry_item.dart';
import '../models/recipe.dart';
import '../models/shopping_cart_item.dart';
import '../navigation/app_routes.dart';
import '../services/food_expiry_service.dart';
import '../services/health_guardrail_service.dart';
import '../services/recipe_learning_service.dart';
import '../services/replacement_cycle_notification_service.dart';
import '../services/savings_statistics_service.dart';
import '../services/user_pref_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/shopping_prep_utils.dart';
import '../widgets/cost_analysis_widget.dart';
import '../widgets/daily_recipe_recommendation_widget.dart';
import '../widgets/ingredients_recommendation_widget.dart';
import '../widgets/recipe_picker_dialog.dart';
import '../widgets/user_preferences_widget.dart';

class FoodExpiryItemsScreen extends StatefulWidget {
  final Future<void> Function(BuildContext, {FoodExpiryItem? existing})?
      onUpsert;
  final List<String>? initialIngredients;
  final bool autoUsageMode;
  final bool openCookableRecipePickerOnStart;
  final bool scrollToDailyRecipeRecommendationOnStart;

  const FoodExpiryItemsScreen({
    super.key,
    this.onUpsert,
    this.initialIngredients,
    this.autoUsageMode = false,
    this.openCookableRecipePickerOnStart = false,
    this.scrollToDailyRecipeRecommendationOnStart = false,
  });

  @override
  State<FoodExpiryItemsScreen> createState() => _FoodExpiryItemsScreenState();
}

class _UsageInput extends StatefulWidget {
  final double? initialValue;
  final double max;
  final String unit;
  final ValueChanged<double?> onChanged;

  const _UsageInput({
    required this.max,
    required this.unit,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<_UsageInput> createState() => _UsageInputState();
}

class _UsageInputState extends State<_UsageInput> {
  double? _value;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(
      text: _formatValue(widget.initialValue),
    );
  }

  @override
  void didUpdateWidget(covariant _UsageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
      _controller.value = TextEditingValue(
        text: _formatValue(widget.initialValue),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double? val) {
    if (val == null) return '';
    final isInt = (val % 1).abs() < 0.000001;
    return isInt ? val.toStringAsFixed(0) : val.toStringAsFixed(2);
  }

  void _bump(double delta) {
    final base = _value ?? 0;
    _setValue(base + delta);
  }

  void _setValue(double? next) {
    if (next != null) {
      final max = widget.max > 0 ? widget.max : 0;
      next = next.clamp(0, max).toDouble();
    }
    setState(() {
      _value = next;
      _controller.value = TextEditingValue(text: _formatValue(next));
    });
    widget.onChanged(next);
  }

  void _handleTextChanged(String raw) {
    final parsed = double.tryParse(raw.trim());
    setState(() => _value = parsed);
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove, color: iconColor),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: () => _bump(-1),
        ),
        SizedBox(
          width: 90,
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              suffixText: widget.unit,
            ),
            onChanged: _handleTextChanged,
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: iconColor),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: () => _bump(1),
        ),
      ],
    );
  }
}

class _FoodExpiryItemsScreenState extends State<FoodExpiryItemsScreen> {
  bool _isUsageMode = false;
  final Map<String, double> _usageMap = {};
  final Set<String> _activeUsageItems = {};

  final GlobalKey _dailyRecipeSectionKey = GlobalKey();

  String? _activeRecipeName;

  // 로케이션 필터
  String? _locationFilter;
  static const List<String> _locationOptions = [
    '전체',
    '냉장',
    '냉동',
    '실온',
    '김치냉장고',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.autoUsageMode) {
      _isUsageMode = true;
    }

    if (widget.scrollToDailyRecipeRecommendationOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _dailyRecipeSectionKey.currentContext;
        if (!mounted || ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.08,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }

    if (widget.openCookableRecipePickerOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showRecipePicker(onlyCookable: true);
      });
    }
  }

  List<String> _normalizeIngredientNames(List<String>? raw) {
    if (raw == null || raw.isEmpty) return const <String>[];
    final seen = <String>{};
    final out = <String>[];
    for (final v in raw) {
      final name = v.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.add(key)) out.add(name);
    }
    return out;
  }

  bool _ingredientMatchesItem(String ingredient, FoodExpiryItem item) {
    final ing = ingredient.trim().toLowerCase();
    if (ing.isEmpty) return false;
    final n = item.name.trim().toLowerCase();
    final c = item.category.trim().toLowerCase();
    return n.contains(ing) || ing.contains(n) || c.contains(ing);
  }

  List<FoodExpiryItem> _matchAllItemsForIngredient(
    String ingredient,
    List<FoodExpiryItem> items,
  ) {
    final matched =
        items.where((it) => _ingredientMatchesItem(ingredient, it)).toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return matched;
  }

  List<FoodExpiryItem> _matchAvailableItemsForIngredient(
    String ingredient,
    List<FoodExpiryItem> items,
  ) {
    return _matchAllItemsForIngredient(
      ingredient,
      items,
    ).where((it) => it.quantity > 0).toList();
  }

  String _formatQuantityValue(double quantity, String unit) {
    final isInt = quantity == quantity.toInt();
    final value = isInt ? quantity.toInt().toString() : '$quantity';
    return '$value$unit';
  }

  String _formatMatchedTotal(List<FoodExpiryItem> matched) {
    if (matched.isEmpty) return '0';
    final unit = matched.first.unit;
    final sameUnit = matched.every((it) => it.unit == unit);
    if (!sameUnit) return '${matched.length}개 항목';
    final sum = matched.fold<double>(0.0, (acc, it) => acc + it.quantity);
    return _formatQuantityValue(sum, unit);
  }

  void _showIngredientMatchesDetail(
    BuildContext context, {
    required String ingredientName,
    required List<FoodExpiryItem> matched,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$ingredientName 재고 (${matched.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: matched.length,
            itemBuilder: (ctx, i) {
              final it = matched[i];
              final left = it.daysLeft(DateTime.now());
              final expiry = DateFormat('yyyy-MM-dd').format(it.expiryDate);
              final leftText = left < 0 ? '지남 ${-left}일' : '$left일 남음';

              return ListTile(
                title: Text(it.name.trim().isEmpty ? '(이름 없음)' : it.name),
                subtitle: Text(
                  '${it.category} | ${it.location} | ${_formatQuantity(it)}\n'
                  '기한: $expiry ($leftText)',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, FoodExpiryItem item) async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('계정 정보를 불러올 수 없습니다.')));
      }
      return;
    }

    final currentItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'shop_${now.microsecondsSinceEpoch}',
      name: item.name,
      createdAt: now,
      updatedAt: now,
    );

    final nextItems = [newItem, ...currentItems];
    await UserPrefService.setShoppingCartItems(
      accountName: accountName,
      items: nextItems,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name}을(를) 장바구니에 담았습니다.'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editQuantity(BuildContext context, FoodExpiryItem item) async {
    final controller = TextEditingController(
      text: item.quantity == item.quantity.toInt()
          ? item.quantity.toInt().toString()
          : item.quantity.toString(),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.name} 수량 변경'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            suffixText: item.unit,
            border: const OutlineInputBorder(),
            labelText: '수량 입력',
          ),
          onSubmitted: (val) {
            final parsed = double.tryParse(val);
            if (parsed != null && parsed >= 0) {
              Navigator.of(ctx).pop(parsed);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != null && result != item.quantity) {
      final used = item.quantity - result;
      if (used > 0) {
        final warning = await HealthGuardrailService.recordUsageAndCheck(
          itemName: item.name,
          amount: used,
          tags: item.healthTags,
        );
        try {
          await ReplacementCycleNotificationService.instance
              .rescheduleFromPrefs();
        } catch (_) {
          // ignore
        }
        if (context.mounted && warning != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(warning.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      if (!context.mounted) return;

      if (result == 0) {
        if (!context.mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('재고 소진'),
            content: Text('${item.name} 재고가 0이 되었습니다.\n목록에서 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('아니오 (0으로 유지)'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('삭제'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await FoodExpiryService.instance.deleteById(item.id);
          return;
        }
      }

      await FoodExpiryService.instance.updateItem(
        id: item.id,
        name: item.name,
        purchaseDate: item.purchaseDate,
        expiryDate: item.expiryDate,
        memo: item.memo,
        quantity: result,
        unit: item.unit,
        healthTags: item.healthTags,
      );
    }
  }

  Future<void> _adjustQuantity(
    BuildContext context,
    FoodExpiryItem item,
    double delta,
  ) async {
    final newQty = item.quantity + delta;
    if (newQty < 0) return; // Prevent negative

    final used = delta < 0 ? -delta : 0.0;
    if (used > 0) {
      final warning = await HealthGuardrailService.recordUsageAndCheck(
        itemName: item.name,
        amount: used,
        tags: item.healthTags,
      );
      try {
        await ReplacementCycleNotificationService.instance
            .rescheduleFromPrefs();
      } catch (_) {
        // ignore
      }
      if (context.mounted && warning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(warning.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (!context.mounted) return;

    if (newQty == 0) {
      // Ask to delete if 0
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('재고 소진'),
          content: Text('${item.name} 재고가 0이 되었습니다.\n목록에서 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('아니오 (0으로 유지)'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('삭제'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await FoodExpiryService.instance.deleteById(item.id);
        return;
      }
    }

    await FoodExpiryService.instance.updateItem(
      id: item.id,
      name: item.name,
      purchaseDate: item.purchaseDate,
      expiryDate: item.expiryDate,
      memo: item.memo,
      quantity: newQty,
      unit: item.unit,
      category: item.category,
      location: item.location,
      price: item.price,
      supplier: item.supplier,
      healthTags: item.healthTags,
    );
  }

  Future<void> _addMissingToCart(List<String> names) async {
    await _addIngredientNamesToCart(names);
  }

  Future<void> _addIngredientNamesToCart(List<String> names) async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) return;

    final currentItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );

    final now = DateTime.now();
    final incoming = <ShoppingCartItem>[];
    for (var i = 0; i < names.length; i++) {
      final name = names[i].trim();
      if (name.isEmpty) continue;
      incoming.add(
        ShoppingCartItem(
          id: 'shop_${now.microsecondsSinceEpoch}_$i',
          name: name,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final merged = ShoppingPrepUtils.mergeByName(
      existing: currentItems,
      incoming: incoming,
    );

    if (merged.added <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('추가할 새 항목이 없습니다.')));
      }
      return;
    }

    await UserPrefService.setShoppingCartItems(
      accountName: accountName,
      items: merged.merged,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${merged.added}개의 재료를 장바구니에 담았습니다.'),
          action: SnackBarAction(
            label: '장바구니 이동',
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.shoppingCart,
                arguments: ShoppingCartArgs(accountName: accountName),
              );
            },
          ),
        ),
      );
    }
  }

  void _showItemDetail(BuildContext context, FoodExpiryItem item) {
    final theme = Theme.of(context);
    final left = item.daysLeft(DateTime.now());
    final leftColor = left < 0
        ? theme.colorScheme.error
        : (left <= 2 ? theme.colorScheme.tertiary : theme.colorScheme.primary);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('카테고리', item.category, Icons.category_outlined, theme),
            _detailRow(
              '보관위치',
              item.location,
              Icons.location_on_outlined,
              theme,
            ),
            _detailRow(
              '수량',
              '${_formatQuantity(item)} ${item.unit}',
              Icons.inventory_2_outlined,
              theme,
            ),
            _detailRow(
              '가격',
              '${CurrencyFormatter.format(item.price)}원',
              Icons.payments_outlined,
              theme,
            ),
            _detailRow(
              '구매처',
              item.supplier.isEmpty ? '-' : item.supplier,
              Icons.storefront_outlined,
              theme,
            ),
            const Divider(),
            _detailRow(
              '구매일',
              DateFormat('yyyy-MM-dd').format(item.purchaseDate),
              Icons.calendar_today_outlined,
              theme,
            ),
            _detailRow(
              '유통기한',
              '${DateFormat('yyyy-MM-dd').format(item.expiryDate)} ($left일 남음)',
              Icons.event_available_outlined,
              theme,
              valueColor: leftColor,
            ),
            if (item.memo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '메모',
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item.memo, style: theme.textTheme.bodyMedium),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onUpsert?.call(context, existing: item);
            },
            child: const Text('수정'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleUsageMode() {
    setState(() {
      _isUsageMode = !_isUsageMode;
      _usageMap.clear();
      _activeUsageItems.clear();
      _activeRecipeName = null;
    });
  }

  void _toggleItemUsage(String id) {
    setState(() {
      if (_activeUsageItems.contains(id)) {
        _activeUsageItems.remove(id);
        _usageMap.remove(id);
      } else {
        _activeUsageItems.add(id);
      }
    });
  }

  Future<void> _confirmAndDeleteItem(FoodExpiryItem item) async {
    final name = item.name.trim().isEmpty ? '(이름 없음)' : item.name.trim();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text("'$name' 항목을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '삭제',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FoodExpiryService.instance.deleteById(item.id);
    }
  }

  Future<void> _applyBulkUsage() async {
    if (_usageMap.isEmpty) return;

    final recipeName = (_activeRecipeName ?? '').trim();

    int updatedCount = 0;
    final items = FoodExpiryService.instance.items.value;
    final List<String> itemsToRemove = [];

    final usedIngredients = <Map<String, dynamic>>[];
    double totalUsedPrice = 0.0;

    for (var entry in _usageMap.entries) {
      if (entry.value <= 0) continue;

      final item = items.firstWhere(
        (i) => i.id == entry.key,
        orElse: () => items.first,
      );
      if (item.id != entry.key) continue;

      final newQty = (item.quantity - entry.value).clamp(0.0, double.infinity);

      // Estimate used price based on (item.price / item.quantity) * used.
      // This assumes item.price is the total price for the current quantity.
      if (item.price > 0 && item.quantity > 0 && entry.value > 0) {
        final unitPrice = item.price / item.quantity;
        final usedPrice = unitPrice * entry.value;
        totalUsedPrice += usedPrice;
        usedIngredients.add(<String, dynamic>{
          'name': item.name,
          'used': entry.value,
          'unit': item.unit,
          'price': usedPrice,
        });
      } else {
        usedIngredients.add(<String, dynamic>{
          'name': item.name,
          'used': entry.value,
          'unit': item.unit,
          'price': 0.0,
        });
      }

      if (newQty <= 0) {
        itemsToRemove.add(item.id);
      } else {
        await FoodExpiryService.instance.updateItem(
          id: item.id,
          name: item.name,
          purchaseDate: item.purchaseDate,
          expiryDate: item.expiryDate,
          memo: item.memo,
          quantity: newQty,
          unit: item.unit,
          category: item.category,
          location: item.location,
          price: item.price,
          supplier: item.supplier,
        );
      }
      updatedCount++;
    }

    if (itemsToRemove.isNotEmpty) {
      for (final id in itemsToRemove) {
        await FoodExpiryService.instance.deleteById(id);
      }
    }

    setState(() {
      _isUsageMode = false;
      _usageMap.clear();
      _activeUsageItems.clear();
      _activeRecipeName = null;
    });

    if (usedIngredients.isNotEmpty) {
      await SavingsStatisticsService.instance.addLog(
        recipeName: recipeName.isEmpty ? '사용 기록' : recipeName,
        totalUsedPrice: totalUsedPrice,
        usedIngredientsJson: jsonEncode(usedIngredients),
        isFromExistingInventory: widget.autoUsageMode,
      );
    }

    if (mounted) {
      String msg = '$updatedCount개의 항목 사용량이 기록되었습니다.';
      if (itemsToRemove.isNotEmpty) {
        msg += '\n(${itemsToRemove.length}개 항목 소진되어 삭제됨)';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _showRecipePicker({bool onlyCookable = false}) async {
    final items = FoodExpiryService.instance.items.value;

    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (ctx) => RecipePickerDialog(
        onlyCookable: onlyCookable,
      ),
    );

    if (selectedRecipe != null) {
      final List<String> missingIngredients = [];
      final List<Map<String, dynamic>> availableIngredients = [];
      final List<Map<String, dynamic>> expiringIngredients = [];
      final now = DateTime.now();

      setState(() {
        _isUsageMode = true;
        _usageMap.clear();
        _activeRecipeName = selectedRecipe.name;

        for (var ingredient in selectedRecipe.ingredients) {
          // FIFO: 유통기한 빠른 순서로 정렬된 항목 중 매칭되는 것 선택
          final matchedItems =
              items
                  .where(
                    (i) =>
                        i.name.contains(ingredient.name) ||
                        ingredient.name.contains(i.name),
                  )
                  .toList()
                ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

          if (matchedItems.isNotEmpty) {
            final item = matchedItems.first; // FIFO: 유통기한 가장 빠른 것
            _usageMap[item.id] = ingredient.quantity;

            final daysLeft = item.daysLeft(now);
            final info = {
              'name': item.name,
              'quantity': _formatQuantity(item),
              'daysLeft': daysLeft,
              'isExpiring': daysLeft <= 3,
            };

            if (daysLeft <= 3) {
              expiringIngredients.add(info);
            } else {
              availableIngredients.add(info);
            }
          } else {
            missingIngredients.add(ingredient.name);
          }
        }
      });

      // 재료 조합 정보 다이얼로그 표시
      if (mounted) {
        await _showIngredientCombinationDialog(
          selectedRecipe,
          availableIngredients,
          expiringIngredients,
          missingIngredients,
        );
      }
    }
  }

  Future<void> _showIngredientCombinationDialog(
    Recipe recipe,
    List<Map<String, dynamic>> available,
    List<Map<String, dynamic>> expiring,
    List<String> missing,
  ) async {
    final recipeName = recipe.name;

    // 건강 점수 계산 (기본 레시피에서 가져오거나 추정)
    final healthScore = _estimateHealthScore(recipe, expiring.length);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(recipeName, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 유통기한 임박 재료
              if (expiring.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '빨리 먹어야 할 재료 (${expiring.length}개)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: expiring.map((ing) {
                      final daysLeft = ing['daysLeft'] as int;
                      final daysText = daysLeft == 0
                          ? '오늘까지'
                          : daysLeft < 0
                          ? '${-daysLeft}일 지남'
                          : '$daysLeft일 남음';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '⚠️ ${ing['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${ing['quantity']} ($daysText)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 사용 가능한 재료
              if (available.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '사용 가능한 재료 (${available.length}개)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: available.map((ing) {
                      final daysLeft = ing['daysLeft'] as int;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '✅ ${ing['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${ing['quantity']} ($daysLeft일)',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 부족한 재료
              if (missing.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '구매 필요 (${missing.length}개)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: missing.map((name) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.remove_circle_outline,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '💡 부족한 재료를 장바구니에 추가할까요?',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],

              // 요약
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getHealthScoreLabel(healthScore),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '건강 $healthScore/5',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getHealthScoreColor(healthScore),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            expiring.isNotEmpty
                                ? '유통기한 임박 재료를 먼저 사용하세요!'
                                : '재료가 모두 준비됐습니다!',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (missing.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx, false);
                _promptAddMissingToCart(missing);
              },
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('장바구니 추가'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.restaurant_menu, size: 18),
            label: const Text('그것 좋겠다!'),
          ),
        ],
      ),
    );

    // 사용자가 "그것 좋겠다!" 선택 시 학습 기록
    if (confirmed == true && mounted) {
      await _recordRecipeLearning(recipe, healthScore, expiring.isNotEmpty);

      // 학습 완료 메시지 + 건강 점수 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ $recipeName 선택 완료!\n'
              '${_getHealthScoreLabel(healthScore)}\n'
              '💡 빅스비가 이 선택을 기억합니다',
            ),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '통계 보기',
              onPressed: _showLearningStats,
            ),
          ),
        );
      }
    }
  }

  int _estimateHealthScore(Recipe recipe, int expiringCount) {
    // 기본 요리별 건강 점수 매핑
    const healthScores = {
      '된장국': 5,
      '김치찌개': 4,
      '채소 볶음': 5,
      '계란말이': 4,
      '시금치나물': 5,
      '두부조림': 5,
      '미역국': 5,
      '닭가슴살 샐러드': 5,
      '계란탁': 4,
      '볶음밥': 3,
      '스파게티': 3,
      '계란프라이': 3,
    };

    int baseScore = healthScores[recipe.name] ?? 3;

    // 유통기한 임박 재료 사용 시 보너스 (+1)
    if (expiringCount > 0 && baseScore < 5) {
      baseScore += 1;
    }

    return baseScore;
  }

  String _getHealthScoreLabel(int score) {
    switch (score) {
      case 5:
        return '💚 매우 건강한 선택입니다!';
      case 4:
        return '💚 건강한 요리예요!';
      case 3:
        return '🟡 보통 수준의 요리입니다';
      case 2:
        return '🟠 가끔 드세요';
      case 1:
        return '🔴 자주 드시지 마세요';
      default:
        return '🟡 보통 수준의 요리입니다';
    }
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 4) return Colors.green.shade700;
    if (score == 3) return Colors.orange;
    return Colors.red.shade700;
  }

  Future<void> _recordRecipeLearning(
    Recipe recipe,
    int healthScore,
    bool hasExpiringIngredients,
  ) async {
    // 현재 시간대 판단
    final hour = DateTime.now().hour;
    String? mealTime;
    if (hour >= 6 && hour < 10) {
      mealTime = 'breakfast';
    } else if (hour >= 11 && hour < 15) {
      mealTime = 'lunch';
    } else if (hour >= 17 && hour < 22) {
      mealTime = 'dinner';
    }

    // 학습 서비스에 기록
    await RecipeLearningService.instance.recordRecipeUsage(
      recipeName: recipe.name,
      ingredients: recipe.ingredients.map((i) => i.name).toList(),
      healthScore: healthScore,
      mealTime: mealTime,
    );

    debugPrint(
      'Recipe learning recorded: ${recipe.name} (health: $healthScore)',
    );
  }

  Future<void> _showLearningStats() async {
    final stats = await RecipeLearningService.instance.getStats();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_graph, size: 24),
            SizedBox(width: 8),
            Text('AI 학습 통계'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('총 요리 횟수', '${stats.totalRecipesCooked}회'),
              const SizedBox(height: 16),

              const Text(
                '자주 만드는 요리',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...stats.topRecipes.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text('• $r'),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                '자주 쓰는 재료',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...stats.topIngredients.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text('• $i'),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats.healthPreferenceLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '건강 점수 평균: ${(stats.healthPreferenceScore * 5).toStringAsFixed(1)}/5',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                '💡 사용할수록 더 똑똑한 추천을 받을 수 있어요!',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Future<void> _promptAddMissingToCart(List<String> missingNames) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('부족한 재료'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ 현재 재고로 요리 가능합니다!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('하지만 다음 재료가 없어요:'),
            const SizedBox(height: 12),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: missingNames
                    .map(
                      (name) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.remove_circle_outline,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '💡 장바구니에 추가해서 다음에 구매하세요!',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('나중에'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('장바구니 추가'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final accountName = await UserPrefService.getLastAccountName();
      if (accountName == null) return;

      final currentItems = await UserPrefService.getShoppingCartItems(
        accountName: accountName,
      );

      final now = DateTime.now();
      final List<ShoppingCartItem> newItems = [];

      for (var name in missingNames) {
        newItems.add(
          ShoppingCartItem(
            id: 'shop_${now.microsecondsSinceEpoch}_${newItems.length}',
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await UserPrefService.setShoppingCartItems(
        accountName: accountName,
        items: [...newItems, ...currentItems],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newItems.length}개의 재료를 장바구니에 담았습니다.'),
            action: SnackBarAction(
              label: '장바구니 이동',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.shoppingCart,
                  arguments: ShoppingCartArgs(accountName: accountName),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 모드에 따라 다른 타이틀 및 아이콘
    final appBarTitle = widget.autoUsageMode ? '유통기한 관리' : '식료품/생활용품';
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(appBarTitle),
        actions: [
          if (_isUsageMode)
            IconButton(
              onPressed: _showRecipePicker,
              icon: const Icon(Icons.menu_book),
              tooltip: '요리 불러오기',
            ),
          IconButton(
            onPressed: _toggleUsageMode,
            icon: Icon(_isUsageMode ? Icons.close : Icons.soup_kitchen),
            tooltip: _isUsageMode ? '사용량 입력 종료' : '요리/사용 모드 (일괄 입력)',
          ),
          if (!_isUsageMode)
            IconButton(
              onPressed: FoodExpiryService.instance.load,
              icon: const Icon(IconCatalog.refresh),
              tooltip: '새로고침',
            ),
        ],
      ),
      floatingActionButton:
          (_isUsageMode || _activeUsageItems.isNotEmpty) && _usageMap.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _applyBulkUsage,
              icon: const Icon(Icons.check),
              label: Text('${_usageMap.length}개 적용'),
            )
          : null,
      body: ValueListenableBuilder<List<FoodExpiryItem>>(
        valueListenable: FoodExpiryService.instance.items,
        builder: (context, allItems, child) {
          // 로케이션 필터 적용
          final items = _locationFilter == null || _locationFilter == '전체'
              ? allItems
              : allItems.where((it) => it.location == _locationFilter).toList();

          final ingredientNames = _normalizeIngredientNames(
            widget.initialIngredients,
          );

          final missingIngredients = <String>[];
          if (ingredientNames.isNotEmpty) {
            for (final ing in ingredientNames) {
              // Treat "quantity <= 0" as effectively missing
              // (still showable in detail)
              final hasAvailable = items.any(
                (it) => _ingredientMatchesItem(ing, it) && it.quantity > 0,
              );
              if (!hasAvailable) missingIngredients.add(ing);
            }
          }

          if (items.isEmpty && missingIngredients.isEmpty) {
            final emptyMsg = widget.autoUsageMode
                ? '등록된 유통기한 항목이 없습니다.\n하단 버튼으로 추가하세요.'
                : '등록된 식료품/생활용품이 없습니다.\n하단 버튼으로 품목을 추가하세요.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  emptyMsg,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              // 로케이션 필터 칩
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: _locationOptions.map((loc) {
                    final isSelected = (_locationFilter ?? '전체') == loc;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(loc),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _locationFilter = loc == '전체' ? null : loc;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
              // 오늘의 요리 추천 위젯
              KeyedSubtree(
                key: _dailyRecipeSectionKey,
                child: const DailyRecipeRecommendationWidget(),
              ),
              // 식재료 추천 강화 위젯
              const IngredientsRecommendationWidget(),
              // 식단 계획 위젯
              // 비용 분석 위젯
              const CostAnalysisWidget(),
              // 사용자 설정 위젯
              const UserPreferencesWidget(),
              if (!_isUsageMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              _showRecipePicker(onlyCookable: true),
                          icon: const Icon(Icons.soup_kitchen),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                          ),
                          label: const Text('보관 중인 식재료 요리'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.ingredientSearch,
                            );
                          },
                          icon: const Icon(Icons.search),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                          ),
                          label: const Text('추천 재료 비교'),
                        ),
                      ],
                    ),
                  ),
                ),

              if (ingredientNames.isNotEmpty)
                Container(
                  width: double.maxFinite,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.25,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '재료 비교 (${ingredientNames.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () =>
                                _addIngredientNamesToCart(ingredientNames),
                            icon: const Icon(Icons.playlist_add, size: 16),
                            label: const Text('모두 담기'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          if (missingIngredients.isNotEmpty)
                            TextButton.icon(
                              onPressed: () =>
                                  _addMissingToCart(missingIngredients),
                              icon: const Icon(
                                Icons.shopping_cart_outlined,
                                size: 16,
                              ),
                              label: const Text('재고 0 모두 담기'),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...ingredientNames.expand((ing) {
                        final matchedAll = _matchAllItemsForIngredient(
                          ing,
                          items,
                        );
                        final matched = _matchAvailableItemsForIngredient(
                          ing,
                          items,
                        );
                        final isMissing = matched.isEmpty;
                        final nearest = isMissing ? null : matched.first;
                        final left = nearest?.daysLeft(DateTime.now());
                        final leftText = left == null
                            ? ''
                            : (left < 0 ? '지남 ${-left}일' : '$left일 남음');
                        final nearestExpiry = left == null
                            ? null
                            : DateFormat(
                                'yyyy-MM-dd',
                              ).format(nearest!.expiryDate);

                        final subtitle = isMissing
                            ? (matchedAll.isEmpty
                                  ? '재고: 0 (없음)'
                                  : '재고: 0 (수량 0)')
                            : '총 ${_formatMatchedTotal(matched)} / '
                                  '가장 빠른 기한: $nearestExpiry ($leftText)';

                        final warnColor = (left != null && left <= 2)
                            ? theme.colorScheme.error
                            : null;

                        return [
                          InkWell(
                            onTap: matchedAll.isEmpty
                                ? null
                                : () => _showIngredientMatchesDetail(
                                    context,
                                    ingredientName: ing,
                                    matched: matchedAll,
                                  ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ing,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: warnColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isMissing)
                                    IconButton(
                                      tooltip: '장바구니 담기',
                                      onPressed: () => _addMissingToCart([ing]),
                                      icon: const Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 18,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: theme.colorScheme.outline,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                        ];
                      }).toList()..removeLast(),
                    ],
                  ),
                ),

              if (missingIngredients.isNotEmpty)
                Container(
                  width: double.maxFinite,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '부족한 식료품/생활용품 (${missingIngredients.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () =>
                                _addMissingToCart(missingIngredients),
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 16,
                            ),
                            label: const Text('장바구니 담기'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('식료품/생활용품 목록'),
                      Wrap(
                        spacing: 8,
                        children: missingIngredients
                            .map(
                              (ing) => Chip(
                                label: Text(ing),
                                visualDensity: VisualDensity.compact,
                                labelStyle: const TextStyle(fontSize: 12),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final it = items[i];
                    final displayName = it.name.trim().isEmpty
                        ? '(이름 없음)'
                        : it.name.trim();
                    final left = it.daysLeft(DateTime.now());
                    final leftText = left < 0
                        ? '지남 ${-left}일'
                        : '남음 $left'
                              '일';
                    final color = left < 0
                        ? theme.colorScheme.error
                        : (left <= 2
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.primary);

                    final isMatched =
                        widget.initialIngredients?.any(
                          (ing) =>
                              it.name.contains(ing) ||
                              ing.contains(it.name) ||
                              it.category.contains(ing),
                        ) ??
                        false;

                    final isItemUsageActive =
                        _isUsageMode || _activeUsageItems.contains(it.id);

                    return Container(
                      color: isMatched
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.2,
                            )
                          : null,
                      child: ListTile(
                        onTap: () => _showItemDetail(context, it),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                if (it.category.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .secondaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        it.category,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.info_outline,
                                        size: 14,
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: !isItemUsageActive
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _adjustQuantity(
                                            context,
                                            it,
                                            -1.0,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: InkWell(
                                            onTap: () =>
                                                _editQuantity(context, it),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              child: Text(
                                                _formatQuantity(it),
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      decoration: TextDecoration
                                                          .underline,
                                                      decorationStyle:
                                                          TextDecorationStyle
                                                              .dotted,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () =>
                                              _adjustQuantity(context, it, 1.0),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '잔량: ${_formatQuantity(it)}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        _UsageInput(
                                          initialValue: _usageMap[it.id],
                                          max: it.quantity,
                                          unit: it.unit,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == null || val <= 0) {
                                                _usageMap.remove(it.id);
                                              } else {
                                                _usageMap[it.id] = val;
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          _itemSubtitleText(it),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _isUsageMode
                            ? null
                            : SizedBox(
                                width: 210,
                                child: Row(
                                  children: [
                                    if (!isItemUsageActive)
                                      Text(
                                        leftText,
                                        style: TextStyle(color: color),
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        isItemUsageActive
                                            ? Icons.close
                                            : Icons.soup_kitchen,
                                        size: 20,
                                        color: isItemUsageActive
                                            ? theme.colorScheme.error
                                            : theme.colorScheme.primary,
                                      ),
                                      tooltip: isItemUsageActive
                                          ? '입력 취소'
                                          : '사용량 입력',
                                      onPressed: () => _toggleItemUsage(it.id),
                                    ),
                                    if (!isItemUsageActive) ...[
                                      IconButton(
                                        icon: const Icon(
                                          IconCatalog.shoppingCart,
                                        ),
                                        tooltip: '장바구니 담기',
                                        onPressed: () =>
                                            _addToCart(context, it),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          IconCatalog.deleteOutline,
                                          color: theme.colorScheme.error,
                                        ),
                                        tooltip: '삭제',
                                        onPressed: () =>
                                            _confirmAndDeleteItem(it),
                                      ),
                                    ],
                                  ],
                                ),
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

  String _formatQuantity(FoodExpiryItem item) {
    String formatQty(double value) {
      if (!value.isFinite) return '0';
      final rounded = value.roundToDouble();
      if ((value - rounded).abs() < 0.000001) {
        return rounded.toStringAsFixed(0);
      }
      return value.toStringAsFixed(1);
    }

    return '${formatQty(item.quantity)}${item.unit}';
  }

  String _itemSubtitleText(FoodExpiryItem item) {
    final purchase = DateFormat('yyyy-MM-dd').format(item.purchaseDate);
    final expiry = DateFormat('yyyy-MM-dd').format(item.expiryDate);

    String base = '구매: $purchase / 기한: $expiry';
    if (item.location.isNotEmpty) {
      base += '\n위치: ${item.location}';
    }
    if (item.price > 0) {
      base += ' / 가격: ${NumberFormat('#,###').format(item.price)}원';
    }

    final memo = item.memo.trim();
    if (memo.isEmpty) return base;
    return '$base\n메모: $memo';
  }
}

