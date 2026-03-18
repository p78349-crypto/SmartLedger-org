part of 'nutrition_report_screen.dart';

/// Food search result widget with tab-based display.
class _FoodSearchResult extends StatefulWidget {
  const _FoodSearchResult({required this.query, this.onAdd});
  final String query;
  final ValueChanged<String>? onAdd;

  @override
  State<_FoodSearchResult> createState() => _FoodSearchResultState();
}

class _FoodSearchResultState extends State<_FoodSearchResult> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant _FoodSearchResult oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = widget.query.trim();

    if (trimmed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '식재료를 입력하세요. 예: 닭고기',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Attempt to look up via Service first, fallback to static if needed
    final entry =
        RecipeKnowledgeService.instance.lookup(trimmed) ??
        NutritionFoodKnowledge.lookup(trimmed);

    if (entry == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '"$trimmed" 데이터가 없습니다.\n(예: 닭고기, 계란, 두부)',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. 헤더 (이름)
        Text(
          entry.primaryName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),

        // 2. 탭 버튼 (Segmented Control 스타일)
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _buildTabButton(context, 0, '영양 정보'),
              _buildTabButton(context, 1, '꿀조합'),
              _buildTabButton(context, 2, '추천 수량'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. 내용 (AnimatedSwitcher로 부드러운 전환)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildBody(context, entry),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ],
    );
  }

  Widget _buildTabButton(BuildContext context, int index, String label) {
    final theme = Theme.of(context);
    final sel = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: sel ? theme.colorScheme.surface : null,
            borderRadius: BorderRadius.circular(6),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              color: sel
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, FoodKnowledgeEntry entry) {
    switch (_selectedIndex) {
      case 0:
        return _buildIntakeInfo(context, entry);
      case 1:
        return _buildPairings(context, entry);
      case 2:
        return _buildQuantities(context, entry);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntakeInfo(BuildContext context, FoodKnowledgeEntry entry) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('intake'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '1인 하루 섭취 권장량',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            entry.dailyIntakeText,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPairings(BuildContext context, FoodKnowledgeEntry entry) {
    final theme = Theme.of(context);
    if (entry.pairings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('추천 조합 데이터가 없습니다.'),
      );
    }
    return Column(
      key: const ValueKey('pairings'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in entry.pairings)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.ingredient,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.why,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onAdd != null) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => widget.onAdd?.call(p.ingredient),
                    tooltip: '장바구니 담기',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    style: IconButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuantities(BuildContext context, FoodKnowledgeEntry entry) {
    final theme = Theme.of(context);
    if (entry.quantitySuggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('추천 수량 데이터가 없습니다.'),
      );
    }
    return Column(
      key: const ValueKey('quantities'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '인원과 취향에 따라 조절하세요.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final line in entry.quantitySuggestions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    line,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
