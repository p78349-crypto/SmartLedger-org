library food_expiry_notification_service;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/food_expiry_item.dart';
import '../models/shopping_cart_item.dart';
import '../navigation/app_routes.dart';
import '../navigation/global_navigator_key.dart';
import '../services/account_service.dart';
import '../services/user_pref_service.dart';
import '../utils/pref_keys.dart';

part 'food_expiry_notification_service_impl.dart';
part 'food_expiry_notification_service_schedule.dart';

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
