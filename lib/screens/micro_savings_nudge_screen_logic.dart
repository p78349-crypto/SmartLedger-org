part of 'micro_savings_nudge_screen.dart';

extension MicroSavingsNudgeLogic on _MicroSavingsNudgeScreenState {
  Future<void> _load() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    _projectSafeRatePct =
        prefs.getDouble(PrefKeys.project100mSafeRatePctV1) ?? 3.0;

    await TransactionService().loadTransactions();
    final all = TransactionService().getTransactions(widget.accountName);

    final thisMonthStart = _startOfThisMonth();
    final lookbackStart = _startOfLookback();

    final thisMonth = <Transaction>[];
    final lookback = <Transaction>[];

    for (final t in all) {
      if (t.date.isBefore(lookbackStart)) continue;
      lookback.add(t);
      if (!t.date.isBefore(thisMonthStart)) {
        thisMonth.add(t);
      }
    }

    if (!mounted) return;
    setState(() {
      _skippedThisMonth = _sumWhere(
        thisMonth,
        BenefitAggregationUtils.isSkippedSpendRecord,
      );
      _skippedLookback = _sumWhere(
        lookback,
        BenefitAggregationUtils.isSkippedSpendRecord,
      );
      _pointsThisMonth = _sumWhere(
        thisMonth,
        BenefitAggregationUtils.isSavedPointsRecord,
      );
      _pointsLookback = _sumWhere(
        lookback,
        BenefitAggregationUtils.isSavedPointsRecord,
      );
      _roundUpThisMonth = _sumWhere(
        thisMonth,
        BenefitAggregationUtils.isRoundUpRecord,
      );
      _roundUpLookback = _sumWhere(
        lookback,
        BenefitAggregationUtils.isRoundUpRecord,
      );
      _loading = false;
    });
  }

  Future<void> _onBatchSave() async {
    final title = _selectedTypeIndex == 0 ? '참은 소비' : '포인트 모으기';
    final memoTag = _selectedTypeIndex == 0
        ? BenefitAggregationUtils.skippedSpendMemoTag
        : BenefitAggregationUtils.savedPointsMemoTag;

    int savedCount = 0;
    for (int i = 0; i < 5; i++) {
      final parsed = CurrencyFormatter.parse(_amountControllers[i].text.trim());
      if (parsed == null || parsed <= 0) continue;

      final memoRaw = _memoControllers[i].text.trim();
      final memo = memoRaw.isEmpty ? memoTag : '$memoTag $memoRaw';

      final tx = Transaction(
        id: 'micro_${DateTime.now().millisecondsSinceEpoch}_$i',
        type: TransactionType.savings,
        description: title,
        amount: parsed.toDouble(),
        date: DateTime.now(),
        memo: memo,
        savingsAllocation: SavingsAllocation.assetIncrease,
      );

      await TransactionService().addTransaction(widget.accountName, tx);
      savedCount++;
    }

    if (savedCount > 0) {
      for (var c in _amountControllers) {
        c.clear();
      }
      for (var c in _memoControllers) {
        c.clear();
      }
      setState(() => _showCalculation = false);
      await _load();
      if (mounted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$savedCount건의 $title를 기록했습니다.')),
        );
      }
    }
  }
}
