import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:smart_ledger/utils/screen_saver_background_photo.dart';

void main() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempRoot;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempRoot = await Directory.systemTemp.createTemp('sl_ss_bg_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
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

  test('saveFromPickedFile copies file into app documents local_only and keeps only one', () async {
    final srcDir = await Directory.systemTemp.createTemp('sl_src_');
    final src1 = File(p.join(srcDir.path, 'a.png'));
    await src1.writeAsBytes([1, 2, 3]);

    final dest1 = await ScreenSaverBackgroundPhoto.saveFromPickedFile(
      pickedFilePath: src1.path,
    );
    expect(File(dest1).existsSync(), isTrue);
    expect(p.basename(dest1), contains('screen_saver_background'));

    final src2 = File(p.join(srcDir.path, 'b.jpg'));
    await src2.writeAsBytes([4, 5, 6, 7]);

    final dest2 = await ScreenSaverBackgroundPhoto.saveFromPickedFile(
      pickedFilePath: src2.path,
    );
    expect(File(dest2).existsSync(), isTrue);
    expect(p.extension(dest2), '.jpg');

    // Old one should be removed.
    expect(File(dest1).existsSync(), isFalse);

    await srcDir.delete(recursive: true);
  });

  test('deleteIfExists ignores null/empty and deletes existing file', () async {
    await ScreenSaverBackgroundPhoto.deleteIfExists(null);
    await ScreenSaverBackgroundPhoto.deleteIfExists('');

    final f = File(p.join(tempRoot.path, 'x.txt'));
    await f.writeAsString('hi');
    expect(f.existsSync(), isTrue);

    await ScreenSaverBackgroundPhoto.deleteIfExists(f.path);
    expect(f.existsSync(), isFalse);
  });
}
