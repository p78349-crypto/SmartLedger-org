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
                queryActive
                    ? '검색 결과가 없습니다.'
                    : '$formattedDate\n반품 내역이 없습니다.',
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
      color: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.08,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _smallToggleButton(
            label: '전체',
            selected: _rangeDays == null,
            onTap: () => setState(() => _rangeDays = null),
          ),
          _smallToggleButton(
            label: '지난 7일',
            selected: _rangeDays == 7,
            onTap: () => setState(() {
              _rangeDays = 7;
              _selectedDay = DateTime.now();
            }),
          ),
          _smallToggleButton(
            label: '지난 30일',
            selected: _rangeDays == 30,
            onTap: () => setState(() {
              _rangeDays = 30;
              _selectedDay = DateTime.now();
            }),
          ),
          _smallToggleButton(
            label: '지난 6개월',
            selected: _rangeDays == 180,
            onTap: () => setState(() {
              _rangeDays = 180;
              _selectedDay = DateTime.now();
            }),
          ),
          _smallToggleButton(
            label: '부분 반품만',
            selected: _partialOnly,
            onTap: () => setState(() => _partialOnly = !_partialOnly),
          ),
          _smallToggleButton(
            label: '결제수단별',
            selected: _groupByPayment,
            onTap: () =>
                setState(() => _groupByPayment = !_groupByPayment),
          ),
        ],
      ),
    );
  }

  Widget _smallToggleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
