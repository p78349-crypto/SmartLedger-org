import 'dart:async';

import 'package:flutter/services.dart';
import '../models/transaction.dart';
import 'deep_link_diagnostics.dart';

/// Service for handling deep links from App Actions, Bixby, and other sources.
///
/// Supported URI schemes:
/// - `smartledger://transaction/add?type=expense&amount=5000&description=커피`
/// - `smartledger://transaction/add?type=income&amount=3000000`
/// - smartledger://transaction/add?type=expense&amount=5000&description=커피
///   &autoSubmit=true
///   (거래 저장: 확인 필요)
/// - smartledger://transaction/add?type=expense&amount=5000&description=커피
///   &autoSubmit=true&confirmed=true
///   (거래 저장: 확인 완료)
/// - `smartledger://transaction/add?type=expense&action=scan`
///   (영수증 스캔(훅): 화면 열고 스캔 시작 유도)
/// - `smartledger://dashboard`
/// - `smartledger://feature/food_expiry`
/// - `smartledger://feature/shopping_cart`
/// - `smartledger://shopping/cart/add?name=우유&location=냉장고`
///   (장바구니 상품 추가)
/// - `smartledger://feature/assets`
/// - `smartledger://feature/recipe`
/// - `smartledger://recipe/recommend` (냉장고 재료 기반 요리 추천)
/// - `smartledger://recipe/recommend?meal=lunch` (점심 요리 추천)
/// - `smartledger://recipe/recommend?meal=dinner&ingredients=닭고기,양파`
///   (저녁 요리 추천, 특정 재료 사용)
/// - `smartledger://receipt/analyze` (영수증 건강도 분석)
/// - `smartledger://receipt/analyze?ingredients=양배추,닭고기,우유`
/// 
/// 책스캔앱 OCR 연계:
/// - `smartledger://transaction/add?amount=45800&store=이마트&items=양배추,닭고기,우유&source=ocr`
///   (책스캔앱에서 OCR 처리 후 SmartLedger로 데이터 반환)
///   (특정 재료 건강도 분석)
/// - `smartledger://stock/check?product=팽이버섯` (재고 조회)
/// - `smartledger://stock/use?product=팽이버섯&amount=1&autoSubmit=true`
///   (재고 차감: 확인 필요)
/// - smartledger://stock/use?product=팽이버섯&amount=1&autoSubmit=true
///   &confirmed=true
///   (재고 차감: 확인 완료)
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
          await DeepLinkDiagnostics.record(
            uri: uri,
            parsed: action != null,
            actionSummary: action != null ? _summarizeAction(action) : null,
            failureReason: action == null ? 'UNSUPPORTED_OR_INVALID' : null,
            source: 'android:onDeepLink',
          );

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

        await DeepLinkDiagnostics.record(
          uri: initial,
          parsed: action != null,
          actionSummary: action != null ? _summarizeAction(action) : null,
          failureReason: action == null ? 'UNSUPPORTED_OR_INVALID' : null,
          source: 'android:initial',
        );

        if (action != null) {
          _linkController.add(action);
        }
      }
    } on PlatformException catch (_) {
      // Platform channel not available (e.g., on desktop)
    }
  }

  String _summarizeAction(DeepLinkAction action) {
    switch (action) {
      case AddTransactionAction():
        return 'transaction/add type=${action.type} autoSubmit=${action.autoSubmit} confirmed=${action.confirmed}';
      case OpenDashboardAction():
        return 'dashboard/open';
      case OpenFeatureAction():
        return 'feature/open id=${action.featureId}';
      case AddToCartAction():
        return 'shopping/cart/add name=${action.name}';
      case RecipeRecommendAction():
        return 'recipe/recommend meal=${action.mealType ?? ""}';
      case ReceiptAnalyzeAction():
        return 'receipt/analyze';
      case OpenRouteAction():
        return 'nav/open route=${action.routeName} intent=${action.intent ?? ""}';
      case CheckStockAction():
        return 'stock/check';
      case UseStockAction():
        return 'stock/use autoSubmit=${action.autoSubmit} confirmed=${action.confirmed}';
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
            savingsAllocation: _parseSavingsAllocation(
              params['savingsAllocation'],
            ),
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

      case 'shopping':
        if (pathSegments.length >= 2 && pathSegments[0] == 'cart') {
          if (pathSegments[1] == 'add') {
            // 장바구니 항목 추가
            final name = params['name'];
            if (name != null && name.isNotEmpty) {
              return DeepLinkAction.addToCart(
                name: name,
                location: params['location'],
                quantity: int.tryParse(params['quantity'] ?? ''),
                price: double.tryParse(params['price'] ?? ''),
              );
            }
          }
        }
        break;

      case 'recipe':
        if (pathSegments.isNotEmpty && pathSegments.first == 'recommend') {
          // 요리 추천
          final mealType = params['meal']; // breakfast, lunch, dinner
          final ingredientsStr = params['ingredients']; // comma-separated
          final ingredients = ingredientsStr?.split(',').map((e) => e.trim()).toList();
          final prioritizeExpiring = params['expiring'] == 'true'; // 유통기한 임박 우선
          
          return DeepLinkAction.recommendRecipe(
            mealType: mealType,
            ingredients: ingredients,
            prioritizeExpiring: prioritizeExpiring,
          );
        }
        break;

      case 'receipt':
        if (pathSegments.isNotEmpty && pathSegments.first == 'analyze') {
          // 영수증 건강도 분석
          final ingredientsStr = params['ingredients']; // comma-separated
          final ingredients = ingredientsStr?.split(',').map((e) => e.trim()).toList();
          
          return DeepLinkAction.analyzeReceipt(ingredients: ingredients);
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
            final parsedAmount = amountParam == null
                ? null
                : double.tryParse(amountParam);
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

          final extras = _sanitizeNavExtras(params);
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

  static const int _maxNavExtraCount = 40;
  static const int _maxNavKeyLength = 50;
  static const int _maxNavValueLength = 300;

  Map<String, String> _sanitizeNavExtras(Map<String, String> params) {
    final extras = Map<String, String>.of(params)
      ..remove('route')
      ..remove('account')
      ..remove('intent')
      ..remove('autoSubmit')
      ..remove('confirmed');

    if (extras.isEmpty) return const <String, String>{};

    final sanitized = <String, String>{};
    for (final entry in extras.entries) {
      if (sanitized.length >= _maxNavExtraCount) break;

      final rawKey = entry.key.trim();
      if (rawKey.isEmpty || rawKey.length > _maxNavKeyLength) continue;
      // Only allow simple keys to reduce weird/unicode injection.
      if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(rawKey)) continue;

      final rawValue = entry.value.trim();
      if (rawValue.isEmpty) continue;
      final value = rawValue.length <= _maxNavValueLength
          ? rawValue
          : rawValue.substring(0, _maxNavValueLength);

      sanitized[rawKey] = value;
    }

    return sanitized;
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

  const factory DeepLinkAction.openFeature(String featureId) =
      OpenFeatureAction;

  const factory DeepLinkAction.addToCart({
    required String name,
    String? location,
    int? quantity,
    double? price,
  }) = AddToCartAction;

  const factory DeepLinkAction.recommendRecipe({
    bool prioritizeExpiring,
    String? mealType,
    List<String>? ingredients,
  }) = RecipeRecommendAction;

  const factory DeepLinkAction.analyzeReceipt({
    List<String>? ingredients,
  }) = ReceiptAnalyzeAction;

  const factory DeepLinkAction.openRoute({
    required String routeName,
    String? accountName,
    String? intent,
    Map<String, String>? params,
    bool? autoSubmit,
    bool? confirmed,
  }) = OpenRouteAction;

  const factory DeepLinkAction.checkStock({required String productName}) =
      CheckStockAction;

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
  final String? items; // 책스캔앱 OCR: 쉼표로 구분된 항목 목록
  final String? source; // 데이터 출처: 'ocr', 'voice', null
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
    this.items,
    this.source,
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

  /// 파라미터 Map으로 변환 (분석 로깅용)
  Map<String, String> toParams() {
    final params = <String, String>{};
    if (amount != null) params['amount'] = amount.toString();
    if (quantity != null) params['quantity'] = quantity.toString();
    if (unit != null) params['unit'] = unit!;
    if (unitPrice != null) params['unitPrice'] = unitPrice.toString();
    if (description != null) params['description'] = description!;
    if (category != null) params['category'] = category!;
    if (paymentMethod != null) params['paymentMethod'] = paymentMethod!;
    if (store != null) params['store'] = store!;
    if (memo != null) params['memo'] = memo!;
    if (items != null) params['items'] = items!;
    if (source != null) params['source'] = source!;
    if (savingsAllocation != null) {
      params['savingsAllocation'] = savingsAllocation.toString();
    }
    params['currency'] = currency;
    params['autoSubmit'] = autoSubmit.toString();
    params['confirmed'] = confirmed.toString();
    return params;
  }

  @override
  String toString() =>
      'AddTransactionAction(type: $type, amount: $amount, '
      'quantity: $quantity, unit: $unit, unitPrice: $unitPrice, '
      'description: $description, category: $category, '
      'paymentMethod: $paymentMethod, store: $store, '
      'memo: $memo, items: $items, source: $source, '
      'savingsAllocation: $savingsAllocation, '
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

  Map<String, String> get params => {'feature': featureId};

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

class AddToCartAction extends DeepLinkAction {
  final String name;
  final String? location;
  final int? quantity;
  final double? price;

  const AddToCartAction({
    required this.name,
    this.location,
    this.quantity,
    this.price,
  });

  @override
  String toString() =>
      'AddToCartAction('
      'name: $name, '
      'location: $location, '
      'quantity: $quantity, '
      'price: $price)';
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
  }) : params = params ?? const <String, String>{},
       autoSubmit = autoSubmit ?? false,
       confirmed = confirmed ?? false;

  @override
  String toString() =>
      'OpenRouteAction('
      'routeName: $routeName, '
      'accountName: $accountName, '
      'intent: $intent, '
      'autoSubmit: $autoSubmit, '
      'confirmed: $confirmed, '
      'params: $params)';
}

/// 재고 조회 액션
class CheckStockAction extends DeepLinkAction {
  final String productName;

  const CheckStockAction({required this.productName});

  Map<String, String> get params => {'product': productName};

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

  Map<String, String> get params {
    final map = <String, String>{'product': productName};
    if (amount != null) map['amount'] = amount.toString();
    if (autoSubmit) map['autoSubmit'] = 'true';
    if (confirmed) map['confirmed'] = 'true';
    return map;
  }

  @override
  String toString() =>
      'UseStockAction('
      'productName: $productName, '
      'amount: $amount, '
      'autoSubmit: $autoSubmit, '
      'confirmed: $confirmed)';
}

/// 요리 추천 액션
class RecipeRecommendAction extends DeepLinkAction {
  /// 끼니 유형: breakfast, lunch, dinner
  final String? mealType;
  final List<String>? ingredients;
  /// 유통기한 임박 재료 우선 사용
  final bool prioritizeExpiring;

  const RecipeRecommendAction({
    this.mealType,
    this.ingredients,
    this.prioritizeExpiring = false,
  });

  @override
  String toString() =>
      'RecipeRecommendAction('
      'mealType: $mealType, '
      'ingredients: $ingredients, '
      'prioritizeExpiring: $prioritizeExpiring)';
}

/// 영수증 건강도 분석 액션
class ReceiptAnalyzeAction extends DeepLinkAction {
  final List<String>? ingredients;

  const ReceiptAnalyzeAction({this.ingredients});

  @override
  String toString() => 'ReceiptAnalyzeAction(ingredients: $ingredients)';
}
