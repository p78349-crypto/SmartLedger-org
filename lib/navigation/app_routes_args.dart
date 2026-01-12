import '../models/shopping_cart_item.dart';

class AccountArgs {
  const AccountArgs({required this.accountName, this.initialIncomeAmount});
  final String accountName;
  final double? initialIncomeAmount;
}

class FoodExpiryArgs {
  const FoodExpiryArgs({
    this.initialIngredients,
    this.autoUsageMode = false,
    this.openUpsertOnStart = false,
    this.openCookableRecipePickerOnStart = false,
    this.scrollToDailyRecipeRecommendationOnStart = false,
    this.upsertPrefill,
    this.upsertAutoSubmit = false,
  });
  final List<String>? initialIngredients;
  final bool autoUsageMode;
  final bool openUpsertOnStart;
  final bool openCookableRecipePickerOnStart;

  /// If true, the screen will scroll to the "오늘의 요리 추천" section
  /// right after the first frame.
  ///
  /// Note: This is navigation-only and must not cause state-changing behavior.
  final bool scrollToDailyRecipeRecommendationOnStart;

  /// Optional prefill values when opening the upsert dialog via assistant.
  final FoodExpiryUpsertPrefill? upsertPrefill;

  /// If true, the dialog will attempt to save automatically once opened.
  ///
  /// (Safety gate should be handled by the deep-link handler using confirmed
  /// flags.)
  final bool upsertAutoSubmit;
}

class FoodExpiryUpsertPrefill {
  const FoodExpiryUpsertPrefill({
    this.name,
    this.quantity,
    this.unit,
    this.location,
    this.category,
    this.supplier,
    this.memo,
    this.purchaseDate,
    this.healthTags,
    this.expiryDate,
    this.price,
  });

  final String? name;
  final double? quantity;
  final String? unit;
  final String? location;
  final String? category;
  final String? supplier;
  final String? memo;
  final DateTime? purchaseDate;
  final List<String>? healthTags;
  final DateTime? expiryDate;
  final double? price;
}

class AccountMainArgs {
  const AccountMainArgs({required this.accountName, this.initialIndex = 0});
  final String accountName;
  final int initialIndex;
}

class IconManagementArgs {
  const IconManagementArgs({required this.accountName});
  final String accountName;
}

class AccountSelectArgs {
  const AccountSelectArgs({required this.accounts});
  final List<String> accounts;
}

class TransactionAddArgs {
  const TransactionAddArgs({
    required this.accountName,
    this.initialTransaction,
    this.learnCategoryHintFromDescription = false,
    this.confirmBeforeSave = false,
    this.treatAsNew = false,
    this.closeAfterSave = false,
    this.autoSubmit = false,
    this.openReceiptScannerOnStart = false,
  });
  final String accountName;
  final Object? initialTransaction;
  final bool learnCategoryHintFromDescription;
  final bool confirmBeforeSave;
  final bool treatAsNew;
  final bool closeAfterSave;
  final bool autoSubmit;

  /// If true, the transaction input screen should prompt/start the receipt scan
  /// flow right after the first frame.
  ///
  /// Note: This flag itself should never cause state-changing behavior.
  final bool openReceiptScannerOnStart;
}

class TransactionDetailArgs {
  const TransactionDetailArgs({
    required this.accountName,
    required this.initialType,
  });
  final String accountName;
  final Object initialType;
}

class DailyTransactionsArgs {
  const DailyTransactionsArgs({
    required this.accountName,
    required this.initialDay,
    this.savedCount,
    this.showShoppingPointsInputCta = false,
  });
  final String accountName;
  final DateTime initialDay;

  /// Optional. When provided, Daily screen shows a one-time snackbar.
  final int? savedCount;

  /// When true, Daily screen shows a non-modal CTA to open Points input.
  final bool showShoppingPointsInputCta;
}

class QuickSimpleExpenseInputArgs {
  const QuickSimpleExpenseInputArgs({
    required this.accountName,
    required this.initialDate,
    this.initialLine,
    this.autoSubmit = false,
  });

  final String accountName;
  final DateTime initialDate;

  /// Optional initial raw line to place in the input field.
  /// Example: "커피 3000원 신용카드 스타벅스"
  final String? initialLine;

  /// If true, the screen will attempt to save once opened.
  /// Safety gate is enforced by DeepLinkHandler using confirmed flags.
  final bool autoSubmit;
}

class AssetSimpleInputArgs {
  const AssetSimpleInputArgs({
    required this.accountName,
    this.initialCategory,
    this.initialName,
    this.initialAmount,
    this.initialLocation,
    this.initialMemo,
    this.autoSubmit = false,
  });

  final String accountName;

  /// One of: '현금', '예금/적금', '소액 투자', '기타 실물 자산'
  final String? initialCategory;
  final String? initialName;
  final double? initialAmount;
  final String? initialLocation;
  final String? initialMemo;

  /// If true, the screen will attempt to save once opened.
  /// Safety gate is enforced by DeepLinkHandler using confirmed flags.
  final bool autoSubmit;
}

class ShoppingCartArgs {
  const ShoppingCartArgs({
    required this.accountName,
    this.openPrepOnStart = false,
    this.initialItems,
  });
  final String accountName;
  final bool openPrepOnStart;
  final List<ShoppingCartItem>? initialItems;
}

class ShoppingGuideArgs {
  const ShoppingGuideArgs({required this.accountName, required this.items});
  final String accountName;
  final List<ShoppingCartItem> items;
}

class QuickStockUseArgs {
  const QuickStockUseArgs({required this.accountName, this.initialProductName});
  final String accountName;
  final String? initialProductName;
}

class TopLevelStatsDetailArgs {
  const TopLevelStatsDetailArgs({required this.dashboard});
  final dynamic dashboard;
}
