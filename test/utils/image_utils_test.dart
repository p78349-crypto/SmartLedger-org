import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:smart_ledger/utils/image_utils.dart';

void main() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempRoot;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempRoot = await Directory.systemTemp.createTemp('sl_img_cache_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getTemporaryDirectory':
          return tempRoot.path;
        default:
          throw PlatformException(code: 'unimplemented', message: call.method);
      }
    });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('processAndCacheImage writes a cached jpg under smart_ledger_wallpapers', () async {
    final srcDir = await Directory.systemTemp.createTemp('sl_img_src_');

    final image = img.Image(width: 8, height: 8);
    final png = img.encodePng(image);

    final src = File(p.join(srcDir.path, 'in.png'));
    await src.writeAsBytes(png, flush: true);

    final out = await processAndCacheImage(src, maxDim: 16, quality: 80);
    expect(out.existsSync(), isTrue);
    expect(out.path, contains('smart_ledger_wallpapers'));
    expect(p.extension(out.path), '.jpg');

    await srcDir.delete(recursive: true);
  });

  test('pruneCache deletes files older than maxAgeSeconds', () async {
    final root = Directory(p.join(tempRoot.path, 'smart_ledger_wallpapers'));
    await root.create(recursive: true);

    final oldFile = File(p.join(root.path, 'old.jpg'));
    await oldFile.writeAsBytes([1, 2, 3], flush: true);
    await oldFile.setLastModified(DateTime.now().subtract(const Duration(days: 10)));

    final newFile = File(p.join(root.path, 'new.jpg'));
    await newFile.writeAsBytes([1, 2, 3], flush: true);

    await pruneCache(maxAgeSeconds: 60 * 60 * 24); // 1 day

    expect(oldFile.existsSync(), isFalse);
    expect(newFile.existsSync(), isTrue);
  });
}
