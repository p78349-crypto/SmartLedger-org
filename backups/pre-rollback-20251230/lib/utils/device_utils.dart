import 'package:device_info_plus/device_info_plus.dart';

/// Returns true when Android SDK is at least [minSdk], otherwise false.
Future<bool> isAndroidSdkAtLeast(int minSdk) async {
  try {
    final di = DeviceInfoPlugin();
    final android = await di.androidInfo;
    final sdk = android.version.sdkInt;
    return sdk >= minSdk;
  } catch (_) {
    // Not an Android device or failed to get info.
    return false;
  }
}

