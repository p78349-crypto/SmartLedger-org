// ignore_for_file: invalid_use_of_protected_member

part of 'transaction_detail_screen.dart';

/// Main build method.
extension TransactionDetailBuild on _TransactionDetailScreenState {
  Widget _buildMain(BuildContext context) {
    final theme = Theme.of(context);
    final service = TransactionService();

    final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month);
    final endOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    List<Transaction> transactions = service
        .getTransactions(widget.accountName)
        .where(
          (tx) =>
              tx.date.isAfter(
                startOfMonth.subtract(const Duration(seconds: 1)),
              ) &&
              tx.date.isBefore(endOfMonth.add(const Duration(seconds: 1))) &&
              tx.type == _selectedType,
        )
        .toList();

    if (_selectedDate != null) {
      transactions = transactions.where((tx) {
        return tx.date.year == _selectedDate!.year &&
            tx.date.month == _selectedDate!.month &&
            tx.date.day == _selectedDate!.day;
      }).toList();
    }

    final groupedByDate = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      groupedByDate.putIfAbsent(dateKey, () => []).add(tx);
    }
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: Text('${_typeLabel(_selectedType)} 상세내역')),
      body: Column(
        children: [
          _buildMonthSelector(theme),
          if (_selectedDate != null) _buildDateFilter(theme),
          Expanded(
            child: transactions.isEmpty
                ? _buildEmptyState(theme)
                : _buildDateGroupedList(theme, sortedDates, groupedByDate),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(IconCatalog.chevronLeft),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                );
                _selectedDate = null;
              });
            },
          ),
          Text(
            DateFormatter.formatMonthLabel(_currentMonth),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(IconCatalog.chevronRight),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                );
                _selectedDate = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: ListTile(
          leading: const Icon(IconCatalog.calendarToday),
          title: Text(DateFormatter.formatDate(_selectedDate!)),
          trailing: IconButton(
            icon: const Icon(IconCatalog.close),
            onPressed: () => setState(() => _selectedDate = null),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconCatalog.inboxOutlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '거래 내역이 없습니다',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroupedList(
    ThemeData theme,
    List<DateTime> sortedDates,
    Map<DateTime, List<Transaction>> groupedByDate,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayTransactions = groupedByDate[date]!;
        final dayTotal = dayTransactions.fold<double>(
          0,
          (sum, tx) => sum + tx.amount,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(theme, date, dayTotal),
              ..._buildTransactionListWithRefunds(dayTransactions, theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(ThemeData theme, DateTime date, double dayTotal) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = _selectedDate == date ? null : date;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Row(
          children: [
            Text(
              DateFormatter.formatMonthDay(date),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              CurrencyFormatter.format(dayTotal),
              style: theme.textTheme.titleSmall?.copyWith(
                color: _typeColor(_selectedType, theme),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
