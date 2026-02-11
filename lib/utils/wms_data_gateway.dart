/// WMS 데이터 경유지 (Data Gateway Pattern)
///
/// 목적:
/// - 모든 WMS 데이터 입출력을 단일 지점에서 제어
/// - 데이터 유효성 검사 및 변환
/// - 로깅 및 분석
/// - 캐싱 및 성능 최적화
/// - 임시저장 (Draft) 기능
library;

import 'package:flutter/foundation.dart';
import '../models/consumable_inventory_item.dart';
import '../models/wms_inventory_draft_entry.dart';
import '../services/consumable_inventory_service.dart';
import '../services/user_pref_service.dart';

part 'wms_data_gateway_models.dart';
part 'wms_data_gateway_draft.dart';

/// WMS 데이터 Gateway - 재고 관리
class WmsInventoryGateway {
  WmsInventoryGateway._();
  static final WmsInventoryGateway instance = WmsInventoryGateway._();

  List<ConsumableInventoryItem>? _cachedItems;
  DateTime? _lastCacheTime;
  static const _cacheDuration = Duration(seconds: 30);

  /// 재고 목록 조회 (캐싱 적용)
  Future<List<ConsumableInventoryItem>> getItems({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    if (!forceRefresh &&
        _cachedItems != null &&
        _lastCacheTime != null &&
        now.difference(_lastCacheTime!) < _cacheDuration) {
      return _cachedItems!;
    }

    await ConsumableInventoryService.instance.load();
    final items = ConsumableInventoryService.instance.items.value;

    _cachedItems = List.unmodifiable(items);
    _lastCacheTime = now;

    _logRead('Loaded ${items.length} inventory items');
    return _cachedItems!;
  }

  /// 단일 아이템 조회 (이름 기준)
  Future<ConsumableInventoryItem?> findByName(String name) async {
    final items = await getItems();
    final normalized = name.trim().toLowerCase();

    for (final item in items) {
      if (item.name.trim().toLowerCase() == normalized) return item;
    }
    return null;
  }

  /// 단일 아이템 조회 (ID 기준)
  Future<ConsumableInventoryItem?> findById(String id) async {
    final items = await getItems();

    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// 위치별 필터링
  Future<List<ConsumableInventoryItem>> getItemsByLocation(
    String location,
  ) async {
    final items = await getItems();
    if (location == '전체') return items;
    return items.where((e) => e.location == location).toList();
  }

  /// 재고 부족 아이템 조회
  Future<List<ConsumableInventoryItem>> getLowStockItems() async {
    final items = await getItems();
    return items.where((e) => e.currentStock <= e.threshold).toList();
  }

  /// 아이템 추가 (유효성 검사 포함)
  Future<WmsOperationResult<ConsumableInventoryItem>> addItem({
    required WmsInventoryInput input,
    WmsInputSource? source,
  }) async {
    try {
      final validation = input.validate();
      if (!validation.isValid) {
        return WmsOperationResult.failure(
          'Validation failed: ${validation.errors.join(', ')}',
        );
      }

      final existing = await findByName(input.name);
      if (existing != null) return WmsOperationResult.duplicate(existing);

      await ConsumableInventoryService.instance.addItem(
        name: input.name,
        currentStock: input.currentStock,
        unit: input.unit,
        threshold: input.threshold,
        bundleSize: input.bundleSize,
        category: input.category,
        detailCategory: input.detailCategory,
        location: input.location,
        healthTags: input.healthTags,
      );

      _invalidateCache();

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

      final warning = await ConsumableInventoryService.instance.useItem(
        id,
        amount,
      );
      _invalidateCache();
      _logWrite('Used item: $id (amount: $amount)');

      if (warning != null) {
        return WmsOperationResult.warning(null, warning.message);
      }
      return WmsOperationResult.success(null);
    } catch (e) {
      _logError('Use item failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  void _invalidateCache() {
    _cachedItems = null;
    _lastCacheTime = null;
  }

  /// 강제 리로드
  Future<void> reload() async {
    _invalidateCache();
    await getItems(forceRefresh: true);
  }

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
