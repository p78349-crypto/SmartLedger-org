part of 'spending_analysis_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension SpendingAnalysisRecurring on _SpendingAnalysisScreenState {
  // === TAB 2: 반복 패턴 ===
  Widget buildRecurringPatternTab(ThemeData theme) {
    final patterns = SpendingAnalysisUtils.detectRecurringPatterns(
      transactions: _allTransactions,
    );

    final duplicateRisks = SpendingAnalysisUtils.detectDuplicatePurchaseRisk(
      transactions: _allTransactions,
    );

    if (patterns.isEmpty) {
      return buildEmptyState(
        theme,
        '반복 구매 패턴이 감지되지 않았습니다.\n'
        '거래 데이터가 쌓이면 분석됩니다.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 중복 구매 위험 경고
          if (duplicateRisks.isNotEmpty) ...[
            buildSectionTitle(theme, '⚠️ 중복 구매 주의', Icons.warning_amber),
            const SizedBox(height: 12),
            _buildDuplicateRiskCards(duplicateRisks, theme),
            const SizedBox(height: 24),
          ],

          // 반복 구매 패턴
          buildSectionTitle(theme, '반복 구매 패턴', Icons.repeat),
          const SizedBox(height: 12),
          _buildPatternList(patterns, theme),

          const SizedBox(height: 24),

          // 다음 구매 예측
          buildSectionTitle(theme, '다음 구매 예측', Icons.calendar_today),
          const SizedBox(height: 12),
          _buildPredictionList(patterns, theme),
        ],
      ),
    );
  }

  Widget _buildDuplicateRiskCards(
    List<RecurringSpendingPattern> risks,
    ThemeData theme,
  ) {
    return Column(
      children: risks.take(3).map((risk) {
        final daysSinceLast = DateTime.now()
            .difference(risk.purchaseDates.last)
            .inDays;

        return Card(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          child: ListTile(
            leading: Icon(Icons.warning, color: theme.colorScheme.error),
            title: Text(risk.name),
            subtitle: Text(
              '$daysSinceLast일 전 구매함 · 평균 주기 ${risk.avgInterval.round()}일',
            ),
            trailing: Text(
              '${(risk.avgInterval - daysSinceLast).round()}일 후\n구매 적절',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPatternList(
    List<RecurringSpendingPattern> patterns,
    ThemeData theme,
  ) {
    return Card(
      child: Column(
        children: patterns.take(10).map((pattern) {
          final confidence = pattern.predictionConfidence;
          final confidenceColor = confidence > 0.7
              ? Colors.green
              : (confidence > 0.5 ? Colors.orange : Colors.grey);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${pattern.frequency}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(pattern.name),
            subtitle: Row(
              children: [
                Text('월 ${pattern.frequency}회'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '신뢰도 ${(confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 10, color: confidenceColor),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(pattern.avgAmount),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '평균 ${pattern.avgInterval.round()}일 간격',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPredictionList(
    List<RecurringSpendingPattern> patterns,
    ThemeData theme,
  ) {
    final upcoming =
        patterns
            .where((p) => p.predictedNextPurchase != null)
            .where((p) => p.predictedNextPurchase!.isAfter(DateTime.now()))
            .where(
              (p) =>
                  p.predictedNextPurchase!.difference(DateTime.now()).inDays <=
                  14,
            )
            .toList()
          ..sort(
            (a, b) =>
                a.predictedNextPurchase!.compareTo(b.predictedNextPurchase!),
          );

    if (upcoming.isEmpty) {
      return buildEmptyCard(theme, '2주 내 예정된 구매가 없습니다');
    }

    return Card(
      child: Column(
        children: upcoming.take(5).map((pattern) {
          final daysUntil = pattern.predictedNextPurchase!
              .difference(DateTime.now())
              .inDays;
          final dateStr = DateFormat(
            'M/d(E)',
            'ko',
          ).format(pattern.predictedNextPurchase!);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: daysUntil <= 3
                  ? theme.colorScheme.error
                  : theme.colorScheme.primaryContainer,
              child: Text(
                'D-$daysUntil',
                style: TextStyle(
                  fontSize: 11,
                  color: daysUntil <= 3
                      ? Colors.white
                      : theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(pattern.name),
            subtitle: Text('예상 구매일: $dateStr'),
            trailing: Text(
              '~${_currencyFormat.format(pattern.avgAmount)}',
              style: theme.textTheme.titleSmall,
            ),
          );
        }).toList(),
      ),
    );
  }
}
