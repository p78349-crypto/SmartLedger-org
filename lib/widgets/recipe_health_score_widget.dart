import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../utils/ingredient_health_score_utils.dart';

/// 레시피 건강 점수 표시 위젯
class RecipeHealthScoreWidget extends StatelessWidget {
  final Recipe recipe;
  final bool showDetails;

  const RecipeHealthScoreWidget({
    super.key,
    required this.recipe,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final ingredientNames =
        recipe.ingredients.map((i) => i.name).toList();
    final analysis =
        IngredientHealthScoreUtils.analyzeIngredients(ingredientNames);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 전체 건강 점수
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '건강 점수',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildScoreBadge(analysis.overallScore),
              ],
            ),
            const SizedBox(height: 12),

            // 요약 메시지
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getScoreColor(analysis.overallScore).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      analysis.summary,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getScoreColor(analysis.overallScore),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (showDetails) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // 재료별 점수
              const Text(
                '재료별 건강도',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              ...analysis.ingredientScores.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      _buildIngredientScoreChip(entry.value),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // 건강 재료 통계
              _buildHealthStats(analysis),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getScoreColor(score),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            IngredientHealthScoreUtils.getScoreLabel(score),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$score점',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientScoreChip(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getScoreColor(score).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getScoreColor(score).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        IngredientHealthScoreUtils.getScoreLabel(score),
        style: TextStyle(
          color: _getScoreColor(score),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHealthStats(IngredientAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '건강도 분포',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (analysis.veryHealthyCount > 0)
          _buildStatRow('💚 매우 건강', analysis.veryHealthyCount, Colors.green),
        if (analysis.healthyCount > 0)
          _buildStatRow('💚 건강', analysis.healthyCount, Colors.lightGreen),
        if (analysis.normalCount > 0)
          _buildStatRow('🟡 보통', analysis.normalCount, Colors.orange),
        if (analysis.cautionCount > 0)
          _buildStatRow('🟠 주의', analysis.cautionCount, Colors.deepOrange),
        if (analysis.unhealthyCount > 0)
          _buildStatRow('🔴 비건강', analysis.unhealthyCount, Colors.red),
        const SizedBox(height: 8),
        Text(
          '건강한 재료: ${(analysis.healthyRatio * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count개',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    switch (score) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
