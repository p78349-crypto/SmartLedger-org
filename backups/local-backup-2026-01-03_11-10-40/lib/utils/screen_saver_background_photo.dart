import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ScreenSaverBackgroundPhoto {
  const ScreenSaverBackgroundPhoto._();

  static const String _dirName = 'local_only';
  static const String _baseName = 'screen_saver_background';

  static Future<Directory> _localOnlyDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, _dirName));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  static Future<String> saveFromPickedFile({
    required String pickedFilePath,
  }) async {
    final ext = p.extension(pickedFilePath);
    final dir = await _localOnlyDir();

    // Keep only one image.
    for (final e in ['.jpg', '.jpeg', '.png', '.webp', '.heic']) {
      final candidate = File(p.join(dir.path, '$_baseName$e'));
      if (candidate.existsSync()) {
        try {
          await candidate.delete();
        } catch (_) {
          // Ignore best-effort cleanup.
        }
      }
    }

    final dest = File(p.join(dir.path, '$_baseName$ext'));
    final src = File(pickedFilePath);
    await src.copy(dest.path);
    return dest.path;
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    final file = File(path);
    if (file.existsSync()) {
      try {
        await file.delete();
      } catch (_) {
        // Ignore.
      }
    }
  }
}
