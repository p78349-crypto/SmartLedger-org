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
  /// Currently simply sets unlocked; replace with biometric/PIN flow as needed.
  static Future<bool> authenticateAndUnlock(String accountName) async {
    // TODO: integrate real auth. For now, clear lock.
    await setLocked(accountName, false);
    return true;
  }
}
