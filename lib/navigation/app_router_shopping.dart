part of 'app_router.dart';

class _ShoppingRoutes {
  static Route<dynamic>? resolve(
    RouteSettings settings,
    String name,
    Object? args,
  ) {
    switch (name) {
      case AppRoutes.foodExpiry:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const _ConsumableInventoryRedirectScreen(),
        );

      case AppRoutes.foodCookingStart:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const _ConsumableInventoryRedirectScreen(),
        );

      case AppRoutes.healthAnalyzer:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const QuickHealthAnalyzerScreen(),
        );

      case AppRoutes.calendar:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CalendarScreen(accountName: a.accountName),
        );

      case AppRoutes.shoppingCart:
        final a = args as ShoppingCartArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ShoppingCartScreen(
            accountName: a.accountName,
            initialItems: a.initialItems,
          ),
        );

      case AppRoutes.shoppingGuide:
        final a = args as ShoppingGuideArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              ShoppingGuideScreen(accountName: a.accountName, items: a.items),
        );

      case AppRoutes.householdConsumables:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              HouseholdConsumablesScreen(accountName: a.accountName),
        );

      case AppRoutes.householdQuickPick:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              HouseholdQuickPickScreen(accountName: a.accountName),
        );

      case AppRoutes.householdItems:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              HouseholdItemsScreen(accountName: a.accountName),
        );

      case AppRoutes.consumableInventory:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ConsumableInventoryScreen(accountName: a.accountName),
        );

      case AppRoutes.quickStockUse:
        final a = args as QuickStockUseArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => QuickStockUseScreen(
            accountName: a.accountName,
            initialProductName: a.initialProductName,
          ),
        );

      case AppRoutes.wmsIo:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => WmsIoScreen(accountName: a.accountName),
        );

      case AppRoutes.wmsGuide:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const WmsGuideScreen(),
        );

      case AppRoutes.shoppingPointsInput:
        final a = args as ShoppingPointsInputArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ShoppingPointsInputScreen(
            accountName: a.accountName,
            lastPaymentMethod: a.lastPaymentMethod,
            lastMemo: a.lastMemo,
            totalAmount: a.totalAmount,
            chargedAmount: a.chargedAmount,
            itemCount: a.itemCount,
          ),
        );

      case AppRoutes.shoppingCheapestMonth:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              ShoppingCheapestMonthScreen(accountName: a.accountName),
        );

      case AppRoutes.nutritionReport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const NutritionReportScreen(rawText: ''),
        );

      case AppRoutes.ingredientSearch:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const _IngredientSearchInputScreen(),
        );

      // 레시피 관리 라우트
      case AppRoutes.recipeManagement:
        final a = args as RecipeManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RecipeManagementScreen(
            accountName: a.accountName,
            initialTabIndex: a.initialTabIndex,
          ),
        );

      case AppRoutes.recipeEdit:
        final a = args as RecipeEditArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RecipeEditScreen(
            accountName: a.accountName,
            recipe: a.recipe,
            isNewFromRecommended: a.isNewFromRecommended,
          ),
        );

      case AppRoutes.recipeToCart:
        final a = args as RecipeToCartArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              RecipeToCartScreen(accountName: a.accountName, recipe: a.recipe),
        );

      default:
        return null;
    }
  }
}
