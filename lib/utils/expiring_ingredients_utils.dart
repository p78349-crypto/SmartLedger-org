import 'package:smart_ledger/models/food_expiry_item.dart';

/// 유통기한이 임박한 식재료를 필터링하는 유틸리티
class ExpiringIngredientsUtils {
  ExpiringIngredientsUtils._();

  /// 3일 이내 유통기한 식재료 필터링
  static List<FoodExpiryItem> getExpiringWithin3Days(
    List<FoodExpiryItem> allItems,
  ) {
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));

    return allItems
        .where((item) {
          // 유통기한이 지나지 않았는지 확인
          if (item.expiryDate.isBefore(now)) {
            return false; // 이미 지난 항목은 제외
          }
          // 3일 이내인지 확인
          return item.expiryDate.isBefore(threeDaysLater) ||
              item.expiryDate.isAtSameMomentAs(threeDaysLater);
        })
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate)); // 임박한 순서로 정렬
  }

  /// 가장 임박한 N개 식재료 반환
  static List<FoodExpiryItem> getTopExpiringItems(
    List<FoodExpiryItem> allItems, {
    int limit = 5,
  }) {
    final expiring = getExpiringWithin3Days(allItems);
    return expiring.take(limit).toList();
  }

  /// 유통기한까지 남은 일수 계산
  static int daysUntilExpiry(FoodExpiryItem item) {
    final now = DateTime.now();
    final difference = item.expiryDate.difference(now);
    return difference.inDays;
  }

  /// 유통기한 상태 라벨 반환 (오늘, 내일, 2일 후, 3일 후)
  static String getExpiryLabel(FoodExpiryItem item) {
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
  static List<FoodExpiryItem> sortByUrgency(
    List<FoodExpiryItem> items,
  ) {
    return List.from(items)
      ..sort((a, b) => daysUntilExpiry(a).compareTo(daysUntilExpiry(b)));
  }
}
