part of activity_household_estimator_service;

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
      'indicators': s.indicators
          .where((e) => e.isValid)
          .map((e) => e.toJson())
          .toList(),
    });
    await prefs.setString(_kSettings, raw);
  }

  static DateTime _startOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

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

    const ladder = <int>[10, 20, 30, 90, 180, 365];
    for (final next in ladder) {
      if (next < b) continue;
      if (next > maxW) continue;
      if (!candidates.contains(next)) candidates.add(next);
    }

    if (!candidates.contains(maxW)) candidates.add(maxW);

    candidates.sort();
    return candidates;
  }

  static bool _matchesName(String recordName, String indicatorName) {
    final r = recordName.trim();
    final k = indicatorName.trim();
    if (r.isEmpty || k.isEmpty) return false;

    return r.contains(k) || k.contains(r);
  }

  static Future<List<HealthConsumptionRecord>?> _loadAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final key = HealthGuardrailService.consumptionLogPrefsKey;
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(HealthConsumptionRecord.fromJson)
          .toList();
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
    final windowRecords = records
        .where((r) => r.timestamp.isAfter(since))
        .toList();
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

  static Future<ActivityHouseholdTrendComparison?> compareTrend({
    int? shortWindowDays,
    int baselineWindowDays = 90,
  }) async {
    final settings = await loadSettings();
    if (!settings.enabled) return null;

    final records = await _loadAllRecords();
    if (records == null || records.isEmpty) return null;

    final now = DateTime.now();
    final shortW = (shortWindowDays ?? settings.windowDays).clamp(
      3,
      settings.maxWindowDays,
    );
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

    final ratio = shortEstimate.estimatedPeople /
        baselineEstimate.estimatedPeople;
    if (!ratio.isFinite || ratio <= 0) return null;

    return ActivityHouseholdTrendComparison(
      shortWindow: shortEstimate,
      baselineWindow: baselineEstimate,
      ratio: double.parse(ratio.toStringAsFixed(2)),
    );
  }

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
      final estimate = _estimateForWindow(
        records: records,
        settings: settings,
        now: now,
        windowDays: windowDays,
      );
      if (estimate != null) {
        return estimate.copyWithUsedWindowDays(windowDays);
      }
    }

    return null;
  }
}

extension on ActivityHouseholdEstimate {
  ActivityHouseholdEstimate copyWithUsedWindowDays(int usedWindowDays) {
    return ActivityHouseholdEstimate(
      estimatedPeople: estimatedPeople,
      confidence: confidence,
      usedWindowDays: usedWindowDays,
      usedIndicators: usedIndicators,
    );
  }
}
