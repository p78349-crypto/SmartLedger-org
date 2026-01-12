library activity_household_estimator_service;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_guardrail_service.dart';

part 'activity_household_estimator_service_impl.dart';

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
