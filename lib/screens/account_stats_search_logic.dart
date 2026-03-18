// ignore_for_file: invalid_use_of_protected_member
part of 'account_stats_search_screen.dart';

/// 검색 실행 및 프로젝션 계산 로직.
extension AccountStatsSearchLogic on _AccountStatsSearchScreenState {
  void _runSearch(TransactionService service, String rawQuery) {
    final seq = ++_searchSeq;
    final query = rawQuery.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const <StatsSearchResult>[];
        _lastPlan = null;
        _tenYearAggTotal = null;
        _tenYearAggLoading = false;
        _pointProjectionLoading = false;
        _pointProjectionMonthlyBase = null;
        _pointProjectionFiveYear = null;
        _pointProjectionTenYear = null;
        _pointProjectionMonthlyBase3mAvg = null;
        _pointProjectionFiveYear3mAvg = null;
        _pointProjectionTenYear3mAvg = null;
        _pointProjectionMonthlyBase6mAvg = null;
        _pointProjectionFiveYear6mAvg = null;
        _pointProjectionTenYear6mAvg = null;
        _pointProjectionAnnualRateUsed =
            _AccountStatsSearchScreenState._defaultAnnualRatePercent;
      });
      return;
    }

    final plan = parseTxSearchPlan(query);
    setState(() => _lastPlan = plan);

    _maybeLoadTenYearAgg(seq, plan);
    _maybeLoadPointProjection(seq, plan);

    () async {
      final txs = service.getTransactions(widget.accountName);
      final byId = <String, Transaction>{for (final tx in txs) tx.id: tx};
      final matched = <StatsSearchResult>[];

      if (plan.ftsQuery.trim().isNotEmpty) {
        final hits = await TransactionFtsIndexService().search(
          accountName: widget.accountName,
          query: plan.ftsQuery,
          memoOnly: widget.memoOnly,
        );
        if (!mounted || seq != _searchSeq) return;
        for (final h in hits) {
          final tx = byId[h.transactionId];
          if (tx == null) continue;
          if (!matchesTxFilters(tx, plan.filters)) continue;
          matched.add(
            StatsSearchResult(accountName: widget.accountName, transaction: tx),
          );
        }
      } else {
        final sorted = List<Transaction>.from(txs)
          ..sort((a, b) => b.date.compareTo(a.date));
        final limited =
            sorted.length > _AccountStatsSearchScreenState._fallbackScanMax
            ? sorted.sublist(0, _AccountStatsSearchScreenState._fallbackScanMax)
            : sorted;
        for (final tx in limited) {
          if (!matchesTxFilters(tx, plan.filters)) continue;
          matched.add(
            StatsSearchResult(accountName: widget.accountName, transaction: tx),
          );
        }
      }

      matched.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
      setState(() => _results = matched);
    }();
  }

  String _ym(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  bool _isBenefitQuery(TxSearchPlan plan) {
    final f = plan.filters;
    return f.benefitOnly ||
        f.pointsOnly ||
        f.minBenefit != null ||
        f.maxBenefit != null;
  }

  double _effectiveAnnualRatePercent(TxSearchPlan plan) {
    final v = plan.filters.annualRatePercent;
    if (v == null) {
      return _AccountStatsSearchScreenState._defaultAnnualRatePercent;
    }
    if (v < 0) return 0;
    return v;
  }

  double _futureValueMonthlyContribution(
    double monthlyContribution,
    double annualRatePercent,
    int months,
  ) {
    if (monthlyContribution <= 0) return 0;
    final annualRate = annualRatePercent / 100.0;
    final i = annualRate / 12.0;
    if (i == 0) return monthlyContribution * months;
    final factor = (math.pow(1 + i, months) - 1) / i;
    return monthlyContribution * factor.toDouble();
  }

  void _maybeLoadPointProjection(int seq, TxSearchPlan plan) {
    if (widget.memoOnly || !plan.filters.pointsOnly) {
      setState(() {
        _pointProjectionLoading = false;
        _pointProjectionMonthlyBase = null;
        _pointProjectionFiveYear = null;
        _pointProjectionTenYear = null;
        _pointProjectionMonthlyBase3mAvg = null;
        _pointProjectionFiveYear3mAvg = null;
        _pointProjectionTenYear3mAvg = null;
        _pointProjectionMonthlyBase6mAvg = null;
        _pointProjectionFiveYear6mAvg = null;
        _pointProjectionTenYear6mAvg = null;
        _pointProjectionAnnualRateUsed =
            _AccountStatsSearchScreenState._defaultAnnualRatePercent;
      });
      return;
    }

    setState(() {
      _pointProjectionLoading = true;
      _pointProjectionMonthlyBase = null;
      _pointProjectionFiveYear = null;
      _pointProjectionTenYear = null;
      _pointProjectionMonthlyBase3mAvg = null;
      _pointProjectionFiveYear3mAvg = null;
      _pointProjectionTenYear3mAvg = null;
      _pointProjectionMonthlyBase6mAvg = null;
      _pointProjectionFiveYear6mAvg = null;
      _pointProjectionTenYear6mAvg = null;
      _pointProjectionAnnualRateUsed = _effectiveAnnualRatePercent(plan);
    });

    () async {
      final svc = TransactionBenefitMonthlyAggService();
      final now = DateTime.now();
      final ym = _ym(now);
      final start3mYm = _ym(DateTime(now.year, now.month - 2));
      final start6mYm = _ym(DateTime(now.year, now.month - 5));
      await svc.ensureAggregatedFromPrefs();

      Future<double> sumPoints(String startYm, String endYm) async {
        final a = await svc.sumTotal(
          accountName: widget.accountName,
          benefitTypeContains: '포인트',
          startYm: startYm,
          endYm: endYm,
        );
        final b = await svc.sumTotal(
          accountName: widget.accountName,
          benefitTypeContains: '적립',
          startYm: startYm,
          endYm: endYm,
        );
        final c = await svc.sumTotal(
          accountName: widget.accountName,
          benefitTypeContains: 'point',
          startYm: startYm,
          endYm: endYm,
        );
        return a + b + c;
      }

      final monthlyBase = await sumPoints(ym, ym);
      final threeMonthAvg = (await sumPoints(start3mYm, ym)) / 3.0;
      final sixMonthAvg = (await sumPoints(start6mYm, ym)) / 6.0;

      final rate = _effectiveAnnualRatePercent(plan);
      final fv = _futureValueMonthlyContribution;

      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _pointProjectionLoading = false;
        _pointProjectionMonthlyBase = monthlyBase;
        _pointProjectionFiveYear = fv(monthlyBase, rate, 60);
        _pointProjectionTenYear = fv(monthlyBase, rate, 120);
        _pointProjectionMonthlyBase3mAvg = threeMonthAvg;
        _pointProjectionFiveYear3mAvg = fv(threeMonthAvg, rate, 60);
        _pointProjectionTenYear3mAvg = fv(threeMonthAvg, rate, 120);
        _pointProjectionMonthlyBase6mAvg = sixMonthAvg;
        _pointProjectionFiveYear6mAvg = fv(sixMonthAvg, rate, 60);
        _pointProjectionTenYear6mAvg = fv(sixMonthAvg, rate, 120);
        _pointProjectionAnnualRateUsed = rate;
      });
    }();
  }

  void _maybeLoadTenYearAgg(int seq, TxSearchPlan plan) {
    if (widget.memoOnly || !_isBenefitQuery(plan)) {
      setState(() {
        _tenYearAggTotal = null;
        _tenYearAggLoading = false;
      });
      return;
    }

    setState(() => _tenYearAggLoading = true);

    () async {
      final svc = TransactionBenefitMonthlyAggService();
      final now = DateTime.now();
      final startYm = _ym(DateTime(now.year, now.month - 119));
      final endYm = _ym(now);
      await svc.ensureAggregatedFromPrefs();

      double total;
      if (plan.filters.pointsOnly) {
        final a = await svc.sumTotal(
          accountName: widget.accountName,
          benefitTypeContains: '포인트',
          startYm: startYm,
          endYm: endYm,
        );
        final b = await svc.sumTotal(
          accountName: widget.accountName,
          benefitTypeContains: '적립',
          startYm: startYm,
          endYm: endYm,
        );
        final c = await svc.sumTotal(
          accountName: widget.accountName,
          benefitTypeContains: 'point',
          startYm: startYm,
          endYm: endYm,
        );
        total = a + b + c;
      } else {
        total = await svc.sumTotal(
          accountName: widget.accountName,
          startYm: startYm,
          endYm: endYm,
        );
      }

      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _tenYearAggTotal = total;
        _tenYearAggLoading = false;
      });
    }();
  }
}
