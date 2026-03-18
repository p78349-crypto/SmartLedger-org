import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/pref_keys.dart';
import '../models/category_hint.dart';
import '../models/shopping_cart_item.dart';
import '../models/shopping_cart_history_entry.dart';
import '../models/transaction.dart';
// import 'package:smart_ledger/screens/nutrition_report_screen.dart';
// Preserved but disabled per request.
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
import '../utils/type_converters.dart';
import '../services/aicore_gemini_service.dart';
part 'transaction_add_detailed_screen_form.dart';
part 'transaction_add_detailed_screen_ui.dart';
part 'transaction_add_detailed_screen_logic.dart';

// 최근 결제수단/메모 저장 키 및 최대 개수
const String _recentDescriptionsBaseKey = 'recent_descriptions';
const String _recentPaymentsBaseKey = 'recent_payments';
const String _recentMemosBaseKey = 'recent_memos';
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
        : (isEditing ? '거래 수정(상세)' : '지출입력(상세)');

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
                        tooltip: '장바구니 동기화',
                        icon: const Icon(IconCatalog.shoppingCart),
                        onPressed: () => _formStateKey.currentState
                            ?.confirmAndOpenShoppingCartPicker(),
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
                  initialPaymentMethod: widget.initialPaymentMethod,
                  initialMemo: widget.initialMemo,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TransactionAddDetailedScreen extends StatefulWidget {
  final String accountName;
  final Transaction? initialTransaction;
  final bool learnCategoryHintFromDescription;
  final bool confirmBeforeSave;
  final bool treatAsNew;
  final bool closeAfterSave;
  final bool autoSubmit;
  final String? initialPaymentMethod;
  final String? initialMemo;

  const TransactionAddDetailedScreen({
    super.key,
    required this.accountName,
    this.initialTransaction,
    this.learnCategoryHintFromDescription = false,
    this.confirmBeforeSave = false,
    this.treatAsNew = false,
    this.closeAfterSave = false,
    this.autoSubmit = false,
    this.initialPaymentMethod,
    this.initialMemo,
  });

  @override
  State<TransactionAddDetailedScreen> createState() =>
      _TransactionAddDetailedScreenState();
}
