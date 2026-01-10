import 'dart:io';

import 'package:flutter/services.dart';

class AssistantLauncher {
  AssistantLauncher._();

  static const MethodChannel _channel = MethodChannel('smart_ledger/assistant');

  static Future<bool> openSystemAssistant() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('openVoiceAssistant');
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openAppByPackage(String packageName) async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'openAppByPackage',
        {'package': packageName},
      );
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openBixby() async {
    if (!Platform.isAndroid) return false;

    const candidates = <String>[
      'com.samsung.android.bixby.agent',
      'com.samsung.android.bixby.service',
      'com.samsung.android.app.spage',
      'com.samsung.android.bixby.wakeup',
    ];

    for (final pkg in candidates) {
      final ok = await openAppByPackage(pkg);
      if (ok) return true;
    }

    return false;
  }
}
