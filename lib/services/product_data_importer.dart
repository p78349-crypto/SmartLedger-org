// Barcode Data Import Utility
//
// Handles importing product data from CSV/Excel files
// Currently supports: Korean product classification data
//
// Usage:
//   final importer = ProductDataImporter(db);
//   await importer.importKoreanProductsFromCsv(filePath);

import 'dart:io';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../utils/app_logger.dart';

class ProductDataImporter {
  final Database _db;
  
  ProductDataImporter({required Database db}) : _db = db;
  
  /// Import Korean products from CSV file
  /// 
  /// Expected CSV format:
  /// kan_code,category_1,category_2,category_3,category_4,product_name_ko
  /// 01010101,가공식품,조미료,종합조미료,천연/발효조미료,간장 (자연발효)
  /// 01010102,가공식품,조미료,종합조미료,식초,식초 (천연)
  /// ...
  /// 
  /// File can be:
  /// - Local path: /path/to/file.csv
  /// - URL: https://example.com/products.csv
  Future<ImportResult> importKoreanProductsFromCsv(
    String filePath, {
    bool clearExisting = false,
    int batchSize = 1000,
    void Function(int current, int total)? onProgress,
  }) async {
    final startTime = DateTime.now();
    final result = ImportResult();
    
    try {
      AppLogger.info('[Importer] Starting Korean product import from: $filePath');
      
      // Clear existing data if requested
      if (clearExisting) {
        await _db.delete('global_product_master', 
          where: 'country_code = ?', 
          whereArgs: ['KR']
        );
        AppLogger.info('[Importer] Cleared existing Korean products');
      }
      
      // Read file
      String csvContent;
      if (filePath.startsWith('http')) {
        // TODO: Implement URL download
        throw UnimplementedError('URL import not yet implemented');
      } else {
        final file = File(filePath);
        if (!file.existsSync()) {
          throw FileSystemException('File not found', filePath);
        }
        csvContent = file.readAsStringSync();
      }
      
      // Parse CSV
      final lines = csvContent.split('\n');
      if (lines.isEmpty) {
        throw const FormatException('CSV file is empty');
      }
      
      // Skip header and parse
      AppLogger.info('[Importer] Parsing CSV (${lines.length} lines)...');
      final totalLines = lines.length > 1 ? lines.length - 1 : 0;
      final products = <Map<String, dynamic>>[];
      final now = DateTime.now().toIso8601String();
      
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        try {
          final product = _parseCsvLine(line, now);
          if (product != null) {
            products.add(product);
          }
          if (onProgress != null && i % 200 == 0) {
            onProgress(i, totalLines);
          }
        } catch (e) {
          AppLogger.warn('[Importer] ✗ Error parsing line $i: $e');
          result.skipped++;
        }
      }

      if (onProgress != null) {
        onProgress(totalLines, totalLines);
      }
      
      AppLogger.info('[Importer] Parsed ${products.length} products');
      result.parsed = products.length;
      
      // Batch insert
      AppLogger.info('[Importer] Inserting in batches (size: $batchSize)...');
      
      for (int i = 0; i < products.length; i += batchSize) {
        final batch = products.sublist(
          i,
          (i + batchSize).clamp(0, products.length),
        );
        
        try {
          final countBefore = await _getProductCount('KR');
          
          for (final product in batch) {
            await _db.insert(
              'global_product_master',
              product,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          
          final countAfter = await _getProductCount('KR');
          result.inserted += countAfter - countBefore;
          
          AppLogger.info('[Importer] Batch inserted: ${batch.length} (total: ${result.inserted})');
          
        } catch (e) {
          AppLogger.error('[Importer] ✗ Batch insert failed', error: e);
          result.errors.add('Batch insert failed: $e');
        }
      }
      
      // Verify
      final finalCount = await _getProductCount('KR');
      AppLogger.info('[Importer] ✓ Import complete! Korean products: $finalCount');
      
      result.success = true;
      result.finalCount = finalCount;
      result.duration = DateTime.now().difference(startTime);
      
      return result;
      
    } catch (e) {
      AppLogger.error('[Importer] ✗ Import failed', error: e);
      result.success = false;
      result.errors.add(e.toString());
      result.duration = DateTime.now().difference(startTime);
      return result;
    }
  }
  
  /// Parse single CSV line
  /// Format: kan_code, category_1, category_2, category_3, category_4, product_name_ko (optional)
  Map<String, dynamic>? _parseCsvLine(String line, String timestamp) {
    try {
      final parts = _parseCsvRow(line);
      
      if (parts.length < 5) {
        AppLogger.warn('[Parser] Invalid format (${parts.length} columns, expected 5+)');
        return null;
      }
      
      final kanCode = parts[0].trim();
      final cate1 = parts[1].trim();
      final cate2 = parts[2].trim();
      final cate3 = parts[3].trim();
      final cate4 = parts[4].trim();
      final productName = parts.length > 5 ? parts[5].trim() : null;
      
      // Validate KAN_CODE (should be 8 digits)
      if (kanCode.isEmpty || kanCode.length != 8) {
        AppLogger.warn('[Parser] Invalid KAN_CODE: $kanCode');
        return null;
      }
      
      return {
        'kan_code': kanCode,
        'category_1': cate1,
        'category_2': cate2,
        'category_3': cate3,
        'category_4': cate4,
        'product_name_ko': productName,
        'default_quantity': 2,  // Korean default
        'country_code': 'KR',
        'data_source': 'korean',
        'created_at': timestamp,
        'updated_at': timestamp,
      };
      
    } catch (e) {
      AppLogger.error('[Parser] ✗ Error', error: e);
      return null;
    }
  }
  
  /// Parse CSV row (handles quoted fields)
  List<String> _parseCsvRow(String line) {
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
    return parts;
  }
  
  /// Get count of products for country
  Future<int> _getProductCount(String countryCode) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM global_product_master WHERE country_code = ?',
      [countryCode],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}

/// Result of import operation
class ImportResult {
  bool success = false;
  int parsed = 0;
  int inserted = 0;
  int skipped = 0;
  int finalCount = 0;
  Duration duration = Duration.zero;
  List<String> errors = [];
  
  @override
  String toString() => '''
ImportResult(
  success: $success,
  parsed: $parsed,
  inserted: $inserted,
  skipped: $skipped,
  final: $finalCount,
  duration: ${duration.inSeconds}s,
  errors: ${errors.length}
)
''';
}

/// CSV Processing Utilities
class CsvUtils {
  /// Parse CSV with proper quote handling
  static List<List<String>> parseCsv(String content) {
    final rows = <List<String>>[];
    final lines = content.split('\n');
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      rows.add(_parseLine(line));
    }
    
    return rows;
  }
  
  /// Parse single CSV line
  static List<String> _parseLine(String line) {
    final fields = <String>[];
    bool inQuotes = false;
    String current = '';
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      final nextChar = i + 1 < line.length ? line[i + 1] : '';
      
      if (char == '"') {
        if (inQuotes && nextChar == '"') {
          // Escaped quote
          current += '"';
          // i++ at end of loop
        } else {
          // Toggle quote mode
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(current);
        current = '';
      } else {
        current += char;
      }
    }
    
    fields.add(current);
    return fields.map((f) => f.trim()).toList();
  }
}
