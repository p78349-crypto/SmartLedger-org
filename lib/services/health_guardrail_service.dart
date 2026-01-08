import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class HealthConsumptionRecord {
  final DateTime timestamp;
  final String itemName;
  final double amount;
  final List<String> tags;

  const HealthConsumptionRecord({
    required this.timestamp,
    required this.itemName,
    required this.amount,
    required this.tags,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestamp': timestamp.toIso8601String(),
        'itemName': itemName,
        'amount': amount,
        'tags': tags,
      };

  factory HealthConsumptionRecord.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final tags = <String>[];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        if (t is String) {
          final s = t.trim();
          if (s.isNotEmpty) tags.add(s);
        }
      }
    }

    return HealthConsumptionRecord(
      timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      itemName: (json['itemName'] as String?)?.trim() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      tags: tags,
    );
  }
}

@immutable
class HealthGuardrailSettings {
  final bool enabled;

  /// tag -> limit
  /// - if missing or <=0: treated as unlimited.
  final Map<String, double> weeklyLimits;
  final Map<String, double> monthlyLimits;

  const HealthGuardrailSettings({
    required this.enabled,
    required this.weeklyLimits,
    required this.monthlyLimits,
  });

  HealthGuardrailSettings copyWith({
    bool? enabled,
    Map<String, double>? weeklyLimits,
    Map<String, double>? monthlyLimits,
  }) {
    return HealthGuardrailSettings(
      enabled: enabled ?? this.enabled,
      weeklyLimits: weeklyLimits ?? this.weeklyLimits,
      monthlyLimits: monthlyLimits ?? this.monthlyLimits,
    );
  }
}

@immutable
class HealthGuardrailWarning {
  final String tag;
  final String period; // 'weekly' | 'monthly'
  final double total;
  final double limit;
  final String message;

  const HealthGuardrailWarning({
    required this.tag,
    required this.period,
    required this.total,
    required this.limit,
    required this.message,
  });
}

class HealthGuardrailService {
  HealthGuardrailService._();

  static const List<String> defaultTags = <String>[
    '탄수화물',
    '당류',
    '주류',
  ];

  static const String _kSettings = 'health_guardrail_settings_v1';
  static const String _kLog = 'health_consumption_log_v1';

  static String get consumptionLogPrefsKey => _kLog;

  // Prevent spamming: warn at most once per day per (tag, period).
  static String _warnKey(String tag, String period) =>
      'health_guardrail_last_warned_${tag}_$period';

  static HealthGuardrailSettings defaultSettings() {
    final weekly = <String, double>{};
    final monthly = <String, double>{};
    for (final t in defaultTags) {
      weekly[t] = 0.0;
      monthly[t] = 0.0;
    }

    return HealthGuardrailSettings(
      enabled: false,
      weeklyLimits: weekly,
      monthlyLimits: monthly,
    );
  }

  static Future<HealthGuardrailSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettings);
    if (raw == null || raw.trim().isEmpty) return defaultSettings();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return defaultSettings();

      final enabled = (decoded['enabled'] as bool?) ?? false;
      final weeklyRaw = decoded['weeklyLimits'];
      final monthlyRaw = decoded['monthlyLimits'];

      Map<String, double> parseLimits(dynamic value) {
        final out = <String, double>{};
        if (value is Map) {
          for (final entry in value.entries) {
            final k = entry.key;
            if (k is! String) continue;
            final v = entry.value;
            out[k.trim()] = (v is num) ? v.toDouble() : 0.0;
          }
        }
        return out;
      }

      final weekly = parseLimits(weeklyRaw);
      final monthly = parseLimits(monthlyRaw);

      // Ensure defaults exist.
      for (final t in defaultTags) {
        weekly.putIfAbsent(t, () => 0.0);
        monthly.putIfAbsent(t, () => 0.0);
      }

      return HealthGuardrailSettings(
        enabled: enabled,
        weeklyLimits: weekly,
        monthlyLimits: monthly,
      );
    } catch (_) {
      return defaultSettings();
    }
  }

  static Future<void> saveSettings(HealthGuardrailSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(<String, dynamic>{
      'enabled': s.enabled,
      'weeklyLimits': s.weeklyLimits,
      'monthlyLimits': s.monthlyLimits,
    });
    await prefs.setString(_kSettings, raw);
  }

  static Future<List<HealthConsumptionRecord>> _loadLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLog);
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

  static Future<void> _saveLog(List<HealthConsumptionRecord> records) async {
    final prefs = await SharedPreferences.getInstance();

    // keep only the last 500 records to bound storage
    final bounded = records.length <= 500
        ? records
        : records.sublist(records.length - 500);

    final raw = jsonEncode(bounded.map((e) => e.toJson()).toList());
    await prefs.setString(_kLog, raw);
  }

  static Future<List<HealthConsumptionRecord>> _appendLogRecord({
    required String itemName,
    required double amount,
    required List<String> tags,
    required DateTime timestamp,
  }) async {
    final record = HealthConsumptionRecord(
      timestamp: timestamp,
      itemName: itemName.trim(),
      amount: amount,
      tags: tags,
    );

    final records = await _loadLog();
    final next = <HealthConsumptionRecord>[...records, record];
    await _saveLog(next);
    return next;
  }

  static DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Future<bool> _canWarnToday(String tag, String period) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_warnKey(tag, period));
    final today = _startOfDay(DateTime.now());
    if (raw != null) {
      final prev = DateTime.tryParse(raw);
      if (prev != null && _isSameDay(prev, today)) return false;
    }
    await prefs.setString(_warnKey(tag, period), today.toIso8601String());
    return true;
  }

  static double _sumForTagSince(
    List<HealthConsumptionRecord> records,
    String tag,
    DateTime since,
  ) {
    var sum = 0.0;
    for (final r in records) {
      if (r.timestamp.isBefore(since)) continue;
      if (!r.tags.contains(tag)) continue;
      sum += r.amount;
    }
    return sum;
  }

  /// Records a usage event and returns a warning if weekly/monthly limit exceeded.
  ///
  /// - `amount` should be positive.
  /// - If settings disabled or tags empty, returns null.
  static Future<HealthGuardrailWarning?> recordUsageAndCheck({
    required String itemName,
    required double amount,
    required List<String> tags,
  }) async {
    final normalizedTags = tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    if (amount <= 0) return null;

    final now = DateTime.now();

    // Always log consumption events (even if guardrail disabled or tags empty)
    // so other local analytics features can use a complete decrement history.
    final next = await _appendLogRecord(
      itemName: itemName,
      amount: amount,
      tags: normalizedTags,
      timestamp: now,
    );

    final settings = await loadSettings();
    if (!settings.enabled) return null;
    if (normalizedTags.isEmpty) return null;

    final weekSince = now.subtract(const Duration(days: 7));
    final monthSince = now.subtract(const Duration(days: 30));

    for (final tag in normalizedTags) {
      final weeklyLimit = settings.weeklyLimits[tag] ?? 0.0;
      final monthlyLimit = settings.monthlyLimits[tag] ?? 0.0;

      if (weeklyLimit > 0) {
        final weeklyTotal = _sumForTagSince(next, tag, weekSince);
        if (weeklyTotal > weeklyLimit) {
          final canWarn = await _canWarnToday(tag, 'weekly');
          if (canWarn) {
            return HealthGuardrailWarning(
              tag: tag,
              period: 'weekly',
              total: weeklyTotal,
              limit: weeklyLimit,
              message: '이번 주 $tag 섭취가 많아요 (${weeklyTotal.toStringAsFixed(0)}/${weeklyLimit.toStringAsFixed(0)})',
            );
          }
        }
      }

      if (monthlyLimit > 0) {
        final monthlyTotal = _sumForTagSince(next, tag, monthSince);
        if (monthlyTotal > monthlyLimit) {
          final canWarn = await _canWarnToday(tag, 'monthly');
          if (canWarn) {
            return HealthGuardrailWarning(
              tag: tag,
              period: 'monthly',
              total: monthlyTotal,
              limit: monthlyLimit,
              message: '이번 달 $tag 섭취가 많아요 (${monthlyTotal.toStringAsFixed(0)}/${monthlyLimit.toStringAsFixed(0)})',
            );
          }
        }
      }
    }

    return null;
  }
}
