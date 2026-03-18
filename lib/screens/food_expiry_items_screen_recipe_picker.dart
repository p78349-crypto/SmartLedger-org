// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

/// Recipe picker, health scoring helpers, and post-confirmation handler.
extension FoodExpiryRecipePickerExt on _FoodExpiryItemsScreenState {
  Future<void> _showRecipePicker({bool onlyCookable = false}) async {
    final items = ConsumableInventoryService.instance.items.value;

    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (ctx) => RecipePickerDialog(onlyCookable: onlyCookable),
    );

    if (selectedRecipe != null) {
      final List<String> missingIngredients = [];
      final List<Map<String, dynamic>> availableIngredients = [];
      final List<Map<String, dynamic>> expiringIngredients = [];
      final now = DateTime.now();

      setState(() {
        _isUsageMode = true;
        _usageMap.clear();
        _activeRecipeName = selectedRecipe.name;

        for (var ingredient in selectedRecipe.ingredients) {
          // FIFO: 유통기한 빠른 순서로 정렬된 항목 중 매칭되는 것 선택
          final matchedItems =
              items
                  .where(
                    (i) =>
                        i.name.contains(ingredient.name) ||
                        ingredient.name.contains(i.name),
                  )
                  .toList()
                ..sort((a, b) {
                  final aDate =
                      a.expiryDate ??
                      DateTime.now().add(const Duration(days: 3650));
                  final bDate =
                      b.expiryDate ??
                      DateTime.now().add(const Duration(days: 3650));
                  return aDate.compareTo(bDate);
                });

          if (matchedItems.isNotEmpty) {
            final item = matchedItems.first; // FIFO: 유통기한 가장 빠른 것
            _usageMap[item.id] = ingredient.quantity;

            final daysLeft = _daysLeftForInventory(item, now);
            final info = {
              'name': item.name,
              'quantity': _formatInventoryQuantity(item),
              'daysLeft': daysLeft,
              'isExpiring': daysLeft <= 3,
            };

            if (daysLeft <= 3) {
              expiringIngredients.add(info);
            } else {
              availableIngredients.add(info);
            }
          } else {
            missingIngredients.add(ingredient.name);
          }
        }
      });

      // 재료 조합 정보 다이얼로그 표시
      if (mounted) {
        await _showIngredientCombinationDialog(
          selectedRecipe,
          availableIngredients,
          expiringIngredients,
          missingIngredients,
        );
      }
    }
  }

  int _estimateHealthScore(Recipe recipe, int expiringCount) {
    // 기본 요리별 건강 점수 매핑
    const healthScores = {
      '된장국': 5,
      '김치찌개': 4,
      '채소 볶음': 5,
      '계란말이': 4,
      '시금치나물': 5,
      '두부조림': 5,
      '미역국': 5,
      '닭가슴살 샐러드': 5,
      '계란탁': 4,
      '볶음밥': 3,
      '스파게티': 3,
      '계란프라이': 3,
    };

    int baseScore = healthScores[recipe.name] ?? 3;

    // 유통기한 임박 재료 사용 시 보너스 (+1)
    if (expiringCount > 0 && baseScore < 5) {
      baseScore += 1;
    }

    return baseScore;
  }

  String _getHealthScoreLabel(int score) {
    switch (score) {
      case 5:
        return '💚 매우 건강한 선택입니다!';
      case 4:
        return '💚 건강한 요리예요!';
      case 3:
        return '🟡 보통 수준의 요리입니다';
      case 2:
        return '🟠 가끔 드세요';
      case 1:
        return '🔴 자주 드시지 마세요';
      default:
        return '🟡 보통 수준의 요리입니다';
    }
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 4) return Colors.green.shade700;
    if (score == 3) return Colors.orange;
    return Colors.red.shade700;
  }

  Future<void> handleRecipeConfirmed(
    Recipe recipe,
    int healthScore,
    bool hasExpiring,
  ) async {
    await _recordRecipeLearning(recipe, healthScore, hasExpiring);
    // 학습 완료 메시지 + 건강 점수 알림
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${recipe.name} 선택 완료!\n'
            '${_getHealthScoreLabel(healthScore)}\n'
            '💡 빅스비가 이 선택을 기억합니다',
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: '통계 보기', onPressed: _showLearningStats),
        ),
      );
    }
  }
}
