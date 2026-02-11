import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/pref_keys.dart';
import '../models/asset.dart';
import '../models/category_hint.dart';
import '../models/shopping_cart_item.dart';
import '../models/shopping_cart_history_entry.dart';
import '../models/transaction.dart';
import 'income_split_screen.dart';
import '../services/asset_service.dart';
import '../services/category_usage_service.dart';
import '../services/consumable_inventory_service.dart';
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
import '../navigation/app_routes_args.dart';
import '../utils/shopping_cart_sync_utils.dart';
import '../services/aicore_gemini_service.dart';

part '_tx_detail_screen.dart';
part '_tx_detail_init.dart';
part '_tx_detail_category.dart';
part '_tx_detail_shopping.dart';
part '_tx_detail_shopping_dialog.dart';
part '_tx_detail_draft.dart';
part '_tx_detail_price.dart';
part '_tx_detail_save.dart';
part '_tx_detail_save_exec.dart';
part '_tx_detail_save_asset.dart';
part '_tx_detail_ui_build.dart';
part '_tx_detail_ui_savings.dart';
part '_tx_detail_ui_common.dart';
part '_tx_detail_ui_income.dart';
part '_tx_detail_ui_expense.dart';
part '_tx_detail_ui_category.dart';
part '_tx_detail_ui_category_expense.dart';

// 최근 결제수단/메모 저장 키 및 최대 개수
const String _recentDescriptionsBaseKey = 'recent_descriptions';
const String _recentPaymentsBaseKey = 'recent_payments';
const String _recentMemosBaseKey = 'recent_memos';
const int _maxRecentDescriptions = 30;
const int _maxRecentPayments = 10;
const int _maxRecentMemos = 10;
const String _lastCategoryMainKeyPrefix = 'last_category_main';
const String _defaultCategory = CategoryDefinitions.defaultCategory;

const int _priceRiseLookbackCount = 20;
const int _priceRiseMinSamples = 3;
const double _priceRisePctThreshold = 0.10;
const double _priceRiseMinDeltaWon = 100;

const int _shoppingAvgLookbackDays = 30;
const Set<String> _shoppingMainCategories = {'생활용품비', '의류/잡화'};
const Set<String> _shoppingFoodSubCategories = {'식자재 구매', '간식', '음료'};

const int _draftTtlMs = 30 * 60 * 1000; // 30 minutes

Map<String, List<String>> _categoryOptionsFor(TransactionType type) {
  if (type == TransactionType.income) {
    return IncomeCategoryDefinitions.categoryOptions;
  }
  return CategoryDefinitions.categoryOptions;
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
  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Input decoration helper
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Mutable state
  // ---------------------------------------------------------------------------
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

  bool get _isEditing =>
      widget.initialTransaction != null && !widget.treatAsNew;

  // ---------------------------------------------------------------------------
  // Lifecycle – thin stubs calling extension helpers
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    performInit();
  }

  @override
  void dispose() {
    disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildBody(context);
}
