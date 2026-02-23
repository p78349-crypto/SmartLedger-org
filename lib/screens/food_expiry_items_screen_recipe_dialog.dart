// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

/// Ingredient combination dialog for recipe selection.
extension FoodExpiryRecipeDialogExt on _FoodExpiryItemsScreenState {
  Future<void> _showIngredientCombinationDialog(
    Recipe recipe,
    List<Map<String, dynamic>> available,
    List<Map<String, dynamic>> expiring,
    List<String> missing,
  ) async {
    final recipeName = recipe.name;

    // 건강 점수 계산 (기본 레시피에서 가져오거나 추정)
    final healthScore = _estimateHealthScore(recipe, expiring.length);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(recipeName, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 유통기한 임박 재료
              if (expiring.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '빨리 먹어야 할 재료 (${expiring.length}개)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: expiring.map((ing) {
                      final daysLeft = ing['daysLeft'] as int;
                      final daysText = daysLeft == 0
                          ? '오늘까지'
                          : daysLeft < 0
                              ? '${-daysLeft}일 지남'
                              : '$daysLeft일 남음';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '⚠️ ${ing['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${ing['quantity']} ($daysText)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 사용 가능한 재료
              if (available.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '사용 가능한 재료 (${available.length}개)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: available.map((ing) {
                      final daysLeft = ing['daysLeft'] as int;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '✅ ${ing['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${ing['quantity']} ($daysLeft일)',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 부족한 재료
              if (missing.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '구매 필요 (${missing.length}개)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: missing.map((name) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.remove_circle_outline,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '💡 부족한 재료를 장바구니에 추가할까요?',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],

              // 요약
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getHealthScoreLabel(healthScore),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '건강 $healthScore/5',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getHealthScoreColor(healthScore),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            expiring.isNotEmpty
                                ? '유통기한 임박 재료를 먼저 사용하세요!'
                                : '재료가 모두 준비됐습니다!',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (missing.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx, false);
                _promptAddMissingToCart(missing);
              },
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('장바구니 추가'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.restaurant_menu, size: 18),
            label: const Text('그것 좋겠다!'),
          ),
        ],
      ),
    );

    // 사용자가 "그것 좋겠다!" 선택 시 학습 기록
    if (confirmed == true && mounted) {
      await handleRecipeConfirmed(recipe, healthScore, expiring.isNotEmpty);
    }
  }
}
