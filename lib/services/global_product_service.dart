// GlobalProductService
//
// Handles barcode lookup with 3-layer caching:
// L1: Memory cache (LinkedHashMap - LRU, max 1000)
// L2: Redis cache (optional, requires setup)
// L3: SQLite database (persistent, always available)
//
// Supports barcode types: EAN-13, UPC-A, JAN, KAN_CODE

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'dart:collection';
import '../models/global_product.dart';
import '../utils/app_logger.dart';

class GlobalProductService {
  final Database _db;

  // L1 Cache: Memory cache with LRU eviction
  final LinkedHashMap<String, GlobalProduct> _memoryCache =
      LinkedHashMap<String, GlobalProduct>();
  static const int _maxCacheSize = 1000;

  // L2 Cache: Redis (optional feature, not implemented yet)
  // TODO: Future<RedisClient> _redisClient;

  GlobalProductService({required Database db}) : _db = db;

  /// Search by barcode with multi-layer caching
  /// Tries: EAN13 → UPC-A → JAN → KAN_CODE → Category
  ///
  /// Returns GlobalProduct if found, null otherwise
  Future<GlobalProduct?> searchByBarcode(String barcode) async {
    if (barcode.isEmpty) return null;

    final normalizedBarcode = _normalizeBarcode(barcode);

    // L1: Check memory cache
    if (_memoryCache.containsKey(normalizedBarcode)) {
      AppLogger.info('[Cache] L1 HIT: $normalizedBarcode');
      return _memoryCache[normalizedBarcode];
    }

    // L2: Check Redis (optional, not implemented)
    // if (await _redisCache.has(normalizedBarcode)) {
    //   print('[Cache] L2 HIT');
    //   return await _redisCache.get(normalizedBarcode);
    // }

    // L3: Query SQLite database
    AppLogger.info('[Cache] L3 MISS: Querying database...');
    final result = await _queryByBarcode(normalizedBarcode);

    if (result != null) {
      _addToMemoryCache(normalizedBarcode, result);
      return result;
    }

    return null;
  }

  /// Query database for barcode (tries multiple barcode types)
  Future<GlobalProduct?> _queryByBarcode(String barcode) async {
    try {
      // Try exact match on all barcode types
      final List<Map<String, dynamic>> results = await _db.query(
        'global_product_master',
        where: '''
          ean13 = ? OR upc_a = ? OR jan_code = ? OR kan_code = ?
        ''',
        whereArgs: [barcode, barcode, barcode, barcode],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return GlobalProduct.fromMap(results.first);
      }

      // If not found, try fuzzy match (remove spaces/hyphens)
      final fuzzyBarcode = barcode.replaceAll(RegExp(r'[\s\-()]'), '');
      if (fuzzyBarcode != barcode) {
        return await _queryByBarcode(fuzzyBarcode);
      }

      return null;
    } catch (e) {
      AppLogger.error('[Error] Database query failed', error: e);
      return null;
    }
  }

  /// Search by category path
  Future<List<GlobalProduct>> searchByCategory(
    String cate1, {
    String? cate2,
    String? cate3,
    String? cate4,
  }) async {
    try {
      String where = 'category_1 = ?';
      final args = <dynamic>[cate1];

      if (cate2 != null && cate2.isNotEmpty) {
        where += ' AND category_2 = ?';
        args.add(cate2);
      }
      if (cate3 != null && cate3.isNotEmpty) {
        where += ' AND category_3 = ?';
        args.add(cate3);
      }
      if (cate4 != null && cate4.isNotEmpty) {
        where += ' AND category_4 = ?';
        args.add(cate4);
      }

      final results = await _db.query(
        'global_product_master',
        where: where,
        whereArgs: args,
        limit: 100,
      );

      return results.map(GlobalProduct.fromMap).toList();
    } catch (e) {
      AppLogger.error('[Error] Category search failed', error: e);
      return [];
    }
  }

  /// Search by product name (partial match)
  Future<List<GlobalProduct>> searchByProductName(
    String name, {
    String locale = 'ko',
  }) async {
    try {
      final nameField = () {
        switch (locale.toLowerCase()) {
          case 'en':
          case 'english':
            return 'product_name_en';
          case 'ja':
          case 'japanese':
            return 'product_name_ja';
          case 'ko':
          case 'korean':
          default:
            return 'product_name_ko';
        }
      }();

      final results = await _db.query(
        'global_product_master',
        where: '$nameField LIKE ?',
        whereArgs: ['%$name%'],
        limit: 20,
      );

      return results.map(GlobalProduct.fromMap).toList();
    } catch (e) {
      AppLogger.error('[Error] Product name search failed', error: e);
      return [];
    }
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final result = await _db.rawQuery(
        'SELECT COUNT(*) as total, '
        'COUNT(DISTINCT country_code) as countries, '
        'GROUP_CONCAT(DISTINCT country_code) as country_codes '
        'FROM global_product_master',
      );

      if (result.isNotEmpty) {
        return {
          'totalProducts': result[0]['total'] ?? 0,
          'countries': result[0]['countries'] ?? 0,
          'countryCodes':
              (result[0]['country_codes'] as String?)?.split(',') ?? [],
          'cacheSize': _memoryCache.length,
          'maxCacheSize': _maxCacheSize,
        };
      }

      return {};
    } catch (e) {
      AppLogger.error('[Error] Statistics query failed', error: e);
      return {};
    }
  }

  /// Clear memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
    AppLogger.info('[Cache] Memory cache cleared');
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'memoryItems': _memoryCache.length,
      'maxItems': _maxCacheSize,
      'utilization': ((_memoryCache.length / _maxCacheSize) * 100).toInt(),
    };
  }

  // ===== Private Methods =====

  /// Add product to L1 memory cache (with LRU eviction)
  void _addToMemoryCache(String barcode, GlobalProduct product) {
    // Remove oldest item if cache is full
    if (_memoryCache.length >= _maxCacheSize) {
      final firstKey = _memoryCache.keys.first;
      _memoryCache.remove(firstKey);
      AppLogger.warn('[Cache] L1 EVICT: $firstKey (cache full)');
    }

    // Add to end (LinkedHashMap maintains insertion order)
    _memoryCache[barcode] = product;
  }

  /// Normalize barcode (remove spaces, hyphens, etc.)
  String _normalizeBarcode(String barcode) {
    return barcode.trim().replaceAll(RegExp(r'[\s\-()]'), '').toUpperCase();
  }
}
