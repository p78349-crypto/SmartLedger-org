part of 'in_app_screen_saver.dart';

class _DashboardData {
  final List<Asset> assets;
  final DashboardSummary dashboardSummary;
  final int todayOutflowCount;
  final int monthOutflowCount;
  final double plannedBudget;
  final double monthOutflow;
  final double emergencyBalance;
  final double emergencyUsedThisMonth;
  final _RecentTxSummary recent;
  final AssetFlowStats assetFlow;
  final List<_TrendPoint> trend;

  const _DashboardData({
    required this.assets,
    required this.dashboardSummary,
    required this.todayOutflowCount,
    required this.monthOutflowCount,
    required this.plannedBudget,
    required this.monthOutflow,
    required this.emergencyBalance,
    required this.emergencyUsedThisMonth,
    required this.recent,
    required this.assetFlow,
    required this.trend,
  });
}

class _SpendingStats {
  final double todayOutflow;
  final double monthOutflow;
  final int todayOutflowCount;
  final int monthOutflowCount;
  const _SpendingStats({
    required this.todayOutflow,
    required this.monthOutflow,
    required this.todayOutflowCount,
    required this.monthOutflowCount,
  });
}

_SpendingStats _computeSpending(List<dynamic> txs, {required DateTime now}) {
  double todayOutflow = 0;
  double monthOutflow = 0;
  int todayOutflowCount = 0;
  int monthOutflowCount = 0;

  for (final raw in txs) {
    final tx = raw as dynamic;
    if (tx.sign != '-') continue;
    final amount = (tx.amount as num).toDouble().abs();
    final d = tx.date as DateTime;
    if (d.year == now.year && d.month == now.month) {
      monthOutflow += amount;
      monthOutflowCount++;
    }
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      todayOutflow += amount;
      todayOutflowCount++;
    }
  }

  return _SpendingStats(
    todayOutflow: todayOutflow,
    monthOutflow: monthOutflow,
    todayOutflowCount: todayOutflowCount,
    monthOutflowCount: monthOutflowCount,
  );
}

class _EmergencyStats {
  final double balance;
  final double usedThisMonth;
  const _EmergencyStats({required this.balance, required this.usedThisMonth});
}

_EmergencyStats _computeEmergency(List<dynamic> txs, {required DateTime now}) {
  double balance = 0;
  double usedThisMonth = 0;
  for (final raw in txs) {
    final t = raw as dynamic;
    final amount = (t.amount as num).toDouble();
    final d = t.date as DateTime;
    balance += amount;
    if (d.year == now.year && d.month == now.month && amount < 0) {
      usedThisMonth += amount.abs();
    }
  }
  return _EmergencyStats(balance: balance, usedThisMonth: usedThisMonth);
}

class _RecentTxSummary {
  final double outflow7d;
  final double inflow7d;
  final int outflowCount7d;
  final int inflowCount7d;
  const _RecentTxSummary({
    required this.outflow7d,
    required this.inflow7d,
    required this.outflowCount7d,
    required this.inflowCount7d,
  });
}

_RecentTxSummary _computeRecentTransactions(List<dynamic> txs) {
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 7));

  double outflow = 0;
  double inflow = 0;
  int outflowCount = 0;
  int inflowCount = 0;

  for (final raw in txs) {
    final tx = raw as dynamic;
    final d = tx.date as DateTime;
    if (d.isBefore(start)) continue;
    final amount = (tx.amount as num).toDouble().abs();
    if (tx.sign == '-') {
      outflow += amount;
      outflowCount++;
    } else if (tx.sign == '+') {
      inflow += amount;
      inflowCount++;
    }
  }

  return _RecentTxSummary(
    outflow7d: outflow,
    inflow7d: inflow,
    outflowCount7d: outflowCount,
    inflowCount7d: inflowCount,
  );
}

class _TrendPoint {
  final String monthKey;
  final String label;
  final double totalAssets;
  const _TrendPoint({
    required this.monthKey,
    required this.label,
    required this.totalAssets,
  });
}

Future<void> _upsertMonthlyAssetSnapshot({
  required String accountName,
  required double totalAssets,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(PrefKeys.assetMonthlySnapshots);
  final Map<String, dynamic> root = raw != null && raw.isNotEmpty
      ? (jsonDecode(raw) as Map<String, dynamic>)
      : <String, dynamic>{};

  final key = DateFormatter.yearMonth.format(DateTime.now());
  final account = Map<String, dynamic>.from(root[accountName] as Map? ?? {});
  // Store a coarse-rounded value to avoid retaining sensitive precision.
  final rounded = (totalAssets / 10000000).round() * 10000000;
  account[key] = rounded;
  root[accountName] = account;

  await prefs.setString(PrefKeys.assetMonthlySnapshots, jsonEncode(root));
}

Future<List<_TrendPoint>> _loadMonthlyAssetTrend({
  required String accountName,
  required int months,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(PrefKeys.assetMonthlySnapshots);
  if (raw == null || raw.isEmpty) {
    return const <_TrendPoint>[];
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return const <_TrendPoint>[];
  final account = decoded[accountName];
  if (account is! Map) return const <_TrendPoint>[];

  final now = DateTime.now();
  final points = <_TrendPoint>[];
  for (var i = months - 1; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i);
    final key = DateFormatter.yearMonth.format(d);
    final label = DateFormatter.shortMonth.format(d);
    final rawValue = account[key];
    final value = rawValue is num ? rawValue.toDouble() : 0.0;
    points.add(_TrendPoint(monthKey: key, label: label, totalAssets: value));
  }
  return points;
}
