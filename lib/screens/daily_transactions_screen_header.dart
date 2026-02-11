// ignore_for_file: invalid_use_of_protected_member

part of 'daily_transactions_screen.dart';

/// 날짜 헤더/요약/가로 헤더 빌더
extension DailyTransactionsHeader on _DailyTransactionsScreenState {
  /// 날짜 헤더 + 요약 정보
  Widget buildDateHeader({
    required ThemeData theme,
    required String formattedDate,
    required _DaySummary summary,
    required bool hasPrev,
    required bool hasNext,
    required int currentIndex,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: hasPrev
                ? () => _changeDay(_eventDays[currentIndex - 1])
                : null,
            icon: const Icon(IconCatalog.chevronLeft),
          ),
          Column(
            children: [
              Text(
                formattedDate,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildSummaryRow(theme, summary),
              if (summary.paymentSummary != null) ...[
                const SizedBox(height: 6),
                Text(
                  '결제: ${summary.paymentSummary}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            onPressed: hasNext
                ? () => _changeDay(_eventDays[currentIndex + 1])
                : null,
            icon: const Icon(IconCatalog.chevronRight),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, _DaySummary s) {
    return Row(
      children: [
        if (s.totalIncome > 0) ...[
          const Text(
            '수입 ',
            style: TextStyle(color: AppColors.income, fontSize: 12),
          ),
          Text(
            '+${_numberFormat.format(s.totalIncome)}원',
            style: const TextStyle(
              color: AppColors.income,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (s.totalExpense > 0) ...[
          const Text(
            '지출 ',
            style: TextStyle(color: AppColors.expense, fontSize: 12),
          ),
          Text(
            '-${_numberFormat.format(s.totalExpense)}원',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.expense,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (s.totalSavings > 0) ...[
          const Text(
            '예금 ',
            style: TextStyle(color: AppColors.savings, fontSize: 12),
          ),
          Text(
            '⊕${_numberFormat.format(s.totalSavings)}원',
            style: const TextStyle(
              color: AppColors.savings,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
        if (s.totalRefund > 0) ...[
          const SizedBox(width: 12),
          const Text(
            '환급 ',
            style: TextStyle(color: RefundUtils.color, fontSize: 12),
          ),
          Text(
            '⊕${_numberFormat.format(s.totalRefund)}원',
            style: const TextStyle(
              color: RefundUtils.color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget buildLandscapeHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DefaultTextStyle(
        style:
            theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ) ??
            const TextStyle(fontSize: 12),
        child: const Row(
          children: [
            Expanded(flex: 4, child: Text('상품명')),
            SizedBox(width: 10),
            Expanded(flex: 3, child: Text('카테고리')),
            SizedBox(width: 10),
            Expanded(flex: 2, child: Text('결제')),
            SizedBox(width: 10),
            Expanded(flex: 4, child: Text('메모')),
            SizedBox(width: 10),
            Text('금액'),
            SizedBox(width: 10),
            Text('카드금액'),
          ],
        ),
      ),
    );
  }
}
