// lib/utils/ingredient_parsing_utils.dart

/// 식재료 이름과 수량을 분리/관리하는 유틸리티
class IngredientParsingUtils {
  // 정형화된 식재료 이름 목록 (외부에서 참조 가능)
  static const Set<String> knownIngredients = {
    '닭고기',
    '돼지고기',
    '소고기',
    '양파',
    '마늘',
    '대파',
    '쪽파',
    '당근',
    '감자',
    '고구마',
    '두부',
    '계란',
    '달걀',
    '우유',
    '치즈',
    '김치',
    '쌀',
    '현미',
    '잡곡',
    '귀리',
    '사과',
    '바나나',
    '딸기',
    '토마토',
    '오이',
    '가지',
    '호박',
    '고추장',
    '된장',
    '간장',
    '소금',
    '설탕',
    '후추',
    '참기름',
    '들기름',
    '올리브유',
    '식용유',
  };

  /// 텍스트 단위 (파싱용)
  static const List<String> _textUnits = [
    '조금',
    '약간',
    '적당량',
    '반 줌',
    '한 줌',
    '두 줌',
    '반 개',
    '한 개',
    '두 개',
    '세 개',
    '반 컵',
    '한 컵',
    '두 컵',
    '한 큰술',
    '반 큰술',
    '한 작은술',
  ];

  /// 원본 문자열에서 (상품명, 수량)을 분리하여 반환
  /// 예: "가지 1개" -> ("가지", "1개")
  /// 예: "닭고기(적은 것) 1마리" -> ("닭고기(적은 것)", "1마리")
  static (String name, String amount) parseNameAndAmount(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return ('', '');

    // 1. 숫자 + 단위 패턴 (문자열 끝부분 검색)
    // 예: 1개, 1마리, 1.5L, 100g, 2~3개, 1/2개
    // 숫자 부분: \d+(?:[-~./]\d+)?
    // 단위 부분: [가-힣a-zA-Z]+
    final regex = RegExp(r'^(.*?)(\d+(?:[-~./]\d+)?\s*[가-힣a-zA-Z]+)$');
    final match = regex.firstMatch(cleaned);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final amount = match.group(2)?.trim() ?? '';

      // 이름이 비어있다면(예: "1개"만 들어온 경우) 원본 반환 또는 처리
      if (name.isEmpty) return (cleaned, '(정보 없음)');

      return (name, amount);
    }

    // 2. 텍스트 단위 패턴 체크
    for (final unit in _textUnits) {
      if (cleaned.endsWith(unit)) {
        final name = cleaned.substring(0, cleaned.length - unit.length).trim();
        return (name.isEmpty ? cleaned : name, unit);
      }
    }

    // 3. 괄호 안에 수량이 있는 경우 (예: "양파(1개)")
    // 단순히 괄호로 끝나는 경우 체크
    if (cleaned.endsWith(')')) {
      final startIndex = cleaned.lastIndexOf('(');
      if (startIndex > 0) {
        final content = cleaned
            .substring(startIndex + 1, cleaned.length - 1)
            .trim();
        // 괄호 내용이 숫자+단위 형식이면 분리
        if (RegExp(r'^\d+').hasMatch(content) || _textUnits.contains(content)) {
          final name = cleaned.substring(0, startIndex).trim();
          return (name, content);
        }
      }
    }

    // 분리할 수 없는 경우
    return (cleaned, '(정보 없음)');
  }

  /// 문자열 리스트에서 식재료 이름만 추출 (중복 제거)
  static List<String> extractUniqueNames(List<String> raws) {
    return raws.map((e) => parseNameAndAmount(e).$1).toSet().toList();
  }
}
