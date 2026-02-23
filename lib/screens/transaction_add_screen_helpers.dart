part of 'transaction_add_screen.dart';

const int _priceRiseLookbackCount = 20;
const int _priceRiseMinSamples = 3;
const double _priceRisePctThreshold = 0.10; // 10%
const double _priceRiseMinDeltaWon = 100; // 최소 100원 이상 상승

const int _shoppingAvgLookbackDays = 30;
const Set<String> _shoppingMainCategories = {'생활용품비', '의류/잡화'};
const Set<String> _shoppingFoodSubCategories = {'식자재 구매', '간식', '음료'};

extension TransactionAddScreenHelpers on _NO1FormState {
  bool get didSave => _didSaveAtLeastOnce;

  /// 연속 입력 시 이전 값 유지를 위한 getter
  String get lastPaymentMethod => _paymentController.text;
  String get lastMemo => _memoController.text;
  String get lastMainCategory => _selectedMainCategory;
  String? get lastSubCategory => _selectedSubCategory;

  Future<void> triggerAutoSubmit() async {
    await _saveTransaction(skipConfirm: true);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool get _isEditing =>
      widget.initialTransaction != null && !widget.treatAsNew;

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

  void _handleDescriptionChanged(String value) {
    if (_isEditing) return;
    if (_selectedType != TransactionType.expense) return;
    if (_userPickedCategory) return;
    if (!_shoppingCategoryHintsLoaded) return;

    _autoCategoryDebounce?.cancel();
    _autoCategoryDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;

      final categoryMap = _categoryOptionsFor(_selectedType);
      String? main;
      String? sub;

      // 1) Try user history hints first
      final hint = _findBestCategoryHint(value);
      if (hint != null) {
        final hintMain = hint.mainCategory.trim();
        if (hintMain.isNotEmpty &&
            hintMain != _defaultCategory &&
            categoryMap.containsKey(hintMain)) {
          main = hintMain;
          final hintSub = hint.subCategory?.trim() ?? '';
          final allowedSubs = categoryMap[main] ?? const <String>[];
          sub = (hintSub.isNotEmpty && allowedSubs.contains(hintSub))
              ? hintSub
              : null;
        }
      }

      // 2) Fallback to keyword dictionary
      if (main == null) {
        final kwResult = CategoryKeywordService.instance.classify(value);
        if (kwResult != null) {
          final kwMain = kwResult.$1;
          if (categoryMap.containsKey(kwMain)) {
            main = kwMain;
            final kwSub = kwResult.$2;
            final allowedSubs = categoryMap[main] ?? const <String>[];
            sub = (kwSub != null && allowedSubs.contains(kwSub)) ? kwSub : null;
          }
        }
      }

      if (main == null) return;
      if (main == _selectedMainCategory && sub == _selectedSubCategory) return;

      setState(() {
        _selectedMainCategory = main!;
        _selectedSubCategory = sub;
      });
      unawaited(_persistLastCategoryForType(_selectedType, main: main));
    });
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

  String? _validatePositiveAmount(String? value, String errorMessage) {
    final raw = value?.trim() ?? '';
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      return errorMessage;
    }
    return null;
  }
}
