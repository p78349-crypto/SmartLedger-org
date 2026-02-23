import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../utils/korean_search_utils.dart';
import '../navigation/app_routes.dart';
import 'recipe_management_screen_lists.dart';

/// 레시피 관리 메인 화면
/// 1. 내 레시피 목록 (사용자 작성)
/// 2. 추천 레시피 목록
/// 3. 레시피 편집/삭제
/// 4. 재료 → 장바구니 전송
class RecipeManagementScreen extends StatefulWidget {
  const RecipeManagementScreen({
    super.key,
    required this.accountName,
    this.initialTabIndex = 0,
  });

  final String accountName;

  /// 0: 내 레시피, 1: 추천 레시피
  final int initialTabIndex;

  @override
  State<RecipeManagementScreen> createState() => _RecipeManagementScreenState();
}

class _RecipeManagementScreenState extends State<RecipeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Recipe> _myRecipes = [];
  List<Recipe> _recommendedRecipes = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadRecipes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() => _loading = true);

    await RecipeService.instance.load();
    final allRecipes = RecipeService.instance.recipes.value;

    // 사용자 레시피: id가 'user_'로 시작
    // 추천 레시피: 나머지
    _myRecipes = allRecipes.where((r) => r.id.startsWith('user_')).toList();
    _recommendedRecipes = allRecipes
        .where((r) => !r.id.startsWith('user_'))
        .toList();

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<Recipe> get _filteredMyRecipes {
    if (_searchQuery.isEmpty) return _myRecipes;
    final q = _searchQuery;
    return _myRecipes.where((r) {
      final matches = r.localizedNames.values
          .any((n) => MultilingualSearchUtils.matches(n, q));
      return matches;
    }).toList();
  }

  List<Recipe> get _filteredRecommendedRecipes {
    if (_searchQuery.isEmpty) return _recommendedRecipes;
    final q = _searchQuery;
    return _recommendedRecipes.where((r) {
      final matches = r.localizedNames.values
          .any((n) => MultilingualSearchUtils.matches(n, q));
      return matches;
    }).toList();
  }

  Future<void> _addNewRecipe() async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.recipeEdit,
      arguments: RecipeEditArgs(accountName: widget.accountName),
    );
    if (result == true) {
      await _loadRecipes();
    }
  }

  Future<void> _editRecipe(Recipe recipe) async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.recipeEdit,
      arguments: RecipeEditArgs(
        accountName: widget.accountName,
        recipe: recipe,
      ),
    );
    if (result == true) {
      await _loadRecipes();
    }
  }

  Future<void> _copyToMyRecipes(Recipe recipe) async {
    // 추천 레시피를 내 레시피로 복사
    final lang = Localizations.localeOf(context).languageCode;
    final displayName = recipe.nameForLocale(lang);
    final newLocalized = Map<String, String>.from(recipe.localizedNames);
    newLocalized[lang] = '$displayName (내 버전)';
    final newRecipe = Recipe(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      localizedNames: newLocalized,
      cuisine: recipe.cuisine,
      ingredients: recipe.ingredients,
      healthScore: recipe.healthScore,
    );

    // 편집 화면으로 이동
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.recipeEdit,
      arguments: RecipeEditArgs(
        accountName: widget.accountName,
        recipe: newRecipe,
        isNewFromRecommended: true,
      ),
    );
    if (result == true) {
      await _loadRecipes();
    }
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레시피 삭제'),
        content: Text(
          "'${recipe.nameForLocale(
            Localizations.localeOf(context).languageCode,
          )}'을(를) 삭제하시겠습니까?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RecipeService.instance.deleteRecipe(recipe.id);
      await _loadRecipes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "'${recipe.nameForLocale(
                Localizations.localeOf(context).languageCode,
              )}' 삭제됨",
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendToCart(Recipe recipe) async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.recipeToCart,
      arguments: RecipeToCartArgs(
        accountName: widget.accountName,
        recipe: recipe,
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "'${recipe.nameForLocale(
              Localizations.localeOf(context).languageCode,
            )}' 재료가 장바구니에 추가되었습니다",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('요리 레시피'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '내 레시피 (${_myRecipes.length})'),
            Tab(text: '추천 레시피 (${_recommendedRecipes.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: '장바구니 열기',
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.shoppingCart,
                arguments: ShoppingCartArgs(accountName: widget.accountName),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: '레시피 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // 탭 컨텐츠
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      buildMyRecipesList(
                        recipes: _filteredMyRecipes,
                        searchQuery: _searchQuery,
                        onRefresh: _loadRecipes,
                        onAddNew: _addNewRecipe,
                        onEdit: _editRecipe,
                        onDelete: _deleteRecipe,
                        onCopyToMy: _copyToMyRecipes,
                        onSendToCart: _sendToCart,
                      ),
                      buildRecommendedRecipesList(
                        recipes: _filteredRecommendedRecipes,
                        searchQuery: _searchQuery,
                        onRefresh: _loadRecipes,
                        onEdit: _editRecipe,
                        onDelete: _deleteRecipe,
                        onCopyToMy: _copyToMyRecipes,
                        onSendToCart: _sendToCart,
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewRecipe,
        icon: const Icon(Icons.add),
        label: const Text('새 레시피'),
      ),
    );
  }

}
