#!/usr/bin/env dart
// Phase 4: Test Barcode Dataset Generator
// Purpose: Generate comprehensive barcode test data for multi-country validation
// Output: test_barcodes.csv, test_barcodes.json
//
// Usage: dart test_barcode_dataset_generator.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

class TestBarcodeDataset {
  /// Generate test barcode data in CSV format
  static String generateCSV() {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      'barcode,product_name_ko,product_name_en,product_name_ja,country_code,barcode_type,expected_quantity,category_ko,use_case',
    );

    // Test Data - Korean Products (KAN_CODE)
    _addRow(
      buffer,
      barcode: '8801040234515',
      nameKo: '종로우유',
      nameEn: 'Jongno Milk 1L',
      nameJa: '牛乳',
      country: 'KR',
      type: 'KAN',
      qty: '2',
      category: '음료',
      useCase: 'Unit·Test·1·Korean·Local·DB',
    );

    _addRow(
      buffer,
      barcode: '8801000010061',
      nameKo: '동풍 우유',
      nameEn: 'Dongpung Milk',
      nameJa: 'ミルク',
      country: 'KR',
      type: 'KAN',
      qty: '2',
      category: '음료',
      useCase: 'Cache·performance·test',
    );

    _addRow(
      buffer,
      barcode: '8801001000088',
      nameKo: '남양 요거트',
      nameEn: 'Namyang Yogurt',
      nameJa: 'ヨーグルト',
      country: 'KR',
      type: 'KAN',
      qty: '2',
      category: '유제품',
      useCase: 'Multi-language·test',
    );

    _addRow(
      buffer,
      barcode: '8801093100017',
      nameKo: '오뚜기 고추장',
      nameEn: 'Ottogi Gochujang',
      nameJa: '唐辛子味噌',
      country: 'KR',
      type: 'KAN',
      qty: '2',
      category: '조미료',
      useCase: 'Normalization·test',
    );

    // Test Data - US Products (UPC-A)
    _addRow(
      buffer,
      barcode: '033674006253',
      nameKo: '코카콜라 제로',
      nameEn: 'Coca-Cola Zero Sugar 12oz',
      nameJa: 'コカ・コーラ ゼロ',
      country: 'US',
      type: 'UPC',
      qty: '1',
      category: '음료',
      useCase: 'Unit·Test·2·US·Local·DB',
    );

    _addRow(
      buffer,
      barcode: '012345678905',
      nameKo: '펩시',
      nameEn: 'Pepsi Cola 12oz',
      nameJa: 'ペプシコーラ',
      country: 'US',
      type: 'UPC',
      qty: '1',
      category: '음료',
      useCase: 'US·validation',
    );

    _addRow(
      buffer,
      barcode: '036000291962',
      nameKo: '캠벨 토마토 수프',
      nameEn: 'Campbell Tomato Soup 10.75oz',
      nameJa: 'トマトスープ',
      country: 'US',
      type: 'UPC',
      qty: '1',
      category: '통조림',
      useCase: 'US·product·variety',
    );

    _addRow(
      buffer,
      barcode: '078742105594',
      nameKo: '스킨 로션',
      nameEn: 'Cetaphil Lotion 16oz',
      nameJa: 'ローション',
      country: 'US',
      type: 'UPC',
      qty: '1',
      category: '생활용품',
      useCase: 'Non-food·product',
    );

    // Test Data - Japan Products (JAN)
    _addRow(
      buffer,
      barcode: '4901000102026',
      nameKo: '일청라면',
      nameEn: 'Nissin Instant Ramen',
      nameJa: '日清インスタントラーメン',
      country: 'JP',
      type: 'JAN',
      qty: '2',
      category: '면류',
      useCase: 'Unit·Test·3·Japan·Local·DB',
    );

    _addRow(
      buffer,
      barcode: '4549160900127',
      nameKo: '마루짱 라면',
      nameEn: 'Maruchan Ramen',
      nameJa: 'まるちゃんラーメン',
      country: 'JP',
      type: 'JAN',
      qty: '2',
      category: '면류',
      useCase: 'Japan·product·variety',
    );

    _addRow(
      buffer,
      barcode: '4902105073803',
      nameKo: '산토리 우롱차',
      nameEn: 'Suntory Oolong Tea',
      nameJa: 'サントリー烏龍茶',
      country: 'JP',
      type: 'JAN',
      qty: '2',
      category: '음료',
      useCase: 'Japan·beverage',
    );

    _addRow(
      buffer,
      barcode: '4560365451961',
      nameKo: '유키지루시 우유',
      nameEn: 'Yukijirushi Milk',
      nameJa: 'ユキジルシ牛乳',
      country: 'JP',
      type: 'JAN',
      qty: '2',
      category: '유제품',
      useCase: 'Japan·dairy',
    );

    // Test Data - Unknown/Edge Cases
    _addRow(
      buffer,
      barcode: '9999999999999',
      nameKo: '테스트상품',
      nameEn: 'Test Product',
      nameJa: 'テスト商品',
      country: 'UNKNOWN',
      type: 'UNKNOWN',
      qty: '1',
      category: '기타',
      useCase: 'Unknown·barcode·fallback',
    );

    _addRow(
      buffer,
      barcode: '1234567890123',
      nameKo: '임시상품',
      nameEn: 'Temporary Product',
      nameJa: '一時的な商品',
      country: 'UNKNOWN',
      type: 'UNKNOWN',
      qty: '1',
      category: '기타',
      useCase: 'API·fallback·test',
    );

    return buffer.toString();
  }

  /// Generate test barcode data in JSON format
  static String generateJSON() {
    final testData = [
      // Korean Products
      {
        'barcode': '8801040234515',
        'product_name_ko': '종로우유',
        'product_name_en': 'Jongno Milk 1L',
        'product_name_ja': '牛乳',
        'country_code': 'KR',
        'barcode_type': 'KAN',
        'default_quantity': 2,
        'test_category': 'Local_DB_Lookup',
        'performance_target_ms': '<1',
      },
      {
        'barcode': '8801000010061',
        'product_name_ko': '동풍 우유',
        'product_name_en': 'Dongpung Milk',
        'product_name_ja': 'ミルク',
        'country_code': 'KR',
        'barcode_type': 'KAN',
        'default_quantity': 2,
        'test_category': 'Cache_Performance',
        'performance_target_ms': '<0.5',
      },

      // US Products
      {
        'barcode': '033674006253',
        'product_name_ko': '코카콜라 제로',
        'product_name_en': 'Coca-Cola Zero Sugar 12oz',
        'product_name_ja': 'コカ・コーラ ゼロ',
        'country_code': 'US',
        'barcode_type': 'UPC',
        'default_quantity': 1,
        'test_category': 'Local_DB_Lookup',
        'performance_target_ms': '<1',
      },
      {
        'barcode': '012345678905',
        'product_name_ko': '펩시',
        'product_name_en': 'Pepsi Cola 12oz',
        'product_name_ja': 'ペプシコーラ',
        'country_code': 'US',
        'barcode_type': 'UPC',
        'default_quantity': 1,
        'test_category': 'US_Variety',
        'performance_target_ms': '<1',
      },

      // Japan Products
      {
        'barcode': '4901000102026',
        'product_name_ko': '일청라면',
        'product_name_en': 'Nissin Instant Ramen',
        'product_name_ja': '日清インスタントラーメン',
        'country_code': 'JP',
        'barcode_type': 'JAN',
        'default_quantity': 2,
        'test_category': 'Local_DB_Lookup',
        'performance_target_ms': '<1',
      },
      {
        'barcode': '4549160900127',
        'product_name_ko': '마루짱 라면',
        'product_name_en': 'Maruchan Ramen',
        'product_name_ja': 'まるちゃんラーメン',
        'country_code': 'JP',
        'barcode_type': 'JAN',
        'default_quantity': 2,
        'test_category': 'Japan_Variety',
        'performance_target_ms': '<1',
      },

      // Edge Cases
      {
        'barcode': '9999999999999',
        'product_name_ko': '테스트상품',
        'product_name_en': 'Test Product',
        'product_name_ja': 'テスト商品',
        'country_code': 'UNKNOWN',
        'barcode_type': 'UNKNOWN',
        'default_quantity': 1,
        'test_category': 'Unknown_Fallback',
        'performance_target_ms': '<10000',
      },
    ];

    return jsonEncode(testData);
  }

  /// Generate test scenario checklist
  static String generateScenarios() {
    return '''
# Phase 4 Test Barcode Scenarios
## Date: 2026-02-14
## Total Test Cases: 12

### Korean Products (KAN_CODE) - Expected Quantity: 2
1. 8801040234515 → 종로우유 (Jongno Milk) ✓
2. 8801000010061 → 동풍 우유 (Dongpung Milk) ✓
3. 8801001000088 → 남양 요거트 (Namyang Yogurt) ✓
4. 8801093100017 → 오뚜기 고추장 (Ottogi Gochujang) ✓

### US Products (UPC-A) - Expected Quantity: 1
5. 033674006253 → Coca-Cola Zero Sugar ✓
6. 012345678905 → Pepsi Cola ✓
7. 036000291962 → Campbell Tomato Soup ✓
8. 078742105594 → Cetaphil Lotion ✓

### Japan Products (JAN) - Expected Quantity: 2
9. 4901000102026 → 日清ラーメン (Nissin Ramen) ✓
10. 4549160900127 → まるちゃんラーメン (Maruchan Ramen) ✓
11. 4902105073803 → サントリー烏龍茶 (Suntory Oolong Tea) ✓
12. 4560365451961 → ユキジルシ牛乳 (Yukijirushi Milk) ✓

### Unknown/Fallback Cases
- 9999999999999 → Unknown (API/Inventory fallback)
- 1234567890123 → Unknown (API/Inventory fallback)

## Test Execution Instructions

### Preparation
1. Start fresh test: Clear app cache
2. Ensure all data imported:
   - Korean: 3,088 products ✓
   - US: 70,000+ products ✓
   - Japan: 10,000+ products ✓
3. Prepare scanner or input method

### Execution (Sequential)
1. Scan Korean → Verify qty=2, product name, <1ms
2. Scan US → Verify qty=1, product name, <1ms
3. Scan Japan → Verify qty=2, product name, <1ms
4. Repeat scan Korean → Verify cache hit <1ms
5. Unknown barcode → Verify fallback, qty=1
6. Invalid format → Verify rejection
7. Rapid sequence → Verify performance

### Expected Results
- 100% of known barcodes found in local DB
- All quantities auto-filled correctly by country
- Response times <1ms for cache hits
- Fallback mechanism works for unknown
- No crashes or exceptions

### Success Criteria
✅ All 12 barcodes recognized correctly
✅ All quantities match country defaults
✅ All response times <1ms (cache) or <100ms (DB)
✅ Unknown barcodes handled gracefully
✅ Multi-language display correct
✅ UI indicators show correct color (🟢 green for local)
''';
  }

  /// Helper method to add a CSV row
  static void _addRow(
    StringBuffer buffer, {
    required String barcode,
    required String nameKo,
    required String nameEn,
    required String nameJa,
    required String country,
    required String type,
    required String qty,
    required String category,
    required String useCase,
  }) {
    final csvRow = [
      barcode,
      nameKo,
      nameEn,
      nameJa,
      country,
      type,
      qty,
      category,
      useCase.replaceAll('·', '_'),
    ].map((v) => '"$v"').join(',');

    buffer.writeln(csvRow);
  }
}

/// Main execution
void main() async {
  print('📊 Phase 4: Test Barcode Dataset Generator');
  print('=========================================\n');

  // Generate CSV
  final csvData = TestBarcodeDataset.generateCSV();
  final csvFile = File('data/test_barcodes.csv');
  await csvFile.parent.create(recursive: true);
  await csvFile.writeAsString(csvData);
  print('✅ CSV dataset created: ${csvFile.path}');
  print('   Rows: ${csvData.split('\n').length - 1} (excludes header)');

  // Generate JSON
  final jsonData = TestBarcodeDataset.generateJSON();
  final jsonFile = File('data/test_barcodes.json');
  await jsonFile.writeAsString(jsonData);
  print('✅ JSON dataset created: ${jsonFile.path}');

  // Generate scenarios
  final scenarios = TestBarcodeDataset.generateScenarios();
  final scenariosFile = File('data/TEST_BARCODE_SCENARIOS.md');
  await scenariosFile.writeAsString(scenarios);
  print('✅ Test scenarios created: ${scenariosFile.path}');

  print('\n📄 Dataset Summary');
  print('==================');
  print('• Korean products (KAN):  4 barcodes');
  print('• US products (UPC-A):    4 barcodes');
  print('• Japan products (JAN):   4 barcodes');
  print('• Edge cases:             2 barcodes (unknown)');
  print('• Total test cases:       14 scenarios');

  print('\n🧪 Test Coverage');
  print('=================');
  print('✓ Local DB lookup (all 3 countries)');
  print('✓ Cache performance (repeated scans)');
  print('✓ API fallback (unknown barcodes)');
  print('✓ Multi-language display');
  print('✓ Country-specific quantity defaults');
  print('✓ Performance benchmarking');

  print('\n✅ Dataset generation completed successfully!');
  print('   Use CSV for admin import UI testing');
  print('   Use JSON for API mock testing');
  print('   Use scenarios for manual test execution');
}
