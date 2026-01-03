import 'dart:convert';
import 'dart:io';

class PackageInfo {
  PackageInfo({
    required this.name,
    required this.rootPath,
    required this.version,
    required this.dependencyKind,
  });

  final String name;
  final String rootPath;
  final String version;
  final String dependencyKind; // e.g. direct main / direct dev / transitive
}

String _detectLicenseType(String text) {
  final normalized = text.toLowerCase();
  if (normalized.contains('apache license') && normalized.contains('version 2')) {
    return 'Apache-2.0 (detected)';
  }
  if (normalized.contains('mit license')) {
    return 'MIT (detected)';
  }
  if (normalized.contains('mozilla public license') && normalized.contains('2.0')) {
    return 'MPL-2.0 (detected)';
  }
  if (normalized.contains('gnu general public license')) {
    if (normalized.contains('version 3')) return 'GPL-3.0 (detected)';
    if (normalized.contains('version 2')) return 'GPL-2.0 (detected)';
    return 'GPL (detected)';
  }
  if (normalized.contains('gnu lesser general public license')) {
    if (normalized.contains('version 3')) return 'LGPL-3.0 (detected)';
    if (normalized.contains('version 2.1')) return 'LGPL-2.1 (detected)';
    return 'LGPL (detected)';
  }
  if (normalized.contains('bsd license') || normalized.contains('redistribution and use in source and binary forms')) {
    return 'BSD (detected)';
  }
  if (normalized.contains('isc license')) {
    return 'ISC (detected)';
  }
  if (normalized.contains('eclipse public license')) {
    return 'EPL (detected)';
  }
  if (normalized.contains('the unlicense')) {
    return 'Unlicense (detected)';
  }
  return 'Unknown (review)';
}

Map<String, ({String version, String dependencyKind})> _parsePubspecLock(String lockText) {
  // Minimal parser for pubspec.lock.
  // It looks for blocks:
  //   <name>:
  //     dependency: <kind>
  //     ...
  //     version: "x.y.z"
  final lines = const LineSplitter().convert(lockText);
  final result = <String, ({String version, String dependencyKind})>{};

  String? current;
  String? dependencyKind;
  String? version;

  void flush() {
    final key = current;
    if (key == null) return;
    result[key] = (
      version: version ?? 'unknown',
      dependencyKind: dependencyKind ?? 'unknown',
    );
  }

  final pkgHeader = RegExp(r'^  ([A-Za-z0-9_]+):\s*$');
  for (final raw in lines) {
    final line = raw;
    final m = pkgHeader.firstMatch(line);
    if (m != null) {
      flush();
      current = m.group(1);
      dependencyKind = null;
      version = null;
      continue;
    }

    if (current == null) continue;

    final trimmed = line.trimLeft();
    if (trimmed.startsWith('dependency:')) {
      dependencyKind = trimmed.substring('dependency:'.length).trim();
      continue;
    }
    if (trimmed.startsWith('version:')) {
      var v = trimmed.substring('version:'.length).trim();
      if ((v.startsWith('"') && v.endsWith('"')) ||
          (v.startsWith("'") && v.endsWith("'"))) {
        v = v.substring(1, v.length - 1);
      }
      version = v;
      continue;
    }
  }
  flush();

  return result;
}

File? _findLicenseFile(Directory pkgRoot) {
  final candidates = <String>[
    'LICENSE',
    'LICENSE.md',
    'LICENSE.txt',
    'COPYING',
    'COPYING.txt',
    'NOTICE',
    'NOTICE.txt',
  ];

  for (final name in candidates) {
    final f = File(PathUtil.join(pkgRoot.path, name));
    if (f.existsSync()) return f;
  }

  // Fallback: any file starting with LICENSE in root.
  final entries = pkgRoot.listSync(followLinks: false);
  for (final e in entries) {
    if (e is File) {
      final base = PathUtil.basename(e.path).toUpperCase();
      if (base.startsWith('LICENSE')) return e;
    }
  }

  // Common case for Flutter SDK packages: the package folder may not contain
  // a dedicated LICENSE file, but the Flutter SDK root does.
  // Try parent directories a few levels up.
  var current = pkgRoot;
  for (var i = 0; i < 4; i++) {
    final parent = current.parent;
    if (parent.path == current.path) break;
    for (final name in candidates) {
      final f = File(PathUtil.join(parent.path, name));
      if (f.existsSync()) return f;
    }
    current = parent;
  }

  return null;
}

// Minimal path helpers to avoid extra dependencies.
class PathUtil {
  static String join(String a, String b) {
    if (a.endsWith('\\') || a.endsWith('/')) return '$a$b';
    return '$a\\$b';
  }

  static String basename(String path) {
    final sep = path.contains('\\') ? '\\' : '/';
    final idx = path.lastIndexOf(sep);
    return idx == -1 ? path : path.substring(idx + 1);
  }
}

String _escapeMd(String s) => s.replaceAll('|', '\\|');

Future<void> main(List<String> args) async {
  final root = Directory.current;
  final pkgConfig = File(
    PathUtil.join(root.path, '.dart_tool\\package_config.json'),
  );
  final lockFile = File(PathUtil.join(root.path, 'pubspec.lock'));

  if (!pkgConfig.existsSync()) {
    stderr.writeln('Missing .dart_tool/package_config.json. Run: flutter pub get');
    exitCode = 2;
    return;
  }
  if (!lockFile.existsSync()) {
    stderr.writeln('Missing pubspec.lock. Run: flutter pub get');
    exitCode = 2;
    return;
  }

  final lockMap = _parsePubspecLock(lockFile.readAsStringSync());
  final pkgJson = jsonDecode(pkgConfig.readAsStringSync()) as Map<String, dynamic>;
  final packages = (pkgJson['packages'] as List).cast<Map<String, dynamic>>();

  final infos = <PackageInfo>[];

  for (final pkg in packages) {
    final name = pkg['name'] as String;
    if (name == 'vccode1') continue;

    final rootUriStr = pkg['rootUri'] as String;
    final uri = Uri.parse(rootUriStr);
    if (uri.scheme != 'file') continue;

    final rootPath = uri.toFilePath(windows: Platform.isWindows);
    final lock = lockMap[name];
    infos.add(
      PackageInfo(
        name: name,
        rootPath: rootPath,
        version: lock?.version ?? 'unknown',
        dependencyKind: lock?.dependencyKind ?? 'unknown',
      ),
    );
  }

  infos.sort((a, b) => a.name.compareTo(b.name));

  final outMd = StringBuffer();
  outMd.writeln('# Third-Party Licenses Summary');
  outMd.writeln();
  outMd.writeln('- Generated: ${DateTime.now().toIso8601String()}');
  outMd.writeln('- Sources: `.dart_tool/package_config.json` + `pubspec.lock` + local Pub cache (package root folders)');
  outMd.writeln('- Note: This file intentionally does NOT include full license texts. It only records which license file was found and a best-effort detected license type.');
  outMd.writeln();
  outMd.writeln('## Package Scan Result');
  outMd.writeln();
  outMd.writeln('| Package | Version | Dependency | License File | Detected Type |');
  outMd.writeln('|---|---:|---|---|---|');

  final missing = <String>[];

  for (final info in infos) {
    final rootDir = Directory(info.rootPath);
    File? license;
    String detected = 'Unknown (review)';

    if (rootDir.existsSync()) {
      license = _findLicenseFile(rootDir);
      if (license != null && license.existsSync()) {
        final content = license.readAsStringSync();
        final head = content.length > 4000 ? content.substring(0, 4000) : content;
        detected = _detectLicenseType(head);
      }
    }

    String licenseName;
    if (license == null) {
      licenseName = 'NOT FOUND';
    } else {
      final base = PathUtil.basename(license.path);
      if (license.parent.path != info.rootPath) {
        licenseName = '$base (parent)';
      } else {
        licenseName = base;
      }
    }
    if (license == null) missing.add(info.name);

    outMd.writeln(
      '| ${_escapeMd(info.name)} | ${_escapeMd(info.version)} | ${_escapeMd(info.dependencyKind)} | ${_escapeMd(licenseName)} | ${_escapeMd(detected)} |',
    );
  }

  outMd.writeln();
  outMd.writeln('## Missing License Files (Manual Review Needed)');
  outMd.writeln();
  if (missing.isEmpty) {
    outMd.writeln('- None');
  } else {
    for (final name in missing) {
      outMd.writeln('- $name');
    }
  }

  final docsDir = Directory(PathUtil.join(root.path, 'docs'));
  if (!docsDir.existsSync()) {
    docsDir.createSync(recursive: true);
  }

  final outFile = File(
    PathUtil.join(docsDir.path, 'THIRD_PARTY_LICENSES_SUMMARY.md'),
  );
  outFile.writeAsStringSync(outMd.toString());

  stdout.writeln('Wrote: ${outFile.path}');
  stdout.writeln('Packages scanned: ${infos.length}');
  stdout.writeln('Missing license files: ${missing.length}');
}

