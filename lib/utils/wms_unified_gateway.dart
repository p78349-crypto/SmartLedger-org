/// WMS 통합 데이터 Gateway
///
/// 재고 관리 + 유통기한 관리 통합 조회
/// (ConsumableInventoryItem에 유통기한 정보 포함)
library;

import '../models/consumable_inventory_item.dart';
import 'wms_data_gateway.dart';

/// WMS 통합 검색 결과
class WmsUnifiedSearchResult {
  final List<ConsumableInventoryItem> inventoryItems;

  const WmsUnifiedSearchResult({
    required this.inventoryItems,
  });

  int get totalCount => inventoryItems.length;
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
      );
    }

    final normalized = query.trim().toLowerCase();

    // 병렬 조회
    final inventoryItems = await WmsInventoryGateway.instance.getItems();

    // 검색 필터링
    final filteredInventory = inventoryItems
        .where((item) => item.name.toLowerCase().contains(normalized))
        .toList();

    return WmsUnifiedSearchResult(
      inventoryItems: filteredInventory,
    );
  }

  /// 재고 부족 + 유통기한 임박 통합 알림
  Future<WmsAlertSummary> getAlerts() async {
    final results = await Future.wait([
      WmsInventoryGateway.instance.getLowStockItems(),
      WmsInventoryGateway.instance.getItems(),
    ]);

    final lowStockItems = results[0] as List<ConsumableInventoryItem>;
    final inventoryItems = results[1] as List<ConsumableInventoryItem>;

    final expiringInventoryItems = inventoryItems
        .where((item) => item.isExpiringWithin())
        .toList();

    final expiredInventoryItems = inventoryItems
        .where((item) => item.isExpired())
        .toList();

    return WmsAlertSummary(
      lowStockItems: lowStockItems,
      expiringInventoryItems: expiringInventoryItems,
      expiredInventoryItems: expiredInventoryItems,
    );
  }

  /// 전체 재로드
  Future<void> reloadAll() async {
    await WmsInventoryGateway.instance.reload();
  }
}

/// 알림 요약
class WmsAlertSummary {
  final List<ConsumableInventoryItem> lowStockItems;
  final List<ConsumableInventoryItem> expiringInventoryItems;
  final List<ConsumableInventoryItem> expiredInventoryItems;

  const WmsAlertSummary({
    required this.lowStockItems,
    required this.expiringInventoryItems,
    required this.expiredInventoryItems,
  });

    int get totalAlerts =>
      lowStockItems.length +
      expiringInventoryItems.length +
      expiredInventoryItems.length;

  bool get hasAlerts => totalAlerts > 0;
}
