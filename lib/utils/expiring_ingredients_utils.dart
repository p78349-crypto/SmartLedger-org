import '../models/consumable_inventory_item.dart';

/// 유통기한이 임박한 식재료를 필터링하는 유틸리티
class ExpiringIngredientsUtils {
  ExpiringIngredientsUtils._();

  /// N일 이내 유통기한 식재료 필터링
  static List<ConsumableInventoryItem> getExpiringWithinDays(
    List<ConsumableInventoryItem> allItems, {
    required int days,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final targetDay = effectiveNow.add(Duration(days: days));

    return allItems.where((item) {
        final expiryDate = item.expiryDate;
        if (expiryDate == null) {
          return false;
        }
        // 유통기한이 지나지 않았는지 확인
        if (expiryDate.isBefore(effectiveNow)) {
          return false; // 이미 지난 항목은 제외
        }
        // N일 이내인지 확인
        return expiryDate.isBefore(targetDay) ||
            expiryDate.isAtSameMomentAs(targetDay);
      }).toList()
      ..sort((a, b) =>
          a.expiryDate!.compareTo(b.expiryDate!)); // 임박한 순서로 정렬
  }

  /// 3일 이내 유통기한 식재료 필터링
  static List<ConsumableInventoryItem> getExpiringWithin3Days(
    List<ConsumableInventoryItem> allItems,
  ) {
    return getExpiringWithinDays(allItems, days: 3);
  }

  /// 가장 임박한 N개 식재료 반환
  static List<ConsumableInventoryItem> getTopExpiringItems(
    List<ConsumableInventoryItem> allItems, {
    int limit = 5,
  }) {
    final expiring = getExpiringWithin3Days(allItems);
    return expiring.take(limit).toList();
  }

  /// 유통기한까지 남은 일수 계산
  static int daysUntilExpiry(ConsumableInventoryItem item) {
    final now = DateTime.now();
    final expiryDate = item.expiryDate;
    if (expiryDate == null) {
      return 99999;
    }
    final difference = expiryDate.difference(now);
    return difference.inDays;
  }

  /// 유통기한 상태 라벨 반환 (오늘, 내일, 2일 후, 3일 후)
  static String getExpiryLabel(ConsumableInventoryItem item) {
    final daysLeft = daysUntilExpiry(item);

    if (daysLeft < 0) {
      return '기한 초과';
    } else if (daysLeft == 0) {
      return '오늘 만료 🔴';
    } else if (daysLeft == 1) {
      return '내일 만료 🟠';
    } else if (daysLeft <= 3) {
      return '$daysLeft일 후 만료 🟡';
    } else {
      return '$daysLeft일 후 만료';
    }
  }

  /// 식재료 목록을 위험도 순으로 정렬
  static List<ConsumableInventoryItem> sortByUrgency(
    List<ConsumableInventoryItem> items,
  ) {
    return List.from(items)
      ..sort((a, b) => daysUntilExpiry(a).compareTo(daysUntilExpiry(b)));
  }
}
