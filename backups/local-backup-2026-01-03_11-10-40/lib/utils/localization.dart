/// 앱 전체에서 사용되는 다국어 문자열 관리
/// 미래에 언어 변경 시 이 파일만 수정하면 전체 앱에 적용됨
class AppStrings {
  // Private constructor to prevent instantiation
  AppStrings._();

  // ==================== 거래 유형 ====================
  static const String transactionTypeSavings = '예금';
  static const String transactionTypeExpense = '지출';
  static const String transactionTypeIncome = '수입';

  // ==================== 버튼 및 액션 ====================
  static const String buttonAdd = '추가';
  static const String buttonDelete = '삭제';
  static const String buttonEdit = '수정';
  static const String buttonCancel = '취소';
  static const String buttonConfirm = '확인';
  static const String buttonSave = '저장';

  // ==================== 메시지 ====================
  static const String messageEmpty = '데이터가 없습니다';
  static const String messageLoading = '로딩 중...';
  static const String messageError = '오류가 발생했습니다';

  // ==================== 다국어 전환 함수 (미래 확장용) ====================
  /// 언어 변경 시 이 함수들을 활용하여 동적으로 문자열 반환
  /// 예: static String getSavings(Language lang) => ...
  /// static String getExpense(Language lang) => ...
}

/// 향후 지원할 언어 정의 (선택사항)
// enum Language { ko, en, ja, zh }
