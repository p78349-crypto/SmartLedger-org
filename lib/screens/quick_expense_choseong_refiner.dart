
import '../utils/quick_stock_use_utils.dart';

/// 초성 입력을 정규 단어로 변환해주는 서비스
class QuickExpenseChoseongRefiner {
  const QuickExpenseChoseongRefiner._();

  /// 입력된 텍스트 중 초성 부분을 재고 품목명에서 찾아 정규 단어로 변환합니다.
  /// 
  /// 예: "ㅋㅍ 1잔 3000원" -> "커피 1잔 3000원" (재고에 '커피'가 있는 경우)
  /// "ㅋㅍㄹㄸ 5000원" -> "카페라떼 5000원"
  static String refineInput(String input) {
    if (input.trim().isEmpty) return input;

    final tokens = input.split(' ');
    final refinedTokens = <String>[];

    for (final token in tokens) {
      if (_isPureChoseong(token)) {
        final matches = QuickStockUseUtils.searchItems(token);
        if (matches.isNotEmpty) {
          // 가장 관련성 높은(검색 결과 첫 번째) 정규 품목명으로 교체
          refinedTokens.add(matches.first.name);
          continue;
        }
      }
      refinedTokens.add(token);
    }

    return refinedTokens.join(' ');
  }

  /// 문자열이 한글 초성으로만 이루어져 있는지 확인합니다.
  static bool _isPureChoseong(String text) {
    if (text.isEmpty) return false;
    // 숫자나 기호가 섞여있으면 초성 전용 입력이 아님
    final chosungRegExp = RegExp(r'^[ㄱ-ㅎ]+$');
    return chosungRegExp.hasMatch(text);
  }
}
