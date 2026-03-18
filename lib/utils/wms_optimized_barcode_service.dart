import 'dart:async';
import '../models/global_product.dart';
import '../services/global_product_service.dart';
import '../services/openfoodfacts_service.dart';
import 'wms_database_pool.dart';

/// WMS 바코드 검색 최적화 서비스
class WmsOptimizedBarcodeService {
  WmsOptimizedBarcodeService._();
  static final WmsOptimizedBarcodeService instance =
      WmsOptimizedBarcodeService._();

  GlobalProductService? _globalService;
  late OpenFoodFactsService _offService;
  bool _isInitialized = false;

  // 검색 결과 캐시 (바코드별)
  final Map<String, GlobalProduct> _barcodeCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(hours: 1);

  /// 🚀 초기화 (한번만)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // DB 연결 풀 사용
      final db = await WmsDatabasePool.instance.getGlobalProductDb();
      _globalService = GlobalProductService(db: db);
      _offService = OpenFoodFactsService();
      _isInitialized = true;
    } catch (e) {
      print('바코드 서비스 초기화 실패: $e');
      rethrow;
    }
  }

  /// 🔍 최적화된 바코드 검색 (병렬 + 타임아웃)
  Future<WmsBarcodeSearchResult> searchBarcode(
    String barcode, {
    Duration timeout = const Duration(seconds: 3),
    bool useCache = true,
  }) async {
    await initialize();

    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) {
      return WmsBarcodeSearchResult.empty();
    }

    // 캐시 확인
    if (useCache && _isCacheValid(cleanBarcode)) {
      final cachedProduct = _barcodeCache[cleanBarcode]!;
      return WmsBarcodeSearchResult(
        product: cachedProduct,
        source: 'cache',
        searchTimeMs: 0,
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      // 🚀 병렬 검색 (로컬 DB + OpenFoodFacts)
      final searchResults = await Future.wait([
        _searchLocalDatabase(cleanBarcode),
        _searchOpenFoodFacts(cleanBarcode).timeout(
          Duration(seconds: 2), // OFF API는 2초 제한
          onTimeout: () => null,
        ),
      ]).timeout(timeout);

      final localProduct = searchResults[0];
      final offProduct = searchResults[1];

      GlobalProduct? finalProduct;
      String source = 'none';

      // 결과 우선순위: 로컬 DB > OpenFoodFacts
      if (localProduct != null) {
        finalProduct = localProduct;
        source = 'local';
      } else if (offProduct != null) {
        finalProduct = offProduct;
        source = 'openfoodfacts';

        // OFF에서 찾은 경우 로컬 DB에 캐시
        await _cacheToLocalDb(finalProduct);
      }

      // 메모리 캐시 업데이트
      if (finalProduct != null) {
        _updateMemoryCache(cleanBarcode, finalProduct);
      }

      return WmsBarcodeSearchResult(
        product: finalProduct,
        source: source,
        searchTimeMs: stopwatch.elapsedMilliseconds,
      );
    } on TimeoutException {
      return WmsBarcodeSearchResult(
        product: null,
        source: 'timeout',
        searchTimeMs: stopwatch.elapsedMilliseconds,
        error: '검색 시간 초과 (${timeout.inSeconds}초)',
      );
    } catch (e) {
      return WmsBarcodeSearchResult(
        product: null,
        source: 'error',
        searchTimeMs: stopwatch.elapsedMilliseconds,
        error: '검색 오류: $e',
      );
    } finally {
      stopwatch.stop();
    }
  }

  /// 📊 배치 바코드 검색 (여러 바코드를 한번에)
  Future<Map<String, WmsBarcodeSearchResult>> searchBarcodesBatch(
    List<String> barcodes, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await initialize();

    final results = <String, WmsBarcodeSearchResult>{};
    final searchTasks = <String, Future<WmsBarcodeSearchResult>>{};

    // 병렬 검색 시작
    for (final barcode in barcodes) {
      if (barcode.trim().isNotEmpty) {
        searchTasks[barcode] = searchBarcode(
          barcode,
          timeout: Duration(seconds: 2), // 배치에서는 개별 타임아웃 단축
        );
      }
    }

    // 모든 검색 완료 대기 (전체 타임아웃 적용)
    try {
      final completedResults = await Future.wait(
        searchTasks.values,
        eagerError: false,
      ).timeout(timeout);

      int index = 0;
      for (final barcode in searchTasks.keys) {
        results[barcode] = completedResults[index++];
      }
    } on TimeoutException {
      // 타임아웃 시 미완료/완료 구분 없이 타임아웃 결과로 반환
      for (final entry in searchTasks.entries) {
        results[entry.key] = WmsBarcodeSearchResult(
          product: null,
          source: 'batch_timeout',
          searchTimeMs: timeout.inMilliseconds,
          error: '배치 검색 시간 초과',
        );
      }
    }

    return results;
  }

  /// 🏪 로컬 DB 검색
  Future<GlobalProduct?> _searchLocalDatabase(String barcode) async {
    try {
      return await _globalService?.searchByBarcode(barcode);
    } catch (e) {
      print('로컬 DB 검색 오류: $e');
      return null;
    }
  }

  /// 🌐 OpenFoodFacts 검색
  Future<GlobalProduct?> _searchOpenFoodFacts(String barcode) async {
    try {
      return await _offService.searchByBarcode(barcode);
    } catch (e) {
      print('OpenFoodFacts 검색 오류: $e');
      return null;
    }
  }

  /// 💾 로컬 DB에 캐시 저장
  Future<void> _cacheToLocalDb(GlobalProduct product) async {
    try {
      // GlobalProductService에 insert API가 없어 로컬 DB 캐시는 생략
    } catch (e) {
      print('로컬 DB 캐시 저장 오류: $e');
    }
  }

  /// 📝 메모리 캐시 업데이트
  void _updateMemoryCache(String barcode, GlobalProduct product) {
    _barcodeCache[barcode] = product;
    _cacheTimestamps[barcode] = DateTime.now();

    // 캐시 크기 제한 (최대 500개)
    if (_barcodeCache.length > 500) {
      _cleanOldCache();
    }
  }

  /// ✅ 캐시 유효성 확인
  bool _isCacheValid(String barcode) {
    if (!_barcodeCache.containsKey(barcode)) return false;

    final timestamp = _cacheTimestamps[barcode];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  /// 🧹 오래된 캐시 정리
  void _cleanOldCache() {
    final now = DateTime.now();
    final oldEntries = <String>[];

    _cacheTimestamps.forEach((barcode, timestamp) {
      if (now.difference(timestamp) > _cacheValidDuration) {
        oldEntries.add(barcode);
      }
    });

    for (final barcode in oldEntries) {
      _barcodeCache.remove(barcode);
      _cacheTimestamps.remove(barcode);
    }
  }

  /// 🗑️ 캐시 무효화
  void clearCache() {
    _barcodeCache.clear();
    _cacheTimestamps.clear();
  }

  /// 📊 성능 통계
  Map<String, dynamic> getPerformanceStats() {
    return {
      'cacheSize': _barcodeCache.length,
      'isInitialized': _isInitialized,
      'cacheHitRatio': _calculateCacheHitRatio(),
    };
  }

  double _calculateCacheHitRatio() {
    // 간단한 캐시 히트율 계산 (실제로는 별도 카운터 필요)
    return _barcodeCache.isNotEmpty ? 0.0 : 0.0; // TODO: 실제 구현
  }
}

/// 바코드 검색 결과
class WmsBarcodeSearchResult {
  final GlobalProduct? product;
  final String source; // 'cache', 'local', 'openfoodfacts', 'timeout', 'error'
  final int searchTimeMs;
  final String? error;

  const WmsBarcodeSearchResult({
    required this.product,
    required this.source,
    required this.searchTimeMs,
    this.error,
  });

  factory WmsBarcodeSearchResult.empty() {
    return const WmsBarcodeSearchResult(
      product: null,
      source: 'empty',
      searchTimeMs: 0,
    );
  }

  bool get isSuccess => product != null;
  bool get isFromCache => source == 'cache';
  bool get isTimeout => source == 'timeout' || source == 'batch_timeout';
  bool get hasError => error != null;
}
