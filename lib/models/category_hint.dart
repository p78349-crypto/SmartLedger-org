class CategoryHint {
  final String mainCategory;
  final String? subCategory;
  final String? detailCategory;

  const CategoryHint({
    required this.mainCategory,
    this.subCategory,
    this.detailCategory,
  });

  factory CategoryHint.fromJson(Map<String, dynamic> json) {
    return CategoryHint(
      mainCategory: (json['mainCategory'] as String?) ?? '미분류',
      subCategory: (json['subCategory'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['subCategory'] as String?),
      detailCategory:
          (json['detailCategory'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['detailCategory'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mainCategory': mainCategory,
      'subCategory': subCategory,
      'detailCategory': detailCategory,
    };
  }
}
