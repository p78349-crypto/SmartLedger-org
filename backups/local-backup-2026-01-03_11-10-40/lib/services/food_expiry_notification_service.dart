import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:smart_ledger/models/food_expiry_item.dart';

@immutable
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
}

class FoodExpiryNotificationService {
  FoodExpiryNotificationService._internal();
  static final FoodExpiryNotificationService instance =
      FoodExpiryNotificationService._internal();

  static const String _kEnabled = 'food_expiry_notify_enabled_v1';
  static const String _kDaysBefore = 'food_expiry_notify_days_before_v1';
  static const String _kHour = 'food_expiry_notify_hour_v1';
  static const String _kMinute = 'food_expiry_notify_minute_v1';

  static const String _androidChannelId = 'food_expiry';
  static const String _androidChannelName = '유통기한 알림';
  static const String _androidChannelDescription = '유통기한 임박/경과 알림을 제공합니다.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      // 앱이 한국어 기반이므로 기본 로케이션을 Asia/Seoul로 시도.
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // Ignore; tz.local will be used.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);

    // Android 채널 등록 (일부 기기/OS에선 필요)
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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

  Future<FoodExpiryNotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kEnabled) ?? false;
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

  Future<bool> requestPermissionIfNeeded() async {
    // Android 13+ / iOS 모두 Permission.notification로 처리.
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final next = await Permission.notification.request();
    return next.isGranted;
  }

  int _stableNotificationId(String itemId) {
    // itemId: fx_<microsecondsSinceEpoch>
    if (itemId.startsWith('fx_')) {
      final raw = itemId.substring(3);
      final v = int.tryParse(raw);
      if (v != null) return v % 2147483647;
    }
    // fallback
    return itemId.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) % 2147483647);
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  Future<void> cancelAllFoodExpiryNotifications() async {
    await _ensureInit();
    await _plugin.cancelAll();
  }

  Future<int> rescheduleFromPrefs(List<FoodExpiryItem> items) async {
    final settings = await loadSettings();
    if (!settings.enabled) {
      await cancelAllFoodExpiryNotifications();
      return 0;
    }
    return rescheduleAll(
      items: items,
      daysBefore: settings.daysBefore,
      time: settings.time,
    );
  }

  Future<int> rescheduleAll({
    required List<FoodExpiryItem> items,
    required int daysBefore,
    required TimeOfDay time,
  }) async {
    await _ensureInit();

    final ok = await requestPermissionIfNeeded();
    if (!ok) {
      // Permission denied: do not schedule.
      await _plugin.cancelAll();
      return 0;
    }

    await _plugin.cancelAll();

    final now = DateTime.now();
    int scheduled = 0;

    for (final it in items) {
      final notifyAt = DateTime(
        it.expiryDate.year,
        it.expiryDate.month,
        it.expiryDate.day,
        time.hour,
        time.minute,
      ).subtract(Duration(days: daysBefore));

      if (!notifyAt.isAfter(now)) {
        continue;
      }

      const title = '유통기한 알림';
      final body = daysBefore == 0
          ? '${it.name} 유통기한 당일입니다.'
          : '${it.name} 유통기한 $daysBefore일 전입니다.';

      final id = _stableNotificationId(it.id);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(notifyAt, tz.local),
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
      );
      scheduled++;
    }

    return scheduled;
  }
}
