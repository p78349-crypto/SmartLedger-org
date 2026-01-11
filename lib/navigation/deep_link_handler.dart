import 'dart:async';

import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'global_navigator_key.dart';
import '../models/shopping_cart_item.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../services/deep_link_service.dart';
import '../services/consumable_inventory_service.dart';
import '../services/health_guardrail_service.dart';
import '../services/product_location_service.dart';
import '../services/user_pref_service.dart';
import '../services/voice_assistant_analytics.dart';
import 'assistant_route_catalog.dart';
import 'route_param_validator.dart';
import '../utils/date_parser.dart';

/// Deep link handler that listens to incoming deep links
/// and navigates to the appropriate screen.
class DeepLinkHandler {
  DeepLinkHandler._();
  static final DeepLinkHandler instance = DeepLinkHandler._();

  StreamSubscription<DeepLinkAction>? _subscription;
  bool _initialized = false;

  /// Initialize the deep link handler.
  /// Should be called once from main.dart after services are loaded.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize the deep link service first
    await DeepLinkService.instance.init();

    // Listen to deep link events
    _subscription = DeepLinkService.instance.linkStream.listen(_handleAction);
  }

  void _handleAction(DeepLinkAction action) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      debugPrint('DeepLinkHandler: Navigator not available');
      return;
    }

    debugPrint('DeepLinkHandler: Received action: ${_summarizeAction(action)}');

    switch (action) {
      case AddTransactionAction():
        _handleAddTransaction(navigator, action);
      case OpenDashboardAction():
        _handleOpenDashboard(navigator);
      case OpenFeatureAction():
        _handleOpenFeature(navigator, action);
      case AddToCartAction():
        _handleAddToCart(navigator, action);
      case RecipeRecommendAction():
        _handleRecipeRecommend(navigator, action);
      case ReceiptAnalyzeAction():
        _handleReceiptAnalyze(navigator, action);
      case OpenRouteAction():
        _handleOpenRoute(navigator, action);
      case CheckStockAction():
        _handleCheckStock(navigator, action);
      case UseStockAction():
        _handleUseStock(navigator, action);
    }
  }

  String _summarizeAction(DeepLinkAction action) {
    switch (action) {
      case AddTransactionAction():
        return 'AddTransactionAction(type: ${action.type}, '
            'autoSubmit: ${action.autoSubmit}, '
            'confirmed: ${action.confirmed}, '
            'openReceiptScannerOnStart: ${action.openReceiptScannerOnStart})';
      case OpenDashboardAction():
        return 'OpenDashboardAction()';
      case OpenFeatureAction():
        return 'OpenFeatureAction(featureId: ${action.featureId})';
      case AddToCartAction():
        return 'AddToCartAction(name: ${action.name}, location: ${action.location})';
      case RecipeRecommendAction():
        return 'RecipeRecommendAction(mealType: ${action.mealType}, ingredients: ${action.ingredients}, prioritizeExpiring: ${action.prioritizeExpiring})';
      case ReceiptAnalyzeAction():
        return 'ReceiptAnalyzeAction(ingredients: ${action.ingredients})';
      case OpenRouteAction():
        final keys = action.params.keys.toList()..sort();
        return 'OpenRouteAction(routeName: ${action.routeName}, '
            'intent: ${action.intent}, '
            'autoSubmit: ${action.autoSubmit}, '
            'confirmed: ${action.confirmed}, '
            'paramKeys: $keys)';
      case CheckStockAction():
        return 'CheckStockAction()';
      case UseStockAction():
        return 'UseStockAction(autoSubmit: ${action.autoSubmit}, '
            'confirmed: ${action.confirmed})';
    }
  }

  void _handleOpenRoute(NavigatorState navigator, OpenRouteAction action) {
    final spec = AssistantRouteCatalog.specs[action.routeName];
    if (spec == null) {
      _logAndShowError(
        navigator: navigator,
        errorType: 'ROUTE_NOT_ALLOWED',
        route: action.routeName,
        assistant: _detectAssistant(action.params),
        message:
            '음성비서로는 해당 화면을 열 수 없습니다.\n'
            '앱에서 직접 열어주세요.\n'
            '(${action.routeName})',
      );
      return;
    }

    final accountName =
        action.accountName ?? AssistantRouteCatalog.resolveDefaultAccountName();
    if (spec.requiresAccount && (accountName == null || accountName.isEmpty)) {
      _logAndShowError(
        navigator: navigator,
        errorType: 'ACCOUNT_REQUIRED',
        route: action.routeName,
        assistant: _detectAssistant(action.params),
        message: '먼저 계정을 생성하거나 선택해주세요.',
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(navigator.context);
              navigator.pushNamed(AppRoutes.accountSelect);
            },
            child: const Text('계정 선택'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(navigator.context),
            child: const Text('취소'),
          ),
        ],
      );
      return;
    }

    final args = spec.buildArgs(accountName);

    // 새로운 파라미터 검증 로직
    final validationResult = RouteParamValidator.validate(
      action.routeName,
      action.params,
    );

    final validatedParams = validationResult.validated;

    // 거부된 파라미터 로깅
    final rejectedKeys = validationResult.rejected;
    if (rejectedKeys.isNotEmpty) {
      debugPrint('DeepLinkHandler: Rejected params: $rejectedKeys');
      VoiceAssistantAnalytics.logRejectedParams(
        route: action.routeName,
        rejected: rejectedKeys,
        assistant: _detectAssistant(action.params),
      );
    }

    // 검증 통과한 파라미터만 사용
    final filteredParams = validatedParams;

    // Safe intent: receipt scan hook for transaction add.
    if (action.routeName == AppRoutes.transactionAdd &&
        args is TransactionAddArgs) {
      final intent = (action.intent ?? '').trim().toLowerCase();
      final requestedAction = (filteredParams['action'] ?? '')
          .trim()
          .toLowerCase();

      final wantsScan =
          intent == 'scan_receipt' ||
          intent == 'scan' ||
          requestedAction == 'scan';

      if (wantsScan) {
        navigator.pushNamed(
          spec.routeName,
          arguments: TransactionAddArgs(
            accountName: args.accountName,
            initialTransaction: args.initialTransaction,
            learnCategoryHintFromDescription:
                args.learnCategoryHintFromDescription,
            confirmBeforeSave: args.confirmBeforeSave,
            treatAsNew: args.treatAsNew,
            closeAfterSave: args.closeAfterSave,
            autoSubmit: args.autoSubmit,
            openReceiptScannerOnStart: true,
          ),
        );
        return;
      }
    }

    // Allow safe, explicit intents for a small set of routes.
    if (action.routeName == AppRoutes.foodExpiry && action.intent == 'upsert') {
      final p = filteredParams;

      String? name = p['name'] ?? p['item'] ?? p['product'];
      name = name?.trim();

      final quantity = double.tryParse(
        (p['quantity'] ?? p['qty'] ?? '').trim(),
      );
      final unit = (p['unit'] ?? '').trim();
      final location = (p['location'] ?? '').trim();
      final category = (p['category'] ?? '').trim();
      final supplier =
          (p['supplier'] ??
                  p['purchasePlace'] ??
                  p['place'] ??
                  p['store'] ??
                  '')
              .trim();
      final memo = (p['memo'] ?? p['note'] ?? p['desc'] ?? '').trim();
      final price = double.tryParse((p['price'] ?? '').trim());

      final healthTagsRaw = (p['healthTags'] ?? p['tags'] ?? '').trim();
      final allowedTags = HealthGuardrailService.defaultTags.toSet();
      final healthTags = <String>{};
      if (healthTagsRaw.isNotEmpty) {
        // Support comma/pipe/space separated or plain phrases.
        final normalized = healthTagsRaw.replaceAll('|', ',');
        final parts = normalized
            .split(',')
            .expand((s) => s.split(RegExp(r'\s+')))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        if (parts.isNotEmpty) {
          for (final part in parts) {
            if (allowedTags.contains(part)) {
              healthTags.add(part);
            }
          }
        }

        // Also allow matching when the value is a phrase like "당류 주류".
        for (final t in allowedTags) {
          if (healthTagsRaw.contains(t)) {
            healthTags.add(t);
          }
        }
      }

      DateTime? purchaseDate;
      final purchaseDateRaw =
          (p['purchaseDate'] ?? p['purchasedAt'] ?? p['buyDate'] ?? '').trim();
      if (purchaseDateRaw.isNotEmpty) {
        purchaseDate = DateTime.tryParse(purchaseDateRaw);
        purchaseDate ??= DateParser.parse(purchaseDateRaw);
      }

      DateTime? expiryDate;
      final expiryDateRaw = (p['expiryDate'] ?? p['expiry'] ?? '').trim();
      if (expiryDateRaw.isNotEmpty) {
        expiryDate = DateTime.tryParse(expiryDateRaw);
        expiryDate ??= DateParser.parse(expiryDateRaw);
      }
      if (expiryDate == null) {
        final days = int.tryParse((p['expiryDays'] ?? p['days'] ?? '').trim());
        if (days != null && days >= 0) {
          expiryDate = DateTime.now().add(Duration(days: days));
        }
      }

      final prefill = FoodExpiryUpsertPrefill(
        name: name,
        quantity: quantity,
        unit: unit.isEmpty ? null : unit,
        location: location.isEmpty ? null : location,
        category: category.isEmpty ? null : category,
        supplier: supplier.isEmpty ? null : supplier,
        memo: memo.isEmpty ? null : memo,
        purchaseDate: purchaseDate,
        healthTags: healthTags.isEmpty ? null : healthTags.toList(),
        expiryDate: expiryDate,
        price: price,
      );

      void openDialog({required bool autoSubmit}) {
        // 성공 로깅
        VoiceAssistantAnalytics.logCommand(
          assistant: _detectAssistant(action.params),
          route: action.routeName,
          intent: action.intent ?? 'upsert',
          success: true,
        );

        navigator.pushNamed(
          spec.routeName,
          arguments: FoodExpiryArgs(
            openUpsertOnStart: true,
            upsertPrefill: prefill,
            upsertAutoSubmit: autoSubmit,
          ),
        );
      }

      if (action.autoSubmit) {
        final missingForAuto =
            name == null || name.isEmpty || expiryDate == null;
        if (missingForAuto) {
          _showSimpleInfoDialog(
            navigator,
            title: '자동 등록 불가',
            message: '자동 등록을 위해서는 품목명과 유통기한 정보가 필요합니다.\n화면을 열어 입력을 계속 진행하세요.',
          );
          openDialog(autoSubmit: false);
          return;
        }

        if (!action.confirmed) {
          final qtyText = quantity == null
              ? '미입력'
              : (quantity == quantity.roundToDouble()
                    ? quantity.toStringAsFixed(0)
                    : quantity.toString());
          final unitText = unit.isEmpty ? '' : unit;
          final locText = location.isEmpty ? '미지정' : location;
          final catText = category.isEmpty ? '미지정' : category;

          final priceText = price == null
              ? null
              : (price == price.roundToDouble()
                    ? price.toStringAsFixed(0)
                    : price.toString());

          final supplierText = supplier.isEmpty ? null : supplier;
          final memoText = memo.isEmpty ? null : memo;
          final tagsText = healthTags.isEmpty ? null : healthTags.join(', ');

          showDialog<bool>(
            context: navigator.context,
            builder: (dialogContext) {
              final purchaseDateText = purchaseDate
                  ?.toLocal()
                  .toString()
                  .split(' ')
                  .first;
              final expiryDateText = expiryDate
                  ?.toLocal()
                  .toString()
                  .split(' ')
                  .first;

              return AlertDialog(
                title: const Text('등록 전에 확인'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('품목: $name'),
                    Text('수량: $qtyText$unitText'),
                    Text('보관: $locText'),
                    if (category.isNotEmpty) Text('분류: $catText'),
                    if (priceText != null) Text('가격: $priceText'),
                    if (supplierText != null) Text('구매처: $supplierText'),
                    if (memoText != null) Text('메모: $memoText'),
                    if (tagsText != null) Text('태그: $tagsText'),
                    if (purchaseDateText != null)
                      Text('구매일: $purchaseDateText'),
                    if (expiryDateText != null) Text('유통기한: $expiryDateText'),
                    const SizedBox(height: 8),
                    const Text('이대로 등록할까요?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('등록'),
                  ),
                ],
              );
            },
          ).then((confirmed) {
            if (confirmed == true) {
              openDialog(autoSubmit: true);
            }
          });
          return;
        }

        openDialog(autoSubmit: true);
        return;
      }

      openDialog(autoSubmit: false);
      return;
    }

    if (action.routeName == AppRoutes.foodExpiry) {
      final intent = (action.intent ?? '').trim().toLowerCase();
      if (intent == 'recipe_recommendation' || intent == 'recipe_recommend') {
        navigator.pushNamed(
          spec.routeName,
          arguments: const FoodExpiryArgs(
            scrollToDailyRecipeRecommendationOnStart: true,
          ),
        );
        return;
      }

      if (intent == 'cookable_recipe_picker' || intent == 'cookable_recipes') {
        navigator.pushNamed(
          spec.routeName,
          arguments: const FoodExpiryArgs(
            openCookableRecipePickerOnStart: true,
          ),
        );
        return;
      }

      if (intent == 'usage_mode' || intent == 'auto_usage') {
        // 성공 로깅
        VoiceAssistantAnalytics.logCommand(
          assistant: _detectAssistant(action.params),
          route: action.routeName,
          intent: intent,
          success: true,
        );

        navigator.pushNamed(
          spec.routeName,
          arguments: const FoodExpiryArgs(autoUsageMode: true),
        );
        return;
      }
    }

    if (action.routeName == AppRoutes.assetSimpleInput &&
        action.intent == 'asset_add') {
      final p = filteredParams;

      final category = (p['category'] ?? p['assetCategory'] ?? '').trim();
      final name = (p['name'] ?? p['assetName'] ?? '').trim();
      final amount = double.tryParse((p['amount'] ?? '').trim());
      final location = (p['location'] ?? '').trim();
      final memo = (p['memo'] ?? '').trim();

      void openScreen({required bool autoSubmit}) {
        navigator.pushNamed(
          spec.routeName,
          arguments: AssetSimpleInputArgs(
            accountName:
                accountName ??
                AssistantRouteCatalog.resolveDefaultAccountName() ??
                '',
            initialCategory: category.isEmpty ? null : category,
            initialName: name.isEmpty ? null : name,
            initialAmount: amount,
            initialLocation: location.isEmpty ? null : location,
            initialMemo: memo.isEmpty ? null : memo,
            autoSubmit: autoSubmit,
          ),
        );
      }

      if (action.autoSubmit) {
        final missingForAuto = name.isEmpty || amount == null;
        if (missingForAuto) {
          _showSimpleInfoDialog(
            navigator,
            title: '자동 저장 불가',
            message:
                '자동 저장을 위해서는 자산명과 금액이 필요합니다.'
                '\n화면을 열어 입력을 계속 진행하세요.',
          );
          openScreen(autoSubmit: false);
          return;
        }

        if (!action.confirmed) {
          final categoryText = category.isEmpty ? '현금' : category;
          final amountText = amount == amount.roundToDouble()
              ? amount.toStringAsFixed(0)
              : amount.toString();

          showDialog<bool>(
            context: navigator.context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('저장 전에 확인'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('종류: $categoryText'),
                    Text('자산명: $name'),
                    Text('금액: $amountText'),
                    if (location.isNotEmpty) Text('위치: $location'),
                    if (memo.isNotEmpty) Text('메모: $memo'),
                    const SizedBox(height: 8),
                    const Text('이대로 저장할까요?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('저장'),
                  ),
                ],
              );
            },
          ).then((confirmed) {
            if (confirmed == true) {
              openScreen(autoSubmit: true);
            }
          });
          return;
        }

        // 성공 로깅
        VoiceAssistantAnalytics.logCommand(
          assistant: _detectAssistant(action.params),
          route: action.routeName,
          intent: action.intent ?? 'asset_add',
          success: true,
        );

        openScreen(autoSubmit: true);
        return;
      }

      // 성공 로깅 (Preview 모드)
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: action.routeName,
        intent: action.intent ?? 'asset_add',
        success: true,
      );

      openScreen(autoSubmit: false);
      return;
    }

    if (action.routeName == AppRoutes.quickSimpleExpenseInput &&
        action.intent == 'quick_expense_add') {
      final p = filteredParams;

      final rawLine = (p['line'] ?? p['raw'] ?? '').toString().trim();
      final description = (p['description'] ?? '').toString().trim();
      final amountStr = (p['amount'] ?? '').toString().trim();
      final payment = (p['payment'] ?? '').toString().trim();
      final store = (p['store'] ?? '').toString().trim();

      final amount = double.tryParse(amountStr.replaceAll(',', ''));

      String composeLine() {
        if (rawLine.isNotEmpty) return rawLine;

        final parts = <String>[];
        if (description.isNotEmpty) parts.add(description);
        if (amount != null) {
          final a = amount == amount.roundToDouble()
              ? amount.toStringAsFixed(0)
              : amount.toString();
          parts.add('$a원');
        }
        if (payment.isNotEmpty) parts.add(payment);
        if (store.isNotEmpty) parts.add(store);
        return parts.join(' ').trim();
      }

      final line = composeLine();

      void openScreen({required bool autoSubmit}) {
        navigator.pushNamed(
          spec.routeName,
          arguments: QuickSimpleExpenseInputArgs(
            accountName:
                accountName ??
                AssistantRouteCatalog.resolveDefaultAccountName() ??
                '',
            initialDate: DateTime.now(),
            initialLine: line.isEmpty ? null : line,
            autoSubmit: autoSubmit,
          ),
        );
      }

      bool hasAmountInLine(String text) {
        final t = text.trim();
        if (t.isEmpty) return false;
        return RegExp(r'(\d[\d,]*)\s*원').hasMatch(t) ||
            RegExp(r'\d[\d,]*\s*$').hasMatch(t);
      }

      if (action.autoSubmit) {
        final missingForAuto = !hasAmountInLine(line);
        if (missingForAuto) {
          _showSimpleInfoDialog(
            navigator,
            title: '자동 저장 불가',
            message:
                '자동 저장을 위해서는 금액이 필요합니다.'
                '\n예: 커피 3000원'
                '\n화면을 열어 입력을 계속 진행하세요.',
          );
          openScreen(autoSubmit: false);
          return;
        }

        if (!action.confirmed) {
          final previewText = line.isNotEmpty
              ? line
              : (description.isNotEmpty ? description : '간편 지출(1줄)');
          final amountText = amount != null
              ? (amount == amount.roundToDouble()
                    ? amount.toStringAsFixed(0)
                    : amount.toString())
              : '';

          showDialog<bool>(
            context: navigator.context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('저장 전에 확인'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('입력: $previewText'),
                    if (amountText.isNotEmpty) Text('금액: $amountText'),
                    const SizedBox(height: 8),
                    const Text('이대로 저장할까요?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('저장'),
                  ),
                ],
              );
            },
          ).then((confirmed) {
            if (confirmed == true) {
              openScreen(autoSubmit: true);
            }
          });
          return;
        }

        // 성공 로깅
        VoiceAssistantAnalytics.logCommand(
          assistant: _detectAssistant(action.params),
          route: action.routeName,
          intent: action.intent ?? 'quick_expense_add',
          success: true,
        );

        openScreen(autoSubmit: true);
        return;
      }

      // 성공 로깅 (Preview 모드)
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: action.routeName,
        intent: action.intent ?? 'quick_expense_add',
        success: true,
      );

      openScreen(autoSubmit: false);
      return;
    }

    // 성공 로깅 (일반 route)
    VoiceAssistantAnalytics.logCommand(
      assistant: _detectAssistant(action.params),
      route: action.routeName,
      intent: action.intent ?? 'open',
      success: true,
    );

    navigator.pushNamed(spec.routeName, arguments: args);
  }

  // ignore: unused_element
  Map<String, String> _filterAllowedRouteParams({
    required String routeName,
    required String? intent,
    required Map<String, String> params,
  }) {
    if (params.isEmpty) return const <String, String>{};

    final allowed = <String>{};

    // Transaction add: allow scan receipt trigger via action param.
    if (routeName == AppRoutes.transactionAdd) {
      allowed.addAll({'action'});
    }

    // Food expiry upsert supports a limited prefill schema.
    if (routeName == AppRoutes.foodExpiry &&
        (intent ?? '').trim().toLowerCase() == 'upsert') {
      allowed.addAll({
        'name',
        'item',
        'product',
        'quantity',
        'qty',
        'unit',
        'location',
        'category',
        'supplier',
        'purchasePlace',
        'place',
        'store',
        'memo',
        'note',
        'desc',
        'price',
        'healthTags',
        'tags',
        'purchaseDate',
        'purchasedAt',
        'buyDate',
        'expiryDate',
        'expiry',
        'expiryDays',
        'days',
      });
    }

    if (allowed.isEmpty) return const <String, String>{};

    final filtered = <String, String>{};
    for (final entry in params.entries) {
      if (!allowed.contains(entry.key)) continue;
      filtered[entry.key] = entry.value;
    }

    return filtered;
  }

  void _showSimpleInfoDialog(
    NavigatorState navigator, {
    required String title,
    required String message,
    List<Widget>? actions,
  }) {
    final context = navigator.context;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions:
            actions ??
            [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인'),
              ),
            ],
      ),
    );
  }

  void _handleAddTransaction(
    NavigatorState navigator,
    AddTransactionAction action,
  ) {
    // 파라미터 검증
    final validationResult = RouteParamValidator.validate(
      action.isIncome
          ? AppRoutes.transactionAddIncome
          : AppRoutes.transactionAdd,
      action.toParams(),
    );

    if (!validationResult.isValid) {
      _logAndShowError(
        navigator: navigator,
        errorType: 'INVALID_PARAMS',
        route: action.isIncome
            ? AppRoutes.transactionAddIncome
            : AppRoutes.transactionAdd,
        assistant: _detectAssistant(action.toParams()),
        rejectedParams: validationResult.rejected,
      );
      return;
    }

    final resolvedAccountName =
        AssistantRouteCatalog.resolveDefaultAccountName() ??
        (AccountService().accounts.isNotEmpty
            ? AccountService().accounts.first.name
            : null);
    if (resolvedAccountName == null || resolvedAccountName.isEmpty) {
      debugPrint('DeepLinkHandler: No accounts available');
      _logAndShowError(
        navigator: navigator,
        errorType: 'ACCOUNT_REQUIRED',
        route: action.isIncome
            ? AppRoutes.transactionAddIncome
            : AppRoutes.transactionAdd,
        assistant: _detectAssistant(action.toParams()),
      );
      return;
    }

    final now = DateTime.now();
    final type = action.isIncome
        ? TransactionType.income
        : action.isSavings
        ? TransactionType.savings
        : action.isRefund
        ? TransactionType.refund
        : TransactionType.expense;
    final amount = action.amount;
    final quantityRaw = action.quantity;
    final unit = action.unit?.trim() ?? '';
    final unitPriceRaw = action.unitPrice;
    final desc = action.description?.trim();
    var memo = action.memo?.trim() ?? '';
    final paymentMethod = action.paymentMethod?.trim() ?? '';
    final store = action.store?.trim() ?? '';
    final savingsAllocation = action.savingsAllocation;

    // 책스캔앱 OCR 결과 처리: items를 memo에 자동 추가
    if (action.items != null && action.items!.isNotEmpty) {
      final itemsList = action.items!
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (itemsList.isNotEmpty) {
        final itemsText = itemsList.join(', ');
        if (memo.isEmpty) {
          memo = '📋 $itemsText';
        } else {
          memo = '$memo\n📋 $itemsText';
        }
      }
    }

    final qty = (quantityRaw != null && quantityRaw > 0)
        ? quantityRaw.round()
        : 1;

    final hasUnitPrice = unitPriceRaw != null && unitPriceRaw > 0;
    final hasQty = quantityRaw != null && quantityRaw > 0;

    Transaction? initialTransaction;
    final hasDesc = desc != null && desc.isNotEmpty;
    if (amount != null || hasDesc || hasUnitPrice || hasQty) {
      final computedAmount =
          amount ?? (hasUnitPrice ? (unitPriceRaw * qty) : 0);
      final computedUnitPrice = hasUnitPrice
          ? unitPriceRaw
          : (qty > 0 ? (computedAmount / qty) : computedAmount);
      initialTransaction = Transaction(
        id: '',
        type: type,
        amount: computedAmount,
        quantity: qty,
        unit: unit.isEmpty ? null : unit,
        unitPrice: computedUnitPrice,
        date: now,
        description: desc ?? '',
        paymentMethod: paymentMethod.isEmpty ? '현금' : paymentMethod,
        memo: memo,
        store: store.isEmpty ? null : store,
        isRefund: action.isRefund,
        savingsAllocation: type == TransactionType.savings
            ? (savingsAllocation ?? SavingsAllocation.assetIncrease)
            : null,
        mainCategory: action.category,
      );
    }

    final routeName = action.isIncome
        ? AppRoutes.transactionAddIncome
        : AppRoutes.transactionAdd;

    void openScreen({required bool autoSubmit}) {
      navigator.pushNamed(
        routeName,
        arguments: TransactionAddArgs(
          accountName: resolvedAccountName,
          initialTransaction: initialTransaction,
          treatAsNew: true,
          closeAfterSave: true,
          autoSubmit: autoSubmit,
          openReceiptScannerOnStart: action.openReceiptScannerOnStart,
        ),
      );
    }

    if (action.autoSubmit) {
      final missingForAuto =
          amount == null || amount <= 0 || desc == null || desc.isEmpty;
      if (missingForAuto) {
        _showSimpleInfoDialog(
          navigator,
          title: '자동 저장 불가',
          message:
              '자동 저장을 위해서는 설명과 금액이 필요합니다.'
              '\n화면을 열어 입력을 계속 진행하세요.',
        );
        openScreen(autoSubmit: false);
        return;
      }

      if (!action.confirmed) {
        final typeText = action.isIncome
            ? '수입'
            : action.isSavings
            ? '저축'
            : action.isRefund
            ? '반품'
            : '지출';
        final categoryText =
            (action.category == null || action.category!.trim().isEmpty)
            ? '미분류'
            : action.category!.trim();
        final amountText = amount.toStringAsFixed(
          amount == amount.roundToDouble() ? 0 : 2,
        );
        final qtyText = qty <= 1 ? '' : qty.toString();
        final unitText = unit.isEmpty ? '' : unit;
        final unitLine = (qtyText.isEmpty && unitText.isEmpty)
            ? ''
            : '$qtyText$unitText';

        showDialog<bool>(
          context: navigator.context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('저장 전에 확인'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('종류: $typeText'),
                  Text('설명: $desc'),
                  Text('금액: $amountText원'),
                  if (unitLine.isNotEmpty) Text('수량: $unitLine'),
                  Text('카테고리: $categoryText'),
                  if (memo.isNotEmpty) Text('메모: $memo'),
                  const SizedBox(height: 8),
                  const Text('이대로 저장할까요?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        ).then((confirmed) {
          if (confirmed == true) {
            openScreen(autoSubmit: true);
          }
        });
        return;
      }

      // 성공 로깅
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.toParams()),
        route: action.isIncome
            ? AppRoutes.transactionAddIncome
            : AppRoutes.transactionAdd,
        intent: 'transaction_add',
        success: true,
      );

      openScreen(autoSubmit: true);
      return;
    }

    // 성공 로깅 (Preview 모드)
    VoiceAssistantAnalytics.logCommand(
      assistant: _detectAssistant(action.toParams()),
      route: action.isIncome
          ? AppRoutes.transactionAddIncome
          : AppRoutes.transactionAdd,
      intent: 'transaction_add',
      success: true,
    );

    openScreen(autoSubmit: false);
  }

  void _handleAddToCart(
    NavigatorState navigator,
    AddToCartAction action,
  ) async {
    // 현재 계정 조회
    final accountService = AccountService();
    await accountService.loadAccounts();
    final accounts = accountService.accounts;
    if (accounts.isEmpty) {
      _showSimpleInfoDialog(
        navigator,
        title: '계정 없음',
        message: '먼저 계정을 생성해주세요.',
      );
      return;
    }

    final accountName = accounts.first.name;
    await UserPrefService.setLastAccountName(accountName);

    // 이전 위치 조회 또는 딥링크 위치 사용
    final locationService = ProductLocationService.instance;
    final previousLocation = await locationService.getLocation(
      accountName: accountName,
      productName: action.name,
    );
    final finalLocation = action.location?.isNotEmpty == true
        ? action.location!
        : (previousLocation ?? '');

    // 장바구니에 추가
    final existingItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'shop_${now.microsecondsSinceEpoch}',
      name: action.name,
      quantity: action.quantity ?? 1,
      unitPrice: action.price ?? 0,
      storeLocation: finalLocation,
      createdAt: now,
      updatedAt: now,
    );

    final updatedItems = [newItem, ...existingItems];
    await UserPrefService.setShoppingCartItems(
      accountName: accountName,
      items: updatedItems,
    );

    // 위치 학습에 저장
    if (finalLocation.isNotEmpty) {
      await locationService.saveLocation(
        accountName: accountName,
        productName: action.name,
        location: finalLocation,
      );
    }

    // 성공 로깅
    VoiceAssistantAnalytics.logCommand(
      assistant: 'voice',
      route: AppRoutes.shoppingCart,
      intent: 'add_to_cart',
      success: true,
    );

    // 장바구니 화면으로 이동
    navigator.pushNamed(
      AppRoutes.shoppingCart,
      arguments: ShoppingCartArgs(accountName: accountName),
    );
  }

  void _handleOpenDashboard(NavigatorState navigator) {
    // Pop to root and show dashboard
    navigator.popUntil((route) => route.isFirst);
  }

  void _handleOpenFeature(NavigatorState navigator, OpenFeatureAction action) {
    // 성공 로깅 헬퍼
    void logSuccess(String routeName) {
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: routeName,
        intent: 'open_feature',
        success: true,
      );
    }

    final route = action.routeName;
    if (route == null) {
      VoiceAssistantAnalytics.logError(
        assistant: _detectAssistant(action.params),
        route: 'unknown',
        errorType: 'ROUTE_NOT_ALLOWED',
      );
      debugPrint('DeepLinkHandler: Unknown feature: ${action.featureId}');
      _showSimpleInfoDialog(
        navigator,
        title: '보안 안내',
        message:
            '보안 사항 접근 안 됩니다.'
            '\n음성비서로는 지원되지 않는 기능입니다.'
            '\n(${action.featureId})',
      );
      return;
    }

    // Special handling for dashboard
    if (route == '/') {
      logSuccess('/');
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    // Handle food_expiry, shopping_cart, assets, recipe, consumables
    switch (action.featureId) {
      case 'food_expiry':
        logSuccess(AppRoutes.foodExpiry);
        navigator.pushNamed(AppRoutes.foodExpiry);
      case 'shopping_cart':
        logSuccess(AppRoutes.shoppingCart);
        logSuccess(AppRoutes.shoppingCart);
        navigator.pushNamed(AppRoutes.shoppingCart);
      case 'assets':
        logSuccess(AppRoutes.assetDashboard);
        navigator.pushNamed(AppRoutes.assetDashboard);
      case 'recipe':
        logSuccess(AppRoutes.foodCookingStart);
        navigator.pushNamed(AppRoutes.foodCookingStart);
      case 'consumables':
        logSuccess(AppRoutes.householdConsumables);
        navigator.pushNamed(AppRoutes.householdConsumables);
      case 'calendar':
        logSuccess(AppRoutes.calendar);
        navigator.pushNamed(AppRoutes.calendar);
      case 'savings':
        logSuccess(AppRoutes.savingsPlanList);
        navigator.pushNamed(AppRoutes.savingsPlanList);
      case 'emergency_fund':
        logSuccess(AppRoutes.emergencyFund);
        navigator.pushNamed(AppRoutes.emergencyFund);
      case 'stats':
        logSuccess(AppRoutes.monthlyStats);
        navigator.pushNamed(AppRoutes.monthlyStats);
      case 'voice':
      case 'voice_dashboard':
        logSuccess(AppRoutes.voiceDashboard);
        navigator.pushNamed(AppRoutes.voiceDashboard);
      case 'transaction_add':
        _handleAddTransaction(
          navigator,
          const AddTransactionAction(type: 'expense'),
        );
      case 'income_add':
        _handleAddTransaction(
          navigator,
          const AddTransactionAction(type: 'income'),
        );
      case 'quick_stock':
        logSuccess(AppRoutes.quickStockUse);
        navigator.pushNamed(AppRoutes.quickStockUse);
      default:
        VoiceAssistantAnalytics.logError(
          assistant: _detectAssistant(action.params),
          route: 'unknown',
          errorType: 'ROUTE_NOT_ALLOWED',
        );
        debugPrint('DeepLinkHandler: No route mapping for ${action.featureId}');
        _showSimpleInfoDialog(
          navigator,
          title: '보안 안내',
          message:
              '보안 사항 접근 안 됩니다.'
              '\n음성비서로는 지원되지 않는 기능입니다.'
              '\n(${action.featureId})',
        );
    }
  }

  /// 재고 조회 - 빅스비/제미나이에서 "팽이버섯 얼마나 남았어?"
  void _handleCheckStock(NavigatorState navigator, CheckStockAction action) {
    final items = ConsumableInventoryService.instance.items.value;
    final product = action.productName.toLowerCase();

    // 상품 검색
    final found = items
        .where(
          (item) =>
              item.name.toLowerCase().contains(product) ||
              product.contains(item.name.toLowerCase()),
        )
        .toList();

    if (found.isEmpty) {
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: AppRoutes.householdConsumables,
        intent: 'check_stock',
        success: false,
        failureReason: 'STOCK_NOT_FOUND',
      );
      _showStockNotFoundDialog(navigator, action.productName);
      return;
    }

    VoiceAssistantAnalytics.logCommand(
      assistant: _detectAssistant(action.params),
      route: AppRoutes.householdConsumables,
      intent: 'check_stock',
      success: true,
    );
    final item = found.first;
    _showStockInfoDialog(navigator, item);
  }

  /// 요리 추천 - 빅스비로 "요리 뭐로 하지?" 또는 "점심 뭐 먹지?"
  void _handleRecipeRecommend(
    NavigatorState navigator,
    RecipeRecommendAction action,
  ) async {
    // 현재 계정 조회
    final accountService = AccountService();
    await accountService.loadAccounts();
    final accounts = accountService.accounts;
    if (accounts.isEmpty) {
      _showSimpleInfoDialog(
        navigator,
        title: '계정 없음',
        message: '먼저 계정을 생성해주세요.',
      );
      VoiceAssistantAnalytics.logCommand(
        assistant: 'Bixby', // Most likely from Bixby
        route: '/food/expiry',
        intent: 'recipe_recommend',
        success: false,
        failureReason: 'ACCOUNT_REQUIRED',
      );
      return;
    }

    final accountName = accounts.first.name;
    await UserPrefService.setLastAccountName(accountName);

    // 끼니별 메시지
    final mealLabel = _getMealLabel(action.mealType);

    // 성공 로깅
    VoiceAssistantAnalytics.logCommand(
      assistant: 'Bixby',
      route: '/food/expiry',
      intent: 'recipe_recommend',
      success: true,
    );

    // 냉장고 화면으로 이동 + 레시피 선택기 자동 열기
    navigator.pushNamed(
      AppRoutes.foodExpiry,
      arguments: const FoodExpiryArgs(
        openCookableRecipePickerOnStart: true,
        scrollToDailyRecipeRecommendationOnStart: true,
      ),
    );

    // 안내 메시지 표시
    Future.delayed(const Duration(milliseconds: 800), () {
      if (navigator.mounted) {
        String message;
        if (action.prioritizeExpiring) {
          // 유통기한 임박 재료 우선 모드
          message =
              '⚠️ 유통기한 임박 재료 활용 요리!\n'
              '🕒 빨리 소진해야 할 재료 우선 사용\n'
              '✅ 현재 재고로 만들 수 있는 레시피\n'
              '📝 부족한 재료는 장바구니에 추가';
        } else if (action.ingredients != null &&
            action.ingredients!.isNotEmpty) {
          final ingredientsText = action.ingredients!.join(', ');
          message =
              '💡 $ingredientsText 사용 가능한 $mealLabel 추천!\n'
              '✅ 현재 재고로 만들 수 있는 레시피\n'
              '📝 부족한 재료는 장바구니에 자동 추가';
        } else if (action.mealType != null) {
          message =
              '💡 $mealLabel 추천!\n'
              '✅ 냉장고 재료로 만들 수 있는 요리\n'
              '📝 부족한 재료는 장바구니에 추가 가능';
        } else {
          message =
              '💡 냉장고 재료로 만들 수 있는 요리 추천!\n'
              '✅ 유통기한 임박 재료 우선 사용\n'
              '📝 부족한 재료는 장바구니에 자동 추가';
        }

        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: '확인', onPressed: () {}),
          ),
        );
      }
    });
  }

  /// 영수증 건강도 분석 - 빅스비로 "영수증 건강도 분석"
  void _handleReceiptAnalyze(
    NavigatorState navigator,
    ReceiptAnalyzeAction action,
  ) async {
    // 성공 로깅
    VoiceAssistantAnalytics.logCommand(
      assistant: 'Bixby',
      route: '/food/health-analyzer',
      intent: 'receipt_analyze',
      success: true,
    );

    // 건강도 분석 화면으로 이동
    navigator.pushNamed(AppRoutes.healthAnalyzer);

    // 안내 메시지 표시
    Future.delayed(const Duration(milliseconds: 800), () {
      if (navigator.mounted) {
        String message;
        if (action.ingredients != null && action.ingredients!.isNotEmpty) {
          message =
              '✅ 입력한 재료의 건강도를 분석합니다\n'
              '💚 5점: 매우 건강 (채소, 버섯)\n'
              '🟡 3점: 보통 (닭고기, 쌀)\n'
              '🔴 1점: 비건강 (튀김, 가공식품)';
        } else {
          message =
              '📋 영수증 재료를 입력하세요\n'
              '✅ 체크박스로 간편하게 선택\n'
              '💚 실시간 건강 점수 계산\n'
              '📊 건강한 재료 비율 통계';
        }

        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    });
  }

  String _getMealLabel(String? mealType) {
    if (mealType == null) return '요리';
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '아침 메뉴';
      case 'lunch':
        return '점심 메뉴';
      case 'dinner':
        return '저녁 메뉴';
      default:
        return '요리';
    }
  }

  /// 재고 차감 - 빅스비/제미나이에서 "팽이버섯 1봉 썼어"
  void _handleUseStock(NavigatorState navigator, UseStockAction action) {
    final accounts = AccountService().accounts;
    if (accounts.isEmpty) {
      debugPrint('DeepLinkHandler: No accounts available');
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: AppRoutes.quickStockUse,
        intent: 'use_stock',
        success: false,
        failureReason: 'ACCOUNT_REQUIRED',
      );
      return;
    }

    final accountName = accounts.first.name;

    double? initialAmount = action.amount;
    if (initialAmount == null) {
      final items = ConsumableInventoryService.instance.items.value;
      final product = action.productName.toLowerCase();
      final found = items
          .where(
            (item) =>
                item.name.toLowerCase().contains(product) ||
                product.contains(item.name.toLowerCase()),
          )
          .toList();
      if (found.isNotEmpty) {
        initialAmount = found.first.currentStock;
      }
    }

    // 성공 로깅 헬퍼
    void logSuccess() {
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: AppRoutes.quickStockUse,
        intent: 'use_stock',
        success: true,
      );
    }

    // 안전 정책: autoSubmit(즉시 실행) 요청은 반드시 확인을 거친 뒤에만 수행
    if (action.autoSubmit && !action.confirmed) {
      _showStockUseConfirmDialog(
        navigator,
        productName: action.productName,
        amount: initialAmount,
        onProceed: () {
          logSuccess();
          navigator.pushNamed(
            AppRoutes.quickStockUse,
            arguments: QuickStockUseArgs(
              accountName: accountName,
              initialProductName: action.productName,
              initialAmount: initialAmount,
              autoSubmit: true,
            ),
          );
        },
        onCancel: () {
          logSuccess();
          navigator.pushNamed(
            AppRoutes.quickStockUse,
            arguments: QuickStockUseArgs(
              accountName: accountName,
              initialProductName: action.productName,
              initialAmount: initialAmount,
            ),
          );
        },
      );
      return;
    }

    logSuccess();
    // 빠른 재고 차감 화면으로 이동 (파라미터 전달)
    navigator.pushNamed(
      AppRoutes.quickStockUse,
      arguments: QuickStockUseArgs(
        accountName: accountName,
        initialProductName: action.productName,
        initialAmount: initialAmount,
        autoSubmit: action.autoSubmit,
      ),
    );
  }

  void _showStockUseConfirmDialog(
    NavigatorState navigator, {
    required String productName,
    required double? amount,
    required VoidCallback onProceed,
    required VoidCallback onCancel,
  }) {
    final context = navigator.context;
    final qtyLabel = amount == null ? '전량' : _formatQty(amount);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('재고 차감 확인'),
          ],
        ),
        content: Text(
          '"$productName" $qtyLabel 차감을 실행할까요?\n'
          '확인하면 즉시 차감이 진행됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCancel();
            },
            child: const Text('아니요'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onProceed();
            },
            child: const Text('실행'),
          ),
        ],
      ),
    );
  }

  /// 재고 없음 다이얼로그
  void _showStockNotFoundDialog(NavigatorState navigator, String productName) {
    final context = navigator.context;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('재고 없음'),
          ],
        ),
        content: Text(
          '"$productName" 상품을 찾을 수 없습니다.\n'
          '재고에 등록되어 있는지 확인해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              navigator.pushNamed(AppRoutes.householdConsumables);
            },
            child: const Text('재고 등록하기'),
          ),
        ],
      ),
    );
  }

  /// 재고 정보 다이얼로그 (음성 확인용)
  void _showStockInfoDialog(NavigatorState navigator, dynamic item) {
    final context = navigator.context;

    // 유통기한 정보
    String? expiryInfo;
    if (item.expiryDate != null) {
      final daysLeft = item.expiryDate!.difference(DateTime.now()).inDays;
      if (daysLeft < 0) {
        expiryInfo = '⚠️ 유통기한 ${-daysLeft}일 경과';
      } else if (daysLeft <= 3) {
        expiryInfo = '⏰ D-$daysLeft 임박!';
      } else {
        expiryInfo = 'D-$daysLeft';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.inventory_2, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 재고량
            _buildInfoRow(
              '📦 현재 재고',
              '${_formatQty(item.currentStock)}${item.unit}',
              item.currentStock <= item.threshold
                  ? Colors.orange
                  : Colors.green,
            ),
            const SizedBox(height: 12),
            // 유통기한
            if (expiryInfo != null) ...[
              _buildInfoRow(
                '📅 유통기한',
                expiryInfo,
                expiryInfo.contains('경과')
                    ? Colors.red
                    : expiryInfo.contains('임박')
                    ? Colors.orange
                    : Colors.grey,
              ),
              const SizedBox(height: 12),
            ],
            // 보관 위치
            _buildInfoRow('📍 보관 위치', item.location, Colors.grey),
            const Divider(height: 24),
            const Text(
              '🎤 "응" 또는 "전량 사용"이라고 말하면\n재고 차감을 진행합니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              final accounts = AccountService().accounts;
              if (accounts.isNotEmpty) {
                navigator.pushNamed(
                  AppRoutes.quickStockUse,
                  arguments: QuickStockUseArgs(
                    accountName: accounts.first.name,
                    initialProductName: item.name,
                    initialAmount: item.currentStock,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: Text('전량 사용 (${_formatQty(item.currentStock)}${item.unit})'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) return rounded.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  /// 어시스턴트 감지 (파라미터 기반 추정)
  String _detectAssistant(Map<String, String>? params) {
    // 향후 확장: User-Agent 또는 origin 파라미터
    return VoiceAssistantAnalytics.detectAssistant(params);
  }

  /// 에러 로깅 및 사용자 친화적 다이얼로그 표시
  void _logAndShowError({
    required NavigatorState navigator,
    required String errorType,
    required String route,
    String? assistant,
    String? message,
    List<Widget>? actions,
    List<String>? rejectedParams,
  }) {
    // 상세 로깅
    debugPrint('DeepLinkHandler Error:');
    debugPrint('  Type: $errorType');
    debugPrint('  Route: $route');
    debugPrint('  Assistant: ${assistant ?? "unknown"}');
    if (rejectedParams != null && rejectedParams.isNotEmpty) {
      debugPrint('  Rejected Params: $rejectedParams');
    }

    // 분석 로깅
    VoiceAssistantAnalytics.logError(
      errorType: errorType,
      route: route,
      assistant: assistant,
    );

    // 거부된 파라미터 로깅
    if (rejectedParams != null && rejectedParams.isNotEmpty) {
      VoiceAssistantAnalytics.logRejectedParams(
        route: route,
        rejected: rejectedParams,
        assistant: assistant,
      );
    }

    // 명령 실패 로깅
    VoiceAssistantAnalytics.logCommand(
      assistant: assistant ?? 'unknown',
      route: route,
      intent: 'open',
      success: false,
      failureReason: errorType,
    );

    // 사용자 메시지
    final errorMessage = _getErrorMessage(errorType, route, message);

    _showSimpleInfoDialog(
      navigator,
      title: errorMessage.title,
      message: errorMessage.body,
      actions: actions,
    );
  }

  /// 에러 타입별 사용자 친화적 메시지
  _ErrorMessage _getErrorMessage(
    String errorType,
    String route, [
    String? customMessage,
  ]) {
    if (customMessage != null) {
      final title = errorType == 'ROUTE_NOT_ALLOWED'
          ? '보안 안내'
          : errorType == 'ACCOUNT_REQUIRED'
          ? '계정이 필요합니다'
          : errorType == 'INVALID_PARAMS'
          ? '잘못된 명령입니다'
          : '오류';

      return _ErrorMessage(title: title, body: customMessage);
    }

    switch (errorType) {
      case 'ROUTE_NOT_ALLOWED':
        return const _ErrorMessage(
          title: '보안 안내',
          body: '음성 명령으로는 이 화면을 열 수 없습니다.\n앱에서 직접 열어주세요.',
        );

      case 'ACCOUNT_REQUIRED':
        return const _ErrorMessage(
          title: '계정이 필요합니다',
          body: '먼저 계정을 생성하거나 선택해주세요.',
        );

      case 'INVALID_PARAMS':
        return const _ErrorMessage(
          title: '잘못된 명령입니다',
          body: '음성 명령의 일부를 인식하지 못했습니다.\n다시 시도해주세요.',
        );

      case 'AUTO_SUBMIT_REJECTED':
        return const _ErrorMessage(
          title: '확인이 필요합니다',
          body: '안전을 위해 앱에서 직접 확인해주세요.',
        );

      default:
        return const _ErrorMessage(
          title: '오류',
          body: '처리 중 문제가 발생했습니다.\n다시 시도해주세요.',
        );
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// 에러 메시지 모델
class _ErrorMessage {
  final String title;
  final String body;

  const _ErrorMessage({required this.title, required this.body});
}

/// Quick Stock Use 화면 인자
class QuickStockUseArgs {
  final String accountName;
  final String? initialProductName;
  final double? initialAmount;
  final bool autoSubmit;

  const QuickStockUseArgs({
    required this.accountName,
    this.initialProductName,
    this.initialAmount,
    this.autoSubmit = false,
  });
}
