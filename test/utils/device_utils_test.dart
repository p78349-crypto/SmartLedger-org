import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/device_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channels = <MethodChannel>[
    MethodChannel('dev.fluttercommunity.plus/device_info'),
    MethodChannel('dev.fluttercommunity.plus/device_info_plus'),
    MethodChannel('plugins.flutter.io/device_info'),
  ];

  tearDown(() async {
    for (final c in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(c, null);
    }
  });

  test('returns false when device info is unavailable', () async {
    for (final c in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(c, (call) async {
        throw PlatformException(code: 'unavailable');
      });
    }

    expect(await isAndroidSdkAtLeast(1), isFalse);
  });

  test('returns false on non-Android test hosts', () async {
    // This test suite runs on the host VM (not an Android device), so the
    // plugin is expected to be unavailable/unsupported.
    expect(await isAndroidSdkAtLeast(0), isFalse);
    expect(await isAndroidSdkAtLeast(999), isFalse);
  });
}
