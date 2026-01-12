part of fixed_cost_stats_screen;

extension _FixedCostStatsScreenList on _FixedCostStatsScreenState {
  List<Widget> _buildSummaryAndList(ThemeData theme, bool isLandscape) {
    return [
      Card(
        color: theme.colorScheme.primaryContainer.withAlpha(100),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('월간 고정비', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '-${_currencyFormat.format(_monthlyTotal)}원',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_fixedCosts.length}개 항목',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        color: theme.colorScheme.errorContainer.withAlpha(100),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('연간 고정비', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '-${_currencyFormat.format(_yearlyTotal)}원',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '월 ${_currencyFormat.format(_monthlyTotal)}원 × 12개월',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text('항목별 고정비', style: theme.textTheme.titleLarge),
      const SizedBox(height: 12),
      ..._sortedCosts.map(
        (cost) {
          final percentage =
              _monthlyTotal > 0 ? (cost.amount / _monthlyTotal * 100) : 0.0;
          final meta = _fixedCostMeta(cost);
          final yearlyLabel =
              '연간: -${_currencyFormat.format(cost.amount * 12)}원';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLandscape
                  ? _buildLandscapeRow(theme, cost, meta)
                  : _buildPortraitCard(theme, cost, meta, percentage, yearlyLabel),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildLandscapeRow(ThemeData theme, FixedCost cost, String meta) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            cost.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (cost.dueDay != null)
          Expanded(
            flex: 2,
            child: Text(
              '매월 ${cost.dueDay}일',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          )
        else
          const Spacer(flex: 2),
        Expanded(
          flex: 3,
          child: Text(
            '-${_currencyFormat.format(cost.amount)}원',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitCard(
    ThemeData theme,
    FixedCost cost,
    String meta,
    double percentage,
    String yearlyLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                cost.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '-${_currencyFormat.format(cost.amount)}원',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.error),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${percentage.toStringAsFixed(1)}% of 월간 고정비',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (cost.dueDay != null)
              Text(
                '매월 ${cost.dueDay}일',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildMetaChips(theme, cost),
        ],
        const SizedBox(height: 8),
        Text(
          yearlyLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMetaChips(ThemeData theme, FixedCost cost) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (cost.paymentMethod.isNotEmpty)
          Chip(
            label: Text(cost.paymentMethod),
            visualDensity: VisualDensity.compact,
            labelStyle: theme.textTheme.bodySmall,
          ),
        if (cost.vendor != null && cost.vendor!.isNotEmpty)
          Chip(
            label: Text(cost.vendor!),
            visualDensity: VisualDensity.compact,
            labelStyle: theme.textTheme.bodySmall,
          ),
        if (cost.memo != null && cost.memo!.isNotEmpty)
          Chip(
            label: Text(cost.memo!),
            visualDensity: VisualDensity.compact,
            labelStyle: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}
