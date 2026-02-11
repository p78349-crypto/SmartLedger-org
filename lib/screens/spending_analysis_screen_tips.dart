part of 'spending_analysis_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension SpendingAnalysisTips on _SpendingAnalysisScreenState {
  // === TAB 3: 절약 팁 ===
  Widget buildSavingTipsTab(ThemeData theme) {
    // 분석 데이터 준비
    final topCategories = SpendingAnalysisUtils.getTopSpendingCategories(
      transactions: _allTransactions,
      currentMonth: _anchorDate,
    );
    final patterns = SpendingAnalysisUtils.detectRecurringPatterns(
      transactions: _allTransactions,
    );

    // 맞춤 팁 생성
    final tips = SavingTipsUtils.generateTipsFromAnalysis(
      topCategories: topCategories,
      recurringPatterns: patterns,
    );

    // 중복 구매 경고 팁
    final duplicateRisks = SpendingAnalysisUtils.detectDuplicatePurchaseRisk(
      transactions: _allTransactions,
    );
    final duplicateWarnings = SavingTipsUtils.generateDuplicatePurchaseWarnings(
      duplicateRisks,
    );

    final allTips = [...duplicateWarnings, ...tips];

    // 총 예상 절약 금액
    final totalSavings = SavingTipsUtils.calculateTotalPotentialSavings(
      allTips,
    );

    if (allTips.isEmpty) {
      return buildEmptyState(
        theme,
        '아직 분석할 데이터가 부족합니다.\n'
        '거래 내역이 쌓이면 맞춤 팁을 제공합니다.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 예상 절약 금액 요약
          if (totalSavings > 0)
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.savings,
                      size: 40,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '예상 월 절약 금액',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            _currencyFormat.format(totalSavings),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // 팁 목록
          buildSectionTitle(theme, '맞춤 절약 팁', Icons.lightbulb),
          const SizedBox(height: 12),
          ...allTips.map((tip) => _buildTipCard(tip, theme)),
        ],
      ),
    );
  }

  Widget _buildTipCard(SavingTip tip, ThemeData theme) {
    final iconName = SavingTipsUtils.getTipTypeIcon(tip.type);
    final typeLabel = SavingTipsUtils.getTipTypeLabel(tip.type);

    IconData getIconData() {
      switch (iconName) {
        case 'emoji_events':
          return Icons.emoji_events;
        case 'compare_arrows':
          return Icons.compare_arrows;
        case 'schedule':
          return Icons.schedule;
        case 'swap_horiz':
          return Icons.swap_horiz;
        case 'psychology':
          return Icons.psychology;
        case 'inventory_2':
          return Icons.inventory_2;
        case 'autorenew':
          return Icons.autorenew;
        case 'card_giftcard':
          return Icons.card_giftcard;
        default:
          return Icons.lightbulb;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: tip.priority == 1
              ? theme.colorScheme.error
              : theme.colorScheme.primaryContainer,
          child: Icon(
            getIconData(),
            color: tip.priority == 1
                ? Colors.white
                : theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          tip.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            if (tip.estimatedMonthlySaving != null &&
                tip.estimatedMonthlySaving! > 0) ...[
              const SizedBox(width: 8),
              Text(
                '월 ~${_currencyFormat.format(tip.estimatedMonthlySaving)} 절약',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.description, style: theme.textTheme.bodyMedium),
                if (tip.actionItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '💡 실천 방법',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...tip.actionItems.map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(action)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
