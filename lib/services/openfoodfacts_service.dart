// OpenFoodFacts API Integration
//
// Provides online product lookup for barcodes not found in local database
//
// API: https://world.openfoodfacts.org/api/v0/products/{barcode}
//
// Features:
// - Real-time product lookup
// - Multi-language support
// - Images and detailed info
// - Caching support

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/global_product.dart';
import '../utils/app_logger.dart';

class OpenFoodFactsService {
  static const String baseUrl = 'https://world.openfoodfacts.org';
  static const String apiVersion = 'api/v0';

  final http.Client _httpClient;
  final Duration _timeout;

  // Response cache (simple in-memory cache)
  final Map<String, GlobalProduct?> _cache = {};
  static const int maxCacheSize = 500;

  OpenFoodFactsService({
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 10),
  }) : _httpClient = httpClient ?? http.Client(),
       _timeout = timeout;

  /// Search product by barcode (EAN-13, UPC-A, etc.)
  ///
  /// Returns GlobalProduct if found, null otherwise
  Future<GlobalProduct?> searchByBarcode(String barcode) async {
    if (barcode.isEmpty) return null;

    final normalized = _normalizeBarcode(barcode);

    // Check cache first
    if (_cache.containsKey(normalized)) {
      AppLogger.info('[OFF] Cache HIT: $normalized');
      return _cache[normalized];
    }

    AppLogger.info('[OFF] Cache MISS, querying API: $normalized');

    try {
      final response = await _makeRequest('/products/$normalized');

      if (response == null) {
        _addToCache(normalized, null);
        return null;
      }

      final product = _convertOffToGlobalProduct(response);
      _addToCache(normalized, product);

      return product;
    } catch (e) {
      AppLogger.error('[OFF] Error', error: e);
      return null;
    }
  }

  /// Search by barcode with fallback to local DB
  ///
  /// This should be called from PDA screen after local search fails
  Future<GlobalProduct?> searchAsFallback(String barcode) async {
    AppLogger.info('[OFF] Using as fallback search for: $barcode');
    return searchByBarcode(barcode);
  }

  /// Make API request to OpenFoodFacts
  Future<Map<String, dynamic>?> _makeRequest(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl/$apiVersion$endpoint.json');
      AppLogger.info('[OFF] GET $url');

      final response = await _httpClient.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // Check if product was found
        final product = json['product'];
        if (product is! Map || (json['status'] as int?) == 0) {
          AppLogger.warn('[OFF] Product not found');
          return null;
        }

        AppLogger.info('[OFF] Product found: ${product['product_name']}');
        return Map<String, dynamic>.from(product);
      } else if (response.statusCode == 404) {
        AppLogger.warn('[OFF] Product not found (404)');
        return null;
      } else {
        AppLogger.error('[OFF] API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.error('[OFF] Request failed', error: e);
      return null;
    }
  }

  /// Convert OpenFoodFacts response to GlobalProduct
  GlobalProduct? _convertOffToGlobalProduct(Map<String, dynamic> data) {
    try {
      // Extract barcodes
      final ean13 = data['ean13'] as String?;
      final upc = data['upc'] as String?;
      String? barcode;

      if (ean13 != null && ean13.isNotEmpty) {
        barcode = ean13;
      } else if (upc != null && upc.isNotEmpty) {
        barcode = upc;
      }

      // Extract product name
      final productName = data['product_name'] as String?;
      if (productName == null || productName.isEmpty) {
        AppLogger.warn('[OFF] No product name, skipping');
        return null;
      }

      String? nameKo;
      String? nameJa;
      final String nameEn = productName;

      if (data['product_name_ko'] is String) {
        nameKo = data['product_name_ko'];
      }
      if (data['product_name_ja'] is String) {
        nameJa = data['product_name_ja'];
      }

      // Extract categories
      final categoriesStr = data['categories'] as String?;
      final categories = <String>[];
      if (categoriesStr != null) {
        categories.addAll(
          categoriesStr.split(',').map((c) => c.trim()).take(4),
        );
      }

      // Extract manufacturer
      final brands = data['brands'] as String?;

      // Extract nutrition (per 100g)
      final nutrientsObj = data['nutriments'] as Map?;
      double? calories;
      double? protein;
      double? fat;
      double? carbs;

      if (nutrientsObj != null) {
        // OpenFoodFacts stores nutrition as nutrient_100g
        calories = _toDouble(nutrientsObj['energy-kcal_100g']);
        protein = _toDouble(nutrientsObj['proteins_100g']);
        fat = _toDouble(nutrientsObj['fat_100g']);
        carbs = _toDouble(nutrientsObj['carbohydrates_100g']);
      }

      // Determine country from barcode prefix or available data
      final countryCode = _detectCountryFromBarcode(barcode ?? '');

      return GlobalProduct(
        id: 0, // Will be auto-generated on insert
        ean13: ean13,
        upcA: upc,
        productNameKo: nameKo,
        productNameEn: nameEn,
        productNameJa: nameJa,
        category1: categories.isNotEmpty ? categories[0] : 'Food',
        category2: categories.length > 1 ? categories[1] : null,
        category3: categories.length > 2 ? categories[2] : null,
        category4: categories.length > 3 ? categories[3] : null,
        manufacturer: brands,
        countryCode: countryCode,
        caloriesPer100g: calories,
        proteinPer100g: protein,
        fatPer100g: fat,
        carbsPer100g: carbs,
        dataSource: 'openfoodfacts',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('[OFF] Conversion error', error: e);
      return null;
    }
  }

  /// Detect country from barcode prefix
  ///
  /// EAN-13 prefix rules:
  /// 60-64: UK
  /// 30-37: France
  /// 40-43: Germany
  /// 45, 49: Japan
  /// 50: UK
  /// 55: Brazil
  /// 88: Korea
  /// 00-09: US/Canada (sometimes)
  static String _detectCountryFromBarcode(String barcode) {
    if (barcode.isEmpty || barcode.length < 2) {
      return 'XX'; // Unknown
    }

    final prefix = int.tryParse(barcode.substring(0, 2)) ?? -1;

    return switch (prefix) {
      >= 60 && <= 64 => 'GB', // UK
      >= 30 && <= 37 => 'FR', // France
      >= 40 && <= 43 => 'DE', // Germany
      45 || 49 => 'JP', // Japan
      50 => 'GB', // UK
      55 => 'BR', // Brazil
      88 => 'KR', // Korea
      _ => 'XX', // Unknown
    };
  }

  /// Normalize barcode
  String _normalizeBarcode(String barcode) {
    return barcode.trim().replaceAll(RegExp(r'[\s\-()]'), '').toUpperCase();
  }

  /// Add to cache (with LRU eviction)
  void _addToCache(String barcode, GlobalProduct? product) {
    if (_cache.length >= maxCacheSize) {
      // Remove oldest entry
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    _cache[barcode] = product;
  }

  /// Convert to double safely
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'items': _cache.length,
      'maxSize': maxCacheSize,
      'utilization': ((_cache.length / maxCacheSize) * 100).toInt(),
    };
  }

  /// Close HTTP client
  void dispose() {
    _httpClient.close();
  }
}
