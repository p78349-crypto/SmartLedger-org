import 'package:flutter/foundation.dart';
import '../models/consumable_inventory_item.dart';
import '../repositories/app_repositories.dart';
import 'health_guardrail_service.dart';
import 'replacement_cycle_notification_service.dart';
import 'stock_depletion_notification_service.dart';

class ConsumableInventoryService {
  ConsumableInventoryService._internal();
  static final ConsumableInventoryService instance =
      ConsumableInventoryService._internal();

  final ValueNotifier<List<ConsumableInventoryItem>> items =
      ValueNotifier<List<ConsumableInventoryItem>>(<ConsumableInventoryItem>[]);

  Future<void> load() async {
    final parsed = await AppRepositories.consumableInventory.loadItems();
    items.value = parsed;
  }

  Future<void> _save() async {
    await AppRepositories.consumableInventory.saveItems(items.value);
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
    DateTime? expiryDate,
    List<String> healthTags = const <String>[],
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
      expiryDate: expiryDate,
      healthTags: healthTags,
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

      // Keep predicted-depletion notifications up to date.
      // Best-effort: do not fail the update flow if scheduling throws.
      try {
        await StockDepletionNotificationService.instance.rescheduleForItem(
          next[index],
        );
      } catch (_) {
        // ignore
      }
    }
  }

  Future<void> deleteItem(String id) async {
    items.value = items.value.where((e) => e.id != id).toList();
    await _save();
  }

  Future<HealthGuardrailWarning?> useItem(String id, double amount) async {
    final index = items.value.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = items.value[index];
      final actualUsed = amount <= 0
          ? 0.0
          : amount > item.currentStock
          ? item.currentStock
          : amount;
      final nextStock = (item.currentStock - amount).clamp(
        0.0,
        double.infinity,
      );

      final now = DateTime.now();
      final nextHistory = <ConsumableUsageRecord>[
        ...item.usageHistory,
        if (actualUsed > 0)
          ConsumableUsageRecord(timestamp: now, amount: actualUsed),
      ];

      // keep only the last 60 records to bound storage
      final bounded = nextHistory.length <= 60
          ? nextHistory
          : nextHistory.sublist(nextHistory.length - 60);

      await updateItem(
        item.copyWith(currentStock: nextStock, usageHistory: bounded),
      );

      if (actualUsed > 0) {
        final warning = await HealthGuardrailService.recordUsageAndCheck(
          itemName: item.name,
          amount: actualUsed,
          tags: item.healthTags,
        );

        // Best-effort: keep replacement-cycle notifications up to date.
        try {
          await ReplacementCycleNotificationService.instance
              .rescheduleFromPrefs();
        } catch (_) {
          // ignore
        }

        return warning;
      }
    }

    return null;
  }
}
