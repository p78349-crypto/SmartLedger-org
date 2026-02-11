// ignore_for_file: invalid_use_of_protected_member
part of 'account_stats_screen.dart';

/// 초기화 및 포맷 헬퍼 메서드.
extension AccountStatsInit on _AccountStatsScreenState {
  Future<void> _initialize() async {
    await TransactionService().loadTransactions();
    await FixedCostService().loadFixedCosts();
    if (!mounted) return;

    final service = TransactionService();
    final transactions = List<Transaction>.from(
      service.getTransactions(widget.accountName),
    );
    final fixedCosts = List<FixedCost>.from(
      FixedCostService().getFixedCosts(widget.accountName),
    );
    final monthlyAggCache = await MonthlyAggCacheService().ensureBuilt(
      accountName: widget.accountName,
      transactions: transactions,
    );
    if (!mounted) return;

    final quickEntries = await QuickSimpleExpenseInputHistoryService()
        .loadEntries(widget.accountName);
    final storeAliasMap = await StoreAliasService.loadMap(widget.accountName);
    final defaultStore = _pickDefaultStore(transactions, storeAliasMap);
    if (!mounted) return;

    DateTime fallbackDate = DateTime.now();
    if (transactions.isNotEmpty) {
      final latest = transactions.reduce(
        (prev, next) => prev.date.isAfter(next.date) ? prev : next,
      );
      fallbackDate = latest.date;
    }

    setState(() {
      _currentMonth = DateTime(fallbackDate.year, fallbackDate.month);
      _currentYear = fallbackDate.year;
      _chartAnchorMonth = DateTime(fallbackDate.year, fallbackDate.month);
      _isInitializing = false;
      _fixedCosts = fixedCosts;
      _monthlyAggCache = monthlyAggCache;
      _quickEntries = quickEntries;
      _storeAliasMap = storeAliasMap;
      _defaultStore = defaultStore;
    });
  }

  String? _pickDefaultStore(
    List<Transaction> txs, Map<String, String> aliasMap,
  ) {
    final now = DateTime.now();
    final scanStart = now.subtract(const Duration(days: 183));
    final ordered = List<Transaction>.from(txs)
      ..sort((a, b) => b.date.compareTo(a.date));
    final limited = ordered.take(1500);
    final counts = <String, int>{};
    for (final t in limited) {
      if (t.date.isBefore(scanStart)) continue;
      final raw = _storeKeyOf(t);
      if (raw == null) continue;
      final canonical = StoreAliasService.resolve(raw, aliasMap);
      counts[canonical] = (counts[canonical] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final ranked = counts.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked.first.key;
  }

  String? _storeKeyOf(Transaction t) {
    final store = t.store?.trim();
    if (store != null && store.isNotEmpty) return store;
    return StoreMemoUtils.extractStoreKey(t.memo);
  }

  SummaryTotals? _tryCalculateRangeSummaryFromMonthlyAgg(
    DateTimeRange range, int months,
  ) {
    final cache = _monthlyAggCache;
    if (cache == null || cache.months.isEmpty) return null;
    double income = 0, expenseOnly = 0, savings = 0;
    for (var i = 0; i < months; i++) {
      final monthDate = DateTime(range.end.year, range.end.month - i);
      final ym = MonthlyAggCacheService.yearMonthOf(monthDate);
      final bucket = cache.months[ym];
      if (bucket == null) continue;
      income += bucket.incomeAmount;
      expenseOnly += bucket.expenseAggAmount;
      savings += bucket.savingsTotalAmount;
    }
    final monthlyFixed = _fixedCostTotalForMonth(_currentMonth);
    final fixedCostTotal = _fixedCosts.isEmpty ? 0.0 : monthlyFixed * months;
    final hasFixed = _fixedCosts.isNotEmpty;
    final includeFixed = hasFixed && _includeFixedCosts;
    final expenseDisplay = expenseOnly + (includeFixed ? fixedCostTotal : 0.0);
    final net = income - expenseDisplay;
    final baseTitle = _fixedCostTitleForMonths(months);
    final fixedCostTitle =
        hasFixed && !_includeFixedCosts ? '$baseTitle(미포함)' : baseTitle;
    final expenseTitle = includeFixed ? '지출(고정비 포함)' : '지출';
    return SummaryTotals(
      income: income, expense: expenseOnly, savings: savings,
      fixedCost: fixedCostTotal, expenseDisplay: expenseDisplay, net: net,
      expenseTitle: expenseTitle, fixedCostTitle: fixedCostTitle,
    );
  }

  double _sumAmounts(Iterable<Transaction> transactions) =>
      transactions.fold<double>(0, (sum, tx) => sum + tx.amount);

  String _formatCurrency(double value, {bool includeSign = false}) {
    final formatted = _currencyFormat.format(value.abs());
    if (!includeSign) return '$formatted원';
    if (value > 0) return '+$formatted원';
    if (value < 0) return '-$formatted원';
    return '$formatted원';
  }

  String _formatAmountByType(double value, TransactionType type) {
    final formatted = _currencyFormat.format(value.abs());
    return '${type.sign}$formatted원';
  }

  String _formatSignedAmount(Transaction tx) =>
      '${tx.type.sign}${_currencyFormat.format(tx.amount)}원';

  String _formatDailyAverage(double total, int daysInMonth) {
    final average = (total / daysInMonth).round().toDouble();
    return _formatCurrency(average);
  }

  DateTime _monthStart(DateTime month) => DateTime(month.year, month.month);

  DateTime _monthEndExclusive(DateTime month) =>
      DateTime(month.year, month.month + 1);

  String _formatWon(double value) => '${_currencyFormat.format(value)}원';
}
