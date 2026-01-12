// ignore_for_file: invalid_use_of_protected_member
part of calendar_screen;

extension _CalendarScreenHelpers on _CalendarScreenState {
  Widget _buildCalendar(
    BuildContext context,
    Map<DateTime, List<Transaction>> events,
  ) {
    final theme = Theme.of(context);
    final headerTitleStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    final weekdayStyle =
        theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ) ??
        const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        );
    final weekendStyle =
        theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ) ??
        TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        );
    final todayDecoration = BoxDecoration(
      color: theme.colorScheme.primary.withValues(alpha: 0.15),
      shape: BoxShape.circle,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TableCalendar<Transaction>(
        firstDay: DateTime.utc(2000),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        daysOfWeekHeight: 32,
        availableCalendarFormats: const {
          CalendarFormat.month: '월',
          CalendarFormat.twoWeeks: '2주',
          CalendarFormat.week: '주',
        },
        selectedDayPredicate: (day) {
          final currentSelection = _selectedDay;
          if (currentSelection == null) {
            return false;
          }
          return isSameDay(currentSelection, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          final strippedDay = _stripTime(selectedDay);
          final shouldClear =
              _selectedDay != null && isSameDay(_selectedDay, strippedDay);

          if (shouldClear) {
            setState(() {
              _selectedDay = null;
            });
            return;
          }

          setState(() {
            _selectedDay = strippedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        eventLoader: (day) {
          return events[_stripTime(day)] ?? const <Transaction>[];
        },
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: headerTitleStyle,
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: theme.colorScheme.primary,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.primary,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: weekdayStyle,
          weekendStyle: weekendStyle,
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: todayDecoration,
          selectedDecoration: const BoxDecoration(color: Colors.transparent),
          markersMaxCount: 0,
          outsideDaysVisible: false,
          cellMargin: const EdgeInsets.all(4),
        ),
        rowHeight: 90,
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(context, day, events[_stripTime(day)] ?? []);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              context,
              day,
              events[_stripTime(day)] ?? [],
              isToday: true,
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              context,
              day,
              events[_stripTime(day)] ?? [],
              isSelected: true,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    List<Transaction> transactions, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);

    double income = 0;
    double expense = 0;
    double savings = 0;
    double refund = 0;

    for (final t in transactions) {
      switch (t.type) {
        case TransactionType.income:
          income += t.amount;
          break;
        case TransactionType.expense:
          expense += t.amount;
          break;
        case TransactionType.savings:
          savings += t.amount;
          break;
        case TransactionType.refund:
          refund += t.amount;
          break;
      }
    }

    final hasTransactions = transactions.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(2),
      width: isSelected ? 80 : null,
      height: isSelected ? 86 : null,
      decoration: isSelected
          ? BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: isToday ? 18 : 14,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isToday ? Colors.pink : theme.textTheme.bodyMedium?.color,
            ),
          ),
          if (hasTransactions) ...[
            const SizedBox(height: 2),
            if (income > 0)
              Text(
                '+${_currencyFormat.format(income)}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.income,
                ),
              ),
            if (expense > 0)
              Text(
                '-${_currencyFormat.format(expense)}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.expense,
                ),
              ),
            if (savings > 0)
              Text(
                '⊕${_currencyFormat.format(savings)}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.savings,
                ),
              ),
            if (refund > 0)
              Text(
                '↺${_currencyFormat.format(refund)}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: RefundUtils.color,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Map<DateTime, List<Transaction>> _groupTransactionsByDay(
    List<Transaction> transactions,
  ) {
    final grouped = <DateTime, List<Transaction>>{};
    for (final transaction in transactions) {
      final key = _stripTime(transaction.date);
      grouped.putIfAbsent(key, () => []).add(transaction);
    }
    return grouped;
  }

  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
