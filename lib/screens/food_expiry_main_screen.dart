import 'package:flutter/material.dart';
import '../models/food_expiry_item.dart';
import '../services/food_expiry_service.dart';
import '../services/recipe_service.dart';
import '../services/user_pref_service.dart';
import '../services/savings_statistics_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/interaction_blockers.dart';
import 'savings_statistics_screen.dart';
import 'cooking_usage_history_screen.dart';
import '../navigation/app_routes_args.dart';
import 'household_items_to_cart_screen.dart';
import 'global_food_to_cart_screen.dart';
import 'household_recommended_screen.dart';
import '../widgets/food_expiry_upsert_dialog.dart';
import 'food_expiry_items_screen.dart';
import 'food_expiry_notifications_screen.dart';

/// 식품 유통기한 관리 전용 메인 네비게이션 화면
class FoodExpiryMainScreen extends StatefulWidget {
  final List<String>? initialIngredients;
  final bool autoUsageMode;
  final bool openUpsertOnStart;
  final bool openCookableRecipePickerOnStart;
  final bool scrollToDailyRecipeRecommendationOnStart;
  final FoodExpiryUpsertPrefill? upsertPrefill;
  final bool upsertAutoSubmit;

  const FoodExpiryMainScreen({
    super.key,
    this.initialIngredients,
    this.autoUsageMode = false,
    this.openUpsertOnStart = false,
    this.openCookableRecipePickerOnStart = false,
    this.scrollToDailyRecipeRecommendationOnStart = false,
    this.upsertPrefill,
    this.upsertAutoSubmit = false,
  });

  @override
  State<FoodExpiryMainScreen> createState() => _FoodExpiryMainScreenState();
}

class _FoodExpiryMainScreenState extends State<FoodExpiryMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    FoodExpiryService.instance.load();
    RecipeService.instance.load();
    SavingsStatisticsService.instance.load();

    if (widget.openUpsertOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openUpsertDialog(
          context,
          prefill: widget.upsertPrefill,
          autoSubmit: widget.upsertAutoSubmit,
        );
      });
    }
  }

  late final List<Widget> _screens = <Widget>[
    FoodExpiryItemsScreen(
      onUpsert: _openUpsertDialog,
      initialIngredients: widget.initialIngredients,
      autoUsageMode: widget.autoUsageMode,
      openCookableRecipePickerOnStart: widget.openCookableRecipePickerOnStart,
      scrollToDailyRecipeRecommendationOnStart:
          widget.scrollToDailyRecipeRecommendationOnStart,
    ),
    FutureBuilder<String?>(
      future: UserPrefService.getLastAccountName(),
      builder: (context, snapshot) {
        final accountName = snapshot.data ?? 'default';
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('생활용품'),
              centerTitle: true,
              bottom: const TabBar(
                tabs: [
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite, size: 18),
                        SizedBox(height: 2),
                        Text('나의', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home, size: 18),
                        SizedBox(height: 2),
                        Text('한국', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.public, size: 18),
                        SizedBox(height: 2),
                        Text('글로벌', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                HouseholdRecommendedScreen(
                  accountName: accountName,
                ),
                HouseholdItemsToCartScreen(
                  accountName: accountName,
                ),
                GlobalFoodToCartScreen(
                  accountName: accountName,
                ),
              ],
            ),
          ),
        );
      },
    ),
    const FoodExpiryNotificationsScreen(),
    const CookingUsageHistoryScreen(),
    const SavingsStatisticsScreen(),
  ];

  /// 모드에 따라 다른 네비게이션 아이템 반환
  List<BottomNavigationBarItem> get _navItems {
    if (widget.autoUsageMode) {
      // 유통기한 관리 / 요리 모드
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.soup_kitchen), label: '요리 모드'),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_basket),
          label: '생활용품',
        ),
        BottomNavigationBarItem(
          icon: Icon(IconCatalog.warningAmber),
          label: '알림',
        ),
        BottomNavigationBarItem(
          icon: Icon(IconCatalog.history),
          label: '소비 기록',
        ),
        BottomNavigationBarItem(icon: Icon(IconCatalog.barChart), label: '통계'),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle, size: 32),
          label: '추가',
        ),
      ];
    } else {
      // 재고 확인 모드
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: '재고 목록'),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_basket),
          label: '생활용품',
        ),
        BottomNavigationBarItem(
          icon: Icon(IconCatalog.warningAmber),
          label: '알림',
        ),
        BottomNavigationBarItem(
          icon: Icon(IconCatalog.history),
          label: '소비 기록',
        ),
        BottomNavigationBarItem(icon: Icon(IconCatalog.barChart), label: '통계'),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle, size: 32),
          label: '추가',
        ),
      ];
    }
  }

  /// 절약 통계 화면으로 빠르게 이동할 수 있는 FAB
  Widget _buildSavingsStatsButton(BuildContext context) {
    final theme = Theme.of(context);
    return Transform.translate(
      offset: const Offset(0, 5),
      child: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.grey),
        ),
        heroTag: 'savings_stats',
        onPressed: () => setState(() => _currentIndex = 4),
        backgroundColor: theme.colorScheme.tertiaryContainer,
        foregroundColor: theme.colorScheme.onTertiaryContainer,
        tooltip: '절약 통계 보기',
        child: const Icon(IconCatalog.savings),
      ),
    );
  }

  Future<void> _openUpsertDialog(
    BuildContext context, {
    FoodExpiryItem? existing,
    FoodExpiryUpsertPrefill? prefill,
    bool autoSubmit = false,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => FoodExpiryUpsertDialog(
        existing: existing,
        prefill: prefill,
        autoSubmit: autoSubmit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: _buildSavingsStatsButton(context),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: InteractionBlockers.gateValue<int>((index) {
          final addIndex = _navItems.length - 1;
          if (index == addIndex) {
            _openUpsertDialog(context);
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        }),
        items: _navItems,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
