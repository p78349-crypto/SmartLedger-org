// US USDA FoodData_Central JSON Parser
//
// Handles parsing and importing USDA FoodData_Central datasets
//
// JSON Structure:
// {
//   "foods": [
//     {
//       "fdcId": 123456,
//       "description": "Product Name",
//       "dataType": "Branded",
//       "gtinUpc": "012345678901",  // UPC-A (12 digits)
//       "foodNutrients": [...],
//       "manufacturer": "Company Name"
//     },
//     ...
//   ]
// }

import 'dart:convert';
import 'dart:io';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'product_data_importer.dart';

import '../utils/app_logger.dart';

class UsProductJsonParser {
  /// Parse USDA FoodData_Central JSON file
  ///
  /// Handles large files (GB+) using streaming to avoid memory overflow
  static Future<List<Map<String, dynamic>>> parseJsonFile(
    String filePath, {
    int maxProducts = -1, // -1 = all products
    void Function(int)? onProgress,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', filePath);
    }

    AppLogger.info('[Parser] Reading JSON file: $filePath');
    AppLogger.info(
      '[Parser] File size: ${(file.lengthSync() / 1024 / 1024).toStringAsFixed(1)}MB',
    );

    try {
      // For small-medium files
      final jsonString = file.readAsStringSync();
      return _parseJsonString(jsonString, maxProducts, onProgress);
    } catch (e) {
      if (e.toString().contains('Out of memory')) {
        AppLogger.warn('[Parser] File too large, using streaming parser');
        return _parseJsonStreaming(filePath, maxProducts, onProgress);
      }
      rethrow;
    }
  }

  /// Parse JSON string directly
  static List<Map<String, dynamic>> _parseJsonString(
    String jsonString,
    int maxProducts,
    void Function(int)? onProgress,
  ) {
    final products = <Map<String, dynamic>>[];

    try {
      final json = jsonDecode(jsonString);
      final foods = json['foods'] as List?;

      if (foods == null) {
        AppLogger.warn('[Parser] No foods array found in JSON');
        return products;
      }

      AppLogger.info('[Parser] Parsing ${foods.length} products...');

      final now = DateTime.now().toIso8601String();
      int count = 0;

      for (final food in foods) {
        try {
          final product = _convertFoodToProduct(food, now);
          if (product != null) {
            products.add(product);
            count++;

            if (maxProducts > 0 && count >= maxProducts) {
              AppLogger.info(
                '[Parser] Reached max products limit: $maxProducts',
              );
              break;
            }

            if (onProgress != null && count % 1000 == 0) {
              onProgress(count);
            }
          }
        } catch (e) {
          AppLogger.warn('[Parser] ✗ Error parsing product: $e');
          continue;
        }
      }

      AppLogger.info('[Parser] ✓ Parsed $count products');
      return products;
    } catch (e) {
      AppLogger.error('[Parser] ✗ JSON parsing failed', error: e);
      return products;
    }
  }

  /// Parse large JSON files using line-based streaming
  static Future<List<Map<String, dynamic>>> _parseJsonStreaming(
    String filePath,
    int maxProducts,
    void Function(int)? onProgress,
  ) async {
    final products = <Map<String, dynamic>>[];
    final file = File(filePath);
    final now = DateTime.now().toIso8601String();

    int count = 0;
    String buffer = '';

    AppLogger.info('[Parser] Using streaming parser (memory efficient)');

    try {
      final stream = file.openRead().transform(utf8.decoder);

      await for (final chunk in stream) {
        buffer += chunk;

        // Find and parse individual food objects
        while (buffer.contains('{') && buffer.contains('}}')) {
          final startIdx = buffer.indexOf('{');
          if (startIdx == -1) break;

          // Find matching closing brace
          int braceCount = 0;
          int endIdx = -1;
          for (int i = startIdx; i < buffer.length; i++) {
            if (buffer[i] == '{') braceCount++;
            if (buffer[i] == '}') braceCount--;
            if (braceCount == 0) {
              endIdx = i;
              break;
            }
          }

          if (endIdx == -1) break;

          final foodJson = buffer.substring(startIdx, endIdx + 1);
          buffer = buffer.substring(endIdx + 1);

          try {
            final food = jsonDecode(foodJson);
            final product = _convertFoodToProduct(food, now);
            if (product != null) {
              products.add(product);
              count++;

              if (maxProducts > 0 && count >= maxProducts) {
                AppLogger.info(
                  '[Parser] Reached max products limit: $maxProducts',
                );
                return products;
              }

              if (onProgress != null && count % 1000 == 0) {
                onProgress(count);
              }
            }
          } catch (e) {
            // Skip malformed entries
            continue;
          }
        }
      }

      AppLogger.info('[Parser] ✓ Streamed $count products');
      return products;
    } catch (e) {
      AppLogger.error('[Parser] ✗ Streaming failed', error: e);
      return products;
    }
  }

  /// Convert USDA food object to GlobalProduct
  static Map<String, dynamic>? _convertFoodToProduct(
    Map<String, dynamic> food,
    String timestamp,
  ) {
    try {
      final description = food['description'] as String?;
      if (description == null || description.isEmpty) {
        return null;
      }

      // Extract UPC-A barcode
      String? upcA = food['gtinUpc'] as String?;
      if (upcA != null) {
        upcA = upcA.replaceAll(RegExp(r'[\s\-()]'), '');
        if (upcA.isEmpty) upcA = null;
      }

      // Extract manufacturer
      final manufacturer = food['manufacturer'] as String?;

      // Extract nutrition info
      final nutrition = _extractNutrition(food['foodNutrients'] as List?);

      return {
        'upc_a': upcA,
        'product_name_en': description,
        'category_1': 'Food', // Default, will refine later
        'category_2': _extractCategoryFromDescription(description),
        'manufacturer': manufacturer,
        'country_code': 'US',
        'calories_per_100g': nutrition?['energy'],
        'protein_per_100g': nutrition?['protein'],
        'fat_per_100g': nutrition?['fat'],
        'carbs_per_100g': nutrition?['carbs'],
        'data_source': 'usda',
        'created_at': timestamp,
        'updated_at': timestamp,
      };
    } catch (e) {
      AppLogger.error('[Converter] Error', error: e);
      return null;
    }
  }

  /// Extract nutrition info from foodNutrients array
  static Map<String, double>? _extractNutrition(List? nutrients) {
    if (nutrients == null || nutrients.isEmpty) {
      return null;
    }

    try {
      final nutrition = <String, double>{};

      for (final nutrient in nutrients) {
        if (nutrient is! Map) continue;

        final nutrientId = nutrient['nutrient']?['id'] as int?;
        final value = nutrient['value'] as num?;

        if (value == null) continue;

        switch (nutrientId) {
          case 1008: // Energy (kcal)
            nutrition['energy'] = value.toDouble();
            break;
          case 1003: // Protein (g)
            nutrition['protein'] = value.toDouble();
            break;
          case 1004: // Fat (g)
            nutrition['fat'] = value.toDouble();
            break;
          case 1005: // Carbs (g)
            nutrition['carbs'] = value.toDouble();
            break;
        }
      }

      return nutrition.isNotEmpty ? nutrition : null;
    } catch (e) {
      return null;
    }
  }

  /// Extract category from product description
  static String _extractCategoryFromDescription(String description) {
    final lower = description.toLowerCase();

    // Common categories
    if (lower.contains('beverage') ||
        lower.contains('drink') ||
        lower.contains('juice')) {
      return 'Beverages';
    }
    if (lower.contains('meat') ||
        lower.contains('beef') ||
        lower.contains('chicken')) {
      return 'Meat & Poultry';
    }
    if (lower.contains('dairy') ||
        lower.contains('milk') ||
        lower.contains('cheese')) {
      return 'Dairy';
    }
    if (lower.contains('snack') ||
        lower.contains('chip') ||
        lower.contains('candy')) {
      return 'Snacks';
    }
    if (lower.contains('bread') ||
        lower.contains('cereal') ||
        lower.contains('grain')) {
      return 'Grains & Cereals';
    }
    if (lower.contains('fruit') || lower.contains('vegetable')) {
      return 'Produce';
    }
    if (lower.contains('sauce') ||
        lower.contains('spice') ||
        lower.contains('seasoning')) {
      return 'Condiments & Spices';
    }

    return 'Packaged Foods';
  }
}

/// Importer for US products (USDA FoodData_Central)
class UsProductImporter {
  final Database _db;

  UsProductImporter({required Database db}) : _db = db;

  /// Import US products from USDA JSON
  Future<ImportResult> importUsProductsFromJson(
    String filePath, {
    int maxProducts = -1,
    int batchSize = 1000,
  }) async {
    final startTime = DateTime.now();
    final result = ImportResult();

    try {
      AppLogger.info('[US Importer] Starting import from: $filePath');

      // Parse JSON
      final products = await UsProductJsonParser.parseJsonFile(
        filePath,
        maxProducts: maxProducts,
        onProgress: (count) {
          AppLogger.info('[US Importer] Parsed: $count products...');
        },
      );

      result.parsed = products.length;

      if (products.isEmpty) {
        AppLogger.warn('[US Importer] No products to import');
        result.success = true;
        return result;
      }

      // Batch insert
      AppLogger.info(
        '[US Importer] Inserting ${products.length} products in batches of $batchSize...',
      );

      for (int i = 0; i < products.length; i += batchSize) {
        final batch = products.sublist(
          i,
          (i + batchSize).clamp(0, products.length),
        );

        try {
          final countBefore = await _getProductCount('US');

          for (final product in batch) {
            await _db.insert(
              'global_product_master',
              product,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          final countAfter = await _getProductCount('US');
          result.inserted += countAfter - countBefore;

          AppLogger.info(
            '[US Importer] Batch inserted: ${batch.length} (total: ${result.inserted})',
          );
        } catch (e) {
          AppLogger.error('[US Importer] ✗ Batch failed', error: e);
          result.errors.add('Batch insert failed: $e');
        }
      }

      final finalCount = await _getProductCount('US');
      AppLogger.info(
        '[US Importer] ✓ Import complete! US products: $finalCount',
      );

      result.success = true;
      result.finalCount = finalCount;
      result.duration = DateTime.now().difference(startTime);

      return result;
    } catch (e) {
      AppLogger.error('[US Importer] ✗ Import failed', error: e);
      result.success = false;
      result.errors.add(e.toString());
      result.duration = DateTime.now().difference(startTime);
      return result;
    }
  }

  /// Get count of US products
  Future<int> _getProductCount(String countryCode) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM global_product_master WHERE country_code = ?',
      [countryCode],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
