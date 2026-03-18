// ignore_for_file: avoid_redundant_argument_values
part of 'refund_transactions_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension RefundBody on _RefundTransactionsScreenState {
  Widget buildHeaderSection({
    required ThemeData theme,
    required bool queryActive,
    required int transactionCount,
    required double totalRefund,
    required String formattedDate,
    required bool hasPrev,
    required bool hasNext,
    required int currentIndex,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: queryActive
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    '검색 결과: $transactionCount건',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (totalRefund > 0)
                  Text(
                    '⊕${_numberFormat.format(totalRefund)}원',
                    style: const TextStyle(
                      color: RefundUtils.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            )
          : Row(
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
                    Row(
                      children: [
                        if (totalRefund > 0) ...[
                          const Text(
                            '환급 ',
                            style: TextStyle(
                              color: RefundUtils.color,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '⊕${_numberFormat.format(totalRefund)}원',
                            style: const TextStyle(
                              color: RefundUtils.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ] else ...[
                          Text(
                            '0원',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
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

  Widget buildTransactionListExpanded({
    required ThemeData theme,
    required List<Transaction> transactions,
    required bool isLandscape,
    required bool queryActive,
    required String formattedDate,
  }) {
    return Expanded(
      child: transactions.isEmpty
          ? Center(
              child: Text(
                queryActive ? '검색 결과가 없습니다.' : '$formattedDate\n반품 내역이 없습니다.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            )
          : Column(
              children: [
                if (isLandscape)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: DefaultTextStyle(
                      style:
                          theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ) ??
                          const TextStyle(fontSize: 12),
                      child: Row(
                        children: [
                          if (queryActive) ...[
                            const Expanded(flex: 2, child: Text('일자')),
                            const SizedBox(width: 10),
                          ],
                          const Expanded(flex: 4, child: Text('상품명')),
                          const SizedBox(width: 10),
                          const Expanded(flex: 3, child: Text('카테고리')),
                          const SizedBox(width: 10),
                          const Expanded(flex: 2, child: Text('결제')),
                          const SizedBox(width: 10),
                          const Expanded(flex: 2, child: Text('수량')),
                          const SizedBox(width: 10),
                          const Expanded(flex: 2, child: Text('단가')),
                          const SizedBox(width: 10),
                          const Expanded(flex: 4, child: Text('메모')),
                          const SizedBox(width: 10),
                          const Text('금액'),
                          const SizedBox(width: 10),
                          const Text('카드금액'),
                        ],
                      ),
                    ),
                  ),
                if (isLandscape) const Divider(height: 1),
                Expanded(
                  child: _groupByPayment
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: buildGroupedByPayment(transactions, theme),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: transactions.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            if (!isLandscape) {
                              return buildRefundTile(
                                theme,
                                tx,
                                showDate: queryActive,
                              );
                            }
                            return buildLandscapeRow(
                              theme,
                              tx,
                              queryActive: queryActive,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget buildBottomFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _roundToggleButton(
              label: '전체',
              selected: _selectedBottomFilter == 'all',
              onTap: () => _applyBottomFilter('all'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _roundToggleButton(
              label: '결제수단',
              selected: _selectedBottomFilter == 'payment',
              onTap: () => _applyBottomFilter('payment'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _roundToggleButton(
              label: '부분 반품',
              selected: _selectedBottomFilter == 'partial',
              onTap: () => _applyBottomFilter('partial'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _roundToggleButton(
              label: '30',
              selected: _selectedBottomFilter == '30',
              onTap: () => _applyBottomFilter('30'),
            ),
          ),
        ],
      ),
    );
  }

  void _applyBottomFilter(String key) {
    setState(() {
      _selectedBottomFilter = key;
      // reset all underlying flags, then set the one corresponding to key
      _groupByPayment = false;
      _partialOnly = false;
      _rangeDays = null;
      if (key == 'all') {
        // default: show selected day (no range)
        _rangeDays = null;
      } else if (key == 'payment') {
        _groupByPayment = true;
      } else if (key == 'partial') {
        _partialOnly = true;
      } else if (key == '30') {
        _rangeDays = 30;
        _selectedDay = DateTime.now();
      }
    });
  }

  // _smallToggleButton removed — replaced by _roundToggleButton per UI update.

  Widget _roundToggleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final selectedTextColor = theme.colorScheme.onPrimary;
    final unselectedTextColor = theme.colorScheme.onSurface;
    final borderColor = selected
        ? selectedColor
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? selectedTextColor : unselectedTextColor,
            fontWeight: FontWeight.w600,
            // reduce font size for specific longer labels to avoid clipping
            fontSize: (label.contains('결제') || label.contains('부분')) ? 12 : 14,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
