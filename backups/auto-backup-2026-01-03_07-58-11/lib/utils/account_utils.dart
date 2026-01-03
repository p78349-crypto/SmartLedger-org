/// ROOT 계정 관련 유틸리티
class AccountUtils {
  /// ROOT 계정 이름
  static const String rootAccountName = 'ROOT';

  /// 계정이 ROOT 계정인지 확인
  static bool isRootAccount(String accountName) {
    return accountName.toUpperCase() == rootAccountName;
  }

  /// 사용자가 다른 계정에 접근할 수 있는지 확인
  /// ROOT 계정만 모든 계정 접근 가능
  static bool canAccessAccount(String currentAccount, String targetAccount) {
    if (isRootAccount(currentAccount)) {
      return true; // ROOT는 모든 계정 접근 가능
    }
    return currentAccount == targetAccount; // 일반 사용자는 자기 계정만
  }

  /// ROOT 계정 전용 기능인지 확인
  static bool isRootOnlyFeature(String accountName) {
    return isRootAccount(accountName);
  }
}

