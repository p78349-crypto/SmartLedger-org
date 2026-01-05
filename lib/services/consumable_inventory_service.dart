import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';

class ConsumableInventoryService {
  ConsumableInventoryService._internal();
  static final ConsumableInventoryService instance =
      ConsumableInventoryService._internal();

  static const String _prefsKey = 'consumable_inventory_items_v1';

  final ValueNotifier<List<ConsumableInventoryItem>> items =
      ValueNotifier<List<ConsumableInventoryItem>>(<ConsumableInventoryItem>[]);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      items.value = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = list
          .whereType<Map<String, dynamic>>()
          .map(ConsumableInventoryItem.fromJson)
          .toList();
      // FIFO: 생성일 기준 정렬 (오래된 것이 먼저)
      parsed.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      items.value = parsed;
    } catch (_) {
      items.value = [];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.value.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  Future<void> addItem({
    required String name,
    double currentStock = 0.0,
    String unit = '개',
    double threshold = 1.0,
    double bundleSize = 1.0,
    String category = '생활용품',
    String? detailCategory,
    String location = '기타',
  }) async {
    final now = DateTime.now();
    final id = 'ci_${now.microsecondsSinceEpoch}';
    final newItem = ConsumableInventoryItem(
      id: id,
      name: name.trim(),
      currentStock: currentStock,
      unit: unit,
      threshold: threshold,
      bundleSize: bundleSize,
      category: category,
      detailCategory: detailCategory,
      location: location,
      createdAt: now,
      lastUpdated: now,
    );
    final next = List<ConsumableInventoryItem>.from(items.value)..add(newItem);
    // FIFO: 생성일 기준 정렬 (오래된 것이 먼저)
    next.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    items.value = next;
    await _save();
  }

  Future<void> updateItem(ConsumableInventoryItem item) async {
    final index = items.value.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      final next = List<ConsumableInventoryItem>.from(items.value);
      next[index] = item.copyWith(lastUpdated: DateTime.now());
      items.value = next;
      await _save();
    }
  }

  Future<void> deleteItem(String id) async {
    items.value = items.value.where((e) => e.id != id).toList();
    await _save();
  }

  Future<void> useItem(String id, double amount) async {
    final index = items.value.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = items.value[index];
      final nextStock =
          (item.currentStock - amount).clamp(0.0, double.infinity);
      await updateItem(item.copyWith(currentStock: nextStock));
    }
  }
}
