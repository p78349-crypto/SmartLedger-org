enum SearchCategory {
  productName('제품명'),
  paymentMethod('결제수단'),
  memo('메모'),
  amount('금액'),
  date('날짜');

  final String label;
  const SearchCategory(this.label);
}

class SearchFilter {
  final SearchCategory category;
  final String query;

  const SearchFilter({
    this.category = SearchCategory.productName,
    this.query = '',
  });

  bool get isEmpty => query.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  SearchFilter copyWith({SearchCategory? category, String? query}) {
    return SearchFilter(
      category: category ?? this.category,
      query: query ?? this.query,
    );
  }
}

class SearchStats {
  final int matchCount;
  final double totalAmount;
  final double allAmount;
  final double percentage;

  const SearchStats({
    required this.matchCount,
    required this.totalAmount,
    required this.allAmount,
    required this.percentage,
  });
}

