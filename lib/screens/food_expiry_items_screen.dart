import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/consumable_inventory_item.dart';
import '../models/food_expiry_item.dart';
import '../models/recipe.dart';
import '../models/shopping_cart_item.dart';
import '../navigation/app_routes.dart';
import '../services/consumable_inventory_service.dart';
import '../services/food_expiry_service.dart';
import '../services/health_guardrail_service.dart';
import '../services/recipe_learning_service.dart';
import '../services/replacement_cycle_notification_service.dart';
import '../services/savings_statistics_service.dart';
import '../services/user_pref_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/shopping_prep_utils.dart';
import '../widgets/cost_analysis_widget.dart';
import '../widgets/daily_recipe_recommendation_widget.dart';
import '../widgets/ingredients_recommendation_widget.dart';
import '../widgets/recipe_picker_dialog.dart';
import '../widgets/user_preferences_widget.dart';

part 'food_expiry_items_screen_usage_input.dart';
part 'food_expiry_items_screen_helpers.dart';
part 'food_expiry_items_screen_item_detail.dart';
part 'food_expiry_items_screen_quantity_edit.dart';
part 'food_expiry_items_screen_shopping_cart.dart';
part 'food_expiry_items_screen_recipe_picker.dart';
part 'food_expiry_items_screen_recipe_dialog.dart';
part 'food_expiry_items_screen_recipe_learning.dart';
part 'food_expiry_items_screen_usage_apply.dart';
part 'food_expiry_items_screen_build_panels.dart';
part 'food_expiry_items_screen_build_item_tile.dart';
part 'food_expiry_items_screen_build_body.dart';

class FoodExpiryItemsScreen extends StatefulWidget {
  final Future<void> Function(BuildContext, {FoodExpiryItem? existing})?
      onUpsert;
  final List<String>? initialIngredients;
  final bool autoUsageMode;
  final bool openCookableRecipePickerOnStart;
  final bool scrollToDailyRecipeRecommendationOnStart;

  const FoodExpiryItemsScreen({
    super.key,
    this.onUpsert,
    this.initialIngredients,
    this.autoUsageMode = false,
    this.openCookableRecipePickerOnStart = false,
    this.scrollToDailyRecipeRecommendationOnStart = false,
  });

  @override
  State<FoodExpiryItemsScreen> createState() => _FoodExpiryItemsScreenState();
}

class _FoodExpiryItemsScreenState extends State<FoodExpiryItemsScreen> {
  bool _isUsageMode = false;
  final Map<String, double> _usageMap = {};
  final Set<String> _activeUsageItems = {};

  final GlobalKey _dailyRecipeSectionKey = GlobalKey();

  String? _activeRecipeName;

  // 로케이션 필터
  String? _locationFilter;
  static const List<String> _locationOptions = [
    '전체',
    '냉장',
    '냉동',
    '실온',
    '김치냉장고',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.autoUsageMode) {
      _isUsageMode = true;
    }

    if (widget.scrollToDailyRecipeRecommendationOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _dailyRecipeSectionKey.currentContext;
        if (!mounted || ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.08,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }

    if (widget.openCookableRecipePickerOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showRecipePicker(onlyCookable: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) => buildBody(context);
}

