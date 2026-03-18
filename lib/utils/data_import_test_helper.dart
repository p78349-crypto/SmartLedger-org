import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../migrations/migration_global_product_db.dart';
import '../services/product_data_importer.dart';
import '../services/us_product_importer.dart';
import '../services/japan_product_importer.dart';
import 'app_logger.dart';

/// Test utility for verifying data import functionality
class DataImportTestHelper {
  static Future<Database> _openGlobalProductDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'global_products.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await migrationGlobalProductDatabase(db);
      },
    );
  }

  /// Test Korean data import
  static Future<void> testKoreanImport(String filePath) async {
    AppLogger.info('[TEST] Starting Korean data import test...');
    AppLogger.info('[TEST] File: $filePath');
    AppLogger.info('[TEST] File exists: ${File(filePath).existsSync()}');

    try {
      final db = await _openGlobalProductDb();
      final importer = ProductDataImporter(db: db);
      final result = await importer.importKoreanProductsFromCsv(
        filePath,
        onProgress: (current, total) {
          if (current % 100 == 0) {
            AppLogger.info('[TEST] Korean progress: $current/$total');
          }
        },
      );

      AppLogger.info('[TEST] ✓ Korean import result:');
      AppLogger.info('[TEST]   Success: ${result.success}');
      AppLogger.info('[TEST]   Items inserted: ${result.inserted}');
      AppLogger.info('[TEST]   Items skipped: ${result.skipped}');
      AppLogger.info('[TEST]   Errors: ${result.errors.length}');
    } catch (e) {
      AppLogger.error('[TEST] ✗ Korean import error', error: e);
    }
  }

  /// Test US data import
  static Future<void> testUsImport(String filePath) async {
    AppLogger.info('[TEST] Starting US data import test...');
    AppLogger.info('[TEST] File: $filePath');
    AppLogger.info('[TEST] File exists: ${File(filePath).existsSync()}');
    AppLogger.info(
      '[TEST] File size: ${File(filePath).lengthSync() / (1024 * 1024)} MB',
    );

    try {
      final db = await _openGlobalProductDb();
      final importer = UsProductImporter(db: db);
      final result = await importer.importUsProductsFromJson(filePath);

      AppLogger.info('[TEST] ✓ US import result:');
      AppLogger.info('[TEST]   Success: ${result.success}');
      AppLogger.info('[TEST]   Items inserted: ${result.inserted}');
      AppLogger.info('[TEST]   Items skipped: ${result.skipped}');
      AppLogger.info('[TEST]   Errors: ${result.errors.length}');
    } catch (e) {
      AppLogger.error('[TEST] ✗ US import error', error: e);
    }
  }

  /// Test Japan data import
  static Future<void> testJapanImport(String filePath) async {
    AppLogger.info('[TEST] Starting Japan data import test...');
    AppLogger.info('[TEST] File: $filePath');
    AppLogger.info('[TEST] File exists: ${File(filePath).existsSync()}');

    try {
      final db = await _openGlobalProductDb();
      final importer = JapanProductImporter(db: db);
      final result = await importer.importJapaneseProductsFromCsv(filePath);

      AppLogger.info('[TEST] ✓ Japan import result:');
      AppLogger.info('[TEST]   Success: ${result.success}');
      AppLogger.info('[TEST]   Items inserted: ${result.inserted}');
      AppLogger.info('[TEST]   Items skipped: ${result.skipped}');
      AppLogger.info('[TEST]   Errors: ${result.errors.length}');
    } catch (e) {
      AppLogger.error('[TEST] ✗ Japan import error', error: e);
    }
  }

  /// Test all imports sequentially
  static Future<void> testAllImports({
    required String koreanFilePath,
    required String usFilePath,
    required String japanFilePath,
  }) async {
    AppLogger.info('\n╔════════════════════════════════════════════╗');
    AppLogger.info('║ Global Product Database Import Test Suite ║');
    AppLogger.info('╚════════════════════════════════════════════╝\n');

    // Test Korean
    AppLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.info('[1/3] Korean Data Import');
    AppLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    await testKoreanImport(koreanFilePath);

    await Future.delayed(const Duration(seconds: 1));

    // Test US
    AppLogger.info('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.info('[2/3] US Data Import');
    AppLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    await testUsImport(usFilePath);

    await Future.delayed(const Duration(seconds: 1));

    // Test Japan
    AppLogger.info('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.info('[3/3] Japan Data Import');
    AppLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    await testJapanImport(japanFilePath);

    AppLogger.info('\n╔════════════════════════════════════════════╗');
    AppLogger.info('║ Test Suite Complete                       ║');
    AppLogger.info('╚════════════════════════════════════════════╝\n');
  }

  /// Generate sample JSON for testing US import
  static String generateSampleUsJson() {
    return '''
{
  "foods": [
    {
      "fdc_id": 1000001,
      "description": "Coca-Cola Zero Sugar, 12 FL OZ CAN",
      "gtinUpc": "033674006253",
      "foodCategory": "Beverages",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 0},
        {"nutrientId": 1003, "value": 0},
        {"nutrientId": 1004, "value": 0},
        {"nutrientId": 1005, "value": 0.1}
      ]
    },
    {
      "fdc_id": 1000002,
      "description": "Apple, Raw, Without Skin",
      "gtinUpc": "033383020008",
      "foodCategory": "Fruits and Fruit Juices",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 217},
        {"nutrientId": 1003, "value": 0.26},
        {"nutrientId": 1004, "value": 0.17},
        {"nutrientId": 1005, "value": 25.8}
      ]
    }
  ]
}
''';
  }

  /// Generate sample CSV for testing Japan import
  static String generateSampleJapanCsv() {
    return '''JAN,商品名,カテゴリ
4901000102026,日清ラーメン 醤油,インスタント食品
4901000102033,マルちゃん正麺 豚骨,インスタント食品
4901005102040,ハウス バーモンドカレー,調味料
''';
  }
}
