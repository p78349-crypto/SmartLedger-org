class CategoryHint {
  final String mainCategory;
  final String? subCategory;

  const CategoryHint({required this.mainCategory, this.subCategory});

  factory CategoryHint.fromJson(Map<String, dynamic> json) {
    return CategoryHint(
      mainCategory: (json['mainCategory'] as String?) ?? '미분류',
      subCategory: (json['subCategory'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['subCategory'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {'mainCategory': mainCategory, 'subCategory': subCategory};
  }
}
