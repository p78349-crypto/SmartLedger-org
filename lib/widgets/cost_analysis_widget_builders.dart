part of cost_analysis_widget;

extension CostAnalysisWidgetBuilders on _CostAnalysisWidgetState {
  Widget _buildBudgetCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '월 예산',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${_budgetLimit.toStringAsFixed(0)}원',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '현재 지출',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${_analysis!.currentCost.toStringAsFixed(0)}원',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '남은 예산',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${_analysis!.remaining.toStringAsFixed(0)}원',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _analysis!.statusText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryRows(ThemeData theme) {
    if (_categorySpending == null) return [];

    final entries = _categorySpending!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(5).map((entry) {
      final percentage = (entry.value / _budgetLimit * 100).toStringAsFixed(1);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(entry.key, style: theme.textTheme.labelMedium),
            ),
            Text(
              '${entry.value.toStringAsFixed(0)}원 ($percentage%)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getStatusColor() {
    if (_analysis!.isOverBudget) return Colors.red;
    if (_analysis!.usagePercentage > 80) return Colors.orange;
    if (_analysis!.usagePercentage > 50) return Colors.green;
    return Colors.blue;
  }

  Color _getBudgetStatusBackground(ThemeData theme) {
    if (_analysis!.isOverBudget) {
      return Colors.red.withValues(alpha: 0.1);
    } else if (_analysis!.usagePercentage > 80) {
      return Colors.orange.withValues(alpha: 0.1);
    } else {
      return Colors.green.withValues(alpha: 0.1);
    }
  }
}
