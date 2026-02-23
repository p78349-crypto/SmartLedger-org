import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_hint.dart';
import '../models/transaction.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';
import '../navigation/app_routes.dart';
// import 'package:smart_ledger/screens/nutrition_report_screen.dart';
// Preserved but disabled per request.
import '../services/category_usage_service.dart';
import '../services/last_input_service.dart';
import '../services/recent_input_service.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../services/category_keyword_service.dart';
import '../theme/app_theme_seed_controller.dart';
import '../utils/category_definitions.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/income_category_definitions.dart';
import '../utils/snackbar_utils.dart';
import '../utils/store_memo_utils.dart';
import '../utils/pref_keys.dart';
import '../utils/type_converters.dart';
import '../widgets/background_widget.dart';
import '../widgets/smart_input_field.dart';
import '../widgets/special_backgrounds.dart';
import '../utils/cart_transaction_prefill.dart';

part 'transaction_add_screen_form_state.dart';
part 'transaction_add_screen_snapshot.dart';
part 'transaction_add_screen_data.dart';
part 'transaction_add_screen_helpers.dart';
part 'transaction_add_screen_save.dart';
part 'transaction_add_screen_dialogs.dart';
part 'transaction_add_screen_build_fields.dart';
part 'transaction_add_screen_build_expense.dart';
part 'transaction_add_screen_widgets.dart';
part 'transaction_add_screen_category_ui.dart';
part 'transaction_add_screen_description.dart';
part 'transaction_add_screen_expense_picker.dart';
part 'transaction_add_screen_asset.dart';

// 최근 결제수단/메모 저장 키 및 최대 개수
const String _recentDescriptionsBaseKey = 'recent_descriptions';
const String _recentPaymentsStorageBaseKey = 'recent_payments';
const String _recentMemosStorageBaseKey = 'recent_memos';
const int _defaultMaxRecentInputs = 30;
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
  final bool closeAfterSave;
  final bool autoSubmit;
  final bool openReceiptScannerOnStart;
  final String? initialPaymentMethod;
  final String? initialMemo;
  const TransactionAddScreen({
    super.key,
    required this.accountName,
    this.initialTransaction,
    this.learnCategoryHintFromDescription = false,
    this.confirmBeforeSave = false,
    this.treatAsNew = false,
    this.closeAfterSave = false,
    this.autoSubmit = false,
    this.openReceiptScannerOnStart = false,
    this.initialPaymentMethod,
    this.initialMemo,
  });

  @override
  State<TransactionAddScreen> createState() => _TransactionAddScreenState();
}

class _TransactionAddScreenState extends State<TransactionAddScreen> {
  final GlobalKey<_NO1FormState> _formStateKey = GlobalKey<_NO1FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.autoSubmit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_formStateKey.currentState?.triggerAutoSubmit());
      });
    }

    if (widget.openReceiptScannerOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // No OCR/auto camera start is implemented here yet.
        // This is a safe hook point for assistant-triggered flows.
        SnackbarUtils.showInfo(context, '영수증 스캔을 시작하려면 영수증/카메라 버튼을 눌러주세요.');
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
        ? (isEditing ? '수입 수정' : '수입')
        : (isEditing ? '거래 수정' : '지출입력');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final formState = _formStateKey.currentState;
        final didSave = formState?.didSave ?? false;
        if (didSave) {
          navigator.pop(
            TransactionAddResult(
              saved: true,
              paymentMethod: formState?.lastPaymentMethod,
              memo: formState?.lastMemo,
              mainCategory: formState?.lastMainCategory,
              subCategory: formState?.lastSubCategory,
            ),
          );
        } else {
          navigator.pop();
        }
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([
          BackgroundHelper.colorNotifier,
          BackgroundHelper.typeNotifier,
          BackgroundHelper.imagePathNotifier,
          BackgroundHelper.blurNotifier,
          AppThemeSeedController.instance.presetId,
        ]),
        builder: (context, _) {
          final bgColor = BackgroundHelper.colorNotifier.value;
          final bgType = BackgroundHelper.typeNotifier.value;
          final bgImagePath = BackgroundHelper.imagePathNotifier.value;
          final bgBlur = BackgroundHelper.blurNotifier.value;
          final presetId = AppThemeSeedController.instance.presetId.value;
          final theme = Theme.of(context);

          // In dark mode, if the background color is still the default white,
          // we should use the theme's scaffold background color instead.
          Color effectiveBgColor = bgColor;
          final isDefaultWhite =
              bgColor.toARGB32() == 0xFFFFFFFF ||
              bgColor.toARGB32() == 0xffffffff;

          if (theme.brightness == Brightness.dark && isDefaultWhite) {
            effectiveBgColor = theme.scaffoldBackgroundColor;
          }

          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;

          return Scaffold(
            backgroundColor: effectiveBgColor,
            extendBodyBehindAppBar: bgType == 'image' && bgImagePath != null,
            appBar: isLandscape
                ? null
                : AppBar(
                    title: Text('$titlePrefix - ${widget.accountName}'),
                    backgroundColor: bgType == 'image' && bgImagePath != null
                        ? Colors.transparent
                        : null,
                    elevation: 0,
                    actions: [
                      IconButton(
                        tooltip: '입력값 되돌리기',
                        icon: const Icon(IconCatalog.restartAlt),
                        onPressed: () =>
                            _formStateKey.currentState?.promptRevertToInitial(),
                      ),
                    ],
                  ),
            body: Stack(
              children: [
                // 1. Base Background (Color or Image)
                Positioned.fill(
                  child: Builder(
                    builder: (context) {
                      if (bgType == 'image' && bgImagePath != null) {
                        return Image.file(
                          File(bgImagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(color: effectiveBgColor),
                        );
                      }

                      if (presetId == 'midnight_gold') {
                        return MidnightGoldBackground(
                          baseColor: effectiveBgColor,
                        );
                      } else if (presetId == 'starlight_navy') {
                        return StarlightNavyBackground(
                          baseColor: effectiveBgColor,
                        );
                      }
                      return ColoredBox(color: effectiveBgColor);
                    },
                  ),
                ),

                // 2. Blur Effect (if image)
                if (bgType == 'image' && bgImagePath != null && bgBlur > 0)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),

                // 3. Dark Overlay for images to ensure readability
                if (bgType == 'image' && bgImagePath != null)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                  ),

                // 4. Content
                SafeArea(
                  top: !isLandscape,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: isLandscape ? 0.0 : 16.0,
                    ),
                    child: NO1Form(
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
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 1-메인-지출입력
class NO1Form extends StatefulWidget {
  final String accountName;
  final Transaction? initialTransaction;
  final bool learnCategoryHintFromDescription;
  final bool confirmBeforeSave;
  final bool treatAsNew;
  final bool closeAfterSave;
  final String? titlePrefix;
  final String? initialPaymentMethod;
  final String? initialMemo;
  const NO1Form({
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
  State<NO1Form> createState() => _NO1FormState();
}
