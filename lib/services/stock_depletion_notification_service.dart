import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/navigation/global_navigator_key.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/activity_household_estimator_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class StockDepletionNotificationService {
  StockDepletionNotificationService._internal();
  static final StockDepletionNotificationService instance =
      StockDepletionNotificationService._internal();

  static const String _androidChannelId = 'stock_depletion';
  static const String _androidChannelName = '소진 알림';
  static const String _androidChannelDescription = '예상 소진(사용 주기 기반) 알림을 제공합니다.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

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

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    // Default tap opens Shopping Cart (쇼핑준비)
    await _openShoppingCart();
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

  Future<void> _openShoppingCart() async {
    final accountName = await _resolveAccountName();
    if (accountName == null || accountName.isEmpty) return;

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

  Future<bool> _isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefKeys.stockUsePredictedDepletionNotifyEnabledV1) ??
        true;
  }

  Future<bool> requestPermissionIfNeeded() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final next = await Permission.notification.request();
    return next.isGranted;
  }

  int _stableNotificationId(String itemId) {
    // itemId: ci_<microsecondsSinceEpoch>
    if (itemId.startsWith('ci_')) {
      final raw = itemId.substring(3);
      final v = int.tryParse(raw);
      if (v != null) return v % 2147483647;
    }
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

  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) return rounded.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

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

  String _formatQtyWithUnit(double value, String unit) {
    final u = unit.trim();
    final q = _formatQty(value);
    return u.isEmpty ? q : '$q$u';
  }

  int? _calculateExpectedDepletionDays(ConsumableInventoryItem item) {
    if (item.currentStock <= 0) return null;
    if (item.usageHistory.length < 2) return null;

    final sorted = [...item.usageHistory]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final first = sorted.first.timestamp;
    final last = sorted.last.timestamp;
    final spanDays = _startOfDay(last).difference(_startOfDay(first)).inDays.abs();
    final denomDays = spanDays < 1 ? 1 : spanDays;
    final totalUsed = sorted.fold<double>(0.0, (sum, r) => sum + r.amount);
    final avgPerDay = totalUsed / denomDays;
    if (avgPerDay <= 0) return null;

    return (item.currentStock / avgPerDay).ceil();
  }

  /// Reschedule (cancel + schedule) predicted depletion notification for an item.
  ///
  /// - If user disabled notifications, cancels existing.
  /// - If there isn't enough usage history, cancels existing.
  /// - Schedules at 09:00 on (expectedDepletionDate - thresholdDays).
  /// - If already within the threshold window, schedules an immediate notification.
  Future<void> rescheduleForItem(ConsumableInventoryItem item) async {
    await _ensureInit();

    final enabled = await _isEnabled();
    final id = _stableNotificationId(item.id);

    if (!enabled) {
      await _plugin.cancel(id);
      return;
    }

    final ok = await requestPermissionIfNeeded();
    if (!ok) {
      await _plugin.cancel(id);
      return;
    }

    final expectedDaysLeft = _calculateExpectedDepletionDays(item);
    if (expectedDaysLeft == null) {
      await _plugin.cancel(id);
      return;
    }

    final thresholdDays = item.expiryDate != null
        ? await UserPrefService.getStockUseAutoAddDepletionDaysFoodV1()
        : await UserPrefService.getStockUseAutoAddDepletionDaysHouseholdV1();

    final now = DateTime.now();
    final expectedDepletionDate = _startOfDay(now).add(Duration(days: expectedDaysLeft));

    // Notify at threshold boundary (09:00), or immediately if already within window.
    final plannedNotifyDay = expectedDepletionDate.subtract(Duration(days: thresholdDays));
    var notifyAt = DateTime(
      plannedNotifyDay.year,
      plannedNotifyDay.month,
      plannedNotifyDay.day,
      9,
    );

    if (!notifyAt.isAfter(now)) {
      // already in the window → notify soon
      notifyAt = now.add(const Duration(minutes: 1));
    }

    final title = item.expiryDate != null ? '식료품 소진 알림' : '생활용품 소진 알림';
    final remaining = _formatQtyWithUnit(item.currentStock, item.unit);
    final expectedText = expectedDaysLeft <= 0
      ? '거의 소진됨'
      : '$expectedDaysLeft일 후 소진 예상';

    final trendLine = await _activityTrendLine();
    final body =
      '${item.name} $thresholdDays일 이내 소진 가능성\n현재 잔량: $remaining\n예상: $expectedText'
      '${trendLine == null ? '' : '\n$trendLine'}\n쇼핑준비를 확인하세요.';

    final payload = jsonEncode({'itemId': item.id, 'itemName': item.name});

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
  }
}
