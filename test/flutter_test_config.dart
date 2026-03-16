// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test bootstrap.
///
/// Runs before each test file via Flutter's `flutter_test_config.dart` hook.
///
/// Goal: prevent plugin-channel MissingPluginException in pure Dart/VM tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider channel used by getTemporaryDirectory/
  // getApplicationDocumentsDirectory in tests.
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    final tempRoot = Directory.systemTemp;
    Future<String> ensureDir(String name) async {
      final dir = Directory('${tempRoot.path}${Platform.pathSeparator}$name');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    }

    switch (methodCall.method) {
      case 'getTemporaryDirectory':
        return await ensureDir('smartledger_test_tmp');
      case 'getApplicationDocumentsDirectory':
        return await ensureDir('smartledger_test_docs');
      case 'getApplicationSupportDirectory':
        return await ensureDir('smartledger_test_support');
      case 'getLibraryDirectory':
        return await ensureDir('smartledger_test_library');
      case 'getDownloadsDirectory':
        return await ensureDir('smartledger_test_downloads');
      case 'getExternalStorageDirectory':
        return await ensureDir('smartledger_test_external');
      case 'getExternalCacheDirectories':
        return <String>[await ensureDir('smartledger_test_ext_cache')];
      case 'getExternalStorageDirectories':
        return <String>[await ensureDir('smartledger_test_ext_storage')];
      default:
        // Safe fallback for any future path_provider method additions.
        return await ensureDir('smartledger_test_fallback');
    }
  });

  await testMain();
}
