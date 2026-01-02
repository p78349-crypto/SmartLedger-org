import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/points_stats_utils.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

@immutable
class _Horizon {
  const _Horizon(this.label, this.days);
  final String label;
  final int days;
}

class PointsMotivationStatsScreen extends StatefulWidget {
  const PointsMotivationStatsScreen({super.key, required this.accountName});
  final String accountName;

  @override
  State<PointsMotivationStatsScreen> createState() =>
      _PointsMotivationStatsScreenState();
}

class _PointsMotivationStatsScreenState extends State<PointsMotivationStatsScreen> {
  static const int _lookbackDaysForRate = 90;
  static const double _defaultGoal100m = 100000000;

  static const List<_Horizon> _horizons = <_Horizon>[
    _Horizon('1일', 1),
    _Horizon('7일', 7),
    _Horizon('1달', 30),
    _Horizon('3개월', 90),
    _Horizon('6개월', 180),
    _Horizon('1년', 365),
    _Horizon('10년', 3650),
  ];

  final _currencyFormat = NumberFormats.currency;

  double _targetAmount = _defaultGoal100m;
  double _investAnnualRatePct = 6;

  bool _loading = true;
  String? _error;

  Map<String, double> _recentByCategory = const <String, double>{};

  int _selectedIndex = 6; // default: 10년

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final target = (prefs.getDouble(PrefKeys.project100mTargetAmountV1) ??
              _defaultGoal100m)
          .clamp(1000000, 999999999999);
      final investRate =
          (prefs.getDouble(PrefKeys.project100mInvestRatePctV1) ?? 6)
              .clamp(0.0, 50.0);

      final service = TransactionService();
      await service.loadTransactions();
      final all = service.getTransactions(widget.accountName);

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: _lookbackDaysForRate));
      final recent = PointsStatsUtils.sumByCategory(
        all,
        start: start,
        end: now,
      );

      if (!mounted) return;
      setState(() {
        _targetAmount = target.toDouble();
        _investAnnualRatePct = investRate.toDouble();
        _recentByCategory = recent;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatWon(double value) => '${_currencyFormat.format(value)}원';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : (_error != null)
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('불러오기 실패: $_error'),
                ),
              )
            : _buildContent(theme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트 통계(동기)'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _load,
            icon: Icon(IconCatalog.refresh, color: scheme.onSurface),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final scheme = theme.colorScheme;
    final now = DateTime.now();

    final selected = _horizons[_selectedIndex];

    final totalRecent = PointsStatsUtils.sumTotal(_recentByCategory);
    final projectedByCategory = PointsStatsUtils.projectByCategory(
      _recentByCategory,
      lookbackDays: _lookbackDaysForRate,
      horizonDays: selected.days,
    );

    final projectedTotal = PointsStatsUtils.sumTotal(projectedByCategory);

    // Dynamic headline based on the selected horizon.
    final fvTotalHeadline = _futureValueOfRecurringSavings(
      totalRecent,
      lookbackDays: _lookbackDaysForRate,
      horizonDays: selected.days,
      annualRatePct: _investAnnualRatePct,
    );
    final fvScaleHeadline =
        (projectedTotal > 0) ? (fvTotalHeadline / projectedTotal) : 0.0;
    final fvByCategoryHeadline = <String, double>{
      for (final c in PointsStatsUtils.categories)
        c: (projectedByCategory[c] ?? 0) * fvScaleHeadline,
    };
    final topHeadline = _topCategory(fvByCategoryHeadline);

    // Always show a fixed 10-year headline for motivation.
    const tenYearsDays = 3650;
    final projectedByCategory10y = PointsStatsUtils.projectByCategory(
      _recentByCategory,
      lookbackDays: _lookbackDaysForRate,
      horizonDays: tenYearsDays,
    );
    final projectedTotal10y = PointsStatsUtils.sumTotal(projectedByCategory10y);
    final fvTotal10y = _futureValueOfRecurringSavings(
      totalRecent,
      lookbackDays: _lookbackDaysForRate,
      horizonDays: tenYearsDays,
      annualRatePct: _investAnnualRatePct,
    );
    final fvScale10y = (projectedTotal10y > 0) ? (fvTotal10y / projectedTotal10y) : 0.0;
    final fvByCategory10y = <String, double>{
      for (final c in PointsStatsUtils.categories)
        c: (projectedByCategory10y[c] ?? 0) * fvScale10y,
    };
    final top10y = _topCategory(fvByCategory10y);

    final fvTotal = _futureValueOfRecurringSavings(
      projectedTotal,
      lookbackDays: _lookbackDaysForRate,
      horizonDays: selected.days,
      annualRatePct: _investAnnualRatePct,
    );

    final fvScale = (projectedTotal > 0) ? (fvTotal / projectedTotal) : 0.0;
    final fvByCategory = <String, double>{
      for (final c in PointsStatsUtils.categories)
        c: (projectedByCategory[c] ?? 0) * fvScale,
    };

    final pct = (fvTotal <= 0)
      ? 0.0
      : ((fvTotal / _targetAmount) * 100).clamp(0.0, 100.0);

    if (totalRecent <= 0) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(IconCatalog.localOffer, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '포인트(혜택) 데이터가 없습니다',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '최근 $_lookbackDaysForRate일 동안 혜택/포인트 절감액이 잡히면 '
                    '카드/마트/온라인 쇼핑/편의점/기타로 자동 표시됩니다.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '팁: 거래 메모에 "혜택:카드=1200, 마트=500" 처럼 기록하거나 '
                    'benefit 입력 기능을 사용하면 더 정확해집니다.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMotivationCard(
          theme,
          horizonLabel: selected.label,
          fvTotal: fvTotalHeadline,
          simpleTotal: projectedTotal,
          topCategory: topHeadline.$1,
          topValue: topHeadline.$2,
          fvTotal10y: fvTotal10y,
          simpleTotal10y: projectedTotal10y,
          topCategory10y: top10y.$1,
          topValue10y: top10y.$2,
        ),
        const SizedBox(height: 12),
        _buildHorizonChips(theme),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(IconCatalog.localOffer, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '예상 포인트 절감액 (${selected.label})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatWon(fvTotal),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '기준: 최근 $_lookbackDaysForRate일 평균(오늘: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '가정: 절약한 돈을 모아 연 ${_investAnnualRatePct.toStringAsFixed(1)}%로 굴림(복리).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '목표 기여: ${pct.toStringAsFixed(2)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      '${_formatWon(fvTotal)} / ${_formatWon(_targetAmount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (fvTotal / _targetAmount).clamp(0.0, 1.0).toDouble(),
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 10),
                Text(
                  '단순 누적(이자 0%): ${_formatWon(projectedTotal)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '카테고리별 (${selected.label})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...PointsStatsUtils.categories.map((c) {
                  final v = fvByCategory[c] ?? 0;
                  final ratio = (fvTotal <= 0)
                      ? 0.0
                      : (v / fvTotal).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            c,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: ratio.toDouble(),
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatWon(v),
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 $_lookbackDaysForRate일 실제 합계(참고)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatWon(totalRecent),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '※ 이 화면은 "미래 동기" 목적이라 최근 패턴을 기반으로 단순 예측합니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationCard(
    ThemeData theme, {
    required String horizonLabel,
    required double fvTotal,
    required double simpleTotal,
    required String topCategory,
    required double topValue,
    required double fvTotal10y,
    required double simpleTotal10y,
    required String topCategory10y,
    required double topValue10y,
  }) {
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(IconCatalog.localOffer, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '작은 절약의 10년 효과',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '현재 패턴이면 $horizonLabel 뒤: ${_formatWon(fvTotal)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '단순 누적(이자 0%): ${_formatWon(simpleTotal)}'
              '  · 가장 큰 유입원: $topCategory ${_formatWon(topValue)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '10년 뒤(항상): ${_formatWon(fvTotal10y)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '단순 누적(이자 0%): ${_formatWon(simpleTotal10y)}'
              '  · 유입원 TOP: $topCategory10y ${_formatWon(topValue10y)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '포인트로 더 저렴하게 산 “가격 차이”를 모으면, 10년 뒤에는 꽤 큰 돈이 됩니다.\n'
              '부자가 되려면 작은 돈이 여러 곳에서 흘러들어오는 구조를 만들고, 꾸준히 유지하는 것이 핵심입니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, double) _topCategory(Map<String, double> byCategory) {
    var bestKey = PointsStatsUtils.catOther;
    var bestValue = 0.0;
    for (final c in PointsStatsUtils.categories) {
      final v = byCategory[c] ?? 0;
      if (v > bestValue) {
        bestValue = v;
        bestKey = c;
      }
    }
    return (bestKey, bestValue);
  }

  /// Converts a recent window total into a recurring monthly contribution,
  /// then computes future value using a monthly compounding approximation.
  double _futureValueOfRecurringSavings(
    double recentWindowTotal, {
    required int lookbackDays,
    required int horizonDays,
    required double annualRatePct,
  }) {
    if (recentWindowTotal <= 0) return 0;
    if (lookbackDays <= 0 || horizonDays <= 0) return 0;

    final avgDaily = recentWindowTotal / lookbackDays;
    final pmt = avgDaily * 30.0;
    final n = (horizonDays / 30.0).clamp(0.0, double.infinity);
    if (pmt <= 0 || n <= 0) return 0;

    final r = (annualRatePct / 100.0) / 12.0;
    if (r <= 0) {
      return pmt * n;
    }

    final factor = 1 + r;
    final powVal = math.pow(factor, n).toDouble();
    final fv = pmt * ((powVal - 1) / r);
    return fv.isFinite && fv > 0 ? fv : 0;
  }

  Widget _buildHorizonChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _horizons.length; i++)
          ChoiceChip(
            label: Text(_horizons[i].label),
            selected: _selectedIndex == i,
            onSelected: (v) {
              if (!v) return;
              setState(() => _selectedIndex = i);
            },
          ),
      ],
    );
  }
}

