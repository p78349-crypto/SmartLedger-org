// ignore_for_file: invalid_use_of_protected_member

part of 'period_detail_stats_screen.dart';

/// 데이터 로딩·필터링·기간 이동 로직
extension PeriodDetailStatsData on _PeriodDetailStatsScreenState {
  Future<void> initialize() async {
    await TransactionService().loadTransactions();
    await FixedCostService().loadFixedCosts();
    final costs = FixedCostService().getFixedCosts(widget.accountName);
    if (!mounted) return;
    setState(() {
      _fixedCosts = costs;
      _isLoading = false;
    });
  }

  String get periodLabel {
    return period.PeriodUtils.getPeriodLabel(widget.periodType);
  }

  String get typeLabel {
    switch (widget.transactionType) {
      case TransactionType.expense:
        return '지출';
      case TransactionType.income:
        return '수입';
      case TransactionType.savings:
        return '예금';
      case TransactionType.refund:
        return '환급';
    }
  }

  int get monthsInPeriod {
    switch (widget.periodType) {
      case period.PeriodType.week:
        return 0;
      case period.PeriodType.month:
        return 1;
      case period.PeriodType.quarter:
        return 3;
      case period.PeriodType.halfYear:
        return 6;
      case period.PeriodType.year:
        return 12;
      case period.PeriodType.decade:
        return 120;
    }
  }

  bool shouldAggregateForType(Transaction tx, TransactionType type) {
    final isSavingsAsExpense =
        tx.type == TransactionType.savings &&
        tx.savingsAllocation == SavingsAllocation.expense;

    switch (type) {
      case TransactionType.expense:
        return tx.type == TransactionType.expense || isSavingsAsExpense;
      case TransactionType.income:
        return tx.type == TransactionType.income;
      case TransactionType.savings:
        return tx.type == TransactionType.savings && !isSavingsAsExpense;
      case TransactionType.refund:
        return tx.type == TransactionType.refund;
    }
  }

  List<Transaction> getFilteredTransactions() {
    final allTransactions = TransactionService().getTransactions(
      widget.accountName,
    );
    final months = monthsInPeriod;

    DateTime startDate;
    DateTime endDate;

    if (widget.periodType == period.PeriodType.decade) {
      final startYear = (_currentYear ~/ 10) * 10;
      startDate = DateTime(startYear);
      endDate = DateTime(startYear + 10, 12, 31);
    } else {
      startDate = DateTime(
        _currentMonth.year,
        _currentMonth.month - months + 1,
      );
      endDate = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    }

    return allTransactions.where((tx) {
      if (tx.date.isBefore(startDate) || tx.date.isAfter(endDate)) {
        return false;
      }
      return shouldAggregateForType(tx, widget.transactionType);
    }).toList();
  }

  double calculateTotal(List<Transaction> transactions) {
    double total = transactions.fold(0.0, (sum, tx) => sum + tx.amount);

    if (_includeFixedCosts &&
        _fixedCosts.isNotEmpty &&
        widget.transactionType == TransactionType.expense) {
      final months = monthsInPeriod;
      final monthlyCost = _fixedCosts.fold(0.0, (sum, fc) => sum + fc.amount);
      total += monthlyCost * months;
    }

    return total;
  }

  void previousPeriod() {
    setState(() {
      if (widget.periodType == period.PeriodType.decade) {
        _currentYear -= 10;
        return;
      }
      if (widget.periodType == period.PeriodType.week) {
        _currentMonth = _currentMonth.subtract(const Duration(days: 7));
        return;
      }
      final stepMonths = monthsInPeriod;
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month - stepMonths,
      );
    });
  }

  void nextPeriod() {
    setState(() {
      if (widget.periodType == period.PeriodType.decade) {
        _currentYear += 10;
        return;
      }
      if (widget.periodType == period.PeriodType.week) {
        _currentMonth = _currentMonth.add(const Duration(days: 7));
        return;
      }
      final stepMonths = monthsInPeriod;
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + stepMonths,
      );
    });
  }

  String getCurrentPeriodLabel(BuildContext context) {
    switch (widget.periodType) {
      case period.PeriodType.week:
        final start = _currentMonth.subtract(const Duration(days: 6));
        final startLabel = LocalizedDateFormatter.yMd(context, start);
        final endLabel = LocalizedDateFormatter.yMd(context, _currentMonth);
        return '$startLabel ~ $endLabel';
      case period.PeriodType.month:
        return LocalizedDateFormatter.yM(context, _currentMonth);
      case period.PeriodType.quarter:
      case period.PeriodType.halfYear:
      case period.PeriodType.year:
        final startMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month - (monthsInPeriod - 1),
        );
        final startLabel = LocalizedDateFormatter.yM(context, startMonth);
        final endLabel = LocalizedDateFormatter.yM(context, _currentMonth);
        return '$startLabel ~ $endLabel';
      case period.PeriodType.decade:
        final startYear = _currentYear - 9;
        final startLabel = LocalizedDateFormatter.y(context, startYear);
        final endLabel = LocalizedDateFormatter.y(context, _currentYear);
        return '$startLabel ~ $endLabel';
    }
  }
}
