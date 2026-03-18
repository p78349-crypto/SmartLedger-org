/// WMS 통합 데이터 Gateway - 🚀 최적화 버전
///
/// 재고 관리 + 유통기한 관리 통합 조회
/// (ConsumableInventoryItem에 유통기한 정보 포함)
///
/// 성능 최적화 기능:
/// - 스마트 캐시 시스템 적용
/// - 데이터베이스 연결 풀 사용
/// - 병렬 검색 처리
library;

import '../models/consumable_inventory_item.dart';
import 'wms_data_gateway.dart';
import 'wms_smart_cache.dart'; // 🚀 스마트 캐시
import 'wms_performance_monitor.dart'; // 🚀 성능 모니터링

/// WMS 통합 검색 결과
class WmsUnifiedSearchResult {
  final List<ConsumableInventoryItem> inventoryItems;

  const WmsUnifiedSearchResult({required this.inventoryItems});

  int get totalCount => inventoryItems.length;
}

/// WMS 통합 Gateway
class WmsUnifiedGateway {
  WmsUnifiedGateway._();
  static final WmsUnifiedGateway instance = WmsUnifiedGateway._();

  // 🚀 최적화된 서비스들
  final _smartCache = WmsSmartCache.instance;
  final _performanceMonitor = WmsPerformanceMonitor.instance;

  /// 🚀 통합 검색 (이름 기준) - 최적화됨
  Future<WmsUnifiedSearchResult> search(String query) async {
    if (query.trim().isEmpty) {
      return const WmsUnifiedSearchResult(inventoryItems: []);
    }

    final stopwatch = Stopwatch()..start();

    try {
      // 🚀 스마트 캐시를 사용한 검색
      final filteredInventory = await _smartCache.searchItems(query);

      stopwatch.stop();

      // 🚀 성능 모니터링
      _performanceMonitor.recordSearchOperation(stopwatch.elapsed);

      return WmsUnifiedSearchResult(inventoryItems: filteredInventory);
    } catch (e) {
      stopwatch.stop();
      // 캐시에서 실패하면 일반 검색으로 폴백
      final inventoryItems = await WmsInventoryGateway.instance.getItems();
      final normalized = query.trim().toLowerCase();

      final filteredInventory = inventoryItems
          .where((item) => item.name.toLowerCase().contains(normalized))
          .toList();

      return WmsUnifiedSearchResult(inventoryItems: filteredInventory);
    }
  }

  /// 재고 부족 + 유통기한 임박 통합 알림
  Future<WmsAlertSummary> getAlerts() async {
    final results = await Future.wait<List<ConsumableInventoryItem>>([
      WmsInventoryGateway.instance.getLowStockItems(),
      WmsInventoryGateway.instance.getItems(),
    ]);

    final lowStockItems = results[0];
    final inventoryItems = results[1];

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
