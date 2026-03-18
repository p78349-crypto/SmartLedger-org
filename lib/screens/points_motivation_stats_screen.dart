import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/transaction_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/number_formats.dart';
import '../utils/points_stats_utils.dart';
import '../utils/pref_keys.dart';

part 'points_motivation_stats_content.dart';
part 'points_motivation_stats_helpers.dart';

const int _lookbackDaysForRate = 90;
const double _defaultGoal100m = 100000000;

const List<_Horizon> _horizons = <_Horizon>[
  _Horizon('1일', 1),
  _Horizon('7일', 7),
  _Horizon('1달', 30),
  _Horizon('3개월', 90),
  _Horizon('6개월', 180),
  _Horizon('1년', 365),
  _Horizon('10년', 3650),
];

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

class _PointsMotivationStatsScreenState
    extends State<PointsMotivationStatsScreen> {
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
      final target =
          (prefs.getDouble(PrefKeys.project100mTargetAmountV1) ??
                  _defaultGoal100m)
              .clamp(1000000, 999999999999);
      final investRate =
          (prefs.getDouble(PrefKeys.project100mInvestRatePctV1) ?? 6).clamp(
            0.0,
            50.0,
          );

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
}
