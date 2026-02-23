library food_expiry_notification_service;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_expiry_item.dart';

class FoodExpiryNotificationSettings {
  final bool enabled;
  final int daysBefore;
  final TimeOfDay time;

  const FoodExpiryNotificationSettings({
    required this.enabled,
    required this.daysBefore,
    required this.time,
  });

  FoodExpiryNotificationSettings copyWith({
    bool? enabled,
    int? daysBefore,
    TimeOfDay? time,
  }) {
    return FoodExpiryNotificationSettings(
      enabled: enabled ?? this.enabled,
      daysBefore: daysBefore ?? this.daysBefore,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enabled': enabled,
    'daysBefore': daysBefore,
    'hour': time.hour,
    'minute': time.minute,
  };

  factory FoodExpiryNotificationSettings.fromJson(Map<String, dynamic> json) {
    final hour = (json['hour'] as int?) ?? 9;
    final minute = (json['minute'] as int?) ?? 0;
    return FoodExpiryNotificationSettings(
      enabled: (json['enabled'] as bool?) ?? true,
      daysBefore: (json['daysBefore'] as int?) ?? 2,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }
}

class FoodExpiryNotificationService {
  FoodExpiryNotificationService._internal();

  static final FoodExpiryNotificationService instance =
      FoodExpiryNotificationService._internal();

  static const String _kEnabled = 'food_expiry_notify_enabled_v1';
  static const String _kDaysBefore = 'food_expiry_notify_days_before_v1';
  static const String _kHour = 'food_expiry_notify_hour_v1';
  static const String _kMinute = 'food_expiry_notify_minute_v1';

  Future<FoodExpiryNotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = prefs.getBool(_kEnabled) ?? true;
    final daysBefore = prefs.getInt(_kDaysBefore) ?? 2;
    final hour = prefs.getInt(_kHour) ?? 9;
    final minute = prefs.getInt(_kMinute) ?? 0;

    return FoodExpiryNotificationSettings(
      enabled: enabled,
      daysBefore: daysBefore.clamp(0, 365),
      time: TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59)),
    );
  }

  Future<void> saveSettings(FoodExpiryNotificationSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, s.enabled);
    await prefs.setInt(_kDaysBefore, s.daysBefore);
    await prefs.setInt(_kHour, s.time.hour);
    await prefs.setInt(_kMinute, s.time.minute);
  }

  Future<int> rescheduleFromPrefs(List<FoodExpiryItem> items) async {
    final settings = await loadSettings();
    if (!settings.enabled) return 0;
    // 알림 스케줄링은 별도 서비스에서 처리 예정 (현재는 카운트 반환)
    return items.length;
  }
}
