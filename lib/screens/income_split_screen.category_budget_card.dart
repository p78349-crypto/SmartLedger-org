// ignore_for_file: invalid_use_of_protected_member
part of 'income_split_screen.dart';

/// Extension: category budget summary card.
extension IncomeSplitCategoryBudgetCard on _IncomeSplitScreenState {
  Widget _buildCategoryBudgetCard() {
    final scheme = Theme.of(context).colorScheme;
    final entries = _categoryBudgets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _categoryBudgetTotal;
    final hasBudget = _budget > 0;
    final difference = _budget - total;
    final matchesBudget = !hasBudget || difference == 0;

    return Card(
      color: matchesBudget
          ? scheme.surface
          : (difference > 0
              ? scheme.tertiaryContainer
              : scheme.errorContainer),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.category, size: 18),
              SizedBox(width: 8),
              Text('카테고리별 배분 요약',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            ...entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(entry.key,
                  style: const TextStyle(fontSize: 13))),
                Text(CurrencyFormatter.format(entry.value),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                if (total > 0) ...[
                  const SizedBox(width: 8),
                  Text(CurrencyFormatter.formatRatio(entry.value, total),
                    style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ]),
            )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('배분 합계',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Text(CurrencyFormatter.format(total),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (hasBudget) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(difference >= 0 ? '남은 예산' : '초과 금액',
                    style: TextStyle(fontWeight: FontWeight.bold,
                      color: difference >= 0
                          ? scheme.primary : scheme.error)),
                  Text(CurrencyFormatter.formatSigned(difference),
                    style: TextStyle(fontWeight: FontWeight.bold,
                      color: difference >= 0
                          ? scheme.primary : scheme.error)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
