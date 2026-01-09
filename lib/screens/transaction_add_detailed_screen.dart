import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/pref_keys.dart';
import '../models/asset.dart';
import '../models/category_hint.dart';
import '../models/shopping_cart_item.dart';
import '../models/transaction.dart';
import 'income_split_screen.dart';
// import 'package:smart_ledger/screens/nutrition_report_screen.dart';
// Preserved but disabled per request.
import '../services/asset_service.dart';
import '../services/category_usage_service.dart';
import '../services/food_expiry_service.dart';
import '../services/recent_input_service.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../services/category_keyword_service.dart';
import '../utils/shopping_cart_bulk_ledger_utils.dart';
import '../utils/category_definitions.dart';
import '../utils/detailed_category_definitions.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/income_category_definitions.dart';
import '../utils/snackbar_utils.dart';
import '../utils/store_memo_utils.dart';

// 최근 결제수단/메모 저장 키 및 최대 개수
const String _recentDescriptionsKey = 'recent_descriptions';
const String _recentPaymentsKey = 'recent_payments';
const String _recentMemosKey = 'recent_memos';
const int _maxRecentDescriptions = 30;
const int _maxRecentPayments = 10;
const int _maxRecentMemos = 10;
const String _lastCategoryMainKeyPrefix = 'last_category_main';
const String _defaultCategory = CategoryDefinitions.defaultCategory;

// const int _maxFavoriteDescriptions = 20;
// const int _maxFavoriteMemos = 10;

Map<String, List<String>> _categoryOptionsFor(TransactionType type) {
  if (type == TransactionType.income) {
    return IncomeCategoryDefinitions.categoryOptions;
  }
  return CategoryDefinitions.categoryOptions;
}

class TransactionAddDetailedScreen extends StatefulWidget {
  final String accountName;
  final Transaction? initialTransaction;
  final bool learnCategoryHintFromDescription;
  final bool confirmBeforeSave;
  final bool treatAsNew;
  final bool closeAfterSave;
  final bool autoSubmit;
  const TransactionAddDetailedScreen({
    super.key,
    required this.accountName,
    this.initialTransaction,
    this.learnCategoryHintFromDescription = false,
    this.confirmBeforeSave = false,
    this.treatAsNew = false,
    this.closeAfterSave = false,
    this.autoSubmit = false,
  });

  @override
  State<TransactionAddDetailedScreen> createState() =>
      _TransactionAddDetailedScreenState();
}

class _TransactionAddDetailedScreenState
    extends State<TransactionAddDetailedScreen> {
  final GlobalKey<_TransactionAddDetailedFormState> _formStateKey =
      GlobalKey<_TransactionAddDetailedFormState>();

  @override
  void initState() {
    super.initState();
    if (widget.autoSubmit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_formStateKey.currentState?.triggerAutoSubmit());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing =
        widget.initialTransaction != null && widget.treatAsNew == false;

    final isIncomeTemplate =
        widget.initialTransaction?.type == TransactionType.income;
    final titlePrefix = isIncomeTemplate
        ? (isEditing ? '수입 수정(상세)' : '수입(상세)')
        : (isEditing ? '거래 수정(상세)' : '2-지출입력(상세)');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final didSave = _formStateKey.currentState?.didSave ?? false;
        if (didSave) {
          navigator.pop(true);
        } else {
          navigator.pop();
        }
      },
      child: Builder(
        builder: (context) {
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;
          return Scaffold(
            appBar: isLandscape
                ? null
                : AppBar(
                    title: Text('$titlePrefix - ${widget.accountName}'),
                    actions: [
                      IconButton(
                        tooltip: '장바구니 불러오기',
                        icon: const Icon(IconCatalog.shoppingCart),
                        onPressed: () => _formStateKey.currentState
                            ?.openShoppingCartPicker(),
                      ),
                      IconButton(
                        tooltip: '입력값 되돌리기',
                        icon: const Icon(IconCatalog.restartAlt),
                        onPressed: () =>
                            _formStateKey.currentState?.promptRevertToInitial(),
                      ),
                    ],
                  ),
            body: SafeArea(
              top: !isLandscape,
              child: Padding(
                padding: EdgeInsets.all(isLandscape ? 0.0 : 16.0),
                child: TransactionAddDetailedForm(
                  key: _formStateKey,
                  accountName: widget.accountName,
                  initialTransaction: widget.initialTransaction,
                  learnCategoryHintFromDescription:
                      widget.learnCategoryHintFromDescription,
                  confirmBeforeSave: widget.confirmBeforeSave,
                  treatAsNew: widget.treatAsNew,
                  closeAfterSave: widget.closeAfterSave,
                  titlePrefix: isLandscape ? titlePrefix : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InitialTransactionFormSnapshot {
  const _InitialTransactionFormSnapshot({
    required this.descText,
    required this.qtyText,
    required this.unitPriceText,
    required this.amountText,
    required this.cardChargedAmountText,
    required this.memoText,
    required this.storeText,
    required this.paymentText,
    required this.selectedType,
    required this.savingsAllocation,
    required this.transactionDate,
    required this.selectedMainCategory,
    required this.selectedSubCategory,
    required this.selectedDetailCategory,
    required this.locationText,
    required this.supplierText,
    required this.unitText,
    required this.expiryDate,
    required this.addToShoppingList,
    required this.showIncomeCategoryOptions,
  });

  final String descText;
  final String qtyText;
  final String unitPriceText;
  final String amountText;
  final String cardChargedAmountText;
  final String memoText;
  final String storeText;
  final String paymentText;
  final TransactionType selectedType;
  final SavingsAllocation savingsAllocation;
  final DateTime transactionDate;
  final String selectedMainCategory;
  final String? selectedSubCategory;
  final String? selectedDetailCategory;
  final String locationText;
  final String supplierText;
  final String unitText;
  final DateTime? expiryDate;
  final bool addToShoppingList;
  final bool showIncomeCategoryOptions;
}

class TransactionAddDetailedForm extends StatefulWidget {
  final String accountName;
  final Transaction? initialTransaction;
  final bool learnCategoryHintFromDescription;
  final bool confirmBeforeSave;
  final bool treatAsNew;
  final bool closeAfterSave;
  final String? titlePrefix;
  const TransactionAddDetailedForm({
    super.key,
    required this.accountName,
    this.initialTransaction,
    this.learnCategoryHintFromDescription = false,
    this.confirmBeforeSave = false,
    this.treatAsNew = false,
    this.closeAfterSave = false,
    this.titlePrefix,
  });

  @override
  State<TransactionAddDetailedForm> createState() =>
      _TransactionAddDetailedFormState();
}

class _TransactionAddDetailedFormState
    extends State<TransactionAddDetailedForm> {
  List<String> _recentDescriptions = [];
  List<String> _recentPayments = [];
  List<String> _recentMemos = [];

  Map<String, CategoryHint> _shoppingCategoryHintsNormalized = const {};
  bool _shoppingCategoryHintsLoaded = false;
  bool _userPickedCategory = false;
  Timer? _autoCategoryDebounce;
  static const int _priceRiseLookbackCount = 20;
  static const int _priceRiseMinSamples = 3;
  static const double _priceRisePctThreshold = 0.10; // 10%
  static const double _priceRiseMinDeltaWon = 100; // 최소 100원 이상 상승

  static const int _shoppingAvgLookbackDays = 30;
  static const Set<String> _shoppingMainCategories = {'생활용품비', '의류/잡화'};
  static const Set<String> _shoppingFoodSubCategories = {'식자재 구매', '간식', '음료'};

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  final FocusNode _descFocusNode = FocusNode();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cardChargedAmountController =
      TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  final FocusNode _expenseUnitPriceFocusNode = FocusNode();
  final FocusNode _expenseQtyFocusNode = FocusNode();
  final FocusNode _paymentFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _storeFocusNode = FocusNode();
  final FocusNode _memoFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _supplierFocusNode = FocusNode();
  final FocusNode _unitFocusNode = FocusNode();
  final FocusNode _calculatedAmountFocusNode = FocusNode(
    canRequestFocus: false,
    skipTraversal: true,
  );

  InputDecoration _standardInputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final contentPadding = EdgeInsets.symmetric(
      horizontal: 12,
      vertical: isLandscape ? 10 : 12,
    );

    final scheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      isDense: true,
      contentPadding: contentPadding,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }

  TransactionType _selectedType = TransactionType.expense;
  SavingsAllocation _savingsAllocation = SavingsAllocation.assetIncrease;
  late DateTime _transactionDate;
  String _selectedMainCategory = DetailedCategoryDefinitions.defaultCategory;
  String? _selectedSubCategory;
  String? _selectedDetailCategory;
  DateTime? _expiryDate;
  bool _addToShoppingList = false;
  bool _showIncomeCategoryOptions = true;

  bool _suppressAmountAutoUpdate = false;
  _InitialTransactionFormSnapshot? _initialSnapshot;

  bool _didSaveAtLeastOnce = false;

  bool get didSave => _didSaveAtLeastOnce;

  Future<void> triggerAutoSubmit() async {
    await _saveTransaction(skipConfirm: true);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isShoppingCategory(String mainCategory, String? subCategory) {
    if (_shoppingMainCategories.contains(mainCategory)) {
      return true;
    }
    if (mainCategory == '식비') {
      final sub = subCategory?.trim();
      if (sub == null || sub.isEmpty) {
        // If user didn't pick a subcategory, treat it as shopping to keep the
        // behavior predictable.
        return true;
      }
      return _shoppingFoodSubCategories.contains(sub);
    }
    return false;
  }

  Future<String?> _buildShoppingSpendComparisonTooltip({
    required String accountName,
  }) async {
    final service = TransactionService();
    await service.loadTransactions();

    final all = service.getTransactions(accountName);
    if (all.isEmpty) return null;

    final now = DateTime.now();
    final today = _dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final rangeStart = yesterday.subtract(
      const Duration(days: _shoppingAvgLookbackDays - 1),
    );

    final totalsByDay = <DateTime, double>{};

    for (final tx in all) {
      if (tx.type != TransactionType.expense) continue;
      if (!_isShoppingCategory(tx.mainCategory, tx.subCategory)) continue;

      final day = _dateOnly(tx.date);
      if (day.isBefore(rangeStart) || day.isAfter(yesterday)) continue;

      totalsByDay[day] = (totalsByDay[day] ?? 0) + tx.amount;
    }

    double sum = 0;
    for (var i = 0; i < _shoppingAvgLookbackDays; i++) {
      final day = rangeStart.add(Duration(days: i));
      sum += totalsByDay[day] ?? 0;
    }

    final yesterdayTotal = totalsByDay[yesterday] ?? 0;
    final avg = sum / _shoppingAvgLookbackDays;

    final yText = CurrencyFormatter.format(yesterdayTotal);
    final avgText = CurrencyFormatter.format(avg);

    String deltaText = '';
    if (avg.abs() > 0.000001) {
      final pct = ((yesterdayTotal - avg) / avg) * 100.0;
      final sign = pct >= 0 ? '+' : '';
      deltaText = ' ($sign${pct.toStringAsFixed(0)}%)';
    }

    return '쇼핑 기준(식비/생활용품/의류)\n'
        '어제: $yText\n'
        '최근 $_shoppingAvgLookbackDays일 일평균: $avgText$deltaText';
  }

  bool get _isEditing =>
      widget.initialTransaction != null && !widget.treatAsNew;

  String _normalizeShoppingHintKey(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.isEmpty) return '';

    // Remove common promotion/multiplier patterns before stripping symbols.
    s = s.replaceAll(RegExp(r'\d+\s*[+×x]\s*\d+'), ' ');

    // Collapse whitespace, then remove punctuation/symbols.
    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll(RegExp(r'[^a-z0-9가-힣]'), '');

    // Remove trailing size/unit/count patterns.
    s = s.replaceAll(
      RegExp(r'(\d+(?:\.\d+)?)(ml|l|kg|g|mg|개|입|팩|봉|병|캔|장|p|pcs|pc|box)$'),
      '',
    );

    // Remove common Korean promotion tokens.
    s = s.replaceAll(RegExp(r'(행사|증정|무료|덤|할인|특가|세일)$'), '');

    return s;
  }

  Future<void> _loadShoppingCategoryHints() async {
    if (_isEditing) return;
    try {
      var hints = await UserPrefService.getShoppingCategoryHints(
        accountName: widget.accountName,
      );
      if (hints.isEmpty) {
        await UserPrefService.bootstrapShoppingCategoryHintsFromTransactions(
          accountName: widget.accountName,
        );
        hints = await UserPrefService.getShoppingCategoryHints(
          accountName: widget.accountName,
        );
      }

      final normalized = <String, CategoryHint>{};
      for (final e in hints.entries) {
        final k = _normalizeShoppingHintKey(e.key);
        if (k.isEmpty) continue;
        normalized[k] = e.value;
      }

      if (!mounted) return;
      setState(() {
        _shoppingCategoryHintsNormalized = normalized;
        _shoppingCategoryHintsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _shoppingCategoryHintsNormalized = const {};
        _shoppingCategoryHintsLoaded = true;
      });
    }
  }

  CategoryHint? _findBestCategoryHint(String description) {
    if (_shoppingCategoryHintsNormalized.isEmpty) return null;
    final key = _normalizeShoppingHintKey(description);
    if (key.isEmpty) return null;

    final direct = _shoppingCategoryHintsNormalized[key];
    if (direct != null) return direct;

    CategoryHint? best;
    var bestLen = 0;
    for (final entry in _shoppingCategoryHintsNormalized.entries) {
      final k = entry.key;
      if (k.isEmpty) continue;
      if (k.length <= bestLen) continue;
      if (key.contains(k)) {
        best = entry.value;
        bestLen = k.length;
      }
    }
    return best;
  }

  void _handleDescriptionChanged(String value) {
    if (_isEditing) return;
    if (_selectedType != TransactionType.expense) return;
    if (_userPickedCategory) return;
    if (!_shoppingCategoryHintsLoaded) return;

    _autoCategoryDebounce?.cancel();
    _autoCategoryDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;

      String? main;
      String? nextSub;
      String? nextDetail;

      // 1) Try user history hints first
      final hint = _findBestCategoryHint(value);
      if (hint != null) {
        final hintMain = hint.mainCategory.trim();
        if (hintMain.isNotEmpty &&
            hintMain != _defaultCategory &&
            DetailedCategoryDefinitions.mainCategories.contains(hintMain)) {
          main = hintMain;

          final hintSub = hint.subCategory?.trim() ?? '';
          if (hintSub.isNotEmpty) {
            final allowedSub = DetailedCategoryDefinitions.getSubCategories(
              main,
            );
            if (allowedSub.contains(hintSub)) {
              nextSub = hintSub;

              final hintDetail = hint.detailCategory?.trim() ?? '';
              if (hintDetail.isNotEmpty) {
                final allowedDetail =
                    DetailedCategoryDefinitions.getDetailCategories(
                      main,
                      hintSub,
                    );
                if (allowedDetail.contains(hintDetail)) {
                  nextDetail = hintDetail;
                }
              }
            }
          }
        }
      }

      // 2) Fallback to keyword dictionary
      if (main == null) {
        final kwResult = CategoryKeywordService.instance.classify(value);
        if (kwResult != null) {
          final kwMain = kwResult.$1;
          if (DetailedCategoryDefinitions.mainCategories.contains(kwMain)) {
            main = kwMain;
            final kwSub = kwResult.$2;
            if (kwSub != null) {
              final allowedSub = DetailedCategoryDefinitions.getSubCategories(
                main,
              );
              if (allowedSub.contains(kwSub)) {
                nextSub = kwSub;
              }
            }
          }
        }
      }

      if (main == null) return;

      final unchanged =
          main == _selectedMainCategory &&
          nextSub == _selectedSubCategory &&
          nextDetail == _selectedDetailCategory;
      if (unchanged) return;

      setState(() {
        _selectedMainCategory = main!;
        _selectedSubCategory = nextSub;
        _selectedDetailCategory = nextDetail;
      });
      unawaited(_persistLastCategoryForType(_selectedType, main: main));
    });
  }

  // ...existing code...
  String _lastCategoryMainKeyFor(TransactionType type) =>
      '${_lastCategoryMainKeyPrefix}_${widget.accountName}_${type.name}';

  Future<void> _persistLastCategoryForType(
    TransactionType type, {
    required String main,
  }) async {
    if (_isEditing) return;
    final prefs = await SharedPreferences.getInstance();
    final trimmed = main.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_lastCategoryMainKeyFor(type));
      return;
    }
    await prefs.setString(_lastCategoryMainKeyFor(type), trimmed);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTransaction;
    _transactionDate = initial?.date ?? DateTime.now();
    if (initial != null) {
      _selectedType = initial.type;
      _descController.text = initial.description;
      _qtyController.text = initial.quantity.toString();
      final unitPrice = initial.unitPrice != 0
          ? initial.unitPrice
          : (initial.quantity > 0
                ? initial.amount / initial.quantity
                : initial.amount);
      if (unitPrice > 0) {
        _unitPriceController.text = unitPrice.toStringAsFixed(
          unitPrice == unitPrice.roundToDouble() ? 0 : 2,
        );
      }
      _amountController.text = initial.amount.toStringAsFixed(
        initial.amount == initial.amount.roundToDouble() ? 0 : 2,
      );
      if (initial.cardChargedAmount != null) {
        final card = initial.cardChargedAmount!;
        _cardChargedAmountController.text = card.toStringAsFixed(
          card == card.roundToDouble() ? 0 : 2,
        );
      }
      _paymentController.text = initial.paymentMethod;
      _memoController.text = initial.memo;
      _storeController.text = initial.store?.trim() ?? '';
      if (initial.type == TransactionType.savings) {
        _savingsAllocation =
            initial.savingsAllocation ?? SavingsAllocation.assetIncrease;
      }
      _selectedMainCategory = initial.mainCategory;
      _selectedSubCategory = initial.subCategory;
      _selectedDetailCategory = initial.detailCategory;
      _locationController.text = initial.location ?? '';
      _supplierController.text = initial.supplier ?? '';
      _unitController.text = initial.unit ?? '';
      _expiryDate = initial.expiryDate;
    } else {
      _qtyController.text = '1';
    }
    if (_selectedType == TransactionType.income) {
      if (_isEditing) {
        _showIncomeCategoryOptions =
            _selectedMainCategory !=
            DetailedCategoryDefinitions.defaultCategory;
      } else {
        _applyIncomeDefaultCategory();
        _showIncomeCategoryOptions = false;
      }
    } else {
      _showIncomeCategoryOptions = true;
    }

    // 신규 입력에서는 마지막으로 선택한 카테고리를 복원한다.
    // (편집/복제 입력에서는 초기값을 우선)
    if (initial == null) {
      unawaited(_restoreLastCategoryForType(_selectedType));
    }

    unawaited(_loadShoppingCategoryHints());

    unawaited(_loadRecentInputs());
    unawaited(_loadDraftIfRecent());
    unawaited(_loadSortedCategories()); // Load sorted categories
    _qtyController.addListener(_updateAmount);
    _unitPriceController.addListener(_updateAmount);
    if (initial == null) {
      _updateAmount();
    }

    // 결제수단/메모 입력란 포커스 이동 시 전체 선택
    _paymentFocusNode.addListener(() {
      if (_paymentFocusNode.hasFocus) {
        final text = _paymentController.text;
        _paymentController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        );
      }
    });
    _memoFocusNode.addListener(() {
      if (_memoFocusNode.hasFocus) {
        final text = _memoController.text;
        _memoController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureInitialSnapshotIfNeeded();
    });
  }

  Future<void> _loadSortedCategories() async {
    final categoryOptions = _categoryOptionsFor(_selectedType);
    final usageCounts = await CategoryUsageService.loadCounts();
    if (!mounted) return;

    final sorted = categoryOptions.keys.toList()
      ..sort((a, b) {
        final ac = CategoryUsageService.countForMain(usageCounts, a);
        final bc = CategoryUsageService.countForMain(usageCounts, b);
        if (ac != bc) return bc.compareTo(ac);
        return a.compareTo(b);
      });

    // Ensure default category is first if present, or handle as needed.
    // Usually default category is '미분류'.
    if (sorted.remove(_defaultCategory)) {
      sorted.insert(0, _defaultCategory);
    }
  }

  Future<void> _loadRecentInputs() async {
    final prefs = await SharedPreferences.getInstance();
    final descriptions =
        prefs.getStringList(_recentDescriptionsKey) ?? const <String>[];
    final payments = prefs.getStringList(_recentPaymentsKey) ?? [];
    final memos = prefs.getStringList(_recentMemosKey) ?? [];

    if (!mounted) return;
    setState(() {
      _recentDescriptions = descriptions
          .take(_maxRecentDescriptions)
          .toList(growable: false);
      _recentPayments = payments
          .take(_maxRecentPayments)
          .toList(growable: false);
      _recentMemos = memos.take(_maxRecentMemos).toList(growable: false);
    });

    if (_paymentController.text.isEmpty && payments.isNotEmpty) {
      _paymentController.text = payments.first;
    }
    if (_memoController.text.isEmpty && memos.isNotEmpty) {
      _memoController.text = memos.first;
    }
  }

  Future<void> _showRecentInputPicker({
    required BuildContext context,
    required List<String> items,
    required ValueChanged<String> onSelected,
    required String title,
  }) async {
    if (items.isEmpty) {
      SnackbarUtils.showInfo(context, '저장된 항목이 없습니다.');
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(title),
                    trailing: IconButton(
                      icon: const Icon(IconCatalog.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final value = items[index];
                        return ListTile(
                          title: Text(value),
                          onTap: () => Navigator.of(sheetContext).pop(value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      onSelected(selected);
    }
  }

  Future<void> openShoppingCartPicker() async {
    FocusScope.of(context).unfocus();
    await _saveDraft();

    var items = await UserPrefService.getShoppingCartItems(
      accountName: widget.accountName,
    );

    if (!mounted || items.isEmpty) {
      if (mounted) SnackbarUtils.showInfo(context, '장바구니에 저장된 항목이 없습니다.');
      return;
    }

    // Make a local mutable copy so we can toggle isChecked in the picker.
    final local = items.map((e) => e.copyWith()).toList();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 640),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('장바구니 항목 선택 (지출입력으로 넘기기)'),
                    trailing: IconButton(
                      icon: const Icon(IconCatalog.close),
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: local.length,
                      itemBuilder: (context, index) {
                        final it = local[index];
                        final qty = it.quantity <= 0 ? 1 : it.quantity;
                        final unitPriceText = it.unitPrice <= 0
                            ? '-'
                            : CurrencyFormatter.formatWithDecimals(
                                it.unitPrice,
                                showUnit: false,
                              );
                        return CheckboxListTile(
                          value: it.isChecked,
                          title: Text(it.name),
                          subtitle: Text(
                            '수량: $qty'
                            '    단가: $unitPriceText',
                          ),
                          onChanged: (v) {
                            local[index] = it.copyWith(isChecked: v ?? false);
                            // rebuild sheet
                            (sheetContext as Element).markNeedsBuild();
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(false),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(true),
                            child: const Text('선택 항목 지출입력으로 이동'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || confirmed != true) return;

    // Replace original items with local (which includes isChecked flags)
    items = local;

    // load category hints for suggestions
    final hints = await UserPrefService.getShoppingCategoryHints(
      accountName: widget.accountName,
    );

    // Ensure widget still mounted before using context across async gaps
    if (!mounted) return;

    // Call bulk utility to handle sequential transactionAdd flows.
    await ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk(
      context: context,
      accountName: widget.accountName,
      items: items,
      categoryHints: hints,
      saveItems: (next) async {
        await UserPrefService.setShoppingCartItems(
          accountName: widget.accountName,
          items: next,
        );
      },
      reload: () async {},
    );
  }

  // Draft persistence (short-lived draft to survive short navigations)
  static const int _draftTtlMs = 30 * 60 * 1000; // 30 minutes

  String _draftKey() => PrefKeys.accountKey(widget.accountName, 'tx_draft_v1');

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = <String, dynamic>{
        'ts': DateTime.now().millisecondsSinceEpoch,
        'desc': _descController.text,
        'qty': _qtyController.text,
        'unitPrice': _unitPriceController.text,
        'amount': _amountController.text,
        'card': _cardChargedAmountController.text,
        'memo': _memoController.text,
        'store': _storeController.text,
        'payment': _paymentController.text,
        'type': _selectedType.name,
        'savingsAllocation': _savingsAllocation.name,
        'date': _transactionDate.toIso8601String(),
        'mainCategory': _selectedMainCategory,
        'subCategory': _selectedSubCategory,
        'detailCategory': _selectedDetailCategory,
        'location': _locationController.text,
        'supplier': _supplierController.text,
        'unit': _unitController.text,
        'expiry': _expiryDate?.toIso8601String(),
        'addToShoppingList': _addToShoppingList,
      };
      await prefs.setString(_draftKey(), jsonEncode(draft));
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey());
    } catch (_) {}
  }

  Future<void> _loadDraftIfRecent() async {
    try {
      if (!mounted) return;
      // Do not overwrite when editing an existing transaction
      if (widget.initialTransaction != null && !widget.treatAsNew) return;

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey());
      if (raw == null || raw.trim().isEmpty) return;
      final Map<String, dynamic> decoded = jsonDecode(raw);
      final ts = decoded['ts'] as int?;
      if (ts == null) {
        // malformed draft — remove
        await prefs.remove(_draftKey());
        return;
      }
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _draftTtlMs) {
        // expired — delete draft
        await prefs.remove(_draftKey());
        return;
      }

      // Restore fields
      if (!mounted) return;
      setState(() {
        _descController.text = decoded['desc'] ?? '';
        _qtyController.text = decoded['qty'] ?? _qtyController.text;
        _unitPriceController.text =
            decoded['unitPrice'] ?? _unitPriceController.text;
        _amountController.text = decoded['amount'] ?? _amountController.text;
        _cardChargedAmountController.text = decoded['card'] ?? '';
        _memoController.text = decoded['memo'] ?? '';
        _storeController.text = decoded['store'] ?? '';
        _paymentController.text = decoded['payment'] ?? '';
        try {
          _selectedType = TransactionType.values.firstWhere(
            (e) => e.name == (decoded['type'] ?? ''),
            orElse: () => _selectedType,
          );
        } catch (_) {}
        try {
          _savingsAllocation = SavingsAllocation.values.firstWhere(
            (e) => e.name == (decoded['savingsAllocation'] ?? ''),
            orElse: () => _savingsAllocation,
          );
        } catch (_) {}
        try {
          _transactionDate = DateTime.parse(
            decoded['date'] ?? _transactionDate.toIso8601String(),
          );
        } catch (_) {}
        _selectedMainCategory =
            decoded['mainCategory'] ?? _selectedMainCategory;
        _selectedSubCategory = decoded['subCategory'];
        _selectedDetailCategory = decoded['detailCategory'];
        _locationController.text = decoded['location'] ?? '';
        _supplierController.text = decoded['supplier'] ?? '';
        _unitController.text = decoded['unit'] ?? '';
        if (decoded['expiry'] != null) {
          try {
            _expiryDate = DateTime.parse(decoded['expiry']);
          } catch (_) {}
        }
        _addToShoppingList = decoded['addToShoppingList'] ?? _addToShoppingList;
      });
      _updateAmount();
    } catch (_) {}
  }

  void _captureInitialSnapshotIfNeeded() {
    if (!mounted) return;
    if (_initialSnapshot != null) return;
    _initialSnapshot = _InitialTransactionFormSnapshot(
      descText: _descController.text,
      qtyText: _qtyController.text,
      unitPriceText: _unitPriceController.text,
      amountText: _amountController.text,
      cardChargedAmountText: _cardChargedAmountController.text,
      memoText: _memoController.text,
      storeText: _storeController.text,
      paymentText: _paymentController.text,
      selectedType: _selectedType,
      savingsAllocation: _savingsAllocation,
      transactionDate: _transactionDate,
      selectedMainCategory: _selectedMainCategory,
      selectedSubCategory: _selectedSubCategory,
      selectedDetailCategory: _selectedDetailCategory,
      locationText: _locationController.text,
      supplierText: _supplierController.text,
      unitText: _unitController.text,
      expiryDate: _expiryDate,
      addToShoppingList: _addToShoppingList,
      showIncomeCategoryOptions: _showIncomeCategoryOptions,
    );
  }

  Future<void> promptRevertToInitial() async {
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
      _restoreFromInitialSnapshot(snapshot);
    }
  }

  void _restoreFromInitialSnapshot(_InitialTransactionFormSnapshot snapshot) {
    FocusScope.of(context).unfocus();

    setState(() {
      _suppressAmountAutoUpdate = true;

      _selectedType = snapshot.selectedType;
      _savingsAllocation = snapshot.savingsAllocation;
      _transactionDate = snapshot.transactionDate;
      _selectedMainCategory = snapshot.selectedMainCategory;
      _selectedSubCategory = snapshot.selectedSubCategory;
      _selectedDetailCategory = snapshot.selectedDetailCategory;
      _expiryDate = snapshot.expiryDate;
      _addToShoppingList = snapshot.addToShoppingList;
      _showIncomeCategoryOptions = snapshot.showIncomeCategoryOptions;

      _descController.text = snapshot.descText;
      _qtyController.text = snapshot.qtyText;
      _unitPriceController.text = snapshot.unitPriceText;
      _amountController.text = snapshot.amountText;
      _cardChargedAmountController.text = snapshot.cardChargedAmountText;
      _memoController.text = snapshot.memoText;
      _storeController.text = snapshot.storeText;
      _paymentController.text = snapshot.paymentText;
      _locationController.text = snapshot.locationText;
      _supplierController.text = snapshot.supplierText;
      _unitController.text = snapshot.unitText;

      _suppressAmountAutoUpdate = false;
    });
  }

  @override
  void dispose() {
    unawaited(_saveDraft());
    _autoCategoryDebounce?.cancel();
    _descController.dispose();
    _qtyController.dispose();
    _unitPriceController.dispose();
    _amountController.dispose();
    _cardChargedAmountController.dispose();
    _memoController.dispose();
    _storeController.dispose();
    _paymentController.dispose();
    _locationController.dispose();
    _supplierController.dispose();
    _unitController.dispose();

    _expenseUnitPriceFocusNode.dispose();
    _expenseQtyFocusNode.dispose();
    _paymentFocusNode.dispose();
    _amountFocusNode.dispose();
    _storeFocusNode.dispose();
    _memoFocusNode.dispose();
    _locationFocusNode.dispose();
    _supplierFocusNode.dispose();
    _unitFocusNode.dispose();
    _calculatedAmountFocusNode.dispose();
    super.dispose();
  }

  Widget _buildStoreOrBuyerField() {
    return KeyedSubtree(
      key: const Key('tx_store'),
      child: TextFormField(
        controller: _storeController,
        focusNode: _storeFocusNode,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
        onChanged: (_) => setState(() {}),
        decoration: _standardInputDecoration(
          labelText: '구매자/거래처(판매자용)',
          hintText: '선택: 판매자인 경우 구매자 이름',
          suffixIcon: _storeController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(IconCatalog.clear),
                  onPressed: () => setState(_storeController.clear),
                )
              : null,
        ),
      ),
    );
  }

  String _normalizeItemKey(String raw) {
    final trimmed = raw.trim().toLowerCase();
    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  double _median(List<double> values) {
    final sorted = List<double>.from(values)..sort();
    final n = sorted.length;
    if (n == 0) return 0;
    final mid = n ~/ 2;
    if (n.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  String _formatWon(double value) {
    final v = value.isFinite ? value : 0;
    final decimals = v == v.roundToDouble() ? 0 : 2;
    return v.toStringAsFixed(decimals);
  }

  Future<bool> _maybeConfirmPriceRise({
    required String accountName,
    required String description,
    required double currentUnitPrice,
    required String? excludeTransactionId,
  }) async {
    final normalized = _normalizeItemKey(description);
    if (normalized.isEmpty || currentUnitPrice <= 0) {
      return true;
    }

    final service = TransactionService();
    await service.loadTransactions();
    if (!mounted) return false;

    final all = service.getTransactions(accountName);
    final candidates = <Transaction>[];
    for (final t in all) {
      if (excludeTransactionId != null && t.id == excludeTransactionId) {
        continue;
      }
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;
      if (_normalizeItemKey(t.description) != normalized) continue;
      candidates.add(t);
    }

    candidates.sort((a, b) => b.date.compareTo(a.date));
    final recent = candidates.take(_priceRiseLookbackCount).toList();
    final historyUnitPrices = <double>[];
    for (final t in recent) {
      if (t.unitPrice > 0) {
        historyUnitPrices.add(t.unitPrice);
        continue;
      }
      final qty = t.quantity;
      if (qty > 0 && t.amount > 0) {
        historyUnitPrices.add(t.amount / qty);
      }
    }

    if (historyUnitPrices.length < _priceRiseMinSamples) {
      return true;
    }

    final baseline = _median(historyUnitPrices);
    if (baseline <= 0) return true;

    final delta = currentUnitPrice - baseline;
    final pct = delta / baseline;
    final isRise =
        pct >= _priceRisePctThreshold && delta >= _priceRiseMinDeltaWon;
    if (!isRise) return true;

    final pctText = (pct * 100).toStringAsFixed(0);
    final deltaText = _formatWon(delta);
    final baselineText = _formatWon(baseline);
    final currentText = _formatWon(currentUnitPrice);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('가격 상승 감지'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('품목: $description'),
              Text('최근 ${historyUnitPrices.length}건 기준 단가(중앙값):'),
              Text('$baselineText원'),
              Text('현재 단가: $currentText원'),
              Text('변화: +$deltaText원 (+$pctText%)'),
              const SizedBox(height: 8),
              const Text('계속 저장할까요?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('계속 저장'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  void _updateAmount() {
    if (_suppressAmountAutoUpdate) {
      return;
    }
    if (_selectedType != TransactionType.expense) {
      return;
    }
    final qtyText = _qtyController.text.trim();
    final qty = qtyText.isEmpty ? 1 : int.tryParse(qtyText) ?? 1;
    final unit = double.tryParse(_unitPriceController.text) ?? 0.0;
    _amountController.text = (qty * unit).toStringAsFixed(0);
  }

  void _applyIncomeDefaultCategory() {
    final defaultMain = IncomeCategoryDefinitions.defaultMainCategory;
    if (defaultMain != null) {
      _selectedMainCategory = defaultMain;
      _selectedSubCategory = null;
    } else {
      _selectedMainCategory = _defaultCategory;
      _selectedSubCategory = null;
    }
  }

  Future<void> _restoreLastCategoryForType(TransactionType type) async {
    if (_isEditing) return;

    final prefs = await SharedPreferences.getInstance();
    final savedMain = prefs.getString(_lastCategoryMainKeyFor(type));
    if (savedMain == null || savedMain.trim().isEmpty) return;

    final categoryOptions = _categoryOptionsFor(type);
    if (!categoryOptions.containsKey(savedMain)) return;

    if (!mounted) return;
    setState(() {
      _selectedMainCategory = savedMain;
      _selectedSubCategory = null;
      if (type == TransactionType.income) {
        _showIncomeCategoryOptions = savedMain != _defaultCategory;
      }
    });
  }

  Future<void> _pickTransactionDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _transactionDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _transactionDate.hour,
        _transactionDate.minute,
        _transactionDate.second,
      );
    });
  }

  Future<void> _saveTransaction({bool skipConfirm = false}) async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);

    final desc = _descController.text.trim();
    final isSavings = _selectedType == TransactionType.savings;
    final isExpense = _selectedType == TransactionType.expense;
    final qty = isExpense
        ? int.tryParse(_qtyController.text.isEmpty ? '1' : _qtyController.text)
        : 1;
    final parsedAmountText = _amountController.text.trim().replaceAll(',', '');
    final unit = isExpense
        ? double.tryParse(_unitPriceController.text)
        : double.tryParse(parsedAmountText);
    final amount = isExpense ? double.tryParse(_amountController.text) : unit;

    final cardChargedRaw = _cardChargedAmountController.text.trim().replaceAll(
      ',',
      '',
    );
    final cardChargedAmount = (!isExpense || cardChargedRaw.isEmpty)
        ? null
        : double.tryParse(cardChargedRaw);
    final paymentRaw = _paymentController.text.trim();
    final payment = isSavings
        ? (paymentRaw.isEmpty ? '자동이체' : paymentRaw)
        : paymentRaw;
    final memo = _memoController.text.trim();
    final location = _locationController.text.trim();
    final supplier = _supplierController.text.trim();
    final unitStr = _unitController.text.trim();
    final effectiveMainCategory = _selectedMainCategory;
    final effectiveSubCategory = _selectedSubCategory;
    final effectiveDetailCategory = _selectedDetailCategory;

    final amountInvalid = amount == null || amount <= 0;
    final cardInvalid =
        isExpense &&
        cardChargedRaw.isNotEmpty &&
        (cardChargedAmount == null || cardChargedAmount <= 0);
    if (desc.isEmpty ||
        qty == null ||
        unit == null ||
        amountInvalid ||
        cardInvalid ||
        (!isSavings && payment.isEmpty)) {
      SnackbarUtils.showWarning(context, '모든 필드를 올바르게 입력하세요');
      return;
    }

    // 최근 상품명/결제수단/메모 저장 (빈값/중복 제외)
    final prefs = await SharedPreferences.getInstance();
    if (desc.isNotEmpty) {
      final updated = [desc, ..._recentDescriptions.where((e) => e != desc)];
      final clipped = updated.take(_maxRecentDescriptions).toList();
      await prefs.setStringList(_recentDescriptionsKey, clipped);
      _recentDescriptions = clipped;
    }
    if (payment.isNotEmpty) {
      final updated = [payment, ..._recentPayments.where((e) => e != payment)];
      await prefs.setStringList(
        _recentPaymentsKey,
        updated.take(_maxRecentPayments).toList(),
      );
      _recentPayments = updated.take(_maxRecentPayments).toList();
    }
    if (memo.isNotEmpty) {
      final updated = [memo, ..._recentMemos.where((e) => e != memo)];
      await prefs.setStringList(
        _recentMemosKey,
        updated.take(_maxRecentMemos).toList(),
      );
      _recentMemos = updated.take(_maxRecentMemos).toList();
    }

    if (isExpense) {
      final ok = await _maybeConfirmPriceRise(
        accountName: widget.accountName,
        description: desc,
        currentUnitPrice: unit,
        excludeTransactionId: _isEditing ? widget.initialTransaction?.id : null,
      );
      if (!mounted) return;
      if (!ok) return;
    }

    if (widget.confirmBeforeSave && !skipConfirm) {
      final isShoppingCategory = _isShoppingCategory(
        effectiveMainCategory,
        effectiveSubCategory,
      );
      final canShowShoppingCompare = isExpense && isShoppingCategory;
      final Future<String?>? shoppingCompareFuture = canShowShoppingCompare
          ? _buildShoppingSpendComparisonTooltip(
              accountName: widget.accountName,
            )
          : null;

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final main = effectiveMainCategory.trim().isEmpty
              ? _defaultCategory
              : effectiveMainCategory;
          final categoryText = '$main / -';
          final qtyText = isExpense ? '$qty개' : '-';
          final unitDecimals = unit == unit.roundToDouble() ? 0 : 2;
          final unitFormatted = unit.toStringAsFixed(unitDecimals);
          final unitText = isExpense ? '$unitFormatted원' : '-';
          final amountDecimals = amount == amount.roundToDouble() ? 0 : 2;
          final amountFormatted = amount.toStringAsFixed(amountDecimals);
          final amountText = '$amountFormatted원';
          final cardText = (cardChargedAmount == null)
              ? '-'
              : '${cardChargedAmount.toStringAsFixed(0)}원';

          return AlertDialog(
            title: const Text('저장 전에 확인'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('상품명: $desc'),
                Text('수량: $qtyText'),
                Text('단가: $unitText'),
                Text('금액: $amountText'),
                if (isExpense) Text('카드결제금액: $cardText'),
                Text('카테고리: $categoryText'),
                if (!isSavings) Text('결제수단: $payment'),
                if (memo.isNotEmpty) Text('메모: $memo'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              if (shoppingCompareFuture == null)
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('저장'),
                )
              else
                FutureBuilder<String?>(
                  future: shoppingCompareFuture,
                  builder: (context, snapshot) {
                    final message = switch (snapshot.connectionState) {
                      ConnectionState.waiting => '비교 계산 중…',
                      _ => snapshot.data,
                    };

                    final button = FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('저장'),
                    );

                    if (message == null || message.trim().isEmpty) {
                      return button;
                    }
                    return Tooltip(message: message, child: button);
                  },
                ),
            ],
          );
        },
      );

      if (!mounted) return;
      if (confirmed != true) {
        return;
      }
    }

    // 즐겨찾기 자동 저장 차단 (임시 비활성화)

    final existing = _isEditing ? widget.initialTransaction : null;
    final derivedStore = StoreMemoUtils.extractStoreKey(memo);
    final typedStore = _storeController.text.trim();
    final storeForSave = typedStore.isNotEmpty
        ? typedStore
        : (existing?.store?.trim().isNotEmpty ?? false)
        ? existing!.store!.trim()
        : (derivedStore?.trim().isNotEmpty ?? false)
        ? derivedStore!.trim()
        : null;
    final transaction = Transaction(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      description: desc,
      amount: amount,
      cardChargedAmount: cardChargedAmount,
      date: existing?.date ?? _transactionDate,
      quantity: qty,
      unit: unitStr.isNotEmpty ? unitStr : null,
      unitPrice: unit,
      paymentMethod: payment,
      memo: memo,
      store: storeForSave,
      savingsAllocation: isSavings ? _savingsAllocation : null,
      mainCategory: effectiveMainCategory,
      subCategory: effectiveSubCategory,
      detailCategory: effectiveDetailCategory,
      location: location.isNotEmpty ? location : null,
      supplier: supplier.isNotEmpty ? supplier : null,
      expiryDate: _expiryDate,
    );

    final service = TransactionService();
    try {
      if (existing == null) {
        await service.addTransaction(widget.accountName, transaction);

        if (_addToShoppingList) {
          final currentItems = await UserPrefService.getShoppingCartItems(
            accountName: widget.accountName,
          );
          final now = DateTime.now();
          final newItem = ShoppingCartItem(
            id: 'sc_${now.microsecondsSinceEpoch}',
            name: desc,
            quantity: qty,
            unitPrice: unit,
            memo: memo,
            createdAt: now,
            updatedAt: now,
          );
          await UserPrefService.setShoppingCartItems(
            accountName: widget.accountName,
            items: [...currentItems, newItem],
          );
        }

        if (effectiveMainCategory !=
            DetailedCategoryDefinitions.defaultCategory) {
          unawaited(
            CategoryUsageService.increment(
              main: effectiveMainCategory,
              sub: effectiveSubCategory,
              detail: effectiveDetailCategory,
            ),
          );
          unawaited(
            RecentInputService.saveCategory(
              CategoryUsageService.labelFor(
                main: effectiveMainCategory,
                sub: effectiveSubCategory,
                detail: effectiveDetailCategory,
              ),
            ),
          );
        }

        // 식비 카테고리이고 유통기한이 입력된 경우 재고 관리(FoodExpiryService)에 자동 추가
        final isFood =
            effectiveMainCategory == '식품·음료비' ||
            effectiveMainCategory == '식비' ||
            effectiveMainCategory == 'Food';
        if (isExpense && isFood && _expiryDate != null) {
          unawaited(
            FoodExpiryService.instance.addItem(
              name: desc,
              purchaseDate: _transactionDate,
              expiryDate: _expiryDate!,
              memo: memo,
              quantity: qty.toDouble(),
              unit: unitStr.isNotEmpty ? unitStr : '개',
            ),
          );
        }

        // 수입 거래인 경우 자산에 추가할지 확인
        if (_selectedType == TransactionType.income && !isSavings) {
          if (!mounted) return;
          // 현재 context를 저장해두고 대화상자 표시
          final shouldDistribute = await _showAssetAllocationDialog(
            transaction,
          );
          if (shouldDistribute == null) {
            // 취소됨
            return;
          } else if (shouldDistribute) {
            // 분배하기 선택
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IncomeSplitScreen(
                  accountName: widget.accountName,
                  initialIncomeAmount: transaction.amount,
                ),
              ),
            );
          } else {
            // 현금 추가만 선택
            await _addToCashAsset(transaction);
          }
        }
      } else {
        final updated = await service.updateTransaction(
          widget.accountName,
          transaction,
        );
        if (!updated) {
          if (!mounted) return;
          SnackbarUtils.showError(context, '거래 수정에 실패했습니다. 다시 시도하세요');
          return;
        }

        if (effectiveMainCategory != _defaultCategory) {
          unawaited(
            CategoryUsageService.increment(
              main: effectiveMainCategory,
              sub: effectiveSubCategory,
            ),
          );
          unawaited(
            RecentInputService.saveCategory(
              CategoryUsageService.labelFor(
                main: effectiveMainCategory,
                sub: effectiveSubCategory,
              ),
            ),
          );
        }
      }

      final baseMessage = existing == null ? '거래가 저장되었습니다' : '거래가 수정되었습니다';
      final detail = isSavings ? ' (${_savingsAllocation.snackBarDetail})' : '';
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '$baseMessage$detail');
      await _clearDraft();

      if (widget.learnCategoryHintFromDescription &&
          effectiveMainCategory != _defaultCategory) {
        unawaited(
          UserPrefService.setShoppingCategoryHint(
            accountName: widget.accountName,
            keyword: desc,
            hint: CategoryHint(
              mainCategory: effectiveMainCategory,
              subCategory: effectiveSubCategory,
              detailCategory: effectiveDetailCategory,
            ),
          ),
        );
      }

      if (existing != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) navigator.pop(true);
        });
      } else {
        if (widget.closeAfterSave) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) navigator.pop(true);
          });
          return;
        }
        if (!mounted) return;
        _didSaveAtLeastOnce = true;
        void resetForNextEntry() {
          setState(() {
            _suppressAmountAutoUpdate = true;

            _userPickedCategory = false;

            _descController.clear();
            // _memoController.clear();

            // 타입/날짜/결제수단/메모/카테고리는 유지(터치 최소화)
            _qtyController.text = '1';
            _unitPriceController.clear();
            _amountController.clear();

            _suppressAmountAutoUpdate = false;

            // 다음 입력을 기준으로 “입력값 되돌리기” 스냅샷을 재설정
            _initialSnapshot = null;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _captureInitialSnapshotIfNeeded();
            _descFocusNode.requestFocus();
          });
        }

        resetForNextEntry();
      }

      _initialSnapshot = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureInitialSnapshotIfNeeded();
      });
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '거래 저장 중 오류: ${e.toString()}');
    }
  }

  /// 수입 거래 저장 후 자산 할당 확인
  /// null: 취소, true: 분배하기, false: 현금 추가만
  Future<bool?> _showAssetAllocationDialog(Transaction transaction) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        return AlertDialog(
          icon: Icon(IconCatalog.trendingUp, size: 48, color: scheme.primary),
          title: const Text('수입 분배'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction.description} ('
                  '${transaction.amount.toStringAsFixed(0)}원)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('이 수입을 어떻게 처리할까요?', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '옵션 1: 현금 자산에 추가 (권장)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                      const Text(
                        '급여가 현금으로 입금되어, 현금 자산의 잔액이 증가합니다.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '옵션 2: 지금 바로 분배하기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.tertiary,
                        ),
                      ),
                      const Text(
                        '저축, 예산, 비상금, 투자로 나누어 배분합니다.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('옵션 1: 현금 추가만'),
            ),
            FilledButton.icon(
              icon: const Icon(IconCatalog.accountBalanceWallet),
              label: const Text('옵션 2: 분배하기'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );
  }

  /// 현금 자산에 수입금 추가
  Future<void> _addToCashAsset(Transaction transaction) async {
    try {
      final assetService = AssetService();
      await assetService.loadAssets();

      var assets = assetService.getAssets(widget.accountName);
      final now = DateTime.now();

      // 현금 자산 찾기 또는 생성
      Asset? cashAsset;
      final cashList = assets
          .where((a) => a.category == AssetCategory.cash && a.name == '현금')
          .toList();
      if (cashList.isNotEmpty) {
        cashAsset = cashList.first;
      }
      final Asset actualCashAsset =
          cashAsset ??
          Asset(
            id: '${now.microsecondsSinceEpoch}_cash',
            name: '현금',
            amount: 0,
            category: AssetCategory.cash,
            memo: '기본 현금 자산',
            date: now,
          );

      if (!assets.any((a) => a.id == actualCashAsset.id)) {
        await assetService.addAsset(widget.accountName, actualCashAsset);
        assets = assetService.getAssets(widget.accountName);
      }

      // 기존 현금 자산의 금액 증가
      final updatedAsset = Asset(
        id: actualCashAsset.id,
        name: actualCashAsset.name,
        amount: actualCashAsset.amount + transaction.amount,
        category: actualCashAsset.category,
        memo: actualCashAsset.memo.isEmpty
            ? '${transaction.description} 입금'
            : '${actualCashAsset.memo}\n${transaction.description} 입금',
        date: actualCashAsset.date,
        inputType: actualCashAsset.inputType,
        targetRatio: actualCashAsset.targetRatio,
        targetAmount: actualCashAsset.targetAmount,
        isInvestment: actualCashAsset.isInvestment,
        conversionDate: actualCashAsset.conversionDate,
      );

      await assetService.updateAsset(widget.accountName, updatedAsset);

      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        '${transaction.amount.toStringAsFixed(0)}원이 현금 자산에 추가되었습니다',
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showWarning(context, '자산 추가 중 오류: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      children: [
        if (widget.titlePrefix != null) _buildInlineHeader(),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.only(
                left: isLandscape ? 16 : 0,
                right: isLandscape ? 16 : 0,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              children: [..._buildFieldsForSelectedType()],
            ),
          ),
        ),
        // 하단 고정 버튼 바 (가로모드에서는 헤더로 통합하여 숨김)
        if (!isLandscape)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _buildSaveButtons(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInlineHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.titlePrefix} - ${widget.accountName}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: '장바구니 불러오기',
              icon: const Icon(IconCatalog.shoppingCart),
              onPressed: openShoppingCartPicker,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '입력값 되돌리기',
              icon: const Icon(IconCatalog.restartAlt),
              onPressed: promptRevertToInitial,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            _buildSaveButtons(compact: true),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFieldsForSelectedType() {
    switch (_selectedType) {
      case TransactionType.savings:
        return _buildSavingsFields();
      case TransactionType.income:
        return _buildIncomeFields();
      case TransactionType.expense:
        return _buildExpenseFields();
      case TransactionType.refund:
        return _buildRefundFields();
    }
  }

  List<Widget> _buildSavingsFields() {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final spacing = isLandscape ? 8.0 : 12.0;

    return [
      _buildDescriptionInput(
        labelText: '상품명',
        emptyMessage: '상품명을 입력하세요.',
        enableHistory: true,
      ),
      SizedBox(height: spacing),
      TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: '예금 금액 (원)',
          border: OutlineInputBorder(),
        ),
        validator: (value) => _validatePositiveAmount(value, '예금 금액을 입력하세요.'),
      ),
      SizedBox(height: spacing),
      _buildSavingsDateField(),
      SizedBox(height: spacing),
      _buildSavingsAllocationSelector(theme),
      const SizedBox(height: 4),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          _savingsAllocation.helperText,
          key: ValueKey(_savingsAllocation),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      SizedBox(height: spacing),
      _buildMemoField(onSubmitted: _saveTransaction),
      SizedBox(height: isLandscape ? 12 : 24),
      _buildCategorySection(),
    ];
  }

  /// 저장 + 저장후계속 버튼
  Widget _buildSaveButtons({bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: compact ? 0.7 : 0.8,
          child: FloatingActionButton.small(
            heroTag: 'save_continue',
            onPressed: _saveAndContinue,
            tooltip: '저장 후 계속',
            child: const Icon(IconCatalog.arrowForward),
          ),
        ),
        const SizedBox(width: 4), // 간격 축소
        Transform.scale(
          scale: compact ? 0.6 : 0.7,
          child: FloatingActionButton(
            heroTag: 'save',
            onPressed: _saveTransaction,
            tooltip: '저장',
            child: Text(
              compact ? '저장' : 'ENT',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// 메모 입력 필드 (공통)
  Widget _buildMemoField({required VoidCallback onSubmitted}) {
    return KeyedSubtree(
      key: const Key('tx_memo'),
      child: TextFormField(
        controller: _memoController,
        focusNode: _memoFocusNode,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => onSubmitted(),
        onChanged: (_) => setState(() {}),
        decoration: _standardInputDecoration(
          labelText: '메모',
          hintText: '예: 마트 이름 + 간단 메모',
          suffixIcon: IconButton(
            tooltip: '입력내용 불러오기',
            icon: Icon(
              Icons.list_alt,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => _showRecentInputPicker(
              context: context,
              items: _recentMemos,
              onSelected: (v) {
                _memoController.text = v;
                _memoController.selection = TextSelection.fromPosition(
                  TextPosition(offset: v.length),
                );
                setState(() {});
              },
              title: '메모 입력내용 불러오기',
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentField({
    required Key fieldKey,
    required FocusNode focusNode,
    required TextEditingController controller,
    required VoidCallback onSubmitted,
    required String labelText,
    String? hintText,
    String? emptyErrorText,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      key: fieldKey,
      focusNode: focusNode,
      controller: controller,
      textInputAction: textInputAction,
      onFieldSubmitted: (_) => onSubmitted(),
      decoration: _standardInputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: IconButton(
          tooltip: '입력내용 불러오기',
          icon: Icon(
            Icons.list_alt,
            size: 20,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => _showRecentInputPicker(
            context: context,
            items: _recentPayments,
            onSelected: (v) {
              controller.text = v;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: v.length),
              );
              setState(() {});
            },
            title: '결제수단 입력내용 불러오기',
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      validator: (value) {
        if (emptyErrorText == null) return null;
        return value == null || value.trim().isEmpty ? emptyErrorText : null;
      },
    );
  }

  Widget _buildSavingsAllocationSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('예금 반영 방식', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<SavingsAllocation>(
            segments: const [
              ButtonSegment<SavingsAllocation>(
                value: SavingsAllocation.assetIncrease,
                icon: Icon(IconCatalog.savings, size: 18),
                label: Text('자산으로 저장'),
              ),
              ButtonSegment<SavingsAllocation>(
                value: SavingsAllocation.expense,
                icon: Icon(IconCatalog.payments, size: 18),
                label: Text('지출로 저장'),
              ),
            ],
            selected: {_savingsAllocation},
            onSelectionChanged: (Set<SavingsAllocation> newSelection) {
              setState(() {
                _savingsAllocation = newSelection.first;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsDateField() {
    final formatted = DateFormatter.defaultDate.format(_transactionDate);
    final theme = Theme.of(context);
    return InkWell(
      onTap: _pickTransactionDate,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '예금일',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatted),
            Icon(
              IconCatalog.calendarTodayOutlined,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIncomeFields() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final spacing = isLandscape ? 8.0 : 12.0;

    return [
      _buildDescriptionInput(
        labelText: '내용',
        emptyMessage: '내용을 입력하세요.',
        enableHistory: true,
        onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: KeyedSubtree(
              key: const Key('tx_amount'),
              child: TextFormField(
                focusNode: _amountFocusNode,
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _paymentFocusNode.requestFocus(),
                validator: (value) =>
                    _validatePositiveAmount(value, '금액을 입력하세요.'),
                decoration: _standardInputDecoration(labelText: '금액 (수동 입력)'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _buildPaymentField(
              fieldKey: const Key('tx_payment'),
              focusNode: _paymentFocusNode,
              controller: _paymentController,
              onSubmitted: () =>
                  FocusScope.of(context).requestFocus(_memoFocusNode),
              labelText: '결제수단',
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      _buildMemoField(onSubmitted: _saveTransaction),
      SizedBox(height: isLandscape ? 12 : 24),
      _buildCategorySection(),
    ];
  }

  List<Widget> _buildRefundFields() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final spacing = isLandscape ? 8.0 : 12.0;

    return [
      _buildDescriptionInput(
        labelText: '반품 내역',
        emptyMessage: '반품 내역을 입력하세요.',
        enableHistory: true,
        onFieldSubmitted: (_) => _storeFocusNode.requestFocus(),
      ),
      SizedBox(height: spacing),
      _buildStoreOrBuyerField(),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: KeyedSubtree(
              key: const Key('tx_amount'),
              child: TextFormField(
                focusNode: _amountFocusNode,
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _paymentFocusNode.requestFocus(),
                validator: (value) =>
                    _validatePositiveAmount(value, '금액을 입력하세요.'),
                decoration: _standardInputDecoration(labelText: '반품 금액'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _buildPaymentField(
              fieldKey: const Key('tx_payment'),
              focusNode: _paymentFocusNode,
              controller: _paymentController,
              onSubmitted: () =>
                  FocusScope.of(context).requestFocus(_memoFocusNode),
              labelText: '환불 계좌/수단',
              emptyErrorText: '환불 수단 입력',
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      _buildMemoField(onSubmitted: _saveTransaction),
      SizedBox(height: isLandscape ? 12 : 24),
      _buildCategorySection(),
    ];
  }

  List<Widget> _buildExpenseFields() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final spacing = isLandscape ? 8.0 : 12.0;

    return [
      _buildDescriptionInput(
        labelText: '상품명',
        emptyMessage: '상품명을 입력하세요.',
        enableHistory: true,
        onFieldSubmitted: (_) => _expenseUnitPriceFocusNode.requestFocus(),
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              key: const Key('tx_unit_price'),
              controller: _unitPriceController,
              focusNode: _expenseUnitPriceFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '단가 입력' : null,
              decoration: _standardInputDecoration(labelText: '단가'),
              onFieldSubmitted: (_) => _expenseQtyFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              key: const Key('tx_qty'),
              controller: _qtyController,
              focusNode: _expenseQtyFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '수량 입력' : null,
              decoration: _standardInputDecoration(labelText: '수량'),
              onFieldSubmitted: (_) => _unitFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              key: const Key('tx_unit'),
              controller: _unitController,
              focusNode: _unitFocusNode,
              textInputAction: TextInputAction.next,
              decoration: _standardInputDecoration(
                labelText: '단위',
                hintText: 'kg, 개 등',
              ),
              onFieldSubmitted: (_) => _locationFocusNode.requestFocus(),
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _locationController,
              focusNode: _locationFocusNode,
              textInputAction: TextInputAction.next,
              decoration: _standardInputDecoration(
                labelText: '보관장소',
                hintText: '냉장고, 팬트리 등',
              ),
              onFieldSubmitted: (_) => _supplierFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _supplierController,
              focusNode: _supplierFocusNode,
              textInputAction: TextInputAction.next,
              decoration: _standardInputDecoration(
                labelText: '마트/쇼핑몰',
                hintText: '마트, 온라인 쇼핑몰 등',
              ),
              onFieldSubmitted: (_) => _paymentFocusNode.requestFocus(),
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _expiryDate ??
                      DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) {
                  setState(() => _expiryDate = picked);
                }
              },
              child: InputDecorator(
                decoration: _standardInputDecoration(labelText: '유통기한'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _expiryDate == null
                          ? '선택 안함'
                          : DateFormat('yyyy-MM-dd').format(_expiryDate!),
                    ),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CheckboxListTile(
              title: const Text('장바구니', style: TextStyle(fontSize: 14)),
              value: _addToShoppingList,
              onChanged: (v) => setState(() => _addToShoppingList = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _amountController,
              focusNode: _calculatedAmountFocusNode,
              readOnly: true,
              decoration: _standardInputDecoration(labelText: '금액(자동계산)'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _buildPaymentField(
              fieldKey: const Key('tx_payment'),
              focusNode: _paymentFocusNode,
              controller: _paymentController,
              onSubmitted: () =>
                  FocusScope.of(context).requestFocus(_memoFocusNode),
              labelText: '결제수단',
              emptyErrorText: '결제수단 입력',
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      _buildMemoField(onSubmitted: _saveTransaction),
      SizedBox(height: isLandscape ? 12 : 24),
      _buildCategorySection(),
    ];
  }

  // 결제수단 기능(히스토리/선택) 비활성화: 사용 중단 상태

  Widget _buildCategorySection() {
    final isIncome = _selectedType == TransactionType.income;
    final showOptions = !isIncome || _showIncomeCategoryOptions;

    if (!showOptions) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              if (_selectedType == TransactionType.income &&
                  _selectedMainCategory ==
                      DetailedCategoryDefinitions.defaultCategory) {
                _applyIncomeDefaultCategory();
              }
              _showIncomeCategoryOptions = true;
            });
          },
          icon: const Icon(IconCatalog.categoryOutlined),
          label: const Text('카테고리 옵션 표시'),
        ),
      );
    }

    final theme = Theme.of(context);

    if (isIncome) {
      const categoryMap = IncomeCategoryDefinitions.categoryOptions;
      final mainCategories = categoryMap.keys.toList();
      final subCategories =
          categoryMap[_selectedMainCategory] ?? const <String>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('카테고리', style: theme.textTheme.labelLarge),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showIncomeCategoryOptions = false;
                    _selectedMainCategory =
                        DetailedCategoryDefinitions.defaultCategory;
                    _selectedSubCategory = null;
                    _selectedDetailCategory = null;
                  });
                },
                icon: const Icon(IconCatalog.visibilityOffOutlined, size: 16),
                label: const Text('숨기기'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mainCategories.map((cat) {
              final isSelected = _selectedMainCategory == cat;
              return ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                    letterSpacing: -0.2,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _userPickedCategory = true;
                    _selectedMainCategory = cat;
                    _selectedSubCategory = null;
                    _selectedDetailCategory = null;
                  });
                  unawaited(
                    _persistLastCategoryForType(_selectedType, main: cat),
                  );
                },
              );
            }).toList(),
          ),
          if (subCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subCategories.map((cat) {
                final isSelected = _selectedSubCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 12.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      _userPickedCategory = true;
                      _selectedSubCategory = cat;
                      _selectedDetailCategory = null;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      );
    }

    // Detailed 3-tier logic for expenses
    final mainCategories = DetailedCategoryDefinitions.mainCategories;
    final subCategories = DetailedCategoryDefinitions.getSubCategories(
      _selectedMainCategory,
    );
    final detailCategories = _selectedSubCategory != null
        ? DetailedCategoryDefinitions.getDetailCategories(
            _selectedMainCategory,
            _selectedSubCategory!,
          )
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('대분류', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: mainCategories.map((cat) {
            final isSelected = _selectedMainCategory == cat;
            return ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12.5,
                  letterSpacing: -0.2,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (!selected) return;
                setState(() {
                  _userPickedCategory = true;
                  _selectedMainCategory = cat;
                  _selectedSubCategory = null;
                  _selectedDetailCategory = null;
                });
                unawaited(
                  _persistLastCategoryForType(_selectedType, main: cat),
                );
              },
            );
          }).toList(),
        ),
        if (subCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('중분류', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subCategories.map((cat) {
              final isSelected = _selectedSubCategory == cat;
              return ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                    letterSpacing: -0.2,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _userPickedCategory = true;
                    _selectedSubCategory = cat;
                    _selectedDetailCategory = null;
                  });
                },
              );
            }).toList(),
          ),
        ],
        if (detailCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('소분류(상세)', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detailCategories.map((cat) {
              final isSelected = _selectedDetailCategory == cat;
              return ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                    letterSpacing: -0.2,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _userPickedCategory = true;
                    _selectedDetailCategory = cat;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionInput({
    required String labelText,
    required String emptyMessage,
    required bool enableHistory,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return KeyedSubtree(
      key: const Key('tx_desc'),
      child: TextFormField(
        controller: _descController,
        focusNode: _descFocusNode,
        textInputAction: TextInputAction.next,
        validator: (value) =>
            value == null || value.trim().isEmpty ? emptyMessage : null,
        onFieldSubmitted: onFieldSubmitted,
        onChanged: (v) {
          _handleDescriptionChanged(v);
          setState(() {});
        },
        decoration: _standardInputDecoration(
          labelText: labelText,
          suffixIcon: IconButton(
            tooltip: '입력내용 불러오기',
            icon: Icon(
              Icons.list_alt,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => _showRecentInputPicker(
              context: context,
              items: _recentDescriptions,
              onSelected: (v) {
                _descController.text = v;
                _descController.selection = TextSelection.fromPosition(
                  TextPosition(offset: v.length),
                );
                _handleDescriptionChanged(v);
                setState(() {});
              },
              title: '상품명 입력내용 불러오기',
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  String? _validatePositiveAmount(String? value, String errorMessage) {
    final raw = value?.trim() ?? '';
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      return errorMessage;
    }
    return null;
  }

  /// 거래 저장 후 계속 입력 (Shift+Enter)
  Future<void> _saveAndContinue() async {
    await _saveTransaction();
  }
}
