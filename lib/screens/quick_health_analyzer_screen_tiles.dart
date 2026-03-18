import 'package:flutter/material.dart';
import '../utils/ingredient_health_score_utils.dart';
import 'quick_health_analyzer_screen_widgets.dart';

/// 재료 체크박스 타일
class IngredientTile extends StatelessWidget {
  final String ingredient;
  final bool isSelected;
  final ValueChanged<String> onToggle;

  const IngredientTile({
    super.key,
    required this.ingredient,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final score = IngredientHealthScoreUtils.getScore(ingredient);
    final scoreColor = getHealthScoreColor(score);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? null : Colors.grey.shade100,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) => onToggle(ingredient),
        title: Row(
          children: [
            Expanded(
              child: Text(
                ingredient,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.grey,
                ),
              ),
            ),
            _ScoreBadge(score: score, color: scoreColor),
          ],
        ),
        subtitle: isSelected
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  IngredientHealthScoreUtils.getScoreDescription(score),
                  style: const TextStyle(fontSize: 11),
                ),
              )
            : null,
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  final Color color;

  const _ScoreBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            IngredientHealthScoreUtils.getScoreLabel(score).split(' ').first,
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
