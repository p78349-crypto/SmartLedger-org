/// WMS 데이터 경유지 (Data Gateway Pattern)
///
/// 목적:
/// - 모든 WMS 데이터 입출력을 단일 지점에서 제어
/// - 데이터 유효성 검사 및 변환
/// - 로깅 및 분석
/// - 🚀 스마트 캐싱 및 성능 최적화
/// - 임시저장 (Draft) 기능
library;

import 'package:flutter/foundation.dart';
import '../models/consumable_inventory_item.dart';
import '../services/consumable_inventory_service.dart';
import 'wms_data_models.dart';
import 'wms_smart_cache.dart';

export 'wms_data_models.dart';
export 'wms_draft_manager.dart';

/// WMS 데이터 Gateway - 재고 관리 (성능 최적화)
class WmsInventoryGateway {
  WmsInventoryGateway._();
  static final WmsInventoryGateway instance = WmsInventoryGateway._();

  // 🚀 스마트 캐시 시스템 사용
  final _smartCache = WmsSmartCache.instance;

  /// 재고 목록 조회 (🚀 스마트 캐싱 적용)
  Future<List<ConsumableInventoryItem>> getItems({
    bool forceRefresh = false,
  }) async {
    try {
      final items = await _smartCache.getAllItems(forceRefresh: forceRefresh);
      _logRead('Loaded ${items.length} inventory items (smart cache)');
      return items;
    } catch (e) {
      _logError('Failed to load items', e);
      return [];
    }
  }

  /// 단일 아이템 조회 (이름 기준) - 🚀 최적화됨
  Future<ConsumableInventoryItem?> findByName(String name) async {
    try {
      final results = await _smartCache.searchItems(name, exactMatch: true);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      _logError('Failed to find item by name: $name', e);
      return null;
    }
  }

  /// 단일 아이템 조회 (ID 기준) - 🚀 최적화됨
  Future<ConsumableInventoryItem?> findById(String id) async {
    try {
      return await _smartCache.getItemById(id);
    } catch (e) {
      _logError('Failed to find item by ID: $id', e);
      return null;
    }
  }

  /// 위치별 필터링 - 🚀 최적화됨
  Future<List<ConsumableInventoryItem>> getItemsByLocation(
    String location,
  ) async {
    try {
      return await _smartCache.getItemsByLocation(location);
    } catch (e) {
      _logError('Failed to get items by location: $location', e);
      return [];
    }
  }

  /// 재고 부족 아이템 조회 - 🚀 최적화됨
  Future<List<ConsumableInventoryItem>> getLowStockItems() async {
    try {
      final items = await _smartCache.getAllItems();
      return items.where((e) => e.currentStock <= e.threshold).toList();
    } catch (e) {
      _logError('Failed to get low stock items', e);
      return [];
    }
  }

  /// 아이템 추가 (유효성 검사 포함)
  Future<WmsOperationResult<ConsumableInventoryItem>> addItem({
    required WmsInventoryInput input,
    WmsInputSource? source,
  }) async {
    try {
      // 1. 유효성 검사
      final validation = input.validate();
      if (!validation.isValid) {
        return WmsOperationResult.failure(
          'Validation failed: ${validation.errors.join(', ')}',
        );
      }

      // 2. 중복 체크
      final existing = await findByName(input.name);
      if (existing != null) {
        return WmsOperationResult.duplicate(existing);
      }

      // 3. Service를 통한 추가
      await ConsumableInventoryService.instance.addItem(
        name: input.name,
        barcode: input.barcode,
        currentStock: input.currentStock,
        unit: input.unit,
        threshold: input.threshold,
        bundleSize: input.bundleSize,
        category: input.category,
        detailCategory: input.detailCategory,
        location: input.location,
      );

      // 4. 캐시 무효화
      _invalidateCache();

      // 5. 추가된 아이템 반환
      final newItem = await findByName(input.name);
      if (newItem == null) {
        return WmsOperationResult.failure('Item creation failed');
      }

      _logWrite(
        'Added item: ${newItem.name} (source: ${source?.name ?? 'manual'})',
      );
      return WmsOperationResult.success(newItem);
    } catch (e) {
      _logError('Add item failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 아이템 수정
  Future<WmsOperationResult<ConsumableInventoryItem>> updateItem({
    required ConsumableInventoryItem item,
  }) async {
    try {
      await ConsumableInventoryService.instance.updateItem(item);
      _invalidateCache();

      _logWrite('Updated item: ${item.name}');
      return WmsOperationResult.success(item);
    } catch (e) {
      _logError('Update item failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 아이템 삭제
  Future<WmsOperationResult<void>> deleteItem(String id) async {
    try {
      await ConsumableInventoryService.instance.deleteItem(id);
      _invalidateCache();

      _logWrite('Deleted item: $id');
      return WmsOperationResult.success(null);
    } catch (e) {
      _logError('Delete item failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 아이템 사용 기록
  Future<WmsOperationResult<void>> useItem({
    required String id,
    required double amount,
  }) async {
    try {
      if (amount <= 0) {
        return WmsOperationResult.failure('Amount must be positive');
      }

      await ConsumableInventoryService.instance.useItem(id, amount);
      _invalidateCache();

      _logWrite('Used item: $id (amount: $amount)');

      return WmsOperationResult.success(null);
    } catch (e) {
      _logError('Use item failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 캐시 무효화
  void _invalidateCache() {
    _smartCache.invalidateCache(clearAll: true);
  }

  /// 강제 리로드
  Future<void> reload() async {
    _invalidateCache();
    await getItems(forceRefresh: true);
  }

  // 로깅 메서드들
  void _logRead(String message) {
    debugPrint('[WMS Gateway][READ] $message');
  }

  void _logWrite(String message) {
    debugPrint('[WMS Gateway][WRITE] $message');
  }

  void _logError(String message, Object error) {
    debugPrint('[WMS Gateway][ERROR] $message: $error');
  }
}
