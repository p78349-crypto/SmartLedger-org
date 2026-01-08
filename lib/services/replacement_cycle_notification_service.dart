import 'dart:convert';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:smart_ledger/services/health_guardrail_service.dart';
import 'package:smart_ledger/services/activity_household_estimator_service.dart';

class ReplacementCycleNotificationSettings {
  final bool enabled;
  final int maxWindowDays; // 60/180/365
  final int leadDays; // notify this many days before the predicted date
  final int minCycleDays; // ignore short-cycle consumables

  const ReplacementCycleNotificationSettings({
    required this.enabled,
    required this.maxWindowDays,
    required this.leadDays,
    required this.minCycleDays,
  });

  ReplacementCycleNotificationSettings copyWith({
    bool? enabled,
    int? maxWindowDays,
    int? leadDays,
    int? minCycleDays,
  }) {
    return ReplacementCycleNotificationSettings(
      enabled: enabled ?? this.enabled,
      maxWindowDays: maxWindowDays ?? this.maxWindowDays,
      leadDays: leadDays ?? this.leadDays,
      minCycleDays: minCycleDays ?? this.minCycleDays,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enabled': enabled,
        'maxWindowDays': maxWindowDays,
        'leadDays': leadDays,
        'minCycleDays': minCycleDays,
      };

  factory ReplacementCycleNotificationSettings.fromJson(Map<String, dynamic> json) {
    return ReplacementCycleNotificationSettings(
      enabled: (json['enabled'] as bool?) ?? false,
      maxWindowDays: (json['maxWindowDays'] as int?) ?? 365,
      leadDays: (json['leadDays'] as int?) ?? 7,
      minCycleDays: (json['minCycleDays'] as int?) ?? 30,
    );
  }
}

class ReplacementCycleNotificationService {
  ReplacementCycleNotificationService._internal();
  static final ReplacementCycleNotificationService instance =
      ReplacementCycleNotificationService._internal();

  static const String _kSettings = 'replacement_cycle_notify_settings_v1';
  static const String _kScheduledIds = 'replacement_cycle_notify_scheduled_ids_v1';

  static const String _androidChannelId = 'replacement_cycle';
  static const String _androidChannelName = '교체 주기 알림';
  static const String _androidChannelDescription = '소모품/교체형 품목의 예상 교체 시점을 알려줍니다.';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // ignore
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.max,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermissionIfNeeded() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final next = await Permission.notification.request();
    return next.isGranted;
  }

  Future<ReplacementCycleNotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettings);
    if (raw == null || raw.trim().isEmpty) return defaultSettings();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return defaultSettings();
      final s = ReplacementCycleNotificationSettings.fromJson(decoded);
      return ReplacementCycleNotificationSettings(
        enabled: s.enabled,
        maxWindowDays: s.maxWindowDays.clamp(60, 365),
        leadDays: s.leadDays.clamp(0, 60),
        minCycleDays: s.minCycleDays.clamp(7, 180),
      );
    } catch (_) {
      return defaultSettings();
    }
  }

  Future<void> saveSettings(ReplacementCycleNotificationSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = ReplacementCycleNotificationSettings(
      enabled: s.enabled,
      maxWindowDays: s.maxWindowDays.clamp(60, 365),
      leadDays: s.leadDays.clamp(0, 60),
      minCycleDays: s.minCycleDays.clamp(7, 180),
    );
    await prefs.setString(_kSettings, jsonEncode(normalized.toJson()));
  }

  ReplacementCycleNotificationSettings defaultSettings() {
    return const ReplacementCycleNotificationSettings(
      enabled: false,
      maxWindowDays: 365,
      leadDays: 7,
      minCycleDays: 30,
    );
  }

  int _stableIdForName(String name) {
    // Deterministic positive int32-ish id (FNV-1a).
    final s = name.trim();
    var hash = 0x811C9DC5;
    for (final c in s.codeUnits) {
      hash ^= c;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return max(1, hash);
  }

  Future<List<HealthConsumptionRecord>> _loadLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(HealthGuardrailService.consumptionLogPrefsKey);
    if (raw == null || raw.trim().isEmpty) return <HealthConsumptionRecord>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <HealthConsumptionRecord>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(HealthConsumptionRecord.fromJson)
          .where((r) => r.itemName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return <HealthConsumptionRecord>[];
    }
  }

  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<String?> _activityTrendLine() async {
    try {
      final trend = await ActivityHouseholdEstimatorService.compareTrend();
      if (trend == null) return null;

      final r = trend.ratio;
      if (!r.isFinite || r <= 0) return null;
      if (r >= 0.9 && r <= 1.1) return null;

      final label = r >= 1 ? '많아요' : '적어요';
      return '최근 소비(활동량)가 평소 대비 $r배 $label.';
    } catch (_) {
      return null;
    }
  }

  int _medianInt(List<int> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return ((sorted[mid - 1] + sorted[mid]) / 2).round();
  }

  tz.TZDateTime _next9am(tz.Location loc, DateTime from) {
    final d = DateTime(from.year, from.month, from.day, 9);
    final candidate = tz.TZDateTime.from(d, loc);
    if (candidate.isAfter(tz.TZDateTime.now(loc))) return candidate;
    return tz.TZDateTime.from(d.add(const Duration(days: 1)), loc);
  }

  Future<void> _cancelPreviouslyScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kScheduledIds);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final e in decoded) {
        final id = e is num ? e.toInt() : int.tryParse(e.toString());
        if (id != null) {
          await _plugin.cancel(id);
        }
      }
    } catch (_) {
      // ignore
    }

    await prefs.remove(_kScheduledIds);
  }

  Future<void> rescheduleFromPrefs() async {
    final settings = await loadSettings();
    if (!settings.enabled) return;

    await _ensureInit();

    final hasPerm = await requestPermissionIfNeeded();
    if (!hasPerm) return;

    await _cancelPreviouslyScheduled();

    final now = DateTime.now();
    final since = _startOfDay(now).subtract(Duration(days: settings.maxWindowDays));

    final records = (await _loadLog())
        .where((r) => r.timestamp.isAfter(since))
        .toList();
    if (records.isEmpty) return;

    final trendLine = await _activityTrendLine();

    // group timestamps by item
    final byItem = <String, List<DateTime>>{};
    for (final r in records) {
      byItem.putIfAbsent(r.itemName, () => <DateTime>[]).add(r.timestamp);
    }

    final scheduledIds = <int>[];
    final loc = tz.local;

    for (final entry in byItem.entries) {
      final itemName = entry.key.trim();
      final ts = [...entry.value]..sort();
      if (ts.length < 2) continue;

      // compute day-based intervals
      final dayTs = ts.map(_startOfDay).toList();
      final intervals = <int>[];
      for (var i = 1; i < dayTs.length; i++) {
        final diff = dayTs[i].difference(dayTs[i - 1]).inDays;
        if (diff > 0) intervals.add(diff);
      }
      if (intervals.isEmpty) continue;

      final medianCycle = _medianInt(intervals);
      if (medianCycle < settings.minCycleDays) continue;
      if (medianCycle > settings.maxWindowDays) continue;

      final last = dayTs.last;
      final predicted = last.add(Duration(days: medianCycle));
      final notifyAt = predicted.subtract(Duration(days: settings.leadDays));

      // If overdue or too soon, notify next 9am.
      final tzNotify = notifyAt.isAfter(now)
          ? tz.TZDateTime.from(
              DateTime(
                notifyAt.year,
                notifyAt.month,
                notifyAt.day,
                9,
              ),
              loc,
            )
          : _next9am(loc, now);

      const android = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      );
      const ios = DarwinNotificationDetails();
      const details = NotificationDetails(android: android, iOS: ios);

      final id = _stableIdForName(itemName);
      final daysSince = max(0, _startOfDay(now).difference(last).inDays);
      final title = '교체 시점이 다가와요: $itemName';
        final body = '예상 교체 주기: 약 $medianCycle일\n'
          '마지막 교체/사용 후: $daysSince일'
          '${trendLine == null ? '' : '\n$trendLine'}';

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzNotify,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      scheduledIds.add(id);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kScheduledIds, jsonEncode(scheduledIds));
  }
}
