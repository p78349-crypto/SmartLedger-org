import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:smart_ledger/models/food_expiry_item.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/navigation/global_navigator_key.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

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

  static const String _actionRecipe = 'food_expiry_action_recipe';
  static const String _actionRepurchase = 'food_expiry_action_repurchase';

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
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

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

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;

    String? itemName;
    try {
      if (payload != null && payload.trim().isNotEmpty) {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          itemName = (decoded['itemName'] as String?)?.trim();
        }
      }
    } catch (_) {
      // ignore
    }

    if (response.actionId == _actionRecipe) {
      await _openFoodExpiry(openCookableRecipePickerOnStart: true);
      return;
    }

    if (response.actionId == _actionRepurchase) {
      await _addToShoppingCartAndOpen(itemName);
      return;
    }

    // Default tap
    await _openFoodExpiry(openCookableRecipePickerOnStart: false);
  }

  Future<void> _openFoodExpiry({
    required bool openCookableRecipePickerOnStart,
  }) async {
    for (int i = 0; i < 10; i++) {
      final nav = appNavigatorKey.currentState;
      if (nav != null) {
        nav.pushNamed(
          AppRoutes.foodExpiry,
          arguments: FoodExpiryArgs(
            openCookableRecipePickerOnStart: openCookableRecipePickerOnStart,
          ),
        );
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<String?> _resolveAccountName() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getString(PrefKeys.selectedAccount)?.trim();
    if (selected != null && selected.isNotEmpty) return selected;

    try {
      final service = AccountService();
      await service.loadAccounts();
      if (service.accounts.isNotEmpty) return service.accounts.first.name;
    } catch (_) {
      // ignore
    }
    return null;
  }

  Future<void> _addToShoppingCartAndOpen(String? itemName) async {
    final name = (itemName ?? '').trim();
    final accountName = await _resolveAccountName();

    if (accountName == null || accountName.isEmpty || name.isEmpty) {
      await _openFoodExpiry(openCookableRecipePickerOnStart: false);
      return;
    }

    final current = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );
    final exists = current.any((i) => i.name.trim() == name);
    if (!exists) {
      final now = DateTime.now();
      final next = List<ShoppingCartItem>.from(current)
        ..add(
          ShoppingCartItem(
            id: 'sc_${now.microsecondsSinceEpoch}',
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
      await UserPrefService.setShoppingCartItems(
        accountName: accountName,
        items: next,
      );
    }

    for (int i = 0; i < 10; i++) {
      final nav = appNavigatorKey.currentState;
      if (nav != null) {
        nav.pushNamed(
          AppRoutes.shoppingCart,
          arguments: ShoppingCartArgs(accountName: accountName),
        );
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<FoodExpiryNotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Default ON for new installs; respect any previously saved user choice.
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
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          _actionRecipe,
          '레시피 보기',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          _actionRepurchase,
          '재구매 담기',
          showsUserInterface: true,
        ),
      ],
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) return rounded.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  String _formatQtyWithUnit(double value, String unit) {
    final u = unit.trim();
    final q = _formatQty(value);
    return u.isEmpty ? q : '$q$u';
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
        final remaining = _formatQtyWithUnit(it.quantity, it.unit);
        final body = daysBefore == 0
          ? '${it.name} 유통기한 당일입니다.\n잔량: $remaining'
          : '${it.name} 유통기한까지 $daysBefore일입니다.\n잔량: $remaining';

      final payload = jsonEncode({'itemId': it.id, 'itemName': it.name});

      final id = _stableNotificationId(it.id);
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(notifyAt, tz.local),
          _details(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      } on PlatformException catch (e) {
        // Android 12+ can block exact alarms unless the user grants
        // special access (SCHEDULE_EXACT_ALARM). Fall back to inexact.
        if (e.code == 'exact_alarms_not_permitted') {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(notifyAt, tz.local),
            _details(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        } else {
          rethrow;
        }
      }
      scheduled++;
    }

    return scheduled;
  }
}
