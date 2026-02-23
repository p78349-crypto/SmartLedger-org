// Global Product Model for barcode matching
//
// Represents a product from the global product database
// Supports: Korea (KAN), USA (UPC-A, EAN-13), Japan (JAN)

class GlobalProduct {
  final int id;
  
  // Barcode fields
  final String? ean13;      // EAN-13 (European Article Number)
  final String? upcA;       // UPC-A (US/Canada)
  final String? janCode;    // JAN (Japan)
  final String? kanCode;    // KAN (Korea - 유통 표준 코드)
  
  // Product names
  final String? productNameKo;
  final String? productNameEn;
  final String? productNameJa;
  
  // Categories (hierarchical)
  final String? category1;  // Large category
  final String? category2;  // Medium category
  final String? category3;  // Small category
  final String? category4;  // Detailed category
  
  // Product details
  final String? manufacturer;
  final String? packagingUnit;  // 병, 팩, 상자, etc.
  final int defaultQuantity;    // Default qty to input (Korea: 2)
  final String countryCode;     // KR, US, JP, etc.
  
  // Nutrition info (optional)
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? carbsPer100g;
  
  // Metadata
  final String dataSource;  // Origin: 'korean', 'usda', 'openfoodfacts'
  final DateTime createdAt;
  
  GlobalProduct({
    required this.id,
    this.ean13,
    this.upcA,
    this.janCode,
    this.kanCode,
    this.productNameKo,
    this.productNameEn,
    this.productNameJa,
    this.category1,
    this.category2,
    this.category3,
    this.category4,
    this.manufacturer,
    this.packagingUnit,
    this.defaultQuantity = 1,
    this.countryCode = 'KR',
    this.caloriesPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.carbsPer100g,
    this.dataSource = 'local',
    required this.createdAt,
  });
  
  /// Get display name based on locale
  String getDisplayName({String locale = 'ko'}) {
    switch (locale.toLowerCase()) {
      case 'ko':
      case 'korean':
        return productNameKo ?? productNameEn ?? 'Unknown Product';
      case 'en':
      case 'english':
        return productNameEn ?? productNameKo ?? 'Unknown Product';
      case 'ja':
      case 'japanese':
        return productNameJa ?? productNameEn ?? 'Unknown Product';
      default:
        return productNameEn ?? productNameKo ?? 'Unknown Product';
    }
  }
  
  /// Get category display path
  String getCategoryPath() {
    final parts = <String>[];
    if (category1 != null) parts.add(category1!);
    if (category2 != null) parts.add(category2!);
    if (category3 != null) parts.add(category3!);
    if (category4 != null) parts.add(category4!);
    return parts.join(' > ');
  }
  
  /// Get primary barcode (in order of preference)
  String? getPrimaryBarcode() {
    return ean13 ?? upcA ?? janCode ?? kanCode;
  }
  
  /// Create from database map
  factory GlobalProduct.fromMap(Map<String, dynamic> map) {
    return GlobalProduct(
      id: map['id'] as int,
      ean13: map['ean13'] as String?,
      upcA: map['upc_a'] as String?,
      janCode: map['jan_code'] as String?,
      kanCode: map['kan_code'] as String?,
      productNameKo: map['product_name_ko'] as String?,
      productNameEn: map['product_name_en'] as String?,
      productNameJa: map['product_name_ja'] as String?,
      category1: map['category_1'] as String?,
      category2: map['category_2'] as String?,
      category3: map['category_3'] as String?,
      category4: map['category_4'] as String?,
      manufacturer: map['manufacturer'] as String?,
      packagingUnit: map['packaging_unit'] as String?,
      defaultQuantity: map['default_quantity'] as int? ?? 1,
      countryCode: map['country_code'] as String? ?? 'KR',
      caloriesPer100g: _toDouble(map['calories_per_100g']),
      proteinPer100g: _toDouble(map['protein_per_100g']),
      fatPer100g: _toDouble(map['fat_per_100g']),
      carbsPer100g: _toDouble(map['carbs_per_100g']),
      dataSource: map['data_source'] as String? ?? 'local',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
  
  /// Static helper to convert nullable values to double
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ean13': ean13,
      'upc_a': upcA,
      'jan_code': janCode,
      'kan_code': kanCode,
      'product_name_ko': productNameKo,
      'product_name_en': productNameEn,
      'product_name_ja': productNameJa,
      'category_1': category1,
      'category_2': category2,
      'category_3': category3,
      'category_4': category4,
      'manufacturer': manufacturer,
      'packaging_unit': packagingUnit,
      'default_quantity': defaultQuantity,
      'country_code': countryCode,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'fat_per_100g': fatPer100g,
      'carbs_per_100g': carbsPer100g,
      'data_source': dataSource,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'GlobalProduct('
        'id: $id, '
        'name: ${getDisplayName()}, '
        'barcode: ${getPrimaryBarcode()}, '
        'category: ${getCategoryPath()}'
        ')';
  }
}
