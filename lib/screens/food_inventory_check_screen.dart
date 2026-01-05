import 'package:flutter/material.dart';
import 'package:smart_ledger/screens/food_expiry_main_screen.dart';

/// Dedicated screen for checking food inventory.
/// 
/// This wraps [FoodExpiryMainScreen] in view/check mode,
/// allowing users to view and manage food inventory and expiry dates.
class FoodInventoryCheckScreen extends StatelessWidget {
  const FoodInventoryCheckScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const FoodExpiryMainScreen();
  }
}
