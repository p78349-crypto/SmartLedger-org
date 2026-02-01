import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../navigation/app_routes.dart';

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
    return _myRecipes
        .where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<Recipe> get _filteredRecommendedRecipes {
    if (_searchQuery.isEmpty) return _recommendedRecipes;
    return _recommendedRecipes
        .where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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
    final newRecipe = Recipe(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: '${recipe.name} (내 버전)',
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
        content: Text("'${recipe.name}'을(를) 삭제하시겠습니까?"),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("'${recipe.name}' 삭제됨")));
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
        SnackBar(content: Text("'${recipe.name}' 재료가 장바구니에 추가되었습니다")),
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
                      _buildMyRecipesList(),
                      _buildRecommendedRecipesList(),
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

  Widget _buildMyRecipesList() {
    final recipes = _filteredMyRecipes;

    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '아직 작성한 레시피가 없습니다' : '검색 결과가 없습니다',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isEmpty)
              FilledButton.icon(
                onPressed: _addNewRecipe,
                icon: const Icon(Icons.add),
                label: const Text('첫 레시피 작성하기'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecipes,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: recipes.length,
        itemBuilder: (context, index) =>
            _buildRecipeCard(recipes[index], isMyRecipe: true),
      ),
    );
  }

  Widget _buildRecommendedRecipesList() {
    final recipes = _filteredRecommendedRecipes;

    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '추천 레시피가 없습니다' : '검색 결과가 없습니다',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecipes,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: recipes.length,
        itemBuilder: (context, index) =>
            _buildRecipeCard(recipes[index], isMyRecipe: false),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, {required bool isMyRecipe}) {
    final theme = Theme.of(context);
    final ingredientCount = recipe.ingredients.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editRecipe(recipe),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTag(recipe.cuisine),
                            const SizedBox(width: 8),
                            _buildTag('재료 $ingredientCount개'),
                            const SizedBox(width: 8),
                            _buildHealthScore(recipe.healthScore),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isMyRecipe)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteRecipe(recipe),
                      tooltip: '삭제',
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // 재료 미리보기
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: recipe.ingredients
                    .take(5)
                    .map(
                      (ing) => Chip(
                        label: Text(
                          ing.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
              if (recipe.ingredients.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${recipe.ingredients.length - 5}개 더',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),

              const Divider(height: 24),

              // 액션 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isMyRecipe)
                    OutlinedButton.icon(
                      onPressed: () => _copyToMyRecipes(recipe),
                      icon: const Icon(Icons.content_copy, size: 18),
                      label: const Text('내 레시피로 복사'),
                    ),
                  if (!isMyRecipe) const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _sendToCart(recipe),
                    icon: const Icon(Icons.shopping_cart, size: 18),
                    label: const Text('장바구니에 추가'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildHealthScore(int score) {
    final color = score >= 4
        ? Colors.green
        : score >= 3
        ? Colors.orange
        : Colors.red;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite, size: 14, color: color),
        const SizedBox(width: 2),
        Text('$score', style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
