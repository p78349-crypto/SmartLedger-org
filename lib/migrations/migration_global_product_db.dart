// Database Migration for Global Product Database
//
// Creates global_product_master table and indexes
//
// Migration: 2026-02-14
// Version: 1

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../utils/app_logger.dart';

/// Run migration to crear global product database
///
/// This migration:
/// 1. Creates global_product_master table
/// 2. Creates B-tree indexes for fast lookups
/// 3. Initializes sample Korean data (optional)
Future<void> migrationGlobalProductDatabase(Database db) async {
  AppLogger.info('[Migration] Starting global product database setup...');
  
  try {
    // Check if table already exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='global_product_master'"
    );
    
    if (tables.isNotEmpty) {
      AppLogger.info('[Migration] Table already exists, skipping creation');
      return;
    }
    
    // Create main table
    await db.execute('''
      CREATE TABLE global_product_master (
        -- Primary key
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        
        -- Barcode fields (at least one should be non-null)
        ean13 TEXT,                         -- EAN-13 (Europe, Global)
        upc_a TEXT,                         -- UPC-A (USA, Canada)  
        jan_code TEXT,                      -- JAN (Japan)
        kan_code TEXT,                      -- KAN_CODE (Korea - 유통 표준 코드)
        
        -- Product names (localized)
        product_name_ko TEXT,               -- Korean name
        product_name_en TEXT,               -- English name
        product_name_ja TEXT,               -- Japanese name
        
        -- Product categories (hierarchical)
        category_1 TEXT,                    -- Large category (대분류)
        category_2 TEXT,                    -- Medium category (중분류)
        category_3 TEXT,                    -- Small category (소분류)
        category_4 TEXT,                    -- Details category (세분류)
        
        -- Product details
        manufacturer TEXT,                  -- Manufacturer or distributor
        packaging_unit TEXT,                -- Unit (병, 팩, 상자, etc)
        default_quantity INTEGER DEFAULT 1, -- Default quantity for input
        country_code TEXT DEFAULT 'KR',     -- Country (KR, US, JP, etc)
        
        -- Nutrition information (per 100g or per serving)
        calories_per_100g REAL,
        protein_per_100g REAL,
        fat_per_100g REAL,
        carbs_per_100g REAL,
        
        -- Status and metadata
        is_active BOOLEAN DEFAULT 1,        -- Soft delete flag
        data_source TEXT,                   -- Origin (korean, usda, openfoodfacts, manual)
        
        -- Timestamps
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        -- Constraints
        UNIQUE(ean13, upc_a, jan_code, kan_code)
      )
    ''');
    
    AppLogger.info('[Migration] ✓ Table created: global_product_master');
    
    // Create indexes for fast lookups
    await db.execute('CREATE INDEX idx_ean13 ON global_product_master(ean13)');
    AppLogger.info('[Migration] ✓ Index created: idx_ean13');
    
    await db.execute('CREATE INDEX idx_upc_a ON global_product_master(upc_a)');  
    AppLogger.info('[Migration] ✓ Index created: idx_upc_a');
    
    await db.execute('CREATE INDEX idx_jan_code ON global_product_master(jan_code)');
    AppLogger.info('[Migration] ✓ Index created: idx_jan_code');
    
    await db.execute('CREATE INDEX idx_kan_code ON global_product_master(kan_code)');
    AppLogger.info('[Migration] ✓ Index created: idx_kan_code');
    
    // Additional indexes for searching
    await db.execute('CREATE INDEX idx_product_name_ko ON global_product_master(product_name_ko)');
    AppLogger.info('[Migration] ✓ Index created: idx_product_name_ko');
    
    await db.execute('CREATE INDEX idx_category_1 ON global_product_master(category_1)');
    AppLogger.info('[Migration] ✓ Index created: idx_category_1');
    
    await db.execute('CREATE INDEX idx_country_code ON global_product_master(country_code)');
    AppLogger.info('[Migration] ✓ Index created: idx_country_code');
    
    // Composite index for common searches
    await db.execute('CREATE INDEX idx_country_active ON global_product_master(country_code, is_active)');
    AppLogger.info('[Migration] ✓ Index created: idx_country_active');
    
    AppLogger.info('[Migration] ✓ Global product database setup complete!');
    
  } catch (e) {
    AppLogger.error('[Migration] ✗ Error', error: e);
    rethrow;
  }
}

/// Sample data for Korean products (KAN_CODE based)
/// This data comes from '식료품 데이터.xlsx'
const List<Map<String, dynamic>> koreanProductSamples = [
  {
    'kan_code': '01010101',
    'category_1': '가공식품',
    'category_2': '조미료',
    'category_3': '종합조미료',
    'category_4': '천연/발효조미료',
    'product_name_ko': '간장 (자연발효)',
    'default_quantity': 2,
    'country_code': 'KR',
    'data_source': 'korean',
  },
  {
    'kan_code': '01010102',
    'category_1': '가공식품',
    'category_2': '조미료',
    'category_3': '종합조미료',
    'category_4': '식초',
    'product_name_ko': '식초 (천연)',
    'default_quantity': 2,
    'country_code': 'KR',
    'data_source': 'korean',
  },
  {
    'kan_code': '01010103',
    'category_1': '가공식품',
    'category_2': '조미료',
    'category_3': '종합조미료',
    'category_4': '천일염',
    'product_name_ko': '천일염',
    'default_quantity': 2,
    'country_code': 'KR',
    'data_source': 'korean',
  },
];

/// Insert sample Korean products into database
/// Only inserts if table is empty (development/testing only)
Future<void> insertSampleKoreanProducts(Database db) async {
  AppLogger.info('[Migration] Checking for existing data...');
  
  try {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM global_product_master'
    );
    
    final count = (result.first['count'] as int?) ?? 0;
    
    if (count == 0) {
      AppLogger.info('[Migration] Database empty, inserting sample data...');
      
      for (final sample in koreanProductSamples) {
        sample['created_at'] = DateTime.now().toIso8601String();
        sample['updated_at'] = DateTime.now().toIso8601String();
        
        await db.insert(
          'global_product_master',
          sample,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      
      AppLogger.info('[Migration] ✓ Sample Korean products inserted: ${koreanProductSamples.length}');
    } else {
      AppLogger.info('[Migration] Database already has $count products, skipping sample insert');
    }
  } catch (e) {
    AppLogger.error('[Migration] ✗ Error inserting sample data', error: e);
    // Don't rethrow - sample data is optional
  }
}

/// Verify migration was successful
Future<bool> verifyGlobalProductDatabase(Database db) async {
  try {
    // Check table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='global_product_master'"
    );
    
    if (tables.isEmpty) {
      AppLogger.warn('[Verify] ✗ Table does not exist');
      return false;
    }
    
    // Check indexes
    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='global_product_master'"
    );
    
    final indexNames = indexes
        .map((i) => i['name'] as String)
        .toList();
    
    AppLogger.info('[Verify] ✓ Table exists with ${indexNames.length} indexes');
    AppLogger.info('[Verify] Indexes: ${indexNames.join(", ")}');
    
    // Check data
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM global_product_master'
    );
    
    final productCount = (result.first['count'] as int?) ?? 0;
    AppLogger.info('[Verify] ✓ Products in database: $productCount');
    
    return true;
  } catch (e) {
    AppLogger.error('[Verify] ✗ Verification failed', error: e);
    return false;
  }
}
