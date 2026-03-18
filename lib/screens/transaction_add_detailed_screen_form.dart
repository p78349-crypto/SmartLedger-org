part of 'transaction_add_detailed_screen.dart';

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
  final String? initialPaymentMethod;
  final String? initialMemo;
  const TransactionAddDetailedForm({
    super.key,
    required this.accountName,
    this.initialTransaction,
    this.learnCategoryHintFromDescription = false,
    this.confirmBeforeSave = false,
    this.treatAsNew = false,
    this.closeAfterSave = false,
    this.titlePrefix,
    this.initialPaymentMethod,
    this.initialMemo,
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

  String get _recentDescriptionsKey {
    if (_selectedType == TransactionType.income) {
      return 'recent_descriptions_income_${widget.accountName}';
    }
    return _recentDescriptionsBaseKey;
  }

  String get _recentPaymentsKey {
    if (_selectedType == TransactionType.income) {
      return 'recent_payments_income_input_${widget.accountName}';
    }
    return _recentPaymentsBaseKey;
  }

  String get _recentMemosKey {
    if (_selectedType == TransactionType.income) {
      return 'recent_memos_income_input_${widget.accountName}';
    }
    return _recentMemosBaseKey;
  }

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

  final AICoreGeminiService _aicore = AICoreGeminiService();
  bool _isAICoreModelLoading = false;

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

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

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
      debugPrint(
        '[TransactionAddDetailedForm.initState] '
        '초기값 바인딩: desc=${initial.description}, '
        'qty=${initial.quantity}, unitPrice=${initial.unitPrice}',
      );
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
      if (_paymentController.text.isEmpty &&
          widget.initialPaymentMethod != null) {
        _paymentController.text = widget.initialPaymentMethod!;
      }
      _memoController.text = initial.memo;
      if (_memoController.text.isEmpty && widget.initialMemo != null) {
        _memoController.text = widget.initialMemo!;
      }
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
      if (widget.initialPaymentMethod != null) {
        _paymentController.text = widget.initialPaymentMethod!;
      }
      if (widget.initialMemo != null) {
        _memoController.text = widget.initialMemo!;
      }
    }
    if (_selectedType == TransactionType.income) {
      if (_isEditing) {
        _showIncomeCategoryOptions =
            _selectedMainCategory !=
            DetailedCategoryDefinitions.defaultCategory;
      } else {
        _applyIncomeDefaultCategory();
        _showIncomeCategoryOptions = true;
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

  // Draft persistence (short-lived draft to survive short navigations)
  static const int _draftTtlMs = 30 * 60 * 1000; // 30 minutes

  String _draftKey() => PrefKeys.accountKey(widget.accountName, 'tx_draft_v1');

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

  /// 저장 + 저장후계속 버튼

  /// 메모 입력 필드 (공통)

  // 결제수단 기능(히스토리/선택) 비활성화: 사용 중단 상태

  /// 거래 저장 후 계속 입력 (Shift+Enter)
}
