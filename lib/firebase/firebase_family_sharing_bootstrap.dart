import 'package:shared_preferences/shared_preferences.dart';

class FirebaseFamilySharingBootstrap {
  static const String activeFamilyIdPrefKey = 'activeFamilyIdV1';

  static const bool enabled = bool.fromEnvironment(
    'ENABLE_FAMILY_SHARING',
  );

  static Future<void> initializeIfEnabled(SharedPreferences prefs) async {
    // Basic mode: Firebase family sharing is intentionally disabled.
    // Keep this stub so future re-enablement is a small, localized change.
    //
    // ignore: unused_local_variable
    final _ = prefs;
    if (!enabled) return;
  }
}
