import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/screens/income_split_screen.dart';
// import 'package:smart_ledger/screens/nutrition_report_screen.dart';
// Preserved but disabled per request.
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/services/category_usage_service.dart';
import 'package:smart_ledger/services/recent_input_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/category_definitions.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';
import 'package:smart_ledger/utils/date_formatter.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/income_category_definitions.dart';
import 'package:smart_ledger/utils/snackbar_utils.dart';
import 'package:smart_ledger/utils/store_memo_utils.dart';
import 'package:smart_ledger/widgets/smart_input_field.dart';

// 최근 결제수단/메모 저장 키 및 최대 개수
const String _recentDescriptionsKey = 'recent_descriptions';
const String _recentPaymentsKey = 'recent_payments';
const String _recentMemosKey = 'recent_memos';
const int _maxRecentDescriptions = 30;
const int _maxRecentPayments = 10;
const int _maxRecentMemos = 10;
const String _lastCategoryMainKeyPrefix = 'last_category_main';
const String _lastCategorySubKeyPrefix = 'last_category_sub';
const String _defaultCategory = CategoryDefinitions.defaultCategory;

// const int _maxFavoriteDescriptions = 20;
// const int _maxFavoriteMemos = 10;

Map<String, List<String>> _categoryOptionsFor(TransactionType type) {
  if (type == TransactionType.income) {
    return IncomeCategoryDefinitions.categoryOptions;
  }
  return CategoryDefinitions.categoryOptions;
}

class TransactionAddScreen extends StatefulWidget {
  final String accountName;
  final Transaction? initialTransaction;
  final bool learnCategoryHintFromDescription;
  final bool confirmBeforeSave;
  final bool treatAsNew;
  const TransactionAddScreen({
    super.key,
    required this.accountName,
    this.initialTransaction,
    this.learnCategoryHintFromDescription = false,
    this.confirmBeforeSave = false,
    this.treatAsNew = false,
  });

  @override
  State<TransactionAddScreen> createState() => _TransactionAddScreenState();
}

class _TransactionAddScreenState extends State<TransactionAddScreen> {
  final GlobalKey<_TransactionAddFormState> _formStateKey =
      GlobalKey<_TransactionAddFormState>();

  @override
  Widget build(BuildContext context) {
    final isEditing =
        widget.initialTransaction != null && widget.treatAsNew == false;

    final isIncomeTemplate =
        widget.initialTransaction?.type == TransactionType.income;
    final titlePrefix = isIncomeTemplate
        ? (isEditing ? '수입 수정' : '수입')
        : (isEditing ? '거래 수정' : '지출 입력');

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
      child: Scaffold(
        appBar: AppBar(
          title: Text('$titlePrefix - ${widget.accountName}'),
          actions: [
            IconButton(
              tooltip: '입력값 되돌리기',
              icon: const Icon(IconCatalog.restartAlt),
              onPressed: () =>
                  _formStateKey.currentState?.promptRevertToInitial(),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical:
                MediaQuery.of(context).orientation == Orientation.landscape
                ? 8.0
                : 16.0,
          ),
          child: TransactionAddForm(
            key: _formStateKey,
            accountName: widget.accountName,
            initialTransaction: widget.initialTransaction,
            learnCategoryHintFromDescription:
                widget.learnCategoryHintFromDescription,
            confirmBeforeSave: widget.confirmBeforeSave,
            treatAsNew: widget.treatAsNew,
          ),
        ),
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
  final bool showIncomeCategoryOptions;
}

class TransactionAddForm extends StatefulWidget {
  final String accountName;
  final Transaction? initialTransaction;
  final bool learnCategoryHintFromDescription;
  final bool confirmBeforeSave;
  final bool treatAsNew;
  const TransactionAddForm({
    super.key,
    required this.accountName,
    this.initialTransaction,
    this.learnCategoryHintFromDescription = false,
    this.confirmBeforeSave = false,
    this.treatAsNew = false,
  });

  @override
  State<TransactionAddForm> createState() => _TransactionAddFormState();
}

class _TransactionAddFormState extends State<TransactionAddForm> {
  List<String> _recentDescriptions = [];
  List<String> _recentPayments = [];
  List<String> _recentMemos = [];
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

  final FocusNode _expenseUnitPriceFocusNode = FocusNode();
  final FocusNode _expenseQtyFocusNode = FocusNode();
  final FocusNode _paymentFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _storeFocusNode = FocusNode();
  final FocusNode _memoFocusNode = FocusNode();
  final FocusNode _calculatedAmountFocusNode = FocusNode(
    canRequestFocus: false,
    skipTraversal: true,
  );

  TransactionType _selectedType = TransactionType.expense;
  SavingsAllocation _savingsAllocation = SavingsAllocation.assetIncrease;
  late DateTime _transactionDate;
  String _selectedMainCategory = _defaultCategory;
  String? _selectedSubCategory;
  bool _showIncomeCategoryOptions = true;

  bool _suppressAmountAutoUpdate = false;
  _InitialTransactionFormSnapshot? _initialSnapshot;

  bool _didSaveAtLeastOnce = false;

  bool get didSave => _didSaveAtLeastOnce;

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

  // ...existing code...
  String _lastCategoryMainKeyFor(TransactionType type) =>
      '${_lastCategoryMainKeyPrefix}_${widget.accountName}_${type.name}';
  String _lastCategorySubKeyFor(TransactionType type) =>
      '${_lastCategorySubKeyPrefix}_${widget.accountName}_${type.name}';

  List<String> _sortedMainCategories = [];

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
      _selectedSubCategory = null;
    } else {
      _qtyController.text = '1';
    }
    if (_selectedType == TransactionType.income) {
      if (_isEditing) {
        _showIncomeCategoryOptions = _selectedMainCategory != _defaultCategory;
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

    unawaited(_loadRecentInputs());
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

    setState(() {
      _sortedMainCategories = sorted;
    });
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
      _selectedSubCategory = null;
      _showIncomeCategoryOptions = snapshot.showIncomeCategoryOptions;

      _descController.text = snapshot.descText;
      _qtyController.text = snapshot.qtyText;
      _unitPriceController.text = snapshot.unitPriceText;
      _amountController.text = snapshot.amountText;
      _cardChargedAmountController.text = snapshot.cardChargedAmountText;
      _memoController.text = snapshot.memoText;
      _storeController.text = snapshot.storeText;
      _paymentController.text = snapshot.paymentText;

      _suppressAmountAutoUpdate = false;
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _qtyController.dispose();
    _unitPriceController.dispose();
    _amountController.dispose();
    _cardChargedAmountController.dispose();
    _memoController.dispose();
    _storeController.dispose();
    _paymentController.dispose();

    _expenseUnitPriceFocusNode.dispose();
    _expenseQtyFocusNode.dispose();
    _paymentFocusNode.dispose();
    _amountFocusNode.dispose();
    _storeFocusNode.dispose();
    _memoFocusNode.dispose();
    _calculatedAmountFocusNode.dispose();
    super.dispose();
  }

  Widget _buildStoreOrBuyerField() {
    return KeyedSubtree(
      key: const Key('tx_store'),
      child: SmartInputField(
        controller: _storeController,
        focusNode: _storeFocusNode,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
        onChanged: (_) => setState(() {}),
        label: '구매자/거래처(판매자용)',
        hint: '선택: 판매자인 경우 구매자 이름',
        suffixIcon: _storeController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(IconCatalog.clear),
                onPressed: () => setState(_storeController.clear),
              )
            : null,
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

  Future<void> _persistLastCategoryForType(
    TransactionType type, {
    required String main,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCategoryMainKeyFor(type), main);
    // TransactionAddScreen now stores main-category only.
    await prefs.remove(_lastCategorySubKeyFor(type));
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

  Future<void> _saveTransaction() async {
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
    final effectiveMainCategory = _selectedMainCategory;
    // TransactionAddScreen now stores main-category only.
    const String? effectiveSubCategory = null;

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

    if (widget.confirmBeforeSave) {
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
      unitPrice: unit,
      paymentMethod: payment,
      memo: memo,
      store: storeForSave,
      savingsAllocation: isSavings ? _savingsAllocation : null,
      mainCategory: effectiveMainCategory,
    );

    final service = TransactionService();
    try {
      if (existing == null) {
        await service.addTransaction(widget.accountName, transaction);

        if (effectiveMainCategory != _defaultCategory) {
          unawaited(
            CategoryUsageService.increment(
              main: effectiveMainCategory,
            ),
          );
          unawaited(
            RecentInputService.saveCategory(
              CategoryUsageService.labelFor(
                main: effectiveMainCategory,
              ),
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
            ),
          );
          unawaited(
            RecentInputService.saveCategory(
              CategoryUsageService.labelFor(
                main: effectiveMainCategory,
              ),
            ),
          );
        }
      }

      final baseMessage = existing == null ? '거래가 저장되었습니다' : '거래가 수정되었습니다';
      final detail = isSavings ? ' (${_savingsAllocation.snackBarDetail})' : '';
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '$baseMessage$detail');

      if (widget.learnCategoryHintFromDescription &&
          effectiveMainCategory != _defaultCategory) {
        unawaited(
          UserPrefService.setShoppingCategoryHint(
            accountName: widget.accountName,
            keyword: desc,
            hint: CategoryHint(
              mainCategory: effectiveMainCategory,
            ),
          ),
        );
      }

      if (existing != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) navigator.pop(true);
        });
      } else {
        if (!mounted) return;
        _didSaveAtLeastOnce = true;
        void resetForNextEntry() {
          setState(() {
            _suppressAmountAutoUpdate = true;

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
    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            top: 12, // Add top padding to prevent label clipping
            bottom:
                MediaQuery.of(context).padding.bottom +
                80, // Add padding for FAB
          ),
          children: [..._buildFieldsForSelectedType()],
        ),
      ),
      floatingActionButton: _buildSaveButtons(),
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
    return [
      _buildDescriptionInput(
        labelText: '상품명',
        emptyMessage: '상품명을 입력하세요.',
        enableHistory: true,
      ),
      const SizedBox(height: 12),
      SmartInputField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        label: '예금 금액 (원)',
        validator: (value) => _validatePositiveAmount(value, '예금 금액을 입력하세요.'),
      ),
      const SizedBox(height: 12),
      _buildSavingsDateField(),
      const SizedBox(height: 12),
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
      const SizedBox(height: 12),
      _buildMemoField(onSubmitted: _saveTransaction),
      const SizedBox(height: 24),
      _buildCategorySection(),
    ];
  }

  /// 저장 + 저장후계속 버튼
  Widget _buildSaveButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'save_continue',
          onPressed: _saveAndContinue,
          tooltip: '저장 후 계속',
          child: const Icon(IconCatalog.arrowForward),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: 'save',
          onPressed: _saveTransaction,
          tooltip: '저장',
          child: const Text(
            'ENT',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// 메모 입력 필드 (공통)
  Widget _buildMemoField({required VoidCallback onSubmitted}) {
    return KeyedSubtree(
      key: const Key('tx_memo'),
      child: SmartInputField(
        controller: _memoController,
        focusNode: _memoFocusNode,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => onSubmitted(),
        onChanged: (_) => setState(() {}),
        label: '메모',
        hint: '예: 마트 이름 + 간단 메모',
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
    return SmartInputField(
      key: fieldKey,
      focusNode: focusNode,
      controller: controller,
      textInputAction: textInputAction,
      onFieldSubmitted: (_) => onSubmitted(),
      label: labelText,
      hint: hintText,
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
    return [
      _buildDescriptionInput(
        labelText: '내용',
        emptyMessage: '내용을 입력하세요.',
        enableHistory: true,
        onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
      ),
      const SizedBox(height: 12),
      KeyedSubtree(
        key: const Key('tx_amount'),
        child: SmartInputField(
          focusNode: _amountFocusNode,
          controller: _amountController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _paymentFocusNode.requestFocus(),
          validator: (value) => _validatePositiveAmount(value, '금액을 입력하세요.'),
          label: '금액 (수동 입력)',
        ),
      ),
      const SizedBox(height: 12),
      _buildPaymentField(
        fieldKey: const Key('tx_payment'),
        focusNode: _paymentFocusNode,
        controller: _paymentController,
        onSubmitted: () => FocusScope.of(context).requestFocus(_memoFocusNode),
        labelText: '결제수단',
      ),
      const SizedBox(height: 12),
      _buildMemoField(onSubmitted: _saveTransaction),
      const SizedBox(height: 24),
      _buildCategorySection(),
    ];
  }

  List<Widget> _buildRefundFields() {
    return [
      _buildDescriptionInput(
        labelText: '반품 내역',
        emptyMessage: '반품 내역을 입력하세요.',
        enableHistory: true,
        onFieldSubmitted: (_) => _storeFocusNode.requestFocus(),
      ),
      const SizedBox(height: 12),
      _buildStoreOrBuyerField(),
      const SizedBox(height: 12),
      KeyedSubtree(
        key: const Key('tx_amount'),
        child: SmartInputField(
          focusNode: _amountFocusNode,
          controller: _amountController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _paymentFocusNode.requestFocus(),
          validator: (value) => _validatePositiveAmount(value, '금액을 입력하세요.'),
          label: '반품 금액',
        ),
      ),
      const SizedBox(height: 12),
      _buildPaymentField(
        fieldKey: const Key('tx_payment'),
        focusNode: _paymentFocusNode,
        controller: _paymentController,
        onSubmitted: () => FocusScope.of(context).requestFocus(_memoFocusNode),
        labelText: '환불 계좌/수단',
        emptyErrorText: '환불 수단 입력',
      ),
      const SizedBox(height: 12),
      _buildMemoField(onSubmitted: _saveTransaction),
      const SizedBox(height: 24),
      _buildCategorySection(),
    ];
  }

  List<Widget> _buildExpenseFields() {
    return [
      _buildDescriptionInput(
        labelText: '상품명',
        emptyMessage: '상품명을 입력하세요.',
        enableHistory: true,
        onFieldSubmitted: (_) => _expenseUnitPriceFocusNode.requestFocus(),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: SmartInputField(
              key: const Key('tx_unit'),
              controller: _unitPriceController,
              focusNode: _expenseUnitPriceFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '단가 입력' : null,
              label: '단가',
              onFieldSubmitted: (_) {
                final raw = _unitPriceController.text.trim();
                final unit = double.tryParse(raw) ?? 0.0;
                if (unit <= 0) {
                  _expenseUnitPriceFocusNode.requestFocus();
                  _unitPriceController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _unitPriceController.text.length,
                  );
                  return;
                }

                _expenseQtyFocusNode.requestFocus();
                _qtyController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _qtyController.text.length,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SmartInputField(
              key: const Key('tx_qty'),
              controller: _qtyController,
              focusNode: _expenseQtyFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '수량 입력' : null,
              label: '수량',
              onFieldSubmitted: (_) {
                final raw = _qtyController.text.trim();
                final qty = int.tryParse(raw) ?? 0;
                if (qty <= 0) {
                  _expenseQtyFocusNode.requestFocus();
                  _qtyController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _qtyController.text.length,
                  );
                  return;
                }

                FocusScope.of(context).requestFocus(_paymentFocusNode);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: SmartInputField(
              controller: _amountController,
              focusNode: _calculatedAmountFocusNode,
              enabled: false, // readOnly equivalent in SmartInputField
              label: '금액(자동계산)',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
      const SizedBox(height: 12),
      _buildMemoField(onSubmitted: _saveTransaction),
      const SizedBox(height: 12),
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
                  _selectedMainCategory == _defaultCategory) {
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

    final categoryMap = _categoryOptionsFor(_selectedType);
    final mainCategories = _sortedMainCategories.isNotEmpty
        ? _sortedMainCategories
        : categoryMap.keys.toList();
    final subCategories =
        categoryMap[_selectedMainCategory] ?? const <String>[];
    final showSubOptions =
        _selectedMainCategory != _defaultCategory && subCategories.isNotEmpty;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('카테고리', style: theme.textTheme.labelLarge),
            if (isIncome)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showIncomeCategoryOptions = false;
                    _selectedMainCategory = _defaultCategory;
                    _selectedSubCategory = null;
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
        LayoutBuilder(
          builder: (context, constraints) {
            final width3 = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mainCategories.map((cat) {
                final isSelected = _selectedMainCategory == cat;
                return SizedBox(
                  width: width3,
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() {
                        _selectedMainCategory = cat;
                        _selectedSubCategory = null;
                      });
                      unawaited(
                        _persistLastCategoryForType(_selectedType, main: cat),
                      );
                    },
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (showSubOptions) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subCategories.map((sub) {
              final isSelected = _selectedSubCategory == sub;
              return ChoiceChip(
                label: Text(sub),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _selectedSubCategory = sub;
                  });
                  unawaited(
                    _persistLastCategoryForType(
                      _selectedType,
                      main: _selectedMainCategory,
                    ),
                  );
                },
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
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
      child: SmartInputField(
        controller: _descController,
        focusNode: _descFocusNode,
        textInputAction: TextInputAction.next,
        validator: (value) =>
            value == null || value.trim().isEmpty ? emptyMessage : null,
        onFieldSubmitted: onFieldSubmitted,
        onChanged: (_) => setState(() {}),
        label: labelText,
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
              setState(() {});
            },
            title: '상품명 입력내용 불러오기',
          ),
          padding: EdgeInsets.zero,
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
