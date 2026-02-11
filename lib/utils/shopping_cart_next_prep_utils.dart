import 'package:flutter/material.dart';

import '../models/category_hint.dart';
import '../models/shopping_cart_history_entry.dart';
import '../models/shopping_cart_item.dart';
import '../models/shopping_template_item.dart';
import '../models/transaction.dart';
import '../services/store_alias_service.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../services/activity_household_estimator_service.dart';
import 'icon_catalog.dart';
import 'shopping_cart_next_prep_dialog_utils.dart';
import 'shopping_prep_utils.dart';
import 'store_memo_utils.dart';

import '../screens/nutrition_report_screen.dart';

part 'shopping_cart_next_prep_utils_store.dart';
part 'shopping_cart_next_prep_utils_recent.dart';
part 'shopping_cart_next_prep_utils_store_recommend.dart';
part 'shopping_cart_next_prep_utils_store_sheet.dart';
part 'shopping_cart_next_prep_utils_freq_recommend.dart';

double? _resolveQuantityFactorFromTrend(
  ActivityHouseholdTrendComparison? trend,
) {
  if (trend == null) return null;
  final r = trend.ratio;
  if (!r.isFinite || r <= 0) return null;
  if (r >= 0.9 && r <= 1.1) return null;
  return r.clamp(0.7, 1.5);
}

int _applyFactorToIntQuantity(int baseQty, double? factor) {
  final b = baseQty <= 0 ? 1 : baseQty;
  if (factor == null) return b;
  final next = (b * factor).ceil();
  return next < 1 ? 1 : next;
}

String _appendFactorMemo(String? existing, double? factor) {
  if (factor == null) return (existing ?? '').trim();
  final line = '활동량 보정 x${factor.toStringAsFixed(2)}';
  final base = (existing ?? '').trim();
  if (base.isEmpty) return line;
  if (base.contains(line)) return base;
  return '$base\n$line';
}

class ShoppingCartNextPrepUtils {
  ShoppingCartNextPrepUtils._();

  static Future<void> run({
    required BuildContext context,
    required String accountName,
    required List<ShoppingCartItem> Function() getItems,
    required Map<String, CategoryHint> Function() getCategoryHints,
    required Future<void> Function(List<ShoppingCartItem> next) saveItems,
    required Future<void> Function() reload,
    bool showChooser = true,
    ShoppingCartNextPrepAction defaultAction =
        ShoppingCartNextPrepAction.recentPurchases20,
  }) async {
    final ShoppingCartNextPrepAction? choice;
    if (showChooser) {
      choice = await ShoppingCartNextPrepDialogUtils.show(
        context,
        defaultAction: defaultAction,
      );
    } else {
      choice = defaultAction;
    }
    if (!context.mounted || choice == null) return;

    switch (choice) {
      case ShoppingCartNextPrepAction.recentPurchases20:
        await _addFromRecentPurchases(
          context: context,
          accountName: accountName,
          existingItems: getItems(),
          saveItems: saveItems,
        );
        return;
      case ShoppingCartNextPrepAction.recommendFrequent20:
        await _recommendFromPurchaseHistoryFrequency(
          context: context,
          accountName: accountName,
          existingItems: getItems(),
          saveItems: saveItems,
          categoryHints: getCategoryHints(),
        );
        return;
      case ShoppingCartNextPrepAction.recommendFrequent20ByStoreMemo:
        await _recommendFromTransactionsFrequencyByStoreMemo(
          context: context,
          accountName: accountName,
          existingItems: getItems(),
          saveItems: saveItems,
          categoryHints: getCategoryHints(),
        );
        return;
      case ShoppingCartNextPrepAction.recipeSearch:
        await _openRecipeSearch(
          context: context,
          accountName: accountName,
          existingItems: getItems(),
          saveItems: saveItems,
        );
        return;
    }
  }
}
