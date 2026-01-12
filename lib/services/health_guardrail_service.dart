library health_guardrail_service;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'health_guardrail_service_impl.dart';

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
      timestamp:
          DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
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
