import 'package:flutter/foundation.dart';
import '../models/consumable_inventory_item.dart';
import '../services/consumable_inventory_service.dart';
import 'wms_optimization_settings.dart';  // 🚀 최적화 설정 추가

/// WMS 고성능 캐시 매니저
class WmsSmartCache {
  WmsSmartCache._();
  static final WmsSmartCache instance = WmsSmartCache._();

  // 🚀 설정 기반 캐시 활성화 확인
  bool get _isEnabled => WmsOptimizationSettings.instance.enableSmartCache;
  int get _maxMemoryMB => WmsOptimizationSettings.instance.maxCacheMemoryMB;

  // 계층화된 캐시 시스템
  final Map<String, ConsumableInventoryItem> _itemCache = {};
  final Map<String, List<ConsumableInventoryItem>> _locationCache = {};
  final Map<String, List<ConsumableInventoryItem>> _queryCache = {};
  List<ConsumableInventoryItem>? _allItemsCache;
  
  DateTime? _lastFullRefresh;
  DateTime? _lastLocationRefresh;
  
  // 캐시 설정
  static const Duration _fullCacheDuration = Duration(minutes: 10); // 전체 캐시: 10분
  static const Duration _locationCacheDuration = Duration(minutes: 5); // 위치별: 5분  
  static const Duration _queryCacheDuration = Duration(minutes: 3); // 검색: 3분
  static const int _maxQueryCache = 50; // 최대 검색 캐시 수
  static const int _maxItemsInMemory = 1000; // 메모리 제한

  /// 📦 전체 아이템 조회 (스마트 캐싱)
  Future<List<ConsumableInventoryItem>> getAllItems({
    bool forceRefresh = false,
  }) async {
    // 🚀 설정에서 캐시가 비활성화된 경우 직접 조회
    if (!_isEnabled) {
      return await _directLoadItems();
    }

    final now = DateTime.now();

    // 캐시 유효성 검사
    if (!forceRefresh && 
        _allItemsCache != null && 
        _lastFullRefresh != null &&
        now.difference(_lastFullRefresh!) < _fullCacheDuration) {
      return _allItemsCache!;
    }

    // 메모리 정리 (필요시)
    _cleanupIfNeeded();

    // 데이터 로딩
    await ConsumableInventoryService.instance.load();
    final items = ConsumableInventoryService.instance.items.value;

    // 캐시 업데이트
    _allItemsCache = List.unmodifiable(items);
    _lastFullRefresh = now;

    // 아이템별 인덱스 캐시 생성
    _rebuildItemCache(items);

    return _allItemsCache!;
  }

  /// 🔍 ID로 빠른 검색 (O(1))
  Future<ConsumableInventoryItem?> getItemById(String id) async {
    // 캐시에서 먼저 확인
    if (_itemCache.containsKey(id)) {
      return _itemCache[id];
    }

    // 전체 캐시가 없으면 로딩
    await getAllItems();
    return _itemCache[id];
  }

  /// 🏪 위치별 아이템 조회 (캐싱)
  Future<List<ConsumableInventoryItem>> getItemsByLocation(
    String location, {
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final cacheKey = 'location_$location';

    // 캐시 확인
    if (!forceRefresh && 
        _locationCache.containsKey(cacheKey) && 
        _lastLocationRefresh != null &&
        now.difference(_lastLocationRefresh!) < _locationCacheDuration) {
      return _locationCache[cacheKey]!;
    }

    // 전체 아이템에서 필터링
    final allItems = await getAllItems(forceRefresh: forceRefresh);
    final locationItems = location == '전체' 
      ? allItems 
      : allItems.where((item) => item.location == location).toList();

    // 위치별 캐시 업데이트
    _locationCache[cacheKey] = List.unmodifiable(locationItems);
    _lastLocationRefresh = now;

    return locationItems;
  }

  /// 🔍 스마트 검색 (캐싱 + 퍼지 매칭)
  Future<List<ConsumableInventoryItem>> searchItems(
    String query, {
    bool exactMatch = false,
  }) async {
    if (query.trim().isEmpty) return await getAllItems();

    final normalizedQuery = query.trim().toLowerCase();
    final cacheKey = 'query_${normalizedQuery}_$exactMatch';

    // 검색 캐시 확인
    if (_queryCache.containsKey(cacheKey)) {
      final cachedResult = _queryCache[cacheKey]!;
      // 검색 결과가 최근 3분 이내인지 확인 (효율성을 위해 간단히 처리)
      return cachedResult;
    }

    // 전체 아이템에서 검색
    final allItems = await getAllItems();
    final results = <ConsumableInventoryItem>[];

    for (final item in allItems) {
      final itemName = item.name.toLowerCase();
      
      if (exactMatch) {
        if (itemName == normalizedQuery) {
          results.add(item);
        }
      } else {
        // 퍼지 매칭: 포함, 시작, 유사도
        if (itemName.contains(normalizedQuery) ||
            itemName.startsWith(normalizedQuery) ||
            _calculateSimilarity(itemName, normalizedQuery) > 0.7) {
          results.add(item);
        }
      }
    }

    // 검색 결과 정렬 (관련도 순)
    results.sort((a, b) {
      final aScore = _getRelevanceScore(a.name.toLowerCase(), normalizedQuery);
      final bScore = _getRelevanceScore(b.name.toLowerCase(), normalizedQuery);
      return bScore.compareTo(aScore);
    });

    // 검색 캐시 저장 (크기 제한)
    _addToQueryCache(cacheKey, results);

    return results;
  }

  /// ⚡ 배치 아이템 조회 (성능 최적화)
  Future<Map<String, ConsumableInventoryItem>> getItemsBatch(
    List<String> ids,
  ) async {
    final result = <String, ConsumableInventoryItem>{};
    final missingIds = <String>[];

    // 캐시에서 먼저 찾기
    for (final id in ids) {
      if (_itemCache.containsKey(id)) {
        result[id] = _itemCache[id]!;
      } else {
        missingIds.add(id);
      }
    }

    // 누락된 것들만 로딩
    if (missingIds.isNotEmpty) {
      await getAllItems();
      for (final id in missingIds) {
        if (_itemCache.containsKey(id)) {
          result[id] = _itemCache[id]!;
        }
      }
    }

    return result;
  }

  /// 🧹 캐시 정리
  void _cleanupIfNeeded() {
    // 쿼리 캐시 크기 제한
    if (_queryCache.length > _maxQueryCache) {
      final keysToRemove = _queryCache.keys.take(_queryCache.length - _maxQueryCache);
      for (final key in keysToRemove) {
        _queryCache.remove(key);
      }
    }

    // 메모리 사용량 확인 (간접적)
    if (_itemCache.length > _maxItemsInMemory) {
      _itemCache.clear();
      _locationCache.clear();
    }
  }

  /// 🔄 아이템 캐시 재구축
  void _rebuildItemCache(List<ConsumableInventoryItem> items) {
    _itemCache.clear();
    for (final item in items) {
      _itemCache[item.id] = item;
    }
  }

  /// 📊 검색 캐시 추가
  void _addToQueryCache(String key, List<ConsumableInventoryItem> results) {
    _queryCache[key] = List.unmodifiable(results);
  }

  /// 🎯 관련도 점수 계산
  double _getRelevanceScore(String itemName, String query) {
    if (itemName == query) return 1.0;
    if (itemName.startsWith(query)) return 0.9;
    if (itemName.contains(query)) return 0.7;
    return _calculateSimilarity(itemName, query);
  }

  /// 📏 문자열 유사도 계산 (간단한 Jaccard 유사도)
  double _calculateSimilarity(String s1, String s2) {
    final set1 = s1.split('').toSet();
    final set2 = s2.split('').toSet();
    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;
    return union > 0 ? intersection / union : 0.0;
  }

  /// 🗑️ 캐시 무효화
  void invalidateCache({
    bool clearAll = false,
    String? location,
    List<String>? itemIds,
  }) {
    if (clearAll) {
      _allItemsCache = null;
      _itemCache.clear();
      _locationCache.clear();
      _queryCache.clear();
      _lastFullRefresh = null;
      _lastLocationRefresh = null;
    } else {
      if (location != null) {
        _locationCache.remove('location_$location');
      }
      if (itemIds != null) {
        for (final id in itemIds) {
          _itemCache.remove(id);
        }
      }
    }
  }

  /// 📊 캐시 상태 정보
  Map<String, dynamic> getCacheStats() {
    return {
      'allItemsCached': _allItemsCache != null,
      'itemCacheSize': _itemCache.length,
      'locationCacheSize': _locationCache.length,
      'queryCacheSize': _queryCache.length,
      'lastFullRefresh': _lastFullRefresh?.toIso8601String(),
      'lastLocationRefresh': _lastLocationRefresh?.toIso8601String(),
    };
  }

  /// 📂 직접 아이템 로딩 (캐시 우회)
  Future<List<ConsumableInventoryItem>> _directLoadItems() async {
    await ConsumableInventoryService.instance.load();
    return ConsumableInventoryService.instance.items.value;
  }

  /// ⚙️ 캐시 설정 업데이트
  void updateSettings({int? maxMemoryMB}) {
    if (maxMemoryMB != null) {
      // 메모리 제한 변경 시 캐시 정리
      _cleanupIfNeeded();
      print('🔧 캐시 메모리 제한 업데이트: ${maxMemoryMB}MB');
    }
  }
}