import 'dart:async';

import 'package:flutter/services.dart';
import '../models/transaction.dart';

/// Service for handling deep links from App Actions, Bixby, and other sources.
///
/// Supported URI schemes:
/// - `smartledger://transaction/add?type=expense&amount=5000&description=커피`
/// - `smartledger://transaction/add?type=income&amount=3000000`
/// - `smartledger://transaction/add?type=expense&amount=5000&description=커피&autoSubmit=true` (거래 저장: 확인 필요)
/// - `smartledger://transaction/add?type=expense&amount=5000&description=커피&autoSubmit=true&confirmed=true` (거래 저장: 확인 완료)
  /// - `smartledger://transaction/add?type=expense&action=scan` (영수증 스캔(훅): 화면 열고 스캔 시작 유도)
/// - `smartledger://dashboard`
/// - `smartledger://feature/food_expiry`
/// - `smartledger://feature/shopping_cart`
/// - `smartledger://feature/assets`
/// - `smartledger://feature/recipe`
/// - `smartledger://stock/check?product=팽이버섯` (재고 조회)
/// - `smartledger://stock/use?product=팽이버섯&amount=1&autoSubmit=true` (재고 차감: 확인 필요)
/// - `smartledger://stock/use?product=팽이버섯&amount=1&autoSubmit=true&confirmed=true` (재고 차감: 확인 완료)
/// - `smartledger://nav/open?route=/settings` (안전한 네비게이션)
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  static const _channel = MethodChannel('com.example.smartledger/deeplink');

  final _linkController = StreamController<DeepLinkAction>.broadcast();

  /// Stream of parsed deep link actions.
  Stream<DeepLinkAction> get linkStream => _linkController.stream;

  bool _initialized = false;

  /// Initialize the deep link listener.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Handle method calls from native side
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final uri = call.arguments as String?;
        if (uri != null && uri.isNotEmpty) {
          final action = parseUri(uri);
          if (action != null) {
            _linkController.add(action);
          }
        }
      }
      return null;
    });

    // Check for initial deep link (app launched via deep link)
    try {
      final initial = await _channel.invokeMethod<String>('getInitialLink');
      if (initial != null && initial.isNotEmpty) {
        final action = parseUri(initial);
        if (action != null) {
          _linkController.add(action);
        }
      }
    } on PlatformException catch (_) {
      // Platform channel not available (e.g., on desktop)
    }
  }

  /// Parse a deep link URI into an action.
  DeepLinkAction? parseUri(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;
    if (uri.scheme != 'smartledger') return null;

    final host = uri.host;
    final pathSegments = uri.pathSegments;
    final params = uri.queryParameters;

    switch (host) {
      case 'transaction':
        if (pathSegments.isNotEmpty && pathSegments.first == 'add') {
          return DeepLinkAction.addTransaction(
            type: params['type'] ?? 'expense',
            amount: double.tryParse(params['amount'] ?? ''),
            quantity: double.tryParse(params['quantity'] ?? ''),
            unit: params['unit'],
            unitPrice: double.tryParse(params['unitPrice'] ?? ''),
            description: params['description'],
            category: params['category'],
            paymentMethod: params['paymentMethod'] ?? params['payment'],
            store: params['store'],
            memo: params['memo'],
            savingsAllocation: _parseSavingsAllocation(params['savingsAllocation']),
            currency: params['currency'] ?? 'KRW',
            autoSubmit: params['autoSubmit'] == 'true',
            confirmed: params['confirmed'] == 'true',
            openReceiptScannerOnStart:
                (params['action'] ?? '').trim().toLowerCase() == 'scan' ||
                (params['intent'] ?? '').trim().toLowerCase() == 'scan_receipt',
          );
        }
        break;

      case 'dashboard':
        return const DeepLinkAction.openDashboard();

      case 'feature':
        if (pathSegments.isNotEmpty) {
          return DeepLinkAction.openFeature(pathSegments.first);
        } else if (params.containsKey('feature')) {
          return DeepLinkAction.openFeature(params['feature']!);
        }
        break;

      case 'stock':
        if (pathSegments.isNotEmpty) {
          final action = pathSegments.first;
          final product = params['product'];
          
          if (action == 'check' && product != null) {
            // 재고 조회
            return DeepLinkAction.checkStock(productName: product);
          } else if (action == 'use' && product != null) {
            // 재고 차감
            final amountParam = params['amount'];
            final parsedAmount = amountParam == null ? null : double.tryParse(amountParam);
            return DeepLinkAction.useStock(
              productName: product,
              amount: parsedAmount,
              autoSubmit: params['autoSubmit'] == 'true',
              confirmed: params['confirmed'] == 'true',
            );
          }
        }
        break;

      case 'nav':
        if (pathSegments.isNotEmpty && pathSegments.first == 'open') {
          final route = params['route'];
          if (route == null || route.isEmpty) return null;

          final extras = Map<String, String>.of(params)
            ..remove('route')
            ..remove('account')
            ..remove('intent');
          return DeepLinkAction.openRoute(
            routeName: route,
            accountName: params['account'],
            intent: params['intent'],
            params: extras,
            autoSubmit: params['autoSubmit'] == 'true',
            confirmed: params['confirmed'] == 'true',
          );
        }
        break;
    }

    return null;
  }

  void dispose() {
    _linkController.close();
  }
}

/// Represents a parsed deep link action.
sealed class DeepLinkAction {
  const DeepLinkAction();

  const factory DeepLinkAction.addTransaction({
    required String type,
    double? amount,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? description,
    String? category,
    String? paymentMethod,
    String? store,
    String? memo,
    SavingsAllocation? savingsAllocation,
    String currency,
    bool autoSubmit,
    bool confirmed,
    bool openReceiptScannerOnStart,
  }) = AddTransactionAction;

  const factory DeepLinkAction.openDashboard() = OpenDashboardAction;

  const factory DeepLinkAction.openFeature(String featureId) = OpenFeatureAction;

  const factory DeepLinkAction.openRoute({
    required String routeName,
    String? accountName,
    String? intent,
    Map<String, String>? params,
    bool? autoSubmit,
    bool? confirmed,
  }) = OpenRouteAction;

  const factory DeepLinkAction.checkStock({
    required String productName,
  }) = CheckStockAction;

  const factory DeepLinkAction.useStock({
    required String productName,
    double? amount,
    bool autoSubmit,
    bool confirmed,
  }) = UseStockAction;
}

class AddTransactionAction extends DeepLinkAction {
  final String type; // 'expense' | 'income' | 'savings'
  final double? amount;
  final double? quantity;
  final String? unit;
  final double? unitPrice;
  final String? description;
  final String? category;
  final String? paymentMethod;
  final String? store;
  final String? memo;
  final SavingsAllocation? savingsAllocation;
  final String currency;
  final bool autoSubmit;
  final bool confirmed;
  final bool openReceiptScannerOnStart;

  const AddTransactionAction({
    required this.type,
    this.amount,
    this.quantity,
    this.unit,
    this.unitPrice,
    this.description,
    this.category,
    this.paymentMethod,
    this.store,
    this.memo,
    this.savingsAllocation,
    this.currency = 'KRW',
    this.autoSubmit = false,
    this.confirmed = false,
    this.openReceiptScannerOnStart = false,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  bool get isSavings => type == 'savings';
  bool get isRefund => type == 'refund';

  @override
  String toString() =>
      'AddTransactionAction(type: $type, amount: $amount, '
      'quantity: $quantity, unit: $unit, unitPrice: $unitPrice, '
      'description: $description, category: $category, '
      'paymentMethod: $paymentMethod, store: $store, '
      'memo: $memo, savingsAllocation: $savingsAllocation, '
      'autoSubmit: $autoSubmit, confirmed: $confirmed, '
      'openReceiptScannerOnStart: $openReceiptScannerOnStart)';
}

SavingsAllocation? _parseSavingsAllocation(String? raw) {
  if (raw == null) return null;
  final normalized = raw.trim().toLowerCase();
  switch (normalized) {
    case 'assetincrease':
    case 'asset_increase':
    case 'asset':
    case 'assetincreaseoption':
      return SavingsAllocation.assetIncrease;
    case 'expense':
      return SavingsAllocation.expense;
  }
  return null;
}

class OpenDashboardAction extends DeepLinkAction {
  const OpenDashboardAction();

  @override
  String toString() => 'OpenDashboardAction()';
}

class OpenFeatureAction extends DeepLinkAction {
  final String featureId;

  const OpenFeatureAction(this.featureId);

  /// Map feature IDs to route names.
  String? get routeName {
    switch (featureId) {
      case 'transaction_add':
        return '/transaction/add';
      case 'income_add':
        return '/transaction/add-income';
      case 'dashboard':
        return '/';
      case 'food_expiry':
        return '/food/expiry';
      case 'shopping_cart':
        return '/shopping/cart';
      case 'assets':
        return '/asset/dashboard';
      case 'recipe':
        return '/food/cooking-start';
      case 'consumables':
        return '/household/consumables';
      case 'calendar':
        return '/calendar';
      case 'savings':
        return '/savings/plan/list';
      case 'emergency_fund':
        return '/emergency-fund';
      case 'stats':
        return '/stats/monthly-simple';
      case 'quick_stock':
        return '/household/quick-stock-use';
      default:
        return null;
    }
  }

  @override
  String toString() => 'OpenFeatureAction(featureId: $featureId)';
}

class OpenRouteAction extends DeepLinkAction {
  final String routeName;
  final String? accountName;
  final String? intent;
  final Map<String, String> params;
  final bool autoSubmit;
  final bool confirmed;

  const OpenRouteAction({
    required this.routeName,
    this.accountName,
    this.intent,
    Map<String, String>? params,
    bool? autoSubmit,
    bool? confirmed,
  })  : params = params ?? const <String, String>{},
        autoSubmit = autoSubmit ?? false,
        confirmed = confirmed ?? false;

  @override
  String toString() =>
      'OpenRouteAction(routeName: $routeName, accountName: $accountName, intent: $intent, '
      'autoSubmit: $autoSubmit, confirmed: $confirmed, params: $params)';
}

/// 재고 조회 액션
class CheckStockAction extends DeepLinkAction {
  final String productName;

  const CheckStockAction({required this.productName});

  @override
  String toString() => 'CheckStockAction(productName: $productName)';
}

/// 재고 차감 액션
class UseStockAction extends DeepLinkAction {
  final String productName;
  final double? amount;
  final bool autoSubmit;
  final bool confirmed;

  const UseStockAction({
    required this.productName,
    this.amount,
    this.autoSubmit = false,
    this.confirmed = false,
  });

  @override
  String toString() =>
      'UseStockAction(productName: $productName, amount: $amount, autoSubmit: $autoSubmit, confirmed: $confirmed)';
}
