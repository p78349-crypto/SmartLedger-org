part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Category prediction, keyword hint matching, and auto-category logic.
extension TxDetailCategory on _TransactionAddDetailedFormState {
  bool _isShoppingCategory(String mainCategory, String? subCategory) {
    if (_shoppingMainCategories.contains(mainCategory)) {
      return true;
    }
    if (mainCategory == '식비') {
      final sub = subCategory?.trim();
      if (sub == null || sub.isEmpty) {
        return true;
      }
      return _shoppingFoodSubCategories.contains(sub);
    }
    return false;
  }

  String _normalizeShoppingHintKey(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.isEmpty) return '';

    s = s.replaceAll(RegExp(r'\d+\s*[+×x]\s*\d+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll(RegExp(r'[^a-z0-9가-힣]'), '');
    s = s.replaceAll(
      RegExp(
        r'(\d+(?:\.\d+)?)(ml|l|kg|g|mg|개|입|팩|봉|병|캔|장|p|pcs|pc|box)$',
      ),
      '',
    );
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

  Future<void> _predictCategoryWithAI() async {
    final text = _descController.text.trim();
    if (text.isEmpty) {
      SnackbarUtils.showInfo(context, '상품명을 먼저 입력해주세요.');
      return;
    }

    setState(() {
      _isAICoreModelLoading = true;
    });

    try {
      final isReady = await _aicore.isAvailable();
      if (!isReady) {
        if (mounted) {
          SnackbarUtils.showWarning(
            context,
            '온디바이스 AI 모델을 불러올 수 없습니다. 모델 파일 설치 확인이 필요합니다.',
          );
        }
        return;
      }

      final candidates = _selectedType == TransactionType.income
          ? IncomeCategoryDefinitions.mainCategories
          : CategoryDefinitions.mainCategories;

      final result = await _aicore.predictCategory(
        text,
        candidateCategories: candidates,
      );

      if (result != null && mounted) {
        setState(() {
          _selectedMainCategory = result;
          _userPickedCategory = true;
        });
        SnackbarUtils.showSuccess(context, 'AI 분류 결과: $result');
      } else {
        if (mounted) {
          SnackbarUtils.showInfo(context, '분류 결과를 찾지 못했습니다.');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAICoreModelLoading = false;
        });
      }
    }
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
