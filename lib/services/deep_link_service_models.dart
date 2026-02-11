part of 'deep_link_service.dart';

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
