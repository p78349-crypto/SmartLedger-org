import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/consumable_inventory_item.dart';
import '../models/food_expiry_item.dart';

/// FoodExpiryItem → ConsumableInventoryItem 마이그레이션 서비스
/// 
/// 목표: SharedPreferences의 food_expiry_items_v1을 
///       ConsumableInventoryService로 통합
class FoodExpiryMigrationService {
  FoodExpiryMigrationService._();

  static const String _sourceKey = 'food_expiry_items_v1';
  static const String _migrationFlag = 'food_expiry_migrated_to_consumable_v1';

  /// FoodExpiryItem을 ConsumableInventoryItem으로 변환
  static ConsumableInventoryItem convertFoodExpiryToConsumable(
    FoodExpiryItem old,
  ) {
    return ConsumableInventoryItem(
      id: old.id,
      name: old.name,
      currentStock: old.quantity,
      unit: old.unit,
      category: old.category.isEmpty ? '식료품' : old.category,
      location: old.location.isEmpty ? '냉장' : old.location,
      createdAt: old.createdAt,
      lastUpdated: DateTime.now(),
      // 식료품 추가 정보
      expiryDate: old.expiryDate,
      purchaseDate: old.purchaseDate,
      price: old.price > 0 ? old.price : null,
      supplier: old.supplier.isEmpty ? null : old.supplier,
    );
  }

  /// 마이그레이션 여부 확인
  static Future<bool> isMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationFlag) ?? false;
  }

  /// 마이그레이션할 데이터 개수 조회
  static Future<int> getPendingMigrationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sourceKey);
    if (raw == null || raw.trim().isEmpty) {
      return 0;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.length;
    } catch (_) {
      return 0;
    }
  }

  /// 기존 FoodExpiry 데이터 로드
  static Future<List<FoodExpiryItem>> loadFoodExpiryData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sourceKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(FoodExpiryItem.fromJson)
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[FoodExpiryMigration] Error loading data: $e');
      return [];
    }
  }

  /// ConsumableInventoryItem으로 변환하여 반환
  static Future<List<ConsumableInventoryItem>> loadAsConsumableItems() async {
    final foodItems = await loadFoodExpiryData();
    return foodItems.map(convertFoodExpiryToConsumable).toList();
  }

  /// 마이그레이션 완료 표시
  static Future<void> markAsMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationFlag, true);
    debugPrint('[FoodExpiryMigration] Migration completed');
  }

  /// 기존 FoodExpiry 데이터 백업 (선택사항)
  static Future<String?> backupFoodExpiryData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sourceKey);
    if (raw == null) return null;

    final backupKey = 'food_expiry_backup_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(backupKey, raw);
    return backupKey;
  }

  /// 기존 데이터 정리 (마이그레이션 완료 후)
  static Future<void> cleanupOldData() async {
    // 기존 key는 유지 (복원용)
    // 필요시 나중에 수동으로 삭제 가능
    debugPrint('[FoodExpiryMigration] Old data cleanup skipped (kept for safety)');
  }

  /// 마이그레이션 상태 리포트
  static Future<String> getMigrationReport() async {
    final isMigrated = await FoodExpiryMigrationService.isMigrated();
    final pending = await getPendingMigrationCount();
    final items = await loadFoodExpiryData();

    final buffer = StringBuffer();
    buffer.writeln('=== FoodExpiry → Consumable Migration Report ===');
    buffer.writeln('Status: ${isMigrated ? "✅ Migrated" : "⏳ Pending"}');
    buffer.writeln('Items to migrate: $pending');

    if (items.isNotEmpty) {
      buffer.writeln('\nDetailed Items:');
      for (final item in items) {
        buffer.writeln(
          '  - ${item.name} (id: ${item.id}, expiry: ${item.expiryDate})',
        );
      }
    }

    return buffer.toString();
  }
}
