/// 앱 전체에서 사용되는 상수 정의
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // Branding / generated names
  static const String backupDownloadsFolderName = 'SmartLedger';

  // SharedPreferences Keys
  static const String lastAccountNameKey = 'last_account_name';
  static const String accountsKey = 'accounts';
  static const String budgetsKey = 'budgets';
  static const String savingsPlansKey = 'savings_plans';
  static const String trashEntriesKey = 'trash_entries';
  static const String favoritePaymentsKeyPrefix = 'favorite_payments';
  static const String favoriteMemosKeyPrefix = 'favorite_memos';
  static const String favoriteDescriptionsKeyPrefix = 'favorite_descriptions';
  static const String favoriteCategoriesKeyPrefix = 'favorite_categories';

  // 제한값
  static const int maxFavoritesCount = 10;
  static const int maxTrashSizeBytes = 60 * 1024 * 1024; // 60MB
  static const int autoBackupIntervalDays = 7; // 자동 백업 주기

  // 기본값
  static const String defaultCurrency = '원';
  static const String defaultAccountName = '임시 계정';

  // 파일명 패턴
  static const String backupFileExtension = '.json';
  static const String exportCsvExtension = '.csv';
  static const String exportExcelExtension = '.xlsx';

  // UI 관련
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardElevation = 2.0;

  // 애니메이션 지속시간
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // 날짜 관련
  static const int monthsInYear = 12;
  static const int daysInWeek = 7;

  // 통계 기간
  static const int statsMonthsPeriod = 1;
  static const int statsQuarterPeriod = 3;
  static const int statsHalfYearPeriod = 6;
  static const int statsYearPeriod = 12;
  static const int statsDecadePeriod = 120;

  // 메시지
  static const String noDataMessage = '데이터가 없습니다';
  static const String loadingMessage = '불러오는 중...';
  static const String savingMessage = '저장 중...';
  static const String deletingMessage = '삭제 중...';
  static const String errorMessage = '오류가 발생했습니다';
  static const String successMessage = '완료되었습니다';

  // 거래 타입 기본 이름
  static const String incomeTypeName = '수입';
  static const String expenseTypeName = '지출';
  static const String savingsTypeName = '예금';

  // 자산 카테고리
  static const List<String> defaultAssetCategories = [
    '현금',
    '은행',
    '증권',
    '부동산',
    '기타',
  ];

  // 고정비용 주기
  static const List<String> fixedCostCycles = ['매일', '매주', '매월', '매년'];

  // 결제 수단 예시
  static const List<String> defaultPaymentMethods = [
    '현금',
    '카드',
    '계좌이체',
    '모바일결제',
  ];
}

/// 앱 테마 관련 상수
class ThemeConstants {
  ThemeConstants._();

  // 색상 관련
  static const double colorOpacityLight = 0.1;
  static const double colorOpacityMedium = 0.3;
  static const double colorOpacityHeavy = 0.5;

  // 텍스트 크기
  static const double textSizeSmall = 12.0;
  static const double textSizeMedium = 14.0;
  static const double textSizeLarge = 16.0;
  static const double textSizeTitle = 20.0;
  static const double textSizeHeadline = 24.0;

  // 아이콘 크기
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // 간격
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
}

/// 에러 메시지 상수
class ErrorMessages {
  ErrorMessages._();

  static const String networkError = '네트워크 연결을 확인해주세요';
  static const String storageError = '저장소 접근에 실패했습니다';
  static const String permissionError = '권한이 필요합니다';
  static const String invalidInput = '입력값이 올바르지 않습니다';
  static const String accountNotFound = '계정을 찾을 수 없습니다';
  static const String transactionNotFound = '거래 내역을 찾을 수 없습니다';
  static const String assetNotFound = '자산을 찾을 수 없습니다';
  static const String backupFailed = '백업에 실패했습니다';
  static const String restoreFailed = '복원에 실패했습니다';
  static const String exportFailed = '내보내기에 실패했습니다';
  static const String importFailed = '가져오기에 실패했습니다';
  static const String duplicateAccount = '이미 존재하는 계정명입니다';
}

/// 성공 메시지 상수
class SuccessMessages {
  SuccessMessages._();

  static const String saved = '저장되었습니다';
  static const String deleted = '삭제되었습니다';
  static const String updated = '수정되었습니다';
  static const String backupCompleted = '백업이 완료되었습니다';
  static const String restoreCompleted = '복원이 완료되었습니다';
  static const String exportCompleted = '내보내기가 완료되었습니다';
  static const String importCompleted = '가져오기가 완료되었습니다';
  static const String accountCreated = '계정이 생성되었습니다';
  static const String accountDeleted = '계정이 삭제되었습니다';

  // 거래 유형 레이블
  static const String transactionTypeSavings = '예금';
  static const String transactionTypeExpense = '지출';
  static const String transactionTypeIncome = '수입';
}

