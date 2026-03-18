// ignore_for_file: invalid_use_of_protected_member
part of 'income_split_screen.dart';

/// Extension: income allocation card + helpers.
extension IncomeSplitAllocationCard on _IncomeSplitScreenState {
  double get _incomeAllocationTotal =>
      _incomeAllocations.values.fold(0, (sum, v) => sum + v);

  Map<String, double> _incomeAllocationsFromItems(List<IncomeItem> items) {
    final allocations = <String, double>{};
    for (final item in items) {
      final normalized = _normalizeIncomeCategoryKey(
        item.category.isNotEmpty ? item.category : item.name,
      );
      if (item.amount <= 0) continue;
      allocations[normalized] = (allocations[normalized] ?? 0) + item.amount;
    }
    return allocations;
  }

  String _normalizeIncomeCategoryKey(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return IncomeCategoryDefinitions.defaultCategory;
    }

    const options = IncomeCategoryDefinitions.categoryOptions;
    if (options.containsKey(value)) return value;

    final valueLower = value.toLowerCase();
    for (final entry in options.entries) {
      if (entry.value.any(
        (sub) => sub == value || sub.toLowerCase() == valueLower,
      )) {
        return entry.key;
      }
    }

    switch (valueLower) {
      case 'salary':
      case 'main':
      case '주수입':
        return '주수입';
      case 'business':
      case '사업':
      case '사업소득':
        return '사업소득';
      case 'bonus':
      case 'sideincome':
      case '부수입':
      case '상여금':
        return '부수입';
      case 'finance':
      case '금융소득':
        return '금융소득';
      case 'other':
      case '기타':
      case '기타소득':
        return '기타소득';
    }
    return IncomeCategoryDefinitions.defaultCategory;
  }

  List<IncomeItem> _buildIncomeItems(Map<String, double> allocations) {
    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    var index = 0;
    return allocations.entries.map((entry) {
      index++;
      return IncomeItem(
        id: '${nowMicros}_income_$index',
        name: entry.key,
        amount: entry.value,
        category: entry.key,
      );
    }).toList();
  }

  Widget _buildIncomeAllocationCard() {
    final scheme = Theme.of(context).colorScheme;
    final entries = _incomeAllocations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalAllocations = _incomeAllocationTotal;
    final difference = _totalIncome - totalAllocations;

    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  '카테고리별 수입 배분',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.map((entry) {
              final percent = totalAllocations > 0
                  ? (entry.value / totalAllocations * 100)
                  : 0.0;
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
                    Text(
                      CurrencyFormatter.format(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (totalAllocations > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '배분 합계',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  CurrencyFormatter.format(totalAllocations),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  difference >= 0 ? '남은 금액' : '초과 금액',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: difference >= 0 ? scheme.primary : scheme.error,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatSigned(difference),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: difference >= 0 ? scheme.primary : scheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
