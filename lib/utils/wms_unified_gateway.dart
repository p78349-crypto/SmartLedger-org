/// WMS 통합 데이터 Gateway
///
/// 재고 관리 + 유통기한 관리 통합 조회
library;

import '../models/consumable_inventory_item.dart';
import '../models/food_expiry_item.dart';
import 'wms_data_gateway.dart';

/// WMS 통합 검색 결과
class WmsUnifiedSearchResult {
  final List<ConsumableInventoryItem> inventoryItems;
  final List<FoodExpiryItem> expiryItems;

  const WmsUnifiedSearchResult({
    required this.inventoryItems,
    required this.expiryItems,
  });

  int get totalCount => inventoryItems.length + expiryItems.length;
}

/// WMS 통합 Gateway
class WmsUnifiedGateway {
  WmsUnifiedGateway._();
  static final WmsUnifiedGateway instance = WmsUnifiedGateway._();

  /// 통합 검색 (이름 기준)
  Future<WmsUnifiedSearchResult> search(String query) async {
    if (query.trim().isEmpty) {
      return const WmsUnifiedSearchResult(
        inventoryItems: [],
        expiryItems: [],
      );
    }

    final normalized = query.trim().toLowerCase();

    // 병렬 조회
    final results = await Future.wait([
      WmsInventoryGateway.instance.getItems(),
      WmsExpiryGateway.instance.getItems(),
    ]);

    final inventoryItems = results[0] as List<ConsumableInventoryItem>;
    final expiryItems = results[1] as List<FoodExpiryItem>;

    // 검색 필터링
    final filteredInventory = inventoryItems
        .where((item) => item.name.toLowerCase().contains(normalized))
        .toList();

    final filteredExpiry = expiryItems
        .where((item) => item.name.toLowerCase().contains(normalized))
        .toList();

    return WmsUnifiedSearchResult(
      inventoryItems: filteredInventory,
      expiryItems: filteredExpiry,
    );
  }

  /// 재고 부족 + 유통기한 임박 통합 알림
  Future<WmsAlertSummary> getAlerts() async {
    final results = await Future.wait([
      WmsInventoryGateway.instance.getLowStockItems(),
      WmsExpiryGateway.instance.getExpiringItems(),
      WmsExpiryGateway.instance.getExpiredItems(),
    ]);

    return WmsAlertSummary(
      lowStockItems: results[0] as List<ConsumableInventoryItem>,
      expiringItems: results[1] as List<FoodExpiryItem>,
      expiredItems: results[2] as List<FoodExpiryItem>,
    );
  }

  /// 전체 재로드
  Future<void> reloadAll() async {
    await Future.wait([
      WmsInventoryGateway.instance.reload(),
      WmsExpiryGateway.instance.reload(),
    ]);
  }
}

/// 알림 요약
class WmsAlertSummary {
  final List<ConsumableInventoryItem> lowStockItems;
  final List<FoodExpiryItem> expiringItems;
  final List<FoodExpiryItem> expiredItems;

  const WmsAlertSummary({
    required this.lowStockItems,
    required this.expiringItems,
    required this.expiredItems,
  });

  int get totalAlerts =>
      lowStockItems.length + expiringItems.length + expiredItems.length;

  bool get hasAlerts => totalAlerts > 0;
}
