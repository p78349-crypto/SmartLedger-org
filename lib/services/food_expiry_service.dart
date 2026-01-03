import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/food_expiry_item.dart';
import 'package:smart_ledger/services/food_expiry_notification_service.dart';

class FoodExpiryService {
  FoodExpiryService._internal();
  static final FoodExpiryService instance = FoodExpiryService._internal();

  static const String _prefsKey = 'food_expiry_items_v1';

  final ValueNotifier<List<FoodExpiryItem>> items =
      ValueNotifier<List<FoodExpiryItem>>(<FoodExpiryItem>[]);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      items.value = <FoodExpiryItem>[];
      await FoodExpiryNotificationService.instance.rescheduleFromPrefs(
        items.value,
      );
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = list
          .whereType<Map<String, dynamic>>()
          .map(FoodExpiryItem.fromJson)
          .where((e) => e.id.isNotEmpty)
          .toList();
      parsed.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      items.value = parsed;
    } catch (_) {
      items.value = <FoodExpiryItem>[];
    }

    await FoodExpiryNotificationService.instance.rescheduleFromPrefs(
      items.value,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.value.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  Future<void> addItem({
    required String name,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    String memo = '',
    double quantity = 1.0,
    String unit = '개',
    String category = '기타',
    String location = '냉장',
    double price = 0.0,
    String supplier = '',
  }) async {
    final now = DateTime.now();
    final id = 'fx_${now.microsecondsSinceEpoch}';
    final next = List<FoodExpiryItem>.from(items.value)
      ..add(
        FoodExpiryItem(
          id: id,
          name: name.trim(),
          purchaseDate: purchaseDate,
          expiryDate: expiryDate,
          createdAt: now,
          memo: memo.trim(),
          quantity: quantity,
          unit: unit,
          category: category,
          location: location,
          price: price,
          supplier: supplier,
        ),
      );
    next.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    items.value = next;
    await _save();
    await FoodExpiryNotificationService.instance.rescheduleFromPrefs(
      items.value,
    );
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required String memo,
    required double quantity,
    required String unit,
    String category = '기타',
    String location = '냉장',
    double price = 0.0,
    String supplier = '',
  }) async {
    final prev = items.value;
    final idx = prev.indexWhere((e) => e.id == id);
    if (idx < 0) return;

    final old = prev[idx];
    final next = List<FoodExpiryItem>.from(prev);
    next[idx] = FoodExpiryItem(
      id: old.id,
      name: name.trim(),
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      createdAt: old.createdAt,
      memo: memo.trim(),
      quantity: quantity,
      unit: unit,
      category: category,
      location: location,
      price: price,
      supplier: supplier,
    );
    next.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    items.value = next;
    await _save();
    await FoodExpiryNotificationService.instance.rescheduleFromPrefs(
      items.value,
    );
  }

  Future<void> deleteById(String id) async {
    final next = items.value.where((e) => e.id != id).toList();
    items.value = next;
    await _save();
    await FoodExpiryNotificationService.instance.rescheduleFromPrefs(
      items.value,
    );
  }
}
