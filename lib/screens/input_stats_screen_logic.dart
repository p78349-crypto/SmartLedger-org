part of 'input_stats_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension InputStatsScreenLogic on _InputStatsScreenState {
  DateTime _startOfLookback() {
    final now = DateTime.now();
    return now.subtract(const Duration(days: 183));
  }

  DateTime _startOfThisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  Future<void> _load() async {
    final scanStart = _startOfLookback();
    final monthStart = _startOfThisMonth();

    await TransactionService().loadTransactions();
    if (!mounted) return;

    final all = List<Transaction>.from(
      TransactionService().getTransactions(widget.accountName),
    );
    all.sort((a, b) => b.date.compareTo(a.date));
    final limited = all.take(_maxTxScan);

    final txs = limited
        .where((t) => !t.date.isBefore(scanStart))
        .toList(growable: false);

    final aliasMap = await StoreAliasService.loadMap(widget.accountName);

    final memoLookback = MemoStatsUtils.memoStats(txs);
    final txsThisMonth = txs
        .where((t) => !t.date.isBefore(monthStart))
        .toList(growable: false);
    final memoThisMonth = MemoStatsUtils.memoStats(txsThisMonth);

    final allEntries = await QuickSimpleExpenseInputHistoryService()
        .loadEntries(widget.accountName);

    final entries = allEntries
        .where((e) {
          return !e.createdAt.isBefore(scanStart);
        })
        .toList(growable: false);

    if (!mounted) return;

    setState(() {
      _memoThisMonth = memoThisMonth;
      _memoLookback = memoLookback;
      _entries = entries;
      _txs = txs;
      _storeAliasMap = aliasMap;
      _selectedStore = _pickDefaultStore(txs, aliasMap);
      _selectedBenefitStore = _pickDefaultStore(txs, aliasMap);
      _isLoading = false;
    });
  }

  String? _pickDefaultStore(
    List<Transaction> txs,
    Map<String, String> aliasMap,
  ) {
    final counts = <String, int>{};
    for (final t in txs) {
      final store = _storeKeyOf(t);
      if (store == null) continue;
      final canonical = StoreAliasService.resolve(store, aliasMap);
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

  String? _resolvedStoreKeyOf(Transaction t) {
    final raw = _storeKeyOf(t);
    if (raw == null) return null;
    return StoreAliasService.resolve(raw, _storeAliasMap);
  }

  String _formatWon(double value) => '${_currencyFormat.format(value)}원';
}
