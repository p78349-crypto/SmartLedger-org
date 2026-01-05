import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/fixed_cost.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/models/shopping_points_draft_entry.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/fixed_cost_service.dart';
import 'package:smart_ledger/services/food_expiry_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/benefit_memo_utils.dart';
import 'package:smart_ledger/utils/category_definitions.dart';
import 'package:smart_ledger/utils/constants.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';
import 'package:smart_ledger/utils/date_formats.dart';
import 'package:smart_ledger/utils/date_formatter.dart';
import 'package:smart_ledger/utils/shopping_category_utils.dart';
import 'package:smart_ledger/utils/store_memo_utils.dart';
import 'package:smart_ledger/widgets/smart_input_field.dart';
// import 'package:smart_ledger/screens/nutrition_report_screen.dart';
// Preserved but disabled per request.

class ShoppingCartQuickTransactionScreen extends StatefulWidget {
  const ShoppingCartQuickTransactionScreen({super.key, required this.args});

  final ShoppingCartQuickTransactionArgs args;

  @override
  State<ShoppingCartQuickTransactionScreen> createState() =>
      _ShoppingCartQuickTransactionScreenState();
}

class _ShoppingCartQuickTransactionScreenState
    extends State<ShoppingCartQuickTransactionScreen> {
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _cardChargedAmountController =
      TextEditingController();

  List<String> _favoritePayments = const <String>[];
  List<String> _favoriteMemos = const <String>[];

  String _selectedMainCategory = CategoryDefinitions.defaultCategory;
  String? _selectedSubCategory;

  List<ShoppingCartItem>? _remainingBulkItems;
  int? _bulkIndex;
  int? _bulkTotalCount;
  Map<String, CategoryHint> _bulkCategoryHintsState =
      const <String, CategoryHint>{};
  final List<String> _savedBulkItemIds = <String>[];

  _InitialQuickTransactionSnapshot? _initialSnapshot;

  bool _addToInventory = false;

  @override
  void dispose() {
    _paymentController.dispose();
    _memoController.dispose();
    _storeController.dispose();
    _cardChargedAmountController.dispose();
    super.dispose();
  }

  double? _parseCardChargedAmount(String raw) {
    final normalized = raw.trim().replaceAll(',', '');
    if (normalized.isEmpty) return null;
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  Future<void> _handleBulkFinishBeforePop() async {
    final receiptTotal = widget.args.bulkGrandTotal;
    if (receiptTotal == null || receiptTotal <= 0) return;

    final draftId = 'sp_${DateTime.now().microsecondsSinceEpoch}';
    final at = DateTime.now();

    await UserPrefService.addShoppingPointsDraft(
      accountName: widget.args.accountName,
      draft: ShoppingPointsDraftEntry(
        id: draftId,
        at: at,
        receiptTotal: receiptTotal,
      ),
    );
  }

  String? _resolveStoreKey({
    required String memo,
    required String explicitStore,
  }) {
    final trimmed = explicitStore.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return StoreMemoUtils.extractStoreKey(memo);
  }

  @override
  void initState() {
    super.initState();
    _selectedMainCategory =
        (widget.args.initialMainCategory == null ||
            widget.args.initialMainCategory!.trim().isEmpty)
        ? CategoryDefinitions.defaultCategory
        : widget.args.initialMainCategory!.trim();
    _selectedSubCategory = widget.args.initialSubCategory;

    _remainingBulkItems = widget.args.bulkRemainingItems?.toList(
      growable: true,
    );
    _bulkIndex = widget.args.bulkIndex;
    _bulkTotalCount = widget.args.bulkTotalCount;
    _bulkCategoryHintsState =
        widget.args.bulkCategoryHints ?? const <String, CategoryHint>{};

    if (widget.args.martStore != null) {
      _storeController.text = widget.args.martStore!;
    }
    if (widget.args.martPayment != null) {
      _paymentController.text = widget.args.martPayment!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadFavoritesAndPrefill();
      if (!mounted) return;

      final seeded =
          await UserPrefService.bootstrapShoppingCategoryHintsFromTransactions(
            accountName: widget.args.accountName,
          );
      if (!mounted) return;
      if (seeded > 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('카테고리 힌트 $seeded개 초기화')));
      }

      await _ensureCategorySuggestion();
      if (!mounted) return;
      _captureInitialSnapshotIfNeeded();
    });
  }

  String _favoritePaymentsKeyForExpense(String accountName) =>
      '${AppConstants.favoritePaymentsKeyPrefix}_${accountName}_'
      '${TransactionType.expense.name}';
  String _legacyFavoritePaymentsKey(String accountName) =>
      '${AppConstants.favoritePaymentsKeyPrefix}_$accountName';
  String _favoriteMemosKeyForExpense(String accountName) =>
      '${AppConstants.favoriteMemosKeyPrefix}_${accountName}_'
      '${TransactionType.expense.name}';
  String _legacyFavoriteMemosKey(String accountName) =>
      '${AppConstants.favoriteMemosKeyPrefix}_$accountName';

  Future<List<String>> _loadFavorites({
    required String newKey,
    required String legacyKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(newKey);
    if (values != null && values.isNotEmpty) {
      return values;
    }
    final legacy = prefs.getStringList(legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setStringList(newKey, legacy);
      return legacy;
    }
    return const <String>[];
  }

  Widget _buildFavoriteChips({
    required List<String> values,
    required void Function(String value) onSelected,
  }) {
    if (values.isEmpty) return const SizedBox.shrink();

    final trimmed = values.take(AppConstants.maxFavoritesCount).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in trimmed)
            ActionChip(label: Text(v), onPressed: () => onSelected(v)),
        ],
      ),
    );
  }

  Future<void> _saveFavorite({
    required String key,
    required String value,
    required int maxEntries,
  }) async {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = (prefs.getStringList(key) ?? <String>[]).toList();
    list.remove(normalized);
    list.insert(0, normalized);
    if (list.length > maxEntries) {
      list.removeRange(maxEntries, list.length);
    }
    await prefs.setStringList(key, list);
  }

  Future<void> _loadFavoritesAndPrefill() async {
    final accountName = widget.args.accountName;

    final payments = await _loadFavorites(
      newKey: _favoritePaymentsKeyForExpense(accountName),
      legacyKey: _legacyFavoritePaymentsKey(accountName),
    );

    final memos = await _loadFavorites(
      newKey: _favoriteMemosKeyForExpense(accountName),
      legacyKey: _legacyFavoriteMemosKey(accountName),
    );
    if (!mounted) return;
    setState(() {
      _favoritePayments = payments;
      if (_paymentController.text.trim().isEmpty && payments.isNotEmpty) {
        _paymentController.text = payments.first;
      }

      _favoriteMemos = memos;
      if (_memoController.text.trim().isEmpty && memos.isNotEmpty) {
        _memoController.text = memos.first;
      }
    });
  }

  Future<void> _ensureCategorySuggestion() async {
    if (_selectedMainCategory != CategoryDefinitions.defaultCategory) {
      return;
    }

    final hints = await UserPrefService.getShoppingCategoryHints(
      accountName: widget.args.accountName,
    );

    final now = DateTime.now();
    final item =
        _bulkCurrentItem ??
        ShoppingCartItem(
          id: 'quick_${now.microsecondsSinceEpoch}',
          name: _resolvedDescription,
          quantity: _resolvedQty,
          unitPrice: _resolvedUnitPrice ?? 0,
          isPlanned: false,
          createdAt: now,
          updatedAt: now,
        );

    final suggested = ShoppingCategoryUtils.suggest(item, learnedHints: hints);

    if (!mounted) return;
    setState(() {
      _selectedMainCategory = suggested.mainCategory;
      _selectedSubCategory = suggested.subCategory;
    });
  }

  bool get _isBulk =>
      _remainingBulkItems != null &&
      _remainingBulkItems!.isNotEmpty &&
      _bulkIndex != null &&
      _bulkTotalCount != null;

  ShoppingCartItem? get _bulkCurrentItem =>
      _isBulk ? _remainingBulkItems!.first : null;

  Map<String, CategoryHint> get _bulkCategoryHints => _bulkCategoryHintsState;

  int get _resolvedQty {
    final item = _bulkCurrentItem;
    if (item != null) {
      return item.quantity <= 0 ? 1 : item.quantity;
    }
    return widget.args.quantity <= 0 ? 1 : widget.args.quantity;
  }

  double? get _resolvedUnitPrice {
    final item = _bulkCurrentItem;
    if (item != null) return item.unitPrice;
    return widget.args.unitPrice;
  }

  double get _resolvedTotal {
    final item = _bulkCurrentItem;
    if (item != null) {
      final qty = item.quantity <= 0 ? 1 : item.quantity;
      return item.unitPrice * qty;
    }
    return widget.args.total;
  }

  String get _resolvedDescription {
    final item = _bulkCurrentItem;
    if (item != null) return item.name;
    return widget.args.description;
  }

  bool get _hasSelectedMainCategory =>
      _selectedMainCategory != CategoryDefinitions.defaultCategory;

  String _mergeMemo(String globalMemo, String itemMemo) {
    final g = globalMemo.trim();
    final i = itemMemo.trim();
    if (g.isEmpty) return i;
    if (i.isEmpty) return g;
    if (g == i) return g;
    if (g.contains(i)) return g;
    if (i.contains(g)) return i;
    return '$g · $i';
  }

  Future<void> _saveRemainingBulk() async {
    FocusScope.of(context).unfocus();
    final payment = _paymentController.text.trim();
    final memo = _memoController.text.trim();

    if (payment.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('결제수단을 입력하세요.')));
      return;
    }

    final remaining = _remainingBulkItems;
    if (remaining == null || remaining.isEmpty) return;

    // If any remaining item would end up as default category, require a
    // fallback main category (to avoid stats confusion).
    final hints = _bulkCategoryHints;
    final needsFallback = remaining.any(
      (i) =>
          ShoppingCategoryUtils.suggest(i, learnedHints: hints).mainCategory ==
          CategoryDefinitions.defaultCategory,
    );

    if (needsFallback && !_hasSelectedMainCategory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('분류되지 않은 항목이 있어 카테고리가 필요합니다.')),
      );
      final picked = await _openCategoryPicker();
      if (!picked || !mounted) return;
      if (!_hasSelectedMainCategory) return;
    }

    final fallbackMain = _hasSelectedMainCategory
        ? _selectedMainCategory
        : null;

    final accountName = widget.args.accountName;

    final storeKey = _resolveStoreKey(
      memo: memo,
      explicitStore: _storeController.text,
    );

    // Persist favorites once.
    await _saveFavorite(
      key: _favoritePaymentsKeyForExpense(accountName),
      value: payment,
      maxEntries: AppConstants.maxFavoritesCount,
    );
    if (memo.isNotEmpty) {
      await _saveFavorite(
        key: _favoriteMemosKeyForExpense(accountName),
        value: memo,
        maxEntries: AppConstants.maxFavoritesCount,
      );
    }

    final savedIds = _savedBulkItemIds.toList(growable: true);
    final baseId = DateTime.now().microsecondsSinceEpoch;
    var idOffset = 0;
    for (final cartItem in remaining) {
      final qty = cartItem.quantity <= 0 ? 1 : cartItem.quantity;
      final unit = cartItem.unitPrice;
      final total = unit * qty;

      final suggested = ShoppingCategoryUtils.suggest(
        cartItem,
        learnedHints: _bulkCategoryHints,
      );

      final resolvedMain =
          suggested.mainCategory == CategoryDefinitions.defaultCategory &&
              fallbackMain != null
          ? fallbackMain
          : suggested.mainCategory;

      final resolvedSub = resolvedMain == CategoryDefinitions.defaultCategory
          ? null
          : (suggested.mainCategory == CategoryDefinitions.defaultCategory
                ? null
                : suggested.subCategory);

      final tx = Transaction(
        id: 'tx_${baseId + (idOffset++)}',
        type: TransactionType.expense,
        description: cartItem.name,
        amount: total,
        date: widget.args.martDate ?? DateTime.now(),
        quantity: qty,
        unitPrice: unit,
        paymentMethod: payment,
        memo: _mergeMemo(memo, cartItem.memo),
        store: storeKey,
        mainCategory: resolvedMain,
        subCategory: (resolvedMain == CategoryDefinitions.defaultCategory)
            ? null
            : resolvedSub,
      );

      try {
        await TransactionService().addTransaction(accountName, tx);
        if (_addToInventory) {
          final purchaseDate = widget.args.martDate ?? DateTime.now();
          await FoodExpiryService.instance.addItem(
            name: cartItem.name,
            purchaseDate: purchaseDate,
            expiryDate: purchaseDate.add(const Duration(days: 7)),
            quantity: qty.toDouble(),
            memo: _mergeMemo(memo, cartItem.memo),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: ${e.toString()}')));
        return;
      }

      savedIds.add(cartItem.id);
    }

    if (!mounted) return;
    await _handleBulkFinishBeforePop();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(ShoppingCartQuickTransactionSaveRestResult(savedItemIds: savedIds));
  }

  Future<void> _advanceBulkAfterSave(String savedItemId) async {
    if (!_isBulk) return;

    _savedBulkItemIds.add(savedItemId);
    final list = _remainingBulkItems;
    if (list == null || list.isEmpty) return;

    list.removeAt(0);
    _bulkIndex = (_bulkIndex ?? 0) + 1;

    if (list.isEmpty) {
      await _handleBulkFinishBeforePop();
      if (!mounted) return;
      Navigator.of(context).pop(
        ShoppingCartQuickTransactionSaveRestResult(
          savedItemIds: _savedBulkItemIds.toList(growable: false),
        ),
      );
      return;
    }

    setState(() {
      _selectedMainCategory = CategoryDefinitions.defaultCategory;
      _selectedSubCategory = null;
    });
    unawaited(_ensureCategorySuggestion());

    final total = _bulkTotalCount;
    final savedCount = _savedBulkItemIds.length;
    final progress = total == null ? '$savedCount' : '$savedCount/$total';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('저장됨 ($progress)')));
  }

  String _categorySummary() {
    if (_selectedMainCategory == CategoryDefinitions.defaultCategory) {
      return CategoryDefinitions.defaultCategory;
    }
    final sub = _selectedSubCategory?.trim() ?? '';
    if (sub.isNotEmpty) {
      return '$_selectedMainCategory · $sub';
    }
    return _selectedMainCategory;
  }

  Future<bool> _openCategoryPicker() async {
    FocusScope.of(context).unfocus();
    String tempMain = _selectedMainCategory;
    String? tempSub = _selectedSubCategory;
    const categoryOptions = CategoryDefinitions.categoryOptions;

    final hints = _bulkCategoryHints;
    final currentItem =
        _bulkCurrentItem ??
        ShoppingCartItem(
          id: 'tmp',
          name: _resolvedDescription,
          quantity: _resolvedQty,
          unitPrice: _resolvedUnitPrice ?? 0,
          isPlanned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    final recommended = ShoppingCategoryUtils.suggestCandidates(
      currentItem,
      learnedHints: hints,
    );

    if (!categoryOptions.containsKey(tempMain)) {
      tempMain = categoryOptions.keys.first;
      tempSub = null;
    }

    final result = await showGeneralDialog<_CategorySelection>(
      context: context,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        String? focusedMain = tempMain == CategoryDefinitions.defaultCategory
            ? null
            : tempMain;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget choiceChip({
              required String label,
              required bool selected,
              required VoidCallback onSelected,
              bool isMain = false,
              bool isLarge = false,
            }) {
              return ChoiceChip(
                label: Padding(
                  padding: isLarge
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                      : EdgeInsets.zero,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isLarge ? 15 : (isMain ? 13 : 12),
                      fontWeight: isMain || isLarge
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                selected: selected,
                onSelected: (_) => onSelected(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(focusedMain ?? '카테고리 선택'),
                leading: IconButton(
                  icon: Icon(
                    focusedMain == null ? Icons.close : Icons.arrow_back,
                  ),
                  onPressed: () {
                    if (focusedMain == null) {
                      Navigator.pop(dialogContext);
                    } else {
                      setSheetState(() => focusedMain = null);
                    }
                  },
                ),
                actions: [
                  if (focusedMain != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          _CategorySelection(tempMain, tempSub),
                        );
                      },
                      child: const Text(
                        '선택 완료',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Always show recommendations at the top
                  if (recommended.isNotEmpty) ...[
                    Text(
                      '추천 카테고리',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recommended.map((pair) {
                        final main = pair.mainCategory;
                        final sub = pair.subCategory;
                        final label = (sub == null || sub.trim().isEmpty)
                            ? main
                            : '$main · $sub';
                        final isSelected =
                            tempMain == main &&
                            ((sub == null || sub.trim().isEmpty)
                                ? tempSub == null
                                : tempSub == sub);
                        return choiceChip(
                          label: label,
                          selected: isSelected,
                          onSelected: () {
                            final selectedMain = main;
                            final selectedSub =
                                (sub == null || sub.trim().isEmpty)
                                ? null
                                : sub;
                            Navigator.pop(
                              dialogContext,
                              _CategorySelection(selectedMain, selectedSub),
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],

                  if (focusedMain == null) ...[
                    // Step 1: Show Main Categories
                    Text(
                      '대분류 선택',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.5,
                      children: CategoryDefinitions.shoppingMainCategories
                          .where(
                            (m) => m != CategoryDefinitions.defaultCategory,
                          )
                          .map((main) {
                            final isSelected = tempMain == main;
                            return InkWell(
                              onTap: () {
                                setSheetState(() {
                                  tempMain = main;
                                  tempSub = null;
                                  focusedMain = main;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer
                                      : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  main,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ] else ...[
                    // Step 2: Show Subcategories for focused main
                    Row(
                      children: [
                        Text(
                          '소분류 선택',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () =>
                              setSheetState(() => focusedMain = null),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('대분류 변경'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        choiceChip(
                          label: '전체 ($focusedMain)',
                          selected: tempMain == focusedMain! && tempSub == null,
                          onSelected: () {
                            Navigator.pop(
                              dialogContext,
                              _CategorySelection(focusedMain!, null),
                            );
                          },
                          isLarge: true,
                        ),
                        ...(categoryOptions[focusedMain!] ?? []).map((sub) {
                          return choiceChip(
                            label: sub,
                            selected:
                                tempMain == focusedMain! && tempSub == sub,
                            onSelected: () {
                              Navigator.pop(
                                dialogContext,
                                _CategorySelection(focusedMain!, sub),
                              );
                            },
                            isLarge: true,
                          );
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedMainCategory = result.main;
        _selectedSubCategory = result.sub;
      });
      return _hasSelectedMainCategory;
    }

    return false;
  }

  void _captureInitialSnapshotIfNeeded() {
    if (!mounted) return;
    if (_initialSnapshot != null) return;
    _initialSnapshot = _InitialQuickTransactionSnapshot(
      paymentText: _paymentController.text,
      memoText: _memoController.text,
    );
  }

  Future<void> _promptRevertToInitial() async {
    _captureInitialSnapshotIfNeeded();
    final snapshot = _initialSnapshot;
    if (snapshot == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('입력값 되돌리기'),
          content: const Text('화면을 열었을 때의 입력값으로 되돌릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('되돌리기'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      FocusScope.of(context).unfocus();
      setState(() {
        _paymentController.text = snapshot.paymentText;
        _memoController.text = snapshot.memoText;
      });
    }
  }

  Future<void> _save() async {
    await _performSave(shouldShowDialog: false);
  }

  Future<void> _saveWithBenefits() async {
    await _performSave(shouldShowDialog: true);
  }

  Future<void> _performSave({required bool shouldShowDialog}) async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final payment = _paymentController.text.trim();
    final memo = _memoController.text.trim();
    final effectiveMemo = _mergeMemo(memo, _bulkCurrentItem?.memo ?? '');

    final storeSuggestion = StoreMemoUtils.extractStoreKey(effectiveMemo) ?? '';
    if (_storeController.text.trim().isEmpty && storeSuggestion.isNotEmpty) {
      _storeController.text = storeSuggestion;
    }

    if (payment.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('결제수단을 입력하세요.')));
      return;
    }

    // Category is optional for speed, but we try to suggest it.
    if (!_hasSelectedMainCategory) {
      await _ensureCategorySuggestion();
    }
    if (!mounted) return;

    final categoryText =
        _selectedMainCategory == CategoryDefinitions.defaultCategory
        ? '미지정'
        : (_selectedSubCategory == null || _selectedSubCategory!.trim().isEmpty)
        ? _selectedMainCategory
        : '$_selectedMainCategory > ${_selectedSubCategory!.trim()}';

    final title = widget.args.title.trim().isEmpty
        ? '장바구니 입력'
        : widget.args.title.trim();

    final qty = _resolvedQty;
    final unit = _resolvedUnitPrice;
    final total = _resolvedTotal;

    String? benefitJson;

    if (shouldShowDialog) {
      final memoSeed = BenefitMemoUtils.parseBenefitByType(effectiveMemo);
      final benefitRowControllers =
          <({TextEditingController type, TextEditingController amount})>[
            for (final e in memoSeed.entries)
              (
                type: TextEditingController(text: e.key),
                amount: TextEditingController(text: e.value.toStringAsFixed(0)),
              ),
          ];

      if (benefitRowControllers.isEmpty) {
        benefitRowControllers.add((
          type: TextEditingController(),
          amount: TextEditingController(),
        ));
      }

      final shippingController = TextEditingController(text: '2500');
      final subscriptionAmountController = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final lines = widget.args.previewLines;
          int page = 0;
          String storePreset = '';
          bool freeShipping = false;
          String subscriptionPreset = '';

          void ensureShippingBenefit() {
            final amountRaw = shippingController.text.trim().replaceAll(
              ',',
              '',
            );
            final parsed = double.tryParse(amountRaw);
            if (parsed == null || parsed <= 0) return;

            for (final row in benefitRowControllers) {
              if (row.type.text.trim() == '배송') {
                if (row.amount.text.trim().isEmpty) {
                  row.amount.text = parsed.toStringAsFixed(0);
                }
                return;
              }
            }
            benefitRowControllers.add((
              type: TextEditingController(text: '배송'),
              amount: TextEditingController(text: parsed.toStringAsFixed(0)),
            ));
          }

          double sumBenefitRows() {
            var sum = 0.0;
            for (final row in benefitRowControllers) {
              final raw = row.amount.text.trim().replaceAll(',', '');
              final v = double.tryParse(raw);
              if (v == null || v <= 0) continue;
              sum += v;
            }
            return sum;
          }

          Map<String, double> benefitRowMap() {
            final byType = <String, double>{};
            for (final row in benefitRowControllers) {
              final key = row.type.text.trim();
              if (key.isEmpty) continue;
              final raw = row.amount.text.trim().replaceAll(',', '');
              final v = double.tryParse(raw);
              if (v == null || v <= 0) continue;
              byType[key] = (byType[key] ?? 0) + v;
            }
            return byType;
          }

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final charged = _parseCardChargedAmount(
                _cardChargedAmountController.text,
              );
              final cardBenefit = charged == null ? null : (total - charged);
              final rowSum = sumBenefitRows();

              Widget buildPage1() {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('상품명: $_resolvedDescription'),
                    if (widget.args.itemCount != null)
                      Text('체크 항목: ${widget.args.itemCount}개'),
                    if (unit != null && unit > 0)
                      Text('가격(단가): ${CurrencyFormatter.format(unit)}'),
                    if (unit != null && unit > 0) Text('수량: $qty개'),
                    Text('금액(제시): ${CurrencyFormatter.format(total)}'),
                    Text('카테고리: $categoryText'),
                    Text('결제수단: $payment'),
                    if (effectiveMemo.isNotEmpty) Text('메모: $effectiveMemo'),
                    if (lines != null && lines.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...lines.map(Text.new),
                    ],
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      '혜택 입력은 선택입니다.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (charged != null)
                      Text(
                        cardBenefit == null
                            ? ''
                            : (cardBenefit > 0
                                ? '현재 기준 혜택(제시-실결제): '
                                    '${CurrencyFormatter.format(cardBenefit)}'
                                : '현재 기준 혜택: 0원'),
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      Text(
                        '팁) “금액(제시)” - “카드 청구금액(실결제)” = 혜택(할인/포인트 등)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                );
              }

              Widget buildBenefitRow(
                ({TextEditingController type, TextEditingController amount})
                row,
                int index,
              ) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: row.type,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: '종류',
                            hintText: '예: 카드/마트/포인트/배송',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: row.amount,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: '금액',
                            hintText: '예: 2500',
                            border: const OutlineInputBorder(),
                            suffixIcon: benefitRowControllers.length <= 1
                                ? null
                                : IconButton(
                                    tooltip: '삭제',
                                    onPressed: () {
                                      setDialogState(() {
                                        benefitRowControllers.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                );
              }

              Widget buildPage2() {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '혜택(선택)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(storePreset),
                      initialValue: storePreset,
                      decoration: const InputDecoration(
                        labelText: '마트/쇼핑몰 선택(선택)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('선택 안함')),
                        DropdownMenuItem(
                          value: '온라인 쇼핑몰',
                          child: Text('온라인 쇼핑몰'),
                        ),
                        DropdownMenuItem(
                          value: '포털 서비스',
                          child: Text('포털 서비스'),
                        ),
                        DropdownMenuItem(value: '마트', child: Text('마트')),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          storePreset = v ?? '';
                          if (storePreset.isNotEmpty) {
                            _storeController.text = storePreset;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SmartInputField(
                      label: '마트/쇼핑몰명(직접입력, 선택)',
                      hint: '예: 온라인 쇼핑몰, 대형마트, 포털 서비스',
                      controller: _storeController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    SmartInputField(
                      label: '결제금액(실결제, 선택)',
                      hint: '예: 12300',
                      controller: _cardChargedAmountController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('무료배송'),
                            value: freeShipping,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (v) {
                              setDialogState(() {
                                freeShipping = v ?? false;
                                if (freeShipping) {
                                  ensureShippingBenefit();
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (freeShipping) ...[
                      TextField(
                        controller: shippingController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '배송비 절약(기본 2500)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          setDialogState(ensureShippingBenefit);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final quick in const [
                          '카드',
                          '마트/쇼핑몰',
                          '포인트',
                          '배송',
                          '쿠폰',
                          '멤버십',
                        ])
                          ActionChip(
                            label: Text(quick),
                            onPressed: () {
                              setDialogState(() {
                                benefitRowControllers.add((
                                  type: TextEditingController(text: quick),
                                  amount: TextEditingController(),
                                ));
                              });
                            },
                          ),
                        ActionChip(
                          label: const Text('+ 추가'),
                          onPressed: () {
                            setDialogState(() {
                              benefitRowControllers.add((
                                type: TextEditingController(),
                                amount: TextEditingController(),
                              ));
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...benefitRowControllers.asMap().entries.map((e) {
                      return buildBenefitRow(e.value, e.key);
                    }),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      '구독(가입비) 미리 등록(선택)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(subscriptionPreset),
                      initialValue: subscriptionPreset,
                      decoration: const InputDecoration(
                        labelText: '구독 선택',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('선택 안함')),
                        DropdownMenuItem(
                          value: '온라인 쇼핑몰 멤버십(연)',
                          child: Text('온라인 쇼핑몰 멤버십(연)'),
                        ),
                        DropdownMenuItem(
                          value: '포털 멤버십(월)',
                          child: Text('포털 멤버십(월)'),
                        ),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          subscriptionPreset = v ?? '';
                          subscriptionAmountController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: subscriptionAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '가입비/구독료 금액',
                        hintText: '예: 4990',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: subscriptionPreset.trim().isEmpty
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final raw = subscriptionAmountController.text
                                    .trim()
                                    .replaceAll(',', '');
                                final amount = double.tryParse(raw);
                                if (amount == null || amount <= 0) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('구독 금액을 입력하세요.'),
                                    ),
                                  );
                                  return;
                                }

                                final now = DateTime.now();
                                final vendor =
                                    subscriptionPreset.contains('온라인 쇼핑몰')
                                    ? '온라인 쇼핑몰'
                                    : (subscriptionPreset.contains('포털')
                                          ? '포털 서비스'
                                          : null);
                                final dueDay =
                                    subscriptionPreset.contains('(월)')
                                    ? now.day
                                    : null;

                                await FixedCostService().loadFixedCosts();
                                final existing = FixedCostService()
                                    .getFixedCosts(widget.args.accountName)
                                    .any(
                                      (c) =>
                                          c.name.trim() ==
                                          subscriptionPreset.trim(),
                                    );

                                if (!mounted) return;
                                if (existing) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '이미 등록된 구독입니다: $subscriptionPreset',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                await FixedCostService().addFixedCost(
                                  widget.args.accountName,
                                  FixedCost(
                                    name: subscriptionPreset.trim(),
                                    amount: amount,
                                    vendor: vendor,
                                    paymentMethod: payment.isEmpty
                                        ? '카드'
                                        : payment,
                                    memo: '쇼핑 입력에서 등록',
                                    dueDay: dueDay,
                                  ),
                                );

                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '구독 등록됨: $subscriptionPreset',
                                    ),
                                  ),
                                );

                                setDialogState(() {
                                  subscriptionPreset = '';
                                  subscriptionAmountController.clear();
                                });
                              },
                        child: const Text('구독으로 등록'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: subscriptionPreset.trim().isEmpty
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final raw = subscriptionAmountController.text
                                    .trim()
                                    .replaceAll(',', '');
                                final amount = double.tryParse(raw);
                                if (amount == null || amount <= 0) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('구독 금액을 입력하세요.'),
                                    ),
                                  );
                                  return;
                                }

                                final now = DateTime.now();
                                final name = subscriptionPreset.trim();
                                final vendor = name.contains('온라인 쇼핑몰')
                                    ? '온라인 쇼핑몰'
                                    : (name.contains('포털') ? '포털 서비스' : null);
                                final dueDay = name.contains('(월)')
                                    ? now.day
                                    : null;
                                final paymentMethod = payment.isEmpty
                                    ? '카드'
                                    : payment;

                                await FixedCostService().loadFixedCosts();
                                final existing = FixedCostService()
                                    .getFixedCosts(widget.args.accountName)
                                    .any((c) => c.name.trim() == name);

                                final txService = TransactionService();
                                await txService.loadTransactions();

                                DateTime targetDate;
                                if (dueDay == null) {
                                  targetDate = DateFormatter.stripTime(now);
                                } else {
                                  final lastDay = DateUtils.getDaysInMonth(
                                    now.year,
                                    now.month,
                                  );
                                  final targetDay = dueDay
                                      .clamp(1, lastDay)
                                      .toInt();
                                  targetDate = DateFormatter.stripTime(
                                    DateTime(now.year, now.month, targetDay),
                                  );
                                }

                                final existingTransactions = txService
                                    .getTransactions(widget.args.accountName);
                                final duplicates = existingTransactions
                                    .where((tx) {
                                      final sameDay = DateFormatter.isSameDay(
                                        tx.date,
                                        targetDate,
                                      );
                                      final sameAmount =
                                          (tx.amount - amount).abs() < 0.01;
                                      return tx.type ==
                                              TransactionType.expense &&
                                          sameDay &&
                                          sameAmount &&
                                          tx.description.trim() == name;
                                    })
                                    .toList(growable: false);

                                if (!mounted) return;

                                final amountLabel = CurrencyFormatter.format(
                                  amount,
                                );
                                final dateLabel = DateFormats.yMd.format(
                                  targetDate,
                                );

                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('구독을 지출로 기록할까요?'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$dateLabel에 $name을(를) 지출로 반영합니다.',
                                        ),
                                        const SizedBox(height: 12),
                                        Text('금액: $amountLabel'),
                                        Text('결제 수단: $paymentMethod'),
                                        if (!existing) ...[
                                          const SizedBox(height: 12),
                                          const Text('고정비에도 함께 등록됩니다.'),
                                        ],
                                        if (duplicates.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            '⚠️ 동일한 금액/이름의 지출이 이미 '
                                            '${duplicates.length}건 존재합니다. '
                                            '중복 기록이 필요하지 않은지 확인하세요.',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('취소'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text(
                                          duplicates.isNotEmpty
                                              ? '그래도 기록'
                                              : '기록',
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true) {
                                  return;
                                }

                                try {
                                  if (!existing) {
                                    await FixedCostService().addFixedCost(
                                      widget.args.accountName,
                                      FixedCost(
                                        name: name,
                                        amount: amount,
                                        vendor: vendor,
                                        paymentMethod: paymentMethod,
                                        memo: '쇼핑 입력에서 등록',
                                        dueDay: dueDay,
                                      ),
                                    );
                                  }

                                  final now = DateTime.now();
                                  final txId =
                                      'tx_${now.microsecondsSinceEpoch}';
                                  await txService.addTransaction(
                                    widget.args.accountName,
                                    Transaction(
                                      id: txId,
                                      type: TransactionType.expense,
                                      description: name,
                                      amount: amount,
                                      date: targetDate,
                                      unitPrice: amount,
                                      paymentMethod: paymentMethod,
                                      memo: '[구독 즉시기록] ${vendor ?? ''}'.trim(),
                                      store: vendor,
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('처리 실패: ${e.toString()}'),
                                    ),
                                  );
                                  return;
                                }

                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      existing
                                          ? '지출 기록됨: $name'
                                          : '구독 등록 + 지출 기록됨: $name',
                                    ),
                                  ),
                                );

                                setDialogState(() {
                                  subscriptionPreset = '';
                                  subscriptionAmountController.clear();
                                });
                              },
                        child: const Text('등록 + 이번달 지출로 기록'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '입력된 혜택 합계: ${CurrencyFormatter.format(rowSum)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (charged != null && cardBenefit != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '제시-실결제: ${CurrencyFormatter.format(cardBenefit)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      '※ 실결제 입력이 있으면 통계는 “제시-실결제”를 우선으로 봅니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }

              return AlertDialog(
                title: Text(page == 0 ? '$title (1/2)' : '$title (2/2)'),
                content: SingleChildScrollView(
                  child: page == 0 ? buildPage1() : buildPage2(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('취소'),
                  ),
                  if (page == 1)
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          page = 0;
                        });
                      },
                      child: const Text('이전'),
                    )
                  else
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          page = 1;
                        });
                      },
                      child: const Text('혜택 입력'),
                    ),
                  FilledButton(
                    onPressed: () {
                      final map = benefitRowMap();
                      final json = map.isEmpty
                          ? null
                          : BenefitMemoUtils.encodeBenefitJson(map);
                      benefitJson = json;
                      Navigator.of(dialogContext).pop(true);
                    },
                    child: const Text('저장'),
                  ),
                ],
              );
            },
          );
        },
      );

      shippingController.dispose();
      subscriptionAmountController.dispose();
      for (final row in benefitRowControllers) {
        row.type.dispose();
        row.amount.dispose();
      }

      if (confirmed != true || !mounted) return;
    } else {
      // Fast save: try to parse benefits from memo automatically
      final memoSeed = BenefitMemoUtils.parseBenefitByType(effectiveMemo);
      if (memoSeed.isNotEmpty) {
        benefitJson = BenefitMemoUtils.encodeBenefitJson(memoSeed);
      }
    }

    await _saveFavorite(
      key: _favoritePaymentsKeyForExpense(widget.args.accountName),
      value: payment,
      maxEntries: AppConstants.maxFavoritesCount,
    );
    if (memo.isNotEmpty) {
      await _saveFavorite(
        key: _favoriteMemosKeyForExpense(widget.args.accountName),
        value: memo,
        maxEntries: AppConstants.maxFavoritesCount,
      );
    }

    final storeKey = _resolveStoreKey(
      memo: effectiveMemo,
      explicitStore: _storeController.text,
    );
    final charged = _parseCardChargedAmount(_cardChargedAmountController.text);

    final tx = Transaction(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      type: TransactionType.expense,
      description: _resolvedDescription,
      amount: total,
      date: widget.args.martDate ?? DateTime.now(),
      quantity: qty,
      unitPrice: unit ?? total,
      paymentMethod: payment,
      memo: effectiveMemo,
      store: storeKey,
      cardChargedAmount: charged,
      benefitJson: benefitJson,
      mainCategory: _selectedMainCategory,
      subCategory:
          (_selectedMainCategory == CategoryDefinitions.defaultCategory)
          ? null
          : _selectedSubCategory,
    );

    try {
      await TransactionService().addTransaction(widget.args.accountName, tx);
      if (_addToInventory) {
        final purchaseDate = widget.args.martDate ?? DateTime.now();
        await FoodExpiryService.instance.addItem(
          name: _resolvedDescription,
          purchaseDate: purchaseDate,
          expiryDate: purchaseDate.add(const Duration(days: 7)),
          quantity: qty.toDouble(),
          memo: effectiveMemo,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: ${e.toString()}')));
      return;
    }

    if (!mounted) return;

    if (_isBulk) {
      final id = _bulkCurrentItem?.id;
      if (id == null) {
        Navigator.of(context).pop(true);
        return;
      }
      await _advanceBulkAfterSave(id);
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.args.title.trim().isEmpty
        ? '거래 입력'
        : widget.args.title.trim();

    final qty = _resolvedQty;
    final unit = _resolvedUnitPrice;
    final total = _resolvedTotal;

    final showSaveRestButton = _isBulk && ((_bulkIndex ?? 0) >= 1);
    final bulkIndexText = _isBulk
        ? ' (${(_bulkIndex ?? 0) + 1}/$_bulkTotalCount)'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: '이전',
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                '$title$bulkIndexText',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: '다음',
              icon: Icon(
                Icons.arrow_forward,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                _save();
                if (!mounted) return;
                final navigator = Navigator.of(context);
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (!mounted) return;
                  navigator.pushNamed(
                    AppRoutes.shoppingPointsInput,
                    arguments: AccountArgs(
                      accountName: widget.args.accountName,
                    ),
                  );
                });
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '입력값 되돌리기',
            icon: const Icon(Icons.restart_alt),
            onPressed: _promptRevertToInitial,
          ),
        ],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _resolvedDescription,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (unit != null && unit > 0)
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '가격(단가)',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(CurrencyFormatter.format(unit)),
                  ),
                )
              else
                const Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '가격(단가)',
                      border: OutlineInputBorder(),
                    ),
                    child: Text('-'),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '수량',
                    border: OutlineInputBorder(),
                  ),
                  child: Text('$qty'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: '금액',
              border: OutlineInputBorder(),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.format(total),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _openCategoryPicker,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.chevron_right),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _categorySummary(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _paymentController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '결제수단',
              hintText: _favoritePayments.isNotEmpty
                  ? '예: ${_favoritePayments.first}'
                  : '예: 카드',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          _buildFavoriteChips(
            values: _favoritePayments,
            onSelected: (value) {
              setState(() => _paymentController.text = value);
              FocusScope.of(context).nextFocus();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memoController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: '메모',
              hintText: _favoriteMemos.isNotEmpty
                  ? '예: ${_favoriteMemos.first}'
                  : '예: 마트/쇼핑몰 이름 + 간단 메모',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          _buildFavoriteChips(
            values: _favoriteMemos,
            onSelected: (value) {
              setState(() => _memoController.text = value);
            },
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('재고 관리(유통기한)에 추가'),
            subtitle: const Text('저장 시 식재료 재고 목록에 자동으로 등록합니다.'),
            value: _addToInventory,
            onChanged: (v) => setState(() => _addToInventory = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          if (showSaveRestButton) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _saveRemainingBulk,
                icon: const Icon(Icons.auto_awesome_motion_outlined, size: 18),
                label: const Text('나머지 모두 저장'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Transform.translate(
                offset: const Offset(0, -6),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 120,
                height: 36,
                child: OutlinedButton(
                  onPressed: _saveWithBenefits,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('혜택 입력'),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 120,
                height: 36,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Transform.translate(
                offset: const Offset(0, -6),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      _save();
                      if (!mounted) return;
                      final navigator = Navigator.of(context);
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (!mounted) return;
                        navigator.pushNamed(
                          AppRoutes.shoppingPointsInput,
                          arguments: AccountArgs(
                            accountName: widget.args.accountName,
                          ),
                        );
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategorySelection {
  const _CategorySelection(this.main, this.sub);

  final String main;
  final String? sub;
}

class _InitialQuickTransactionSnapshot {
  const _InitialQuickTransactionSnapshot({
    required this.paymentText,
    required this.memoText,
  });

  final String paymentText;
  final String memoText;
}
