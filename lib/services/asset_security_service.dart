import 'package:shared_preferences/shared_preferences.dart';
import '../utils/pref_keys.dart';

/// Simple per-account asset lock service.
class AssetSecurityService {
  const AssetSecurityService._();

  static String _keyFor(String accountName) =>
      '${PrefKeys.assetLockPrefix}_$accountName';

  /// Returns whether assets for [accountName] are locked (cannot view details).
  static Future<bool> isLocked(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFor(accountName)) ?? false;
  }

  /// Sets lock state for account.
  static Future<void> setLocked(String accountName, bool locked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(accountName), locked);
  }

  /// Placeholder: call to perform authentication and unlock. Returns true if unlocked.
  /// FUTURE: Replace with biometric (local_auth) or PIN verification.
  /// See user_pin_service.dart for PIN implementation reference.
  static Future<bool> authenticateAndUnlock(String accountName) async {
    // 현재는 바로 잠금 해제; 실제 인증 로직은 추후 추가
    await setLocked(accountName, false);
    return true;
  }
}
