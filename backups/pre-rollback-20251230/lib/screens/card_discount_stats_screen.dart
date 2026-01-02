import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/monthly_agg_cache_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/benefit_aggregation_utils.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';
import 'package:smart_ledger/utils/date_formatter.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class CardDiscountStatsScreen extends StatefulWidget {
  const CardDiscountStatsScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<CardDiscountStatsScreen> createState() =>
      _CardDiscountStatsScreenState();
}

typedef _DiscountStats = ({double total, int count});

enum _OldDataViewMode {
  standard,
  yearSummaryOnly,
  monthSummaryOnly,
  selectedMonthDetail,
}

class _CardDiscountStatsScreenState extends State<CardDiscountStatsScreen> {
  bool _isLoading = true;
  bool _isUpdatingDetails = false;
  _OldDataViewMode _viewMode = _OldDataViewMode.standard;
  DateTime? _selectedMonth;
  _DiscountStats _thisMonth = (total: 0, count: 0);
  _DiscountStats _lookback = (total: 0, count: 0);
  _DiscountStats _year = (total: 0, count: 0);
  _DiscountStats _skippedThisMonth = (total: 0, count: 0);
  _DiscountStats _skippedLookback = (total: 0, count: 0);
  _DiscountStats _pointsThisMonth = (total: 0, count: 0);
  _DiscountStats _pointsLookback = (total: 0, count: 0);
  _DiscountStats _roundUpThisMonth = (total: 0, count: 0);
  _DiscountStats _roundUpLookback = (total: 0, count: 0);
  List<({DateTime month, double total, int count})> _yearMonths = const [];
  List<({String method, double total, int count})> _byMethodThisMonth = const [];
  List<({String method, double total, int count})> _byMethodLookback = const [];

  Map<String, List<({DateTime day, double total, int count})>>
  _daysByMethodThisMonth = const {};
  Map<String, List<({DateTime day, double total, int count})>>
  _daysByMethodLookback = const {};

  List<({String issuer, double total, int count})> _byIssuerThisMonth = const [];
  List<({String issuer, double total, int count})> _byIssuerLookback = const [];

  Map<String, List<({String card, double total, int count})>>
  _cardsByIssuerThisMonth = const {};
  Map<String, List<({String card, double total, int count})>>
  _cardsByIssuerLookback = const {};

  Map<String, Map<String, List<({DateTime day, double total, int count})>>>
  _daysByIssuerCardThisMonth = const {};
  Map<String, Map<String, List<({DateTime day, double total, int count})>>>
  _daysByIssuerCardLookback = const {};

    _DiscountStats _selectedMonthStats = (total: 0, count: 0);
    List<({String method, double total, int count})> _byMethodSelectedMonth =
      const [];
    Map<String, List<({DateTime day, double total, int count})>>
    _daysByMethodSelectedMonth = const {};
    List<({String issuer, double total, int count})> _byIssuerSelectedMonth =
      const [];
    Map<String, List<({String card, double total, int count})>>
    _cardsByIssuerSelectedMonth = const {};
    Map<String, Map<String, List<({DateTime day, double total, int count})>>>
    _daysByIssuerCardSelectedMonth = const {};

  final _currencyFormat = NumberFormats.currency;

  int _projectYears = 10;
  double _projectTargetAmount = 100000000;
  double _projectSafeRatePct = 3;
  double _projectInvestRatePct = 6;
  double _projectCashToInvestThresholdAmount = 100000;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProject100mPrefs());
    _startLoad();
  }

  Future<void> _loadProject100mPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final years = (prefs.getInt(PrefKeys.project100mYearsV1) ?? 10).clamp(1, 50);
    final target = (prefs.getDouble(PrefKeys.project100mTargetAmountV1) ?? 100000000)
        .clamp(0.0, double.infinity);
    final safeRate = (prefs.getDouble(PrefKeys.project100mSafeRatePctV1) ?? 3)
        .clamp(0.0, 100.0);
    final investRate =
      (prefs.getDouble(PrefKeys.project100mInvestRatePctV1) ?? 6)
        .clamp(0.0, 100.0);
    final threshold =
      (prefs.getDouble(PrefKeys.project100mCashToInvestThresholdAmountV1) ??
          100000)
        .clamp(0.0, double.infinity);

    if (!mounted) return;
    setState(() {
      _projectYears = years;
      _projectTargetAmount = target;
      _projectSafeRatePct = safeRate;
      _projectInvestRatePct = investRate;
      _projectCashToInvestThresholdAmount = threshold;
    });
  }

  double _fvMonthlyBenefitWithCashToInvestSwitch({
    required double monthly,
    required double cashAnnualRatePct,
    required double investAnnualRatePct,
    required int years,
    required double cashToInvestThresholdAmount,
  }) {
    if (monthly <= 0) return 0;
    final months = years * 12;
    if (months <= 0) return 0;

    final rCash = (cashAnnualRatePct / 100.0).clamp(0.0, 100.0) / 12.0;
    final rInvest = (investAnnualRatePct / 100.0).clamp(0.0, 100.0) / 12.0;
    final threshold = cashToInvestThresholdAmount.clamp(0.0, double.infinity);

    var cash = 0.0;
    var invest = 0.0;
    var switched = false;

    for (var i = 0; i < months; i++) {
      if (cash > 0 && rCash > 0) {
        cash *= 1 + rCash;
      }
      if (invest > 0 && rInvest > 0) {
        invest *= 1 + rInvest;
      }

      if (!switched) {
        cash += monthly;
        if (threshold == 0 || cash >= threshold) {
          invest += cash;
          cash = 0;
          switched = true;
        }
      } else {
        invest += monthly;
      }
    }

    return cash + invest;
  }

  Future<void> _startLoad({bool forceRebuildDirty = false}) async {
    setState(() {
      _isLoading = true;
      _isUpdatingDetails = false;

      _skippedThisMonth = (total: 0, count: 0);
      _skippedLookback = (total: 0, count: 0);
      _pointsThisMonth = (total: 0, count: 0);
      _pointsLookback = (total: 0, count: 0);
      _roundUpThisMonth = (total: 0, count: 0);
      _roundUpLookback = (total: 0, count: 0);

      // Clear detail sections to avoid showing stale data.
      _byMethodThisMonth = const [];
      _byMethodLookback = const [];
      _daysByMethodThisMonth = const {};
      _daysByMethodLookback = const {};
      _byIssuerThisMonth = const [];
      _byIssuerLookback = const [];
      _cardsByIssuerThisMonth = const {};
      _cardsByIssuerLookback = const {};
      _daysByIssuerCardThisMonth = const {};
      _daysByIssuerCardLookback = const {};
    });

    await _loadFastFromCache();
    unawaited(_loadBackgroundDetails(forceRebuildDirty: forceRebuildDirty));
  }

  _DiscountStats _sumCardDiscountFromCache(
    MonthlyAggCache cache,
    int months,
  ) {
    final now = DateTime.now();
    var total = 0.0;
    var count = 0;
    for (var i = 0; i < months; i++) {
      final dt = DateTime(now.year, now.month - i, 1);
      final ym = MonthlyAggCacheService.yearMonthOf(dt);
      final bucket = cache.months[ym];
      if (bucket == null) continue;
      total += bucket.cardDiscountAmount;
      count += bucket.cardDiscountCount;
    }
    return (total: total, count: count);
  }

  Future<void> _loadFastFromCache() async {
    final cache = await MonthlyAggCacheService().load(widget.accountName);
    if (!mounted) return;

    final now = DateTime.now();
    final yearMonths = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - i, 1);
      final ym = MonthlyAggCacheService.yearMonthOf(dt);
      final bucket = cache.months[ym];
      return (
        month: dt,
        total: bucket?.cardDiscountAmount ?? 0.0,
        count: bucket?.cardDiscountCount ?? 0,
      );
    }, growable: false);

    setState(() {
      _thisMonth = _sumCardDiscountFromCache(cache, 1);
      _lookback = _sumCardDiscountFromCache(cache, 6);
      _year = _sumCardDiscountFromCache(cache, 12);
      _yearMonths = yearMonths;
      _isLoading = false;
      _isUpdatingDetails = true;
    });
  }

  Future<void> _loadBackgroundDetails({required bool forceRebuildDirty}) async {
    // 1) Ensure monthly cache is up-to-date (dirty months only).
    // 2) Recompute recent drilldowns without sorting the full history.
    try {
      await TransactionService().loadTransactions();
      if (!mounted) return;
      final all = TransactionService().getTransactions(widget.accountName);

      await MonthlyAggCacheService().autoEnsureBuiltIfDirtyThrottled(
        accountName: widget.accountName,
        transactions: List<Transaction>.from(all),
        includeQuickInput: false,
        minIntervalSameMonth:
            forceRebuildDirty ? Duration.zero : const Duration(hours: 6),
      );

      final refreshedCache = await MonthlyAggCacheService().load(
        widget.accountName,
      );

      final yearStart = _startOfYearLookback();
      final scanStart = _startOfLookback();
      final monthStart = _startOfThisMonth();

      final txsYear = <Transaction>[];
      final txsLookback = <Transaction>[];
      final txsThisMonth = <Transaction>[];

      for (final t in all) {
        if (t.date.isBefore(yearStart)) continue;
        txsYear.add(t);
        if (!t.date.isBefore(scanStart)) {
          txsLookback.add(t);
        }
        if (!t.date.isBefore(monthStart)) {
          txsThisMonth.add(t);
        }
      }

      final byMethodLookback = _groupByPaymentMethod(txsLookback);
      final byMethodThisMonth = _groupByPaymentMethod(txsThisMonth);
      final daysByMethodThisMonth = _groupDaysByMethod(txsThisMonth);
      final daysByMethodLookback = _groupDaysByMethod(txsLookback);

      final skippedThisMonth = _sumSkippedSpend(txsThisMonth);
      final skippedLookback = _sumSkippedSpend(txsLookback);
      final pointsThisMonth = _sumSavedPoints(txsThisMonth);
      final pointsLookback = _sumSavedPoints(txsLookback);
      final roundUpThisMonth = _sumRoundUp(txsThisMonth);
      final roundUpLookback = _sumRoundUp(txsLookback);

      final issuerMonth = _groupIssuerCardDay(txsThisMonth);
      final issuerLookback = _groupIssuerCardDay(txsLookback);

      if (!mounted) return;
      setState(() {
        // Refresh totals from cache (fast path) in case dirty months changed.
        _thisMonth = _sumCardDiscountFromCache(refreshedCache, 1);
        _lookback = _sumCardDiscountFromCache(refreshedCache, 6);
        _year = _sumCardDiscountFromCache(refreshedCache, 12);

        final now = DateTime.now();
        _yearMonths = List.generate(12, (i) {
          final dt = DateTime(now.year, now.month - i, 1);
          final ym = MonthlyAggCacheService.yearMonthOf(dt);
          final bucket = refreshedCache.months[ym];
          return (
            month: dt,
            total: bucket?.cardDiscountAmount ?? 0.0,
            count: bucket?.cardDiscountCount ?? 0,
          );
        }, growable: false);

        _byMethodLookback = byMethodLookback;
        _byMethodThisMonth = byMethodThisMonth;
        _daysByMethodThisMonth = daysByMethodThisMonth;
        _daysByMethodLookback = daysByMethodLookback;

        _skippedThisMonth = skippedThisMonth;
        _skippedLookback = skippedLookback;

        _pointsThisMonth = pointsThisMonth;
        _pointsLookback = pointsLookback;

        _roundUpThisMonth = roundUpThisMonth;
        _roundUpLookback = roundUpLookback;

        _byIssuerThisMonth = issuerMonth.byIssuer;
        _byIssuerLookback = issuerLookback.byIssuer;
        _cardsByIssuerThisMonth = issuerMonth.cardsByIssuer;
        _cardsByIssuerLookback = issuerLookback.cardsByIssuer;
        _daysByIssuerCardThisMonth = issuerMonth.daysByIssuerCard;
        _daysByIssuerCardLookback = issuerLookback.daysByIssuerCard;
        _isUpdatingDetails = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUpdatingDetails = false);
    }
  }

  DateTime _startOfLookback() {
    final now = DateTime.now();
    // Month-based window to match MonthlyAggCache buckets.
    // "최근 6개월" = current month + previous 5 months.
    return DateTime(now.year, now.month - 5, 1);
  }

  DateTime _startOfYearLookback() {
    final now = DateTime.now();
    // Month-based window to match MonthlyAggCache buckets.
    // "최근 1년" = current month + previous 11 months.
    return DateTime(now.year, now.month - 11, 1);
  }

  DateTime _startOfThisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  _DiscountStats _sumSkippedSpend(Iterable<Transaction> txs) {
    var total = 0.0;
    var count = 0;
    for (final t in txs) {
      if (!BenefitAggregationUtils.isSkippedSpendRecord(t)) continue;
      final amt = t.amount;
      if (amt <= 0) continue;
      total += amt;
      count += 1;
    }
    return (total: total, count: count);
  }

  _DiscountStats _sumSavedPoints(Iterable<Transaction> txs) {
    var total = 0.0;
    var count = 0;
    for (final t in txs) {
      if (!BenefitAggregationUtils.isSavedPointsRecord(t)) continue;
      final amt = t.amount;
      if (amt <= 0) continue;
      total += amt;
      count += 1;
    }
    return (total: total, count: count);
  }

  _DiscountStats _sumRoundUp(Iterable<Transaction> txs) {
    var total = 0.0;
    var count = 0;
    for (final t in txs) {
      if (!BenefitAggregationUtils.isRoundUpRecord(t)) continue;
      final amt = t.amount;
      if (amt <= 0) continue;
      total += amt;
      count += 1;
    }
    return (total: total, count: count);
  }

  Future<void> _openSkippedSpendDialog() async {
    final amountController = TextEditingController();
    final memoController = TextEditingController();
    final amountFocusNode = FocusNode();
    final memoFocusNode = FocusNode();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!amountFocusNode.hasFocus) {
            amountFocusNode.requestFocus();
          }
          final text = amountController.text;
          amountController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: text.length,
          );
        });
        return AlertDialog(
          title: const Text('참은 소비 기록'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                focusNode: amountFocusNode,
                decoration: const InputDecoration(
                  labelText: '금액',
                  hintText: '예: 15000',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autofocus: true,
                onSubmitted: (_) => memoFocusNode.requestFocus(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memoController,
                focusNode: memoFocusNode,
                decoration: const InputDecoration(
                  labelText: '메모(선택)',
                  hintText: '예: 치킨 대신 집밥',
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),
              Text(
                '이 기록은 1억 프로젝트의 “혜택/절약”에 포함됩니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('기록'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      amountController.dispose();
      memoController.dispose();
      amountFocusNode.dispose();
      memoFocusNode.dispose();
      return;
    }

    final parsed = CurrencyFormatter.parse(amountController.text.trim());
    final memo = memoController.text.trim();

    amountController.dispose();
    memoController.dispose();
    amountFocusNode.dispose();
    memoFocusNode.dispose();

    final amount = (parsed ?? 0).toDouble();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금액을 확인해주세요.')),
      );
      return;
    }

    final tx = Transaction(
      id: 'skipped_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.savings,
      description: '참은 소비',
      amount: amount,
      date: DateTime.now(),
      paymentMethod: '현금',
      memo: memo.isEmpty
          ? BenefitAggregationUtils.skippedSpendMemoTag
          : '${BenefitAggregationUtils.skippedSpendMemoTag} $memo',
      savingsAllocation: SavingsAllocation.assetIncrease,
    );

    await TransactionService().addTransaction(widget.accountName, tx);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('참은 소비 ${_formatWon(amount)} 기록 완료')),
    );

    await _startLoad(forceRebuildDirty: true);
  }

  Future<void> _openSavedPointsDialog() async {
    final amountController = TextEditingController();
    final memoController = TextEditingController();
    final amountFocusNode = FocusNode();
    final memoFocusNode = FocusNode();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!amountFocusNode.hasFocus) {
            amountFocusNode.requestFocus();
          }
          final text = amountController.text;
          amountController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: text.length,
          );
        });
        return AlertDialog(
          title: const Text('포인트 모으기 기록'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                focusNode: amountFocusNode,
                decoration: const InputDecoration(
                  labelText: '금액',
                  hintText: '예: 3200',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autofocus: true,
                onSubmitted: (_) => memoFocusNode.requestFocus(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memoController,
                focusNode: memoFocusNode,
                decoration: const InputDecoration(
                  labelText: '메모(선택)',
                  hintText: '예: 카드 포인트 적립',
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),
              Text(
                '이 기록은 1억 프로젝트의 “혜택/절약”에 포함됩니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('기록'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      amountController.dispose();
      memoController.dispose();
      amountFocusNode.dispose();
      memoFocusNode.dispose();
      return;
    }

    final parsed = CurrencyFormatter.parse(amountController.text.trim());
    final memo = memoController.text.trim();

    amountController.dispose();
    memoController.dispose();
    amountFocusNode.dispose();
    memoFocusNode.dispose();

    final amount = (parsed ?? 0).toDouble();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금액을 확인해주세요.')),
      );
      return;
    }

    final tx = Transaction(
      id: 'points_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.savings,
      description: '포인트 모으기',
      amount: amount,
      date: DateTime.now(),
      paymentMethod: '현금',
      memo: memo.isEmpty
          ? BenefitAggregationUtils.savedPointsMemoTag
          : '${BenefitAggregationUtils.savedPointsMemoTag} $memo',
      savingsAllocation: SavingsAllocation.assetIncrease,
    );

    await TransactionService().addTransaction(widget.accountName, tx);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('포인트 ${_formatWon(amount)} 기록 완료')),
    );

    await _startLoad(forceRebuildDirty: true);
  }

  Widget _buildProjectFoundationCard(ThemeData theme) {
    final monthly = (
      _thisMonth.total +
      _skippedThisMonth.total +
      _pointsThisMonth.total +
      _roundUpThisMonth.total
    ).clamp(0.0, double.infinity);
    final annualized = monthly * 12;
    final fv = _fvMonthlyBenefitWithCashToInvestSwitch(
      monthly: monthly,
      cashAnnualRatePct: _projectSafeRatePct,
      investAnnualRatePct: _projectInvestRatePct,
      years: _projectYears,
      cashToInvestThresholdAmount: _projectCashToInvestThresholdAmount,
    );
    final pct = _projectTargetAmount > 0 ? (fv / _projectTargetAmount) * 100 : 0;

    final thresholdLabel = CurrencyFormatter.format(
      _projectCashToInvestThresholdAmount,
      showUnit: true,
    );

    final lookbackMonthlyAvg = (
          _lookback.total +
          _skippedLookback.total +
          _pointsLookback.total +
          _roundUpLookback.total
        ) /
        6.0;
    final avgLabel = CurrencyFormatter.format(lookbackMonthlyAvg, showUnit: true);
    final monthsToThreshold = lookbackMonthlyAvg > 0
      ? (_projectCashToInvestThresholdAmount / lookbackMonthlyAvg).ceil()
      : null;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '1억 프로젝트 초석',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '설정(자산 탭에서 변경한 값 사용)',
                  onPressed: _loadProject100mPrefs,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMiniMetric(
                    theme,
                    title: '이번달 카드할인',
                    value: _formatWon(_thisMonth.total),
                    sub: '${_thisMonth.count}건',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniMetric(
                    theme,
                    title: '이번달 참은소비',
                    value: _formatWon(_skippedThisMonth.total),
                    sub: '${_skippedThisMonth.count}건',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildMiniMetric(
              theme,
              title: '이번달 포인트 모으기',
              value: _formatWon(_pointsThisMonth.total),
              sub: '${_pointsThisMonth.count}건',
            ),
            const SizedBox(height: 10),
            _buildMiniMetric(
              theme,
              title: '이번달 잔돈 모으기(반올림)',
              value: _formatWon(_roundUpThisMonth.total),
              sub: '${_roundUpThisMonth.count}건',
            ),
            const SizedBox(height: 12),
            Text(
              '합계(이번달): ${_formatWon(monthly)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '1년 환산: ${_formatWon(annualized)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$_projectYears년 미래가치(연 ${_projectSafeRatePct.toStringAsFixed(1)}%→'
              '${_projectInvestRatePct.toStringAsFixed(1)}%): ${_formatWon(fv)}'
              '  · 목표 대비 ${pct.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '팁: 작은 할인/포인트는 먼저 비상금(현금)으로 모으고, 일정 금액이 되면 투자로 전환해보세요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '전환 기준: 비상금 $thresholdLabel 도달 시 투자로 전환(가정)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (monthsToThreshold != null) ...[
              const SizedBox(height: 4),
              Text(
                '최근 6개월 평균 $avgLabel → 약 $monthsToThreshold개월',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _openSkippedSpendDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('참은 소비 기록'),
                ),
                const SizedBox(width: 10),
                Text(
                  '최근 6개월 참은소비: ${_formatWon(_skippedLookback.total)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _openSavedPointsDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('포인트 모으기 기록'),
                ),
                const SizedBox(width: 10),
                Text(
                  '최근 6개월 포인트: ${_formatWon(_pointsLookback.total)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '최근 6개월 잔돈 모으기: ${_formatWon(_roundUpLookback.total)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '최근 6개월 잔돈 평균: ${_formatWon(_roundUpLookback.total / 6.0)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(
    ThemeData theme, {
    required String title,
    required String value,
    required String sub,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatWon(double value) => '${_currencyFormat.format(value)}원';

  String _monthLabel(DateTime month) {
    final y = month.year.toString().padLeft(4, '0');
    final m = month.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  Future<void> _pickMonthAndLoadDetail() async {
    final now = DateTime.now();
    final initial = _selectedMonth ?? DateTime(now.year, now.month, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      helpText: '월 선택(상세)',
    );

    if (picked == null || !mounted) return;
    final selected = DateTime(picked.year, picked.month, 1);
    setState(() {
      _viewMode = _OldDataViewMode.selectedMonthDetail;
      _selectedMonth = selected;
      _isLoading = true;
      _isUpdatingDetails = false;
    });

    await _loadSelectedMonthDetail(selected);
  }

  Future<void> _loadSelectedMonthDetail(DateTime month) async {
    await TransactionService().loadTransactions();
    if (!mounted) return;

    final all = TransactionService().getTransactions(widget.accountName);
    final monthTxs = all
        .where((t) => t.date.year == month.year && t.date.month == month.month)
        .toList(growable: false);

    final stats = _computeDiscountStats(monthTxs);
    final byMethod = _groupByPaymentMethod(monthTxs);
    final daysByMethod = _groupDaysByMethod(monthTxs);
    final issuer = _groupIssuerCardDay(monthTxs);

    if (!mounted) return;
    setState(() {
      _selectedMonthStats = stats;
      _byMethodSelectedMonth = byMethod;
      _daysByMethodSelectedMonth = daysByMethod;
      _byIssuerSelectedMonth = issuer.byIssuer;
      _cardsByIssuerSelectedMonth = issuer.cardsByIssuer;
      _daysByIssuerCardSelectedMonth = issuer.daysByIssuerCard;
      _isLoading = false;
    });
  }

  Widget _buildOldDataOptionsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오래된 자료 열람 옵션', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => setState(
                    () => _viewMode = _OldDataViewMode.yearSummaryOnly,
                  ),
                  child: const Text('1년 통계만'),
                ),
                OutlinedButton(
                  onPressed: () => setState(
                    () => _viewMode = _OldDataViewMode.monthSummaryOnly,
                  ),
                  child: const Text('월별 통계(요약)'),
                ),
                OutlinedButton(
                  onPressed: _pickMonthAndLoadDetail,
                  child: const Text('원하는 달(상세)'),
                ),
              ],
            ),
            if (_viewMode != _OldDataViewMode.standard) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(
                    () => _viewMode = _OldDataViewMode.standard,
                  ),
                  child: const Text('기본 보기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOlderMonthSummaryCard(ThemeData theme) {
    // Policy: show details only for the recent 6 months.
    // Older months (within 1 year window) are displayed as month-level summary.
    final older = _yearMonths.length <= 6
        ? const <({DateTime month, double total, int count})>[]
        : _yearMonths.sublist(6);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(IconCatalog.calendarViewMonth),
                const SizedBox(width: 8),
                Text('6개월 이전(월별 요약)', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            if (older.isEmpty)
              Text(
                '표시할 월별 요약이 없습니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...older.map(
                (e) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _monthLabel(e.month),
                    style: theme.textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    '${e.count}건',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Text(
                    _formatWon(e.total),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMonthDetailSection(ThemeData theme) {
    final month = _selectedMonth;
    if (month == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '월을 선택하면 해당 월 자료만 상세 분석합니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(IconCatalog.cardGiftcard),
                    const SizedBox(width: 8),
                    Text(
                      '${_monthLabel(month)} 카드 할인(상세)',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatWon(_selectedMonthStats.total),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedMonthStats.count}건',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildByMethodCard(
          theme,
          title: '${_monthLabel(month)} 카드별 할인',
          rows: _byMethodSelectedMonth,
        ),
        const SizedBox(height: 12),
        _buildCardDayDrilldown(
          theme,
          title: '${_monthLabel(month)} 카드별 → 날짜별 할인',
          methods: _byMethodSelectedMonth,
          daysByMethod: _daysByMethodSelectedMonth,
        ),
        const SizedBox(height: 12),
        _buildIssuerCardDayDrilldown(
          theme,
          title: '${_monthLabel(month)} 카드사별 → 카드별 → 날짜별',
          issuers: _byIssuerSelectedMonth,
          cardsByIssuer: _cardsByIssuerSelectedMonth,
          daysByIssuerCard: _daysByIssuerCardSelectedMonth,
        ),
      ],
    );
  }

  ({String issuer, String card}) _normalizeIssuerAndCard(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (issuer: '카드(미입력)', card: '카드(미입력)');
    }
    if (trimmed == '카드') {
      return (issuer: '카드(기타)', card: '카드(기타)');
    }

    // Preserve suffix like last 4 digits if present (e.g., "현대카드 1234").
    final last4 = RegExp(r'(\d{4})(?!\d)')
        .firstMatch(trimmed)
        ?.group(1);

    // Aggressive normalization for grouping.
    // - Remove spaces/punctuations.
    // - Strip generic words (카드/체크/신용/MASTER/VISA etc).
    var compact = trimmed
        .replaceAll(RegExp(r'[\s\-_/()\[\]{}.,]+'), '')
        .toLowerCase();

    compact = compact
        .replaceAll('카드', '')
        .replaceAll('체크', '')
        .replaceAll('신용', '')
        .replaceAll('master', '')
        .replaceAll('visa', '')
        .replaceAll('amex', '')
        .replaceAll('unionpay', '')
        .replaceAll('jcb', '')
        .replaceAll('bc', '비씨');

    String? issuer;
    // Korean issuer mapping (order matters).
    if (compact.contains('현대')) issuer = '현대';
    if (compact.contains('삼성')) issuer = '삼성';
    if (compact.contains('신한')) issuer = '신한';
    if (compact.contains('롯데')) issuer = '롯데';
    if (compact.contains('우리')) issuer = '우리';
    if (compact.contains('하나')) issuer = '하나';

    // KB / Kookmin
    if (issuer == null && (compact.contains('국민') || compact.contains('kb'))) {
      issuer = '국민';
    }

    // NH / Nonghyup
    if (issuer == null && (compact.contains('농협') || compact.contains('nh'))) {
      issuer = '농협';
    }

    // BC card
    if (issuer == null && (compact.contains('비씨') || compact.contains('bc'))) {
      issuer = '비씨';
    }

    // Citi
    if (issuer == null && (compact.contains('씨티') || compact.contains('citi'))) {
      issuer = '씨티';
    }

    // Kakao / Toss
    if (issuer == null && (compact.contains('카카오') || compact.contains('kakao'))) {
      issuer = '카카오';
    }
    if (issuer == null && (compact.contains('토스') || compact.contains('toss'))) {
      issuer = '토스';
    }

    // Fallback: keep a cleaned human-readable string.
    final cleaned = trimmed
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' 카드', '')
        .replaceAll('(카드)', '')
        .trim();

    final base = (issuer ?? cleaned).trim();
    if (base.isEmpty) {
      return (issuer: '카드(기타)', card: '카드(기타)');
    }

    final card = last4 == null ? base : '$base $last4';
    return (issuer: base, card: card);
  }

  String _normalizeCardKey(String raw) => _normalizeIssuerAndCard(raw).card;

  _DiscountStats _computeDiscountStats(Iterable<Transaction> txs) {
    var total = 0.0;
    var count = 0;

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      final charged = t.cardChargedAmount;
      if (charged == null) continue;

      final baseAbs = t.amount.abs();
      final discount = baseAbs - charged;
      if (discount <= 0) continue;

      total += discount;
      count += 1;
    }

    return (total: total, count: count);
  }

  List<({String method, double total, int count})> _groupByPaymentMethod(
    Iterable<Transaction> txs,
  ) {
    final map = <String, ({double total, int count})>{};

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      final charged = t.cardChargedAmount;
      if (charged == null) continue;

      final baseAbs = t.amount.abs();
      final discount = baseAbs - charged;
      if (discount <= 0) continue;

      final method = _normalizeCardKey(t.paymentMethod);

      final prev = map[method] ?? (total: 0.0, count: 0);
      map[method] = (total: prev.total + discount, count: prev.count + 1);
    }

    final list = map.entries
        .map((e) => (method: e.key, total: e.value.total, count: e.value.count))
        .toList(growable: false)
      ..sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  Map<String, List<({DateTime day, double total, int count})>>
  _groupDaysByMethod(
    Iterable<Transaction> txs,
  ) {
    final map =
        <String, Map<DateTime, ({double total, int count})>>{};

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      final charged = t.cardChargedAmount;
      if (charged == null) continue;

      final baseAbs = t.amount.abs();
      final discount = baseAbs - charged;
      if (discount <= 0) continue;

      final method = _normalizeCardKey(t.paymentMethod);
      final day = DateTime(t.date.year, t.date.month, t.date.day);

      final dayMap = map.putIfAbsent(
        method,
        () => <DateTime, ({double total, int count})>{},
      );
      final prev = dayMap[day] ?? (total: 0.0, count: 0);
      dayMap[day] = (total: prev.total + discount, count: prev.count + 1);
    }

    return map.map((method, dayMap) {
      final list = dayMap.entries
          .map((e) => (day: e.key, total: e.value.total, count: e.value.count))
          .toList(growable: false)
        ..sort((a, b) => b.day.compareTo(a.day));
      return MapEntry(method, list);
    });
  }

  ({
    List<({String issuer, double total, int count})> byIssuer,
    Map<String, List<({String card, double total, int count})>> cardsByIssuer,
    Map<String, Map<String, List<({DateTime day, double total, int count})>>>
    daysByIssuerCard,
  }) _groupIssuerCardDay(Iterable<Transaction> txs) {
    final issuerTotals = <String, ({double total, int count})>{};
    final cardTotalsByIssuer = <String, Map<String, ({double total, int count})>>{};
    final dayTotalsByIssuerCard =
        <String, Map<String, Map<DateTime, ({double total, int count})>>>{};

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      final charged = t.cardChargedAmount;
      if (charged == null) continue;

      final baseAbs = t.amount.abs();
      final discount = baseAbs - charged;
      if (discount <= 0) continue;

      final norm = _normalizeIssuerAndCard(t.paymentMethod);
      final issuer = norm.issuer;
      final card = norm.card;
      final day = DateTime(t.date.year, t.date.month, t.date.day);

      final issuerPrev = issuerTotals[issuer] ?? (total: 0.0, count: 0);
      issuerTotals[issuer] =
          (total: issuerPrev.total + discount, count: issuerPrev.count + 1);

      final cardMap = cardTotalsByIssuer.putIfAbsent(
        issuer,
        () => <String, ({double total, int count})>{},
      );
      final cardPrev = cardMap[card] ?? (total: 0.0, count: 0);
      cardMap[card] =
          (total: cardPrev.total + discount, count: cardPrev.count + 1);

      final issuerDayMap = dayTotalsByIssuerCard.putIfAbsent(
        issuer,
        () => <String, Map<DateTime, ({double total, int count})>>{},
      );
      final cardDayMap = issuerDayMap.putIfAbsent(
        card,
        () => <DateTime, ({double total, int count})>{},
      );
      final dayPrev = cardDayMap[day] ?? (total: 0.0, count: 0);
      cardDayMap[day] =
          (total: dayPrev.total + discount, count: dayPrev.count + 1);
    }

    final byIssuer = issuerTotals.entries
        .map((e) => (issuer: e.key, total: e.value.total, count: e.value.count))
        .toList(growable: false)
      ..sort((a, b) => b.total.compareTo(a.total));

    final cardsByIssuer = cardTotalsByIssuer.map((issuer, cardMap) {
      final cards = cardMap.entries
          .map(
            (e) => (card: e.key, total: e.value.total, count: e.value.count),
          )
          .toList(growable: false)
        ..sort((a, b) => b.total.compareTo(a.total));
      return MapEntry(issuer, cards);
    });

    final daysByIssuerCard = dayTotalsByIssuerCard.map((issuer, cardDayMaps) {
      final cards = cardDayMaps.map((card, dayMap) {
        final days = dayMap.entries
            .map(
              (e) => (day: e.key, total: e.value.total, count: e.value.count),
            )
            .toList(growable: false)
          ..sort((a, b) => b.day.compareTo(a.day));
        return MapEntry(card, days);
      });
      return MapEntry(issuer, cards);
    });

    return (
      byIssuer: byIssuer,
      cardsByIssuer: cardsByIssuer,
      daysByIssuerCard: daysByIssuerCard,
    );
  }

  Widget _buildCardDayDrilldown(
    ThemeData theme, {
    required String title,
    required List<({String method, double total, int count})> methods,
    required Map<String, List<({DateTime day, double total, int count})>>
    daysByMethod,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(IconCatalog.creditCard),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            if (methods.isEmpty)
              Text(
                '표시할 카드별 할인 내역이 없습니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...methods.map((m) {
                final rows = daysByMethod[m.method] ?? const [];
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    m.method,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '할인 ${_formatWon(m.total)} · ${m.count}건',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  children: rows.isEmpty
                      ? [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '날짜별 내역이 없습니다.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ]
                      : rows
                          .map(
                            (e) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(IconCatalog.arrowDownward),
                              title: Text(
                                DateFormatter.mmdd.format(e.day),
                                style: theme.textTheme.bodyMedium,
                              ),
                              subtitle: Text(
                                '${e.count}건',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Text(
                                _formatWon(e.total),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuerCardDayDrilldown(
    ThemeData theme, {
    required String title,
    required List<({String issuer, double total, int count})> issuers,
    required Map<String, List<({String card, double total, int count})>>
    cardsByIssuer,
    required Map<String, Map<String, List<({DateTime day, double total, int count})>>>
    daysByIssuerCard,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(IconCatalog.creditCard),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            if (issuers.isEmpty)
              Text(
                '표시할 카드사 할인 내역이 없습니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...issuers.map((issuerStat) {
                final issuer = issuerStat.issuer;
                final cards = cardsByIssuer[issuer] ?? const [];
                final issuerDays = daysByIssuerCard[issuer] ?? const {};

                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    issuer,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '할인 ${_formatWon(issuerStat.total)} · ${issuerStat.count}건',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  children: cards.isEmpty
                      ? [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '카드 내역이 없습니다.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ]
                      : cards.map((cardStat) {
                          final card = cardStat.card;
                          final rows = issuerDays[card] ?? const [];

                          return ExpansionTile(
                            tilePadding: const EdgeInsets.only(left: 16),
                            childrenPadding: EdgeInsets.zero,
                            title: Text(
                              card,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                            subtitle: Text(
                              '할인 ${_formatWon(cardStat.total)} · ${cardStat.count}건',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            children: rows.isEmpty
                                ? [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      bottom: 12,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '날짜별 내역이 없습니다.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ),
                                ]
                                : rows
                                    .map(
                                      (e) => ListTile(
                                        dense: true,
                                        contentPadding: const EdgeInsets.only(
                                          left: 32,
                                          right: 0,
                                        ),
                                        leading:
                                            const Icon(IconCatalog.arrowDownward),
                                        title: Text(
                                          DateFormatter.mmdd.format(e.day),
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        subtitle: Text(
                                          '${e.count}건',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        trailing: Text(
                                          _formatWon(e.total),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                          );
                        }).toList(growable: false),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildByMethodCard(
    ThemeData theme, {
    required String title,
    required List<({String method, double total, int count})> rows,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(IconCatalog.creditCard),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text(
                '표시할 할인 내역이 없습니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...rows.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.method,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatWon(e.total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${e.count}건',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 할인 통계'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(IconCatalog.refresh),
            onPressed: () => _startLoad(forceRebuildDirty: true),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '카드 결제금액이 더 작을 때(지출 기준) 자동 합산',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOldDataOptionsCard(theme),
                  const SizedBox(height: 12),

                  _buildProjectFoundationCard(theme),
                  const SizedBox(height: 12),

                  if (_viewMode == _OldDataViewMode.selectedMonthDetail) ...[
                    _buildSelectedMonthDetailSection(theme),
                  ] else if (_viewMode == _OldDataViewMode.yearSummaryOnly) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(IconCatalog.cardGiftcard),
                                const SizedBox(width: 8),
                                Text(
                                  '최근 1년 카드 할인 합계',
                                  style: theme.textTheme.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatWon(_year.total),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_year.count}건',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOlderMonthSummaryCard(theme),
                  ] else if (_viewMode == _OldDataViewMode.monthSummaryOnly) ...[
                    _buildOlderMonthSummaryCard(theme),
                  ] else ...[
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(IconCatalog.cardGiftcard),
                              const SizedBox(width: 8),
                              Text(
                                '이번달 카드 할인 합계',
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatWon(_thisMonth.total),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_thisMonth.count}건',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(IconCatalog.cardGiftcard),
                              const SizedBox(width: 8),
                              Text(
                                '최근 6개월 카드 할인 합계',
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatWon(_lookback.total),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_lookback.count}건',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(IconCatalog.cardGiftcard),
                              const SizedBox(width: 8),
                              Text(
                                '최근 1년 카드 할인 합계',
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatWon(_year.total),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_year.count}건',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_isUpdatingDetails) ...[
                    const SizedBox(height: 12),
                    _buildByMethodCard(
                      theme,
                      title: '이번달 카드별 할인',
                      rows: _byMethodThisMonth,
                    ),
                    const SizedBox(height: 12),
                    _buildByMethodCard(
                      theme,
                      title: '최근 6개월 카드별 할인',
                      rows: _byMethodLookback,
                    ),
                    const SizedBox(height: 12),
                    _buildCardDayDrilldown(
                      theme,
                      title: '이번달 카드별 → 날짜별 할인',
                      methods: _byMethodThisMonth,
                      daysByMethod: _daysByMethodThisMonth,
                    ),
                    const SizedBox(height: 12),
                    _buildCardDayDrilldown(
                      theme,
                      title: '최근 6개월 카드별 → 날짜별 할인',
                      methods: _byMethodLookback,
                      daysByMethod: _daysByMethodLookback,
                    ),
                    const SizedBox(height: 12),
                    _buildIssuerCardDayDrilldown(
                      theme,
                      title: '이번달 카드사별 → 카드별 → 날짜별',
                      issuers: _byIssuerThisMonth,
                      cardsByIssuer: _cardsByIssuerThisMonth,
                      daysByIssuerCard: _daysByIssuerCardThisMonth,
                    ),
                    const SizedBox(height: 12),
                    _buildIssuerCardDayDrilldown(
                      theme,
                      title: '최근 6개월 카드사별 → 카드별 → 날짜별',
                      issuers: _byIssuerLookback,
                      cardsByIssuer: _cardsByIssuerLookback,
                      daysByIssuerCard: _daysByIssuerCardLookback,
                    ),
                    const SizedBox(height: 12),
                    _buildOlderMonthSummaryCard(theme),
                  ],
                  ],
                ],
              ),
      ),
    );
  }
}

