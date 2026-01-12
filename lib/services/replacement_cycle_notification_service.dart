library replacement_cycle_notification_service;

import 'dart:convert';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'activity_household_estimator_service.dart';
import 'health_guardrail_service.dart';

part 'replacement_cycle_notification_service_impl.dart';

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

  factory ReplacementCycleNotificationSettings.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReplacementCycleNotificationSettings(
      enabled: (json['enabled'] as bool?) ?? false,
      maxWindowDays: (json['maxWindowDays'] as int?) ?? 365,
      leadDays: (json['leadDays'] as int?) ?? 7,
      minCycleDays: (json['minCycleDays'] as int?) ?? 30,
    );
  }
}
