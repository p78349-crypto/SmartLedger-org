import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resize and compress image and save to app cache.
/// Returns processed file.
Future<File> processAndCacheImage(
  File input, {
  int maxDim = 2048,
  int quality = 85,
}) async {
  final bytes = input.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('Unsupported image format');

  // Resize preserving aspect ratio
  final longer = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  img.Image resized = decoded;
  if (longer > maxDim) {
    final scale = maxDim / longer;
    final newW = (decoded.width * scale).round();
    final newH = (decoded.height * scale).round();
    resized = img.copyResize(
      decoded,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.average,
    );
  }

  // Encode as JPEG to balance compatibility and size
  final jpg = img.encodeJpg(resized, quality: quality);

  // Use a cache key based on filename + size + modified timestamp
  final stat = input.statSync();
  final base = p.basename(input.path).replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final key = '${base}_${stat.size}_'
      '${stat.modified.millisecondsSinceEpoch}_${maxDim}_'
      '$quality.jpg';

  final cacheDir = await getTemporaryDirectory();
  final outPath = p.join(cacheDir.path, 'vccode1_wallpapers', key);
  final outDir = Directory(p.dirname(outPath));
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final outFile = File(outPath);
  outFile.writeAsBytesSync(jpg, flush: true);
  return outFile;
}

/// Helper: delete cached wallpapers older than [maxAgeSeconds]
/// and enforce size/count limits.
Future<void> pruneCache({
  int maxAgeSeconds = 60 * 60 * 24 * 14,
  int maxFiles = 50,
  int maxTotalBytes = 100 * 1024 * 1024,
}) async {
  final cacheDir = await getTemporaryDirectory();
  final root = Directory(p.join(cacheDir.path, 'vccode1_wallpapers'));
  if (!root.existsSync()) return;

  final now = DateTime.now();
  final files = <File>[];
  for (final f in root.listSync(recursive: false)) {
    if (f is File) {
      final stat = f.statSync();
      // Delete by age first
      if (now.difference(stat.modified).inSeconds > maxAgeSeconds) {
        try {
          f.deleteSync();
        } catch (_) {}
        continue;
      }
      files.add(f);
    }
  }

  if (files.isEmpty) return;

  // Sort by oldest first
  files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

  // Enforce max files
  while (files.length > maxFiles) {
    final f = files.removeAt(0);
    try {
      f.deleteSync();
    } catch (_) {}
  }

  // Enforce total size
  int total = 0;
  for (final f in files) {
    total += f.statSync().size;
  }
  while (total > maxTotalBytes && files.isNotEmpty) {
    final f = files.removeAt(0);
    try {
      total -= f.statSync().size;
      f.deleteSync();
    } catch (_) {}
  }
}
