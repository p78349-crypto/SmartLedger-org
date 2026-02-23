class HouseholdProduct {
  final String code;
  final String category1;
  final String category2;
  final String category3;
  final String category4;
  final String name;
  final String unit;
  final int defaultQuantity;

  const HouseholdProduct({
    required this.code,
    required this.category1,
    required this.category2,
    required this.category3,
    required this.category4,
    required this.name,
    required this.unit,
    required this.defaultQuantity,
  });

  factory HouseholdProduct.fromJson(Map<String, dynamic> json) {
    return HouseholdProduct(
      code: json['code'] as String? ?? '',
      category1: json['category1'] as String? ?? '',
      category2: json['category2'] as String? ?? '',
      category3: json['category3'] as String? ?? '',
      category4: json['category4'] as String? ?? '',
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? '개',
      defaultQuantity: json['defaultQuantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'category1': category1,
      'category2': category2,
      'category3': category3,
      'category4': category4,
      'name': name,
      'unit': unit,
      'defaultQuantity': defaultQuantity,
    };
  }

  /// 표시용 카테고리 경로
  String get categoryPath => '$category1 > $category2 > $category3';
}
