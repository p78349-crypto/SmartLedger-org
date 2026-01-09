import 'dart:async';

import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'global_navigator_key.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../services/deep_link_service.dart';
import '../services/consumable_inventory_service.dart';
import '../services/health_guardrail_service.dart';
import 'assistant_route_catalog.dart';
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

    debugPrint('DeepLinkHandler: Received action: $action');

    switch (action) {
      case AddTransactionAction():
        _handleAddTransaction(navigator, action);
      case OpenDashboardAction():
        _handleOpenDashboard(navigator);
      case OpenFeatureAction():
        _handleOpenFeature(navigator, action);
      case OpenRouteAction():
        _handleOpenRoute(navigator, action);
      case CheckStockAction():
        _handleCheckStock(navigator, action);
      case UseStockAction():
        _handleUseStock(navigator, action);
    }
  }

  void _handleOpenRoute(NavigatorState navigator, OpenRouteAction action) {
    final spec = AssistantRouteCatalog.specs[action.routeName];
    if (spec == null) {
      debugPrint('DeepLinkHandler: Route not allowed: ${action.routeName}');
      _showSimpleInfoDialog(
        navigator,
        title: '지원되지 않는 화면',
        message: '해당 화면은 음성으로 바로 열 수 없습니다.\n(${action.routeName})',
      );
      return;
    }

    final accountName = action.accountName ?? AssistantRouteCatalog.resolveDefaultAccountName();
    if (spec.requiresAccount && (accountName == null || accountName.isEmpty)) {
      _showSimpleInfoDialog(
        navigator,
        title: '계정이 필요합니다',
        message: '먼저 계정을 생성/선택한 뒤 다시 시도해주세요.',
      );
      return;
    }

    final args = spec.buildArgs(accountName);

    // Safe intent: receipt scan hook for transaction add.
    if (action.routeName == AppRoutes.transactionAdd && args is TransactionAddArgs) {
      final intent = (action.intent ?? '').trim().toLowerCase();
      final requestedAction = (action.params['action'] ?? '').trim().toLowerCase();

      final wantsScan =
          intent == 'scan_receipt' || intent == 'scan' || requestedAction == 'scan';

      if (wantsScan) {
        navigator.pushNamed(
          spec.routeName,
          arguments: TransactionAddArgs(
            accountName: args.accountName,
            initialTransaction: args.initialTransaction,
            learnCategoryHintFromDescription: args.learnCategoryHintFromDescription,
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
      final p = action.params;

      String? name = p['name'] ?? p['item'] ?? p['product'];
      name = name?.trim();

      final quantity = double.tryParse((p['quantity'] ?? p['qty'] ?? '').trim());
      final unit = (p['unit'] ?? '').trim();
      final location = (p['location'] ?? '').trim();
      final category = (p['category'] ?? '').trim();
      final supplier =
          (p['supplier'] ?? p['purchasePlace'] ?? p['place'] ?? p['store'] ?? '')
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
                    if (purchaseDate != null)
                      Text('구매일: ${purchaseDate.toLocal().toString().split(' ').first}'),
                    if (expiryDate != null)
                      Text('유통기한: ${expiryDate.toLocal().toString().split(' ').first}'),
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
        navigator.pushNamed(
          spec.routeName,
          arguments: const FoodExpiryArgs(
            autoUsageMode: true,
          ),
        );
        return;
      }
    }

    if (action.routeName == AppRoutes.assetSimpleInput && action.intent == 'asset_add') {
      final p = action.params;

      final category = (p['category'] ?? p['assetCategory'] ?? '').trim();
      final name = (p['name'] ?? p['assetName'] ?? '').trim();
      final amount = double.tryParse((p['amount'] ?? '').trim());
      final location = (p['location'] ?? '').trim();
      final memo = (p['memo'] ?? '').trim();

      void openScreen({required bool autoSubmit}) {
        navigator.pushNamed(
          spec.routeName,
          arguments: AssetSimpleInputArgs(
            accountName: accountName ?? AssistantRouteCatalog.resolveDefaultAccountName() ?? '',
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
            message: '자동 저장을 위해서는 자산명과 금액이 필요합니다.\n화면을 열어 입력을 계속 진행하세요.',
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

        openScreen(autoSubmit: true);
        return;
      }

      openScreen(autoSubmit: false);
      return;
    }

    if (action.routeName == AppRoutes.quickSimpleExpenseInput && action.intent == 'quick_expense_add') {
      final p = action.params;

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
            accountName: accountName ?? AssistantRouteCatalog.resolveDefaultAccountName() ?? '',
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
            message: '자동 저장을 위해서는 금액이 필요합니다.\n예: 커피 3000원\n화면을 열어 입력을 계속 진행하세요.',
          );
          openScreen(autoSubmit: false);
          return;
        }

        if (!action.confirmed) {
          final previewText = line.isNotEmpty
              ? line
              : (description.isNotEmpty
                    ? description
                    : '간편 지출(1줄)');
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

        openScreen(autoSubmit: true);
        return;
      }

      openScreen(autoSubmit: false);
      return;
    }
    navigator.pushNamed(spec.routeName, arguments: args);
  }

  void _showSimpleInfoDialog(
    NavigatorState navigator, {
    required String title,
    required String message,
  }) {
    final context = navigator.context;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _handleAddTransaction(NavigatorState navigator, AddTransactionAction action) {
    final resolvedAccountName =
        AssistantRouteCatalog.resolveDefaultAccountName() ??
        (AccountService().accounts.isNotEmpty
            ? AccountService().accounts.first.name
            : null);
    if (resolvedAccountName == null || resolvedAccountName.isEmpty) {
      debugPrint('DeepLinkHandler: No accounts available');
      _showSimpleInfoDialog(
        navigator,
        title: '계정이 필요합니다',
        message: '먼저 계정을 생성/선택한 뒤 다시 시도해주세요.',
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
    final memo = action.memo?.trim() ?? '';
    final paymentMethod = action.paymentMethod?.trim() ?? '';
    final store = action.store?.trim() ?? '';
    final savingsAllocation = action.savingsAllocation;

    final qty = (quantityRaw != null && quantityRaw > 0)
        ? quantityRaw.round()
        : 1;

    final hasUnitPrice = unitPriceRaw != null && unitPriceRaw > 0;
    final hasQty = quantityRaw != null && quantityRaw > 0;

    Transaction? initialTransaction;
    final hasDesc = desc != null && desc.isNotEmpty;
    if (amount != null || hasDesc || hasUnitPrice || hasQty) {
      final computedAmount = amount ?? (hasUnitPrice ? (unitPriceRaw * qty) : 0);
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

    final routeName = action.isIncome ? AppRoutes.transactionAddIncome : AppRoutes.transactionAdd;

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
          message: '자동 저장을 위해서는 설명과 금액이 필요합니다.\n화면을 열어 입력을 계속 진행하세요.',
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
        final categoryText = (action.category == null || action.category!.trim().isEmpty)
            ? '미분류'
            : action.category!.trim();
        final amountText = amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
        final qtyText = qty <= 1 ? '' : qty.toString();
        final unitText = unit.isEmpty ? '' : unit;
        final unitLine = (qtyText.isEmpty && unitText.isEmpty) ? '' : '$qtyText$unitText';

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

      openScreen(autoSubmit: true);
      return;
    }

    openScreen(autoSubmit: false);
  }

  void _handleOpenDashboard(NavigatorState navigator) {
    // Pop to root and show dashboard
    navigator.popUntil((route) => route.isFirst);
  }

  void _handleOpenFeature(NavigatorState navigator, OpenFeatureAction action) {
    final route = action.routeName;
    if (route == null) {
      debugPrint('DeepLinkHandler: Unknown feature: ${action.featureId}');
      return;
    }

    // Special handling for dashboard
    if (route == '/') {
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    // Handle food_expiry, shopping_cart, assets, recipe, consumables
    switch (action.featureId) {
      case 'food_expiry':
        navigator.pushNamed(AppRoutes.foodExpiry);
      case 'shopping_cart':
        navigator.pushNamed(AppRoutes.shoppingCart);
      case 'assets':
        navigator.pushNamed(AppRoutes.assetDashboard);
      case 'recipe':
        navigator.pushNamed(AppRoutes.foodCookingStart);
      case 'consumables':
        navigator.pushNamed(AppRoutes.householdConsumables);
      case 'calendar':
        navigator.pushNamed(AppRoutes.calendar);
      case 'savings':
        navigator.pushNamed(AppRoutes.savingsPlanList);
      case 'emergency_fund':
        navigator.pushNamed(AppRoutes.emergencyFund);
      case 'stats':
        navigator.pushNamed(AppRoutes.monthlyStats);
      case 'voice':
      case 'voice_dashboard':
        navigator.pushNamed(AppRoutes.voiceDashboard);
      case 'transaction_add':
        _handleAddTransaction(navigator, const AddTransactionAction(type: 'expense'));
      case 'income_add':
        _handleAddTransaction(navigator, const AddTransactionAction(type: 'income'));
      case 'quick_stock':
        navigator.pushNamed(AppRoutes.quickStockUse);
      default:
        debugPrint('DeepLinkHandler: No route mapping for ${action.featureId}');
    }
  }

  /// 재고 조회 - 빅스비/제미나이에서 "팽이버섯 얼마나 남았어?"
  void _handleCheckStock(NavigatorState navigator, CheckStockAction action) {
    final items = ConsumableInventoryService.instance.items.value;
    final product = action.productName.toLowerCase();
    
    // 상품 검색
    final found = items.where((item) => 
      item.name.toLowerCase().contains(product) ||
      product.contains(item.name.toLowerCase())
    ).toList();

    if (found.isEmpty) {
      _showStockNotFoundDialog(navigator, action.productName);
      return;
    }

    final item = found.first;
    _showStockInfoDialog(navigator, item);
  }

  /// 재고 차감 - 빅스비/제미나이에서 "팽이버섯 1봉 썼어"
  void _handleUseStock(NavigatorState navigator, UseStockAction action) {
    final accounts = AccountService().accounts;
    if (accounts.isEmpty) {
      debugPrint('DeepLinkHandler: No accounts available');
      return;
    }

    final accountName = accounts.first.name;

    double? initialAmount = action.amount;
    if (initialAmount == null) {
      final items = ConsumableInventoryService.instance.items.value;
      final product = action.productName.toLowerCase();
      final found = items.where((item) =>
        item.name.toLowerCase().contains(product) ||
        product.contains(item.name.toLowerCase())
      ).toList();
      if (found.isNotEmpty) {
        initialAmount = found.first.currentStock;
      }
    }

    // 안전 정책: autoSubmit(즉시 실행) 요청은 반드시 확인을 거친 뒤에만 수행
    if (action.autoSubmit && !action.confirmed) {
      _showStockUseConfirmDialog(
        navigator,
        productName: action.productName,
        amount: initialAmount,
        onProceed: () {
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
              item.currentStock <= item.threshold ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 12),
            // 유통기한
            if (expiryInfo != null) ...[
              _buildInfoRow(
                '📅 유통기한',
                expiryInfo,
                expiryInfo.contains('경과') ? Colors.red : 
                  expiryInfo.contains('임박') ? Colors.orange : Colors.grey,
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

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
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
