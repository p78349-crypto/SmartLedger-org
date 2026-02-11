part of 'deep_link_service.dart';

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

  const factory DeepLinkAction.analyzeReceipt({List<String>? ingredients}) =
      ReceiptAnalyzeAction;

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
    params['type'] = type;
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
      params['savingsAllocation'] = switch (savingsAllocation!) {
        SavingsAllocation.assetIncrease => 'asset_increase',
        SavingsAllocation.expense => 'expense',
      };
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
