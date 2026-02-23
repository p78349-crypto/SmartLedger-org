// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

/// Recipe learning recording and stats dialog.
extension FoodExpiryRecipeLearningExt on _FoodExpiryItemsScreenState {
  Future<void> _recordRecipeLearning(
    Recipe recipe,
    int healthScore,
    bool hasExpiringIngredients,
  ) async {
    // 현재 시간대 판단
    final hour = DateTime.now().hour;
    String? mealTime;
    if (hour >= 6 && hour < 10) {
      mealTime = 'breakfast';
    } else if (hour >= 11 && hour < 15) {
      mealTime = 'lunch';
    } else if (hour >= 17 && hour < 22) {
      mealTime = 'dinner';
    }

    // 학습 서비스에 기록
    await RecipeLearningService.instance.recordRecipeUsage(
      recipeName: recipe.name,
      ingredients: recipe.ingredients.map((i) => i.name).toList(),
      healthScore: healthScore,
      mealTime: mealTime,
    );

    debugPrint(
      'Recipe learning recorded: ${recipe.name} (health: $healthScore)',
    );
  }

  Future<void> _showLearningStats() async {
    final stats = await RecipeLearningService.instance.getStats();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_graph, size: 24),
            SizedBox(width: 8),
            Text('AI 학습 통계'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('총 요리 횟수', '${stats.totalRecipesCooked}회'),
              const SizedBox(height: 16),

              const Text(
                '자주 만드는 요리',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...stats.topRecipes.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text('• $r'),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                '자주 쓰는 재료',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...stats.topIngredients.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text('• $i'),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats.healthPreferenceLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '건강 점수 평균: ${(stats.healthPreferenceScore * 5).toStringAsFixed(1)}/5',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                '💡 사용할수록 더 똑똑한 추천을 받을 수 있어요!',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
