import 'package:flutter/services.dart';

class AppIconService {
  AppIconService._();

  static const MethodChannel _channel = MethodChannel('smart_ledger/app_icon');

  static Future<Uint8List?> getAppIconPngBytes() async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>(
        'getAppIconPngBytes',
      );
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Switch Android launcher icon theme by enabling a launcher activity-alias.
  ///
  /// Supported ids: 'auto', 'light', 'dark'.
  static Future<bool> setLauncherIconTheme(String themeId) async {
    try {
      await _channel.invokeMethod<void>('setLauncherIconTheme', {
        'theme': themeId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
