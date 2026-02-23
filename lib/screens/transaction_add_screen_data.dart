part of 'transaction_add_screen.dart';

extension TransactionAddScreenData on _NO1FormState {
  String get _recentDescriptionsKey {
    if (_selectedType == TransactionType.income) {
      return 'recent_descriptions_income_${widget.accountName}';
    }
    return _recentDescriptionsBaseKey;
  }

  String get _recentPaymentsKey {
    // 수입 입력이면 별도 키 사용
    if (_selectedType == TransactionType.income) {
      return 'recent_payments_income_input_${widget.accountName}';
    }
    return _recentPaymentsStorageBaseKey;
  }

  String get _recentMemosKey {
    if (_selectedType == TransactionType.income) {
      return 'recent_memos_income_input_${widget.accountName}';
    }
    return _recentMemosStorageBaseKey;
  }

  // ...existing code...
  String _lastCategoryMainKeyFor(TransactionType type) =>
      '${_lastCategoryMainKeyPrefix}_${widget.accountName}_${type.name}';
  String _lastCategorySubKeyFor(TransactionType type) =>
      '${_lastCategorySubKeyPrefix}_${widget.accountName}_${type.name}';

  /// LastInputService에서 마지막 입력값 로드 (결제수단/메모만)
  Future<void> _loadLastInputFromService() async {
    final lastInput = await LastInputService.instance.getLastTransaction(
      widget.accountName,
    );
    if (!mounted || lastInput == null) return;

    setState(() {
      // Args로 전달된 값이 없는 경우에만 LastInputService 값 사용
      if (_paymentController.text.isEmpty &&
          lastInput.paymentMethod != null &&
          lastInput.paymentMethod!.isNotEmpty) {
        _paymentController.text = lastInput.paymentMethod!;
      }
      if (_memoController.text.isEmpty &&
          lastInput.memo != null &&
          lastInput.memo!.isNotEmpty) {
        _memoController.text = lastInput.memo!;
      }
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

    final enabled = prefs.getBool(PrefKeys.txRecentInputsEnabledV1);
    final autofill = prefs.getBool(PrefKeys.txRecentInputsAutofillEnabledV1);
    final maxCount = prefs.getInt(PrefKeys.txRecentInputsMaxCountV1);

    final nextEnabled = enabled ?? true;
    final nextAutofill = autofill ?? true;
    final nextMaxCount = (maxCount ?? _defaultMaxRecentInputs).clamp(1, 100);

    if (!mounted) return;
    setState(() {
      _recentInputsEnabled = nextEnabled;
      _recentInputsAutofillEnabled = nextAutofill;
      _recentInputsMaxCount = nextMaxCount;
    });

    if (!nextEnabled) {
      if (!mounted) return;
      setState(() {
        _recentDescriptions = const <String>[];
        _recentPayments = const <String>[];
        _recentMemos = const <String>[];
      });
      return;
    }

    final descriptions =
        prefs.getStringList(_recentDescriptionsKey) ?? const <String>[];
    final payments = prefs.getStringList(_recentPaymentsKey) ?? [];
    final memos = prefs.getStringList(_recentMemosKey) ?? [];

    if (!mounted) return;
    setState(() {
      _recentDescriptions = descriptions
          .take(_recentInputsMaxCount)
          .toList(growable: false);
      _recentPayments = payments
          .take(_recentInputsMaxCount)
          .toList(growable: false);
      _recentMemos = memos.take(_recentInputsMaxCount).toList(growable: false);
    });

    if (_recentInputsAutofillEnabled) {
      // 사용자가 현재 입력 중이면 autofill 하지 않음
      if (_paymentController.text.isEmpty &&
          payments.isNotEmpty &&
          !_paymentFocusNode.hasFocus) {
        _paymentController.text = payments.first;
      }
      if (_memoController.text.isEmpty &&
          memos.isNotEmpty &&
          !_memoFocusNode.hasFocus) {
        _memoController.text = memos.first;
      }
    }
  }

  String _normalizeShoppingHintKey(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.isEmpty) return '';

    // Remove common promotion/multiplier patterns before stripping symbols.
    // Examples: 1+1, 2 + 1, 3x2, 3×2
    s = s.replaceAll(RegExp(r'\d+\s*[+×x]\s*\d+'), ' ');

    // Collapse whitespace, then remove punctuation/symbols.
    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll(RegExp(r'[^a-z0-9가-힣]'), '');

    // Remove trailing size/unit/count patterns to match across variants.
    // Examples: 900ml, 1l, 500g, 10kg, 2개, 10입, 1팩
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
}
