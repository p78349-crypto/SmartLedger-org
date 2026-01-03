class ShoppingRepurchaseRules {
  ShoppingRepurchaseRules._();

  /// Minimum days between purchases before recommending repurchase.
  /// - Short shelf-life: 2~7 days
  /// - Medium: 10~14 days
  /// - Long: 30+ days
  static const Map<String, int> keywordToMinDays = {
    // Fresh / short cycle
    '우유': 3,
    '두유': 5,
    '요거트': 5,
    '요구르트': 5,
    '계란': 7,
    '빵': 4,
    '샐러드': 3,
    '야채': 4,
    '채소': 4,
    '상추': 3,
    '시금치': 3,
    '깻잎': 3,
    '파': 5,
    '대파': 5,
    '양파': 10,
    '감자': 14,
    '고기': 7,
    '닭': 7,
    '생선': 5,
    '두부': 4,
    // Fruit examples
    '바나나': 5,
    '딸기': 4,
    '포도': 7,
    '귤': 14,
    '사과': 30,
  };

  static int defaultMinDays = 7;
}
