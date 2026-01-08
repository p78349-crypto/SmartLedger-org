import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/health_guardrail_service.dart';

@immutable
class ActivityIndicatorItem {
  final String name;
  final String unit;

  /// Expected average consumption per person per day.
  /// Example: eggs -> 0.5 (1 egg per 2 days)
  final double perPersonPerDay;

  const ActivityIndicatorItem({
    required this.name,
    required this.unit,
    required this.perPersonPerDay,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'unit': unit,
        'perPersonPerDay': perPersonPerDay,
      };

  factory ActivityIndicatorItem.fromJson(Map<String, dynamic> json) {
    return ActivityIndicatorItem(
      name: (json['name'] as String?)?.trim() ?? '',
      unit: (json['unit'] as String?)?.trim() ?? '',
      perPersonPerDay: (json['perPersonPerDay'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isValid => name.trim().isNotEmpty && perPersonPerDay > 0;
}

@immutable
class ActivityHouseholdEstimatorSettings {
  final bool enabled;
  final int windowDays;
  final int maxWindowDays;
  final List<ActivityIndicatorItem> indicators;

  const ActivityHouseholdEstimatorSettings({
    required this.enabled,
    required this.windowDays,
    required this.maxWindowDays,
    required this.indicators,
  });

  ActivityHouseholdEstimatorSettings copyWith({
    bool? enabled,
    int? windowDays,
    int? maxWindowDays,
    List<ActivityIndicatorItem>? indicators,
  }) {
    return ActivityHouseholdEstimatorSettings(
      enabled: enabled ?? this.enabled,
      windowDays: windowDays ?? this.windowDays,
      maxWindowDays: maxWindowDays ?? this.maxWindowDays,
      indicators: indicators ?? this.indicators,
    );
  }
}

@immutable
class ActivityHouseholdEstimate {
  final double estimatedPeople;
  final double confidence; // 0..1

  /// The actual window (days) used for the estimate.
  /// May be wider than the configured setting if data was insufficient.
  final int usedWindowDays;

  /// Which indicators contributed.
  final List<String> usedIndicators;

  const ActivityHouseholdEstimate({
    required this.estimatedPeople,
    required this.confidence,
    required this.usedWindowDays,
    required this.usedIndicators,
  });
}

@immutable
class ActivityHouseholdTrendComparison {
  final ActivityHouseholdEstimate shortWindow;
  final ActivityHouseholdEstimate baselineWindow;
  final double ratio; // short / baseline

  const ActivityHouseholdTrendComparison({
    required this.shortWindow,
    required this.baselineWindow,
    required this.ratio,
  });
}

class ActivityHouseholdEstimatorService {
  ActivityHouseholdEstimatorService._();

  static const String _kSettings = 'activity_household_estimator_settings_v1';

  static ActivityHouseholdEstimatorSettings defaultSettings() {
    return const ActivityHouseholdEstimatorSettings(
      enabled: false,
      windowDays: 10,
      maxWindowDays: 365,
      indicators: <ActivityIndicatorItem>[
        ActivityIndicatorItem(
          name: '달걀',
          unit: '개',
          perPersonPerDay: 0.5,
        ),
      ],
    );
  }

  static Future<ActivityHouseholdEstimatorSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettings);
    if (raw == null || raw.trim().isEmpty) return defaultSettings();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return defaultSettings();

      final enabled = (decoded['enabled'] as bool?) ?? false;
      final windowDays = (decoded['windowDays'] as int?) ?? 10;
      final maxWindowDays = (decoded['maxWindowDays'] as int?) ?? 365;

      final indicatorsRaw = decoded['indicators'];
      final indicators = <ActivityIndicatorItem>[];
      if (indicatorsRaw is List) {
        for (final e in indicatorsRaw) {
          if (e is Map<String, dynamic>) {
            final it = ActivityIndicatorItem.fromJson(e);
            if (it.isValid) indicators.add(it);
          }
        }
      }

      final normalizedMaxWindow = maxWindowDays.clamp(60, 365);
      final normalizedWindow = windowDays.clamp(3, normalizedMaxWindow);

      return ActivityHouseholdEstimatorSettings(
        enabled: enabled,
        windowDays: normalizedWindow,
        maxWindowDays: normalizedMaxWindow,
        indicators: indicators.isEmpty ? defaultSettings().indicators : indicators,
      );
    } catch (_) {
      return defaultSettings();
    }
  }

  static Future<void> saveSettings(ActivityHouseholdEstimatorSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedMaxWindow = s.maxWindowDays.clamp(60, 365);
    final raw = jsonEncode(<String, dynamic>{
      'enabled': s.enabled,
      'windowDays': s.windowDays.clamp(3, normalizedMaxWindow),
      'maxWindowDays': normalizedMaxWindow,
      'indicators': s.indicators.where((e) => e.isValid).map((e) => e.toJson()).toList(),
    });
    await prefs.setString(_kSettings, raw);
  }

  static DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static double _median(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  static List<int> _candidateWindows({
    required int base,
    required int maxWindowDays,
  }) {
    final maxW = maxWindowDays.clamp(60, 365);
    final b = base.clamp(3, maxW);
    final candidates = <int>[b];

    // Adaptive Engine v2: widen in coarse buckets to reduce noise and
    // capture weekly/monthly/seasonal patterns.
    // Sequence: 10 → 20 → 30 → 90 → 180 → 365 (capped by maxW).
    const ladder = <int>[10, 20, 30, 90, 180, 365];
    for (final next in ladder) {
      if (next < b) continue;
      if (next > maxW) continue;
      if (!candidates.contains(next)) candidates.add(next);
    }

    // Always try the configured maximum as a last resort (e.g., max=60).
    if (!candidates.contains(maxW)) candidates.add(maxW);

    // Ensure monotonic increase for predictable behaviour.
    candidates.sort();
    return candidates;
  }

  static bool _matchesName(String recordName, String indicatorName) {
    final r = recordName.trim();
    final k = indicatorName.trim();
    if (r.isEmpty || k.isEmpty) return false;

    // Keep it simple: substring match either way.
    return r.contains(k) || k.contains(r);
  }

  static Future<List<HealthConsumptionRecord>?> _loadAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(HealthGuardrailService.consumptionLogPrefsKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      final records = decoded
          .whereType<Map<String, dynamic>>()
          .map(HealthConsumptionRecord.fromJson)
          .toList();
      return records;
    } catch (_) {
      return null;
    }
  }

  static ActivityHouseholdEstimate? _estimateForWindow({
    required List<HealthConsumptionRecord> records,
    required ActivityHouseholdEstimatorSettings settings,
    required DateTime now,
    required int windowDays,
  }) {
    final w = windowDays.clamp(3, settings.maxWindowDays);
    final since = _startOfDay(now).subtract(Duration(days: w));
    final windowRecords = records.where((r) => r.timestamp.isAfter(since)).toList();
    if (windowRecords.isEmpty) return null;

    final estimates = <double>[];
    final usedIndicators = <String>[];
    for (final indicator in settings.indicators.where((e) => e.isValid)) {
      var sum = 0.0;
      for (final r in windowRecords) {
        if (_matchesName(r.itemName, indicator.name)) {
          sum += r.amount;
        }
      }
      final avgPerDay = sum / w;
      if (avgPerDay <= 0) continue;
      final est = avgPerDay / indicator.perPersonPerDay;
      if (est.isFinite && est > 0) {
        estimates.add(est);
        usedIndicators.add(indicator.name);
      }
    }

    if (estimates.isEmpty) return null;

    final median = _median(estimates);
    final countFactor = (usedIndicators.length / 3.0).clamp(0.2, 1.0);
    final windowFactor = (w / 180.0).clamp(0.4, 1.0);
    final confidence = (countFactor * windowFactor).clamp(0.2, 1.0);
    final estimatedPeople = median.clamp(0.5, 20.0);

    return ActivityHouseholdEstimate(
      estimatedPeople: double.parse(estimatedPeople.toStringAsFixed(1)),
      confidence: double.parse(confidence.toStringAsFixed(2)),
      usedWindowDays: w,
      usedIndicators: usedIndicators,
    );
  }

  /// Compares short-window activity vs baseline window (default 90d).
  ///
  /// Returns null if either window has insufficient data.
  static Future<ActivityHouseholdTrendComparison?> compareTrend({
    int? shortWindowDays,
    int baselineWindowDays = 90,
  }) async {
    final settings = await loadSettings();
    if (!settings.enabled) return null;

    final records = await _loadAllRecords();
    if (records == null || records.isEmpty) return null;

    final now = DateTime.now();
    final shortW = (shortWindowDays ?? settings.windowDays).clamp(3, settings.maxWindowDays);
    final baseW = baselineWindowDays.clamp(10, settings.maxWindowDays);

    final shortEstimate = _estimateForWindow(
      records: records,
      settings: settings,
      now: now,
      windowDays: shortW,
    );
    final baselineEstimate = _estimateForWindow(
      records: records,
      settings: settings,
      now: now,
      windowDays: baseW,
    );

    if (shortEstimate == null || baselineEstimate == null) return null;
    if (baselineEstimate.estimatedPeople <= 0) return null;

    final ratio = shortEstimate.estimatedPeople / baselineEstimate.estimatedPeople;
    if (!ratio.isFinite || ratio <= 0) return null;

    return ActivityHouseholdTrendComparison(
      shortWindow: shortEstimate,
      baselineWindow: baselineEstimate,
      ratio: double.parse(ratio.toStringAsFixed(2)),
    );
  }

  /// Estimate "active household people" from recent consumption logs.
  ///
  /// Uses HealthGuardrailService consumption log (triggered on decrements).
  /// For each configured indicator:
  /// - avgUsagePerDay = sum(amount) / windowDays
  /// - estimate = avgUsagePerDay / perPersonPerDay
  /// Aggregate via median across indicators to dampen outliers.
  static Future<ActivityHouseholdEstimate?> estimateNow() async {
    final settings = await loadSettings();
    if (!settings.enabled) return null;

    final now = DateTime.now();

    final records = await _loadAllRecords();
    if (records == null || records.isEmpty) return null;

    for (final windowDays in _candidateWindows(
      base: settings.windowDays,
      maxWindowDays: settings.maxWindowDays,
    )) {
      final since = _startOfDay(now).subtract(Duration(days: windowDays));
      final windowRecords = records.where((r) => r.timestamp.isAfter(since)).toList();
      if (windowRecords.isEmpty) continue;

      final estimates = <double>[];
      final usedIndicators = <String>[];

      for (final indicator in settings.indicators.where((e) => e.isValid)) {
        var sum = 0.0;
        for (final r in windowRecords) {
          if (_matchesName(r.itemName, indicator.name)) {
            sum += r.amount;
          }
        }

        final avgPerDay = sum / windowDays;
        if (avgPerDay <= 0) continue;

        final est = avgPerDay / indicator.perPersonPerDay;
        if (est.isFinite && est > 0) {
          estimates.add(est);
          usedIndicators.add(indicator.name);
        }
      }

      // Require at least one contributing indicator.
      if (estimates.isEmpty) continue;

      final median = _median(estimates);

      // Confidence: heuristic based on indicator count and window size.
      final countFactor = (usedIndicators.length / 3.0).clamp(0.2, 1.0);
      final windowFactor = (windowDays / 180.0).clamp(0.4, 1.0);
      final confidence = (countFactor * windowFactor).clamp(0.2, 1.0);

      // Clamp to a reasonable range.
      final estimatedPeople = median.clamp(0.5, 20.0);

      return ActivityHouseholdEstimate(
        estimatedPeople: double.parse(estimatedPeople.toStringAsFixed(1)),
        confidence: double.parse(confidence.toStringAsFixed(2)),
        usedWindowDays: windowDays,
        usedIndicators: usedIndicators,
      );
    }

    return null;
  }
}
