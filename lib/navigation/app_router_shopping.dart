part of 'app_router.dart';

class _ShoppingRoutes {
  static Route<dynamic>? resolve(
    RouteSettings settings,
    String name,
    Object? args,
  ) {
    switch (name) {
      case AppRoutes.foodExpiry:
        final a = args is FoodExpiryArgs ? args : const FoodExpiryArgs();
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => FoodExpiryMainScreen(
            initialIngredients: a.initialIngredients,
            autoUsageMode: a.autoUsageMode,
            openUpsertOnStart: a.openUpsertOnStart,
            openCookableRecipePickerOnStart:
                a.openCookableRecipePickerOnStart,
            scrollToDailyRecipeRecommendationOnStart:
                a.scrollToDailyRecipeRecommendationOnStart,
            upsertPrefill: a.upsertPrefill,
            upsertAutoSubmit: a.upsertAutoSubmit,
          ),
        );

      case AppRoutes.foodCookingStart:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const FoodCookingStartScreen(),
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
            openPrepOnStart: a.openPrepOnStart,
            initialItems: a.initialItems,
          ),
        );

      case AppRoutes.shoppingPrep:
        final a = args as ShoppingCartArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ShoppingCartScreen(
            accountName: a.accountName,
            openPrepOnStart: true,
            initialItems: a.initialItems,
          ),
        );

      case AppRoutes.shoppingGuide:
        final a = args as ShoppingGuideArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ShoppingGuideScreen(
            accountName: a.accountName,
            items: a.items,
          ),
        );

      case AppRoutes.householdConsumables:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HouseholdConsumablesScreen(
            accountName: a.accountName,
          ),
        );

      case AppRoutes.consumableInventory:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ConsumableInventoryScreen(
            accountName: a.accountName,
          ),
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

      case AppRoutes.shoppingPointsInput:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ShoppingPointsInputScreen(
            accountName: a.accountName,
          ),
        );

      case AppRoutes.shoppingCheapestMonth:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ShoppingCheapestMonthScreen(
            accountName: a.accountName,
          ),
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

      default:
        return null;
    }
  }
}

/// 식재료 검색 입력 화면 (요리 필요 재료 검색)
class _IngredientSearchInputScreen extends StatefulWidget {
  const _IngredientSearchInputScreen();

  @override
  State<_IngredientSearchInputScreen> createState() =>
      _IngredientSearchInputScreenState();
}

class _IngredientSearchInputScreenState
    extends State<_IngredientSearchInputScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색어를 입력하세요.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IngredientSearchListScreen(searchQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('요리 필요 재료 검색'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '요리 이름을 입력하세요',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '예: 닭고기, 돼지고기, 생선 등',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '요리 이름 입력',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: _search,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _search(_controller.text),
              icon: const Icon(Icons.search),
              label: const Text('검색'),
            ),
          ],
        ),
      ),
    );
  }
}
