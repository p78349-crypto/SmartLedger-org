/// Pure utility functions for voice expense text parsing.
library;

/// Returns true if [text] contains any of the given [keywords].
bool containsAny(String text, List<String> keywords) {
  return keywords.any((k) => text.contains(k));
}

/// 간단한 한글 지출 텍스트 파서 - 정확도 향상 및 복합 명사 처리
Map<String, String?> parseExpense(String text) {
  // 1. 의도와 상관없는 불필요한 단어 제거
  final cleanText = text
      .replaceAll(
        RegExp(r'(지출|기록|입력|저장|해줘|해|줘|좀|요|은|는|이|가|을|를)$'),
        '',
      )
      .trim();

  // 2. 가격 패턴 추출 (단위: 십, 백, 천, 만 포함)
  // 3천5백원, 1만5000원 등의 복합 형태 대응
  final priceRegex = RegExp(r'(\d+[만천백십\d]*원?|[만천백십]+원?)');
  final matches = priceRegex.allMatches(cleanText).toList();

  String? price;
  String? item;

  if (matches.isNotEmpty) {
    // 기본적으로 마지막 매치를 가격으로 보되,
    // '원' 단위나 '만/천' 단위가 포함된 것을 우선적으로 찾음
    final bestMatch = matches.reversed.firstWhere(
      (m) {
        final mText = m.group(0) ?? '';
        return mText.contains(RegExp(r'[원만천백십]')) ||
            (int.tryParse(mText.replaceAll(',', '')) ?? 0) >= 100;
      },
      orElse: () => matches.last,
    );

    price = bestMatch.group(0);
    // 복합 명사(사과만원) 처리를 위해 replaceFirst 사용
    item = cleanText
        .replaceFirst(price!, '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    if (item.isEmpty) item = null;
  } else {
    // 숫자가 없으면 전체를 품목 후보로 (단, 의도어만 있는 경우는 제외)
    final intentWords = ['지출', '기록', '돈', '썼', '결제', '구매', '샀'];
    final isOnlyIntent = intentWords.any((w) => cleanText == w);
    if (!isOnlyIntent && cleanText.isNotEmpty) {
      item = cleanText;
    }
  }

  return {'item': item, 'price': price};
}
