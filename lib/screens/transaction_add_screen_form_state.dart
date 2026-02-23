part of 'transaction_add_screen.dart';

class _NO1FormState extends State<NO1Form> {
  List<String> _recentDescriptions = [];
  List<String> _recentPayments = [];
  List<String> _recentMemos = [];

  Map<String, CategoryHint> _shoppingCategoryHintsNormalized = const {};
  bool _shoppingCategoryHintsLoaded = false;
  bool _userPickedCategory = false;
  Timer? _autoCategoryDebounce;

  bool _recentInputsEnabled = true;
  bool _recentInputsAutofillEnabled = true;
  int _recentInputsMaxCount = _defaultMaxRecentInputs;

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
  bool _paymentFirstFocus = true;
  bool _memoFirstFocus = true;
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

  List<String> _sortedMainCategories = [];

  void _updateAmount() {
    if (_suppressAmountAutoUpdate) {
      return;
    }
    if (_selectedType != TransactionType.expense) {
      return;
    }
    final qtyText = _qtyController.text.trim();
    final qty = qtyText.isEmpty ? 1 : int.tryParse(qtyText) ?? 1;
    final unit = TypeConverters.parseCurrency(_unitPriceController.text) ?? 0.0;
    _amountController.text = (qty * unit).toStringAsFixed(0);
  }

  @override
  void initState() {
    super.initState();

    final initial = widget.initialTransaction;
    _transactionDate = initial?.date ?? DateTime.now();
    if (initial != null) {
      _selectedType = initial.type;
      _qtyController.text = '1';
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

      // 연속 입력 시 이전 결제수단/메모 우선 적용 (bulk flow에서 전달된 값)
      if (widget.initialPaymentMethod != null &&
          widget.initialPaymentMethod!.isNotEmpty) {
        _paymentController.text = widget.initialPaymentMethod!;
      }
      if (widget.initialMemo != null && widget.initialMemo!.isNotEmpty) {
        _memoController.text = widget.initialMemo!;
      }
    } else {
      _qtyController.text = '1';
    }
    if (_selectedType == TransactionType.income) {
      if (_isEditing) {
        _showIncomeCategoryOptions = _selectedMainCategory != _defaultCategory;
      } else {
        _applyIncomeDefaultCategory();
        _showIncomeCategoryOptions = true; // Changed from false to true to show labels immediately
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
    unawaited(_loadSortedCategories()); // Load sorted categories
    _qtyController.addListener(_updateAmount);
    _unitPriceController.addListener(_updateAmount);
    if (initial == null) {
      _updateAmount();
      // 연속 입력 시 이전 결제수단/메모 유지 (Args 우선, 없으면 LastInputService)
      if (widget.initialPaymentMethod != null &&
          widget.initialPaymentMethod!.isNotEmpty) {
        _paymentController.text = widget.initialPaymentMethod!;
      }
      if (widget.initialMemo != null && widget.initialMemo!.isNotEmpty) {
        _memoController.text = widget.initialMemo!;
      }
      // Args가 없으면 LastInputService에서 마지막 입력값 로드
      if ((widget.initialPaymentMethod == null ||
              widget.initialPaymentMethod!.isEmpty) ||
          (widget.initialMemo == null || widget.initialMemo!.isEmpty)) {
        unawaited(_loadLastInputFromService());
      }
      // Try to read cart prefill (saved by shopping cart flow).
      unawaited(() async {
        final prefill = await CartTransactionPrefill.readPrefill(
          accountName: widget.accountName,
        );
        if (!mounted || prefill.isEmpty) return;
        final tx = prefill.first;
        setState(() {
          if (_descController.text.isEmpty) {
            _descController.text = tx.description;
          }
          if (_qtyController.text == '1' || _qtyController.text.isEmpty) {
            _qtyController.text = tx.quantity.toString();
          }
          final computedUnitPrice = tx.unitPrice != 0
              ? tx.unitPrice
              : (tx.quantity > 0 ? tx.amount / tx.quantity : tx.amount);
          if (_unitPriceController.text.isEmpty && computedUnitPrice > 0) {
            _unitPriceController.text = computedUnitPrice.toStringAsFixed(
              computedUnitPrice == computedUnitPrice.roundToDouble() ? 0 : 2,
            );
          }
          if (_amountController.text.isEmpty) {
            _amountController.text = tx.amount.toStringAsFixed(
              tx.amount == tx.amount.roundToDouble() ? 0 : 2,
            );
          }
          if (_paymentController.text.isEmpty && tx.paymentMethod.isNotEmpty) {
            _paymentController.text = tx.paymentMethod;
          }
          if (_memoController.text.isEmpty && tx.memo.isNotEmpty) {
            _memoController.text = tx.memo;
          }
          if (_storeController.text.isEmpty &&
              (tx.store?.isNotEmpty ?? false)) {
            _storeController.text = tx.store!.trim();
          }
          _selectedMainCategory = tx.mainCategory;
          _selectedSubCategory = tx.subCategory;
          _transactionDate = tx.date;
        });
        _updateAmount();
      }());
    }

    // 결제수단/메모 입력란 첫 포커스 시 전체 선택
    _paymentFocusNode.addListener(() {
      if (_paymentFocusNode.hasFocus && _paymentFirstFocus) {
        _paymentFirstFocus = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_paymentFocusNode.hasFocus) {
            final text = _paymentController.text;
            _paymentController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: text.length,
            );
          }
        });
      }
    });
    _memoFocusNode.addListener(() {
      if (_memoFocusNode.hasFocus && _memoFirstFocus) {
        _memoFirstFocus = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_memoFocusNode.hasFocus) {
            final text = _memoController.text;
            _memoController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: text.length,
            );
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureInitialSnapshotIfNeeded();
    });
  }

  @override
  void dispose() {
    _autoCategoryDebounce?.cancel();

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

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      children: [
        if (isLandscape && widget.titlePrefix != null) _buildInlineHeader(),
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
      ],
    );
  }
}
