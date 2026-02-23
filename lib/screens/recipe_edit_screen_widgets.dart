import 'package:flutter/material.dart';

/// 건강 점수 선택 위젯 (1~5점)
class HealthScoreSelector extends StatelessWidget {
  const HealthScoreSelector({
    super.key,
    required this.score,
    required this.onChanged,
  });

  final int score;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('건강 점수', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final s = index + 1;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2,
                  ),
                  decoration: BoxDecoration(
                    color: score >= s
                        ? theme.colorScheme.primary
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: score >= s
                        ? Colors.white
                        : Colors.grey[400],
                    size: 24,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          score >= 4
              ? '매우 건강해요!'
              : score >= 3
                  ? '적당해요'
                  : '가끔 먹어요',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// 재료가 비어있을 때 표시하는 플레이스홀더
class EmptyIngredientsPlaceholder extends StatelessWidget {
  const EmptyIngredientsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.egg_alt_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            '아직 재료가 없습니다',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            '재료 추가 버튼을 눌러 추가해주세요',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
