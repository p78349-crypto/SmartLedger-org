part of food_expiry_notification_service;

Future<int> _foodExpiryRescheduleAll(
  FoodExpiryNotificationService self, {
  required List<FoodExpiryItem> items,
  required int daysBefore,
  required TimeOfDay time,
}) async {
  await self._ensureInit();

  final ok = await self.requestPermissionIfNeeded();
  if (!ok) {
    // Permission denied: do not schedule.
    await self._plugin.cancelAll();
    return 0;
  }

  await self._plugin.cancelAll();

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
    final remaining = self._formatQtyWithUnit(it.quantity, it.unit);
    final body = daysBefore == 0
        ? '${it.name} 유통기한 당일입니다.\n잔량: $remaining'
        : '${it.name} 유통기한까지 $daysBefore일입니다.\n잔량: $remaining';

    final payload = jsonEncode(<String, dynamic>{
      'itemId': it.id,
      'itemName': it.name,
    });

    final id = self._stableNotificationId(it.id);
    try {
      await self._plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(notifyAt, tz.local),
        self._details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } on PlatformException catch (e) {
      // Android 12+ can block exact alarms unless the user grants
      // special access (SCHEDULE_EXACT_ALARM). Fall back to inexact.
      if (e.code == 'exact_alarms_not_permitted') {
        await self._plugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(notifyAt, tz.local),
          self._details(),
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
