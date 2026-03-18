// Japan MEXT Kagsei Food Database Parser
//
// Handles parsing and importing Japanese food data from XLSX files
//
// Data structure:
// - 年号 (Year)
// - 食品コード (Food Code = JAN-like)
// - 食品名 (Food Name)
// - 分類 (Category)
// - 栄養素... (Nutrients)

import 'dart:io';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'product_data_importer.dart';

import '../utils/app_logger.dart';

class JapanExcelParser {
  /// Parse Japanese MEXT XLSX file
  ///
  /// Japanese file format:
  /// Column A: 食品コード (Food Code - 13 digits, similar to JAN)
  /// Column B: 食品名 (Food Name)
  /// Column C: 分類 (Category)
  /// Column D+: 栄養素 (Nutrients)
  static Future<List<Map<String, dynamic>>> parseExcelFile(
    String filePath, {
    int maxProducts = -1,
    void Function(int)? onProgress,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', filePath);
    }

    AppLogger.info('[JP Parser] Reading Excel file: $filePath');
    AppLogger.info(
      '[JP Parser] File size: ${(file.lengthSync() / 1024 / 1024).toStringAsFixed(1)}MB',
    );

    // For now, return empty - actual parsing requires 'excel' package
    // which may not be available in Flutter
    AppLogger.warn(
      '[JP Parser] ⚠️  Note: Excel parsing requires external package setup',
    );
    AppLogger.info('[JP Parser] Recommended: Convert XLSX to CSV first');

    return [];
  }

  /// Alternative: Parse Japanese CSV format
  /// (After converting from XLSX)
  static List<Map<String, dynamic>> _parseJapaneseCsv(
    String csvContent, {
    int maxProducts = -1,
    void Function(int)? onProgress,
  }) {
    final products = <Map<String, dynamic>>[];
    final lines = csvContent.split('\n');
    final now = DateTime.now().toIso8601String();

    if (lines.isEmpty) return products;

    // Skip header (first row)
    int count = 0;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final product = _parseJapaneseCsvLine(line, now);
        if (product != null) {
          products.add(product);
          count++;

          if (maxProducts > 0 && count >= maxProducts) {
            AppLogger.info('[JP Parser] Reached max products: $maxProducts');
            break;
          }

          if (onProgress != null && count % 100 == 0) {
            onProgress(count);
          }
        }
      } catch (e) {
        AppLogger.warn('[JP Parser] Error parsing line $i: $e');
        continue;
      }
    }

    AppLogger.info('[JP Parser] ✓ Parsed $count Japanese products');
    return products;
  }

  /// Parse single Japanese CSV line
  /// Format: jan_code,product_name_ja,category_1,category_2,[nutrients...]
  static Map<String, dynamic>? _parseJapaneseCsvLine(
    String line,
    String timestamp,
  ) {
    try {
      final parts = _parseCsvRow(line);

      if (parts.length < 3) {
        AppLogger.warn(
          '[JP Parser] Invalid format (${parts.length} columns, need 3+)',
        );
        return null;
      }

      final janCode = parts[0].trim();
      final productName = parts[1].trim();
      final cate1 = parts[2].trim();
      final cate2 = parts.length > 3 ? parts[3].trim() : null;

      // Validate JAN code (should be 13 digits)
      if (janCode.isEmpty || janCode.length != 13) {
        AppLogger.warn('[JP Parser] Invalid JAN code: $janCode');
        return null;
      }

      // Map category
      final category = _mapJapaneseCategoryToEnglish(cate1, cate2);

      return {
        'jan_code': janCode,
        'product_name_ja': productName,
        'product_name_en':
            productName, // Will be improved with translation API later
        'category_1': category['main'],
        'category_2': category['sub'],
        'default_quantity': 2, // Japanese default
        'country_code': 'JP',
        'data_source': 'mext',
        'created_at': timestamp,
        'updated_at': timestamp,
      };
    } catch (e) {
      AppLogger.error('[JP Parser] Error', error: e);
      return null;
    }
  }

  /// Parse CSV row (handles quoted fields)
  static List<String> _parseCsvRow(String line) {
    final parts = <String>[];
    bool inQuotes = false;
    String current = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        parts.add(current);
        current = '';
      } else {
        current += char;
      }
    }

    parts.add(current);
    return parts.map((p) => p.trim()).toList();
  }

  /// Map Japanese categories to English
  static Map<String, String> _mapJapaneseCategoryToEnglish(
    String jaMain,
    String? jaSub,
  ) {
    final jaLower = jaMain.toLowerCase();

    String main = 'Food';
    String? sub;

    if (jaLower.contains('飲') || jaLower.contains('飲料')) {
      main = 'Beverages';
    } else if (jaLower.contains('肉') || jaLower.contains('鶏')) {
      main = 'Meat & Poultry';
    } else if (jaLower.contains('乳') || jaLower.contains('チーズ')) {
      main = 'Dairy';
    } else if (jaLower.contains('魚') || jaLower.contains('水産')) {
      main = 'Seafood';
    } else if (jaLower.contains('野菜') || jaLower.contains('果物')) {
      main = 'Produce';
    } else if (jaLower.contains('穀')) {
      main = 'Grains';
    } else if (jaLower.contains('菓子') || jaLower.contains('スナック')) {
      main = 'Snacks';
    } else if (jaLower.contains('調味') || jaLower.contains('香辛')) {
      main = 'Condiments';
    }

    if (jaSub != null) {
      sub = jaSub;
    }

    return {'main': main, 'sub': sub ?? main};
  }
}

/// Importer for Japanese products (MEXT)
class JapanProductImporter {
  final Database _db;

  JapanProductImporter({required Database db}) : _db = db;

  /// Import Japanese products from CSV (converted from XLSX)
  Future<ImportResult> importJapaneseProductsFromCsv(
    String filePath, {
    int maxProducts = -1,
    int batchSize = 1000,
  }) async {
    final startTime = DateTime.now();
    final result = ImportResult();

    try {
      AppLogger.info('[JP Importer] Starting import from: $filePath');

      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileSystemException('File not found', filePath);
      }

      // Read CSV
      final content = file.readAsStringSync();

      // Parse CSV
      final products = JapanExcelParser._parseJapaneseCsv(
        content,
        maxProducts: maxProducts,
        onProgress: (count) {
          AppLogger.info('[JP Importer] Parsed: $count products...');
        },
      );

      result.parsed = products.length;

      if (products.isEmpty) {
        AppLogger.warn('[JP Importer] No products to import');
        result.success = true;
        return result;
      }

      // Batch insert
      AppLogger.info('[JP Importer] Inserting ${products.length} products...');

      for (int i = 0; i < products.length; i += batchSize) {
        final batch = products.sublist(
          i,
          (i + batchSize).clamp(0, products.length),
        );

        try {
          final countBefore = await _getProductCount('JP');

          for (final product in batch) {
            await _db.insert(
              'global_product_master',
              product,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          final countAfter = await _getProductCount('JP');
          result.inserted += countAfter - countBefore;

          AppLogger.info(
            '[JP Importer] Batch inserted: ${batch.length} (total: ${result.inserted})',
          );
        } catch (e) {
          AppLogger.error('[JP Importer] ✗ Batch failed', error: e);
          result.errors.add('Batch insert failed: $e');
        }
      }

      final finalCount = await _getProductCount('JP');
      AppLogger.info(
        '[JP Importer] ✓ Import complete! JP products: $finalCount',
      );

      result.success = true;
      result.finalCount = finalCount;
      result.duration = DateTime.now().difference(startTime);

      return result;
    } catch (e) {
      AppLogger.error('[JP Importer] ✗ Import failed', error: e);
      result.success = false;
      result.errors.add(e.toString());
      result.duration = DateTime.now().difference(startTime);
      return result;
    }
  }

  /// Get count of Japanese products
  Future<int> _getProductCount(String countryCode) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM global_product_master WHERE country_code = ?',
      [countryCode],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
