import 'package:flutter/material.dart';
import 'food_expiry_main_screen.dart';

/// Dedicated screen for cooking start mode.
/// 
/// This wraps [FoodExpiryMainScreen] in cooking/usage mode,
/// allowing users to select a recipe and track ingredient usage.
class FoodCookingStartScreen extends StatelessWidget {
  const FoodCookingStartScreen({
    super.key,
    this.initialIngredients,
  });

  /// Optional. Pre-fill the screen with specific ingredients.
  final List<String>? initialIngredients;

  @override
  Widget build(BuildContext context) {
    return FoodExpiryMainScreen(
      initialIngredients: initialIngredients,
      autoUsageMode: true, // Automatically start in cooking/usage mode
    );
  }
}
