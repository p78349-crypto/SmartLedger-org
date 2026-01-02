import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('icons manifest references existing files', () {
    final manifestFile = File('assets/icons/metadata/icons.json');
    expect(manifestFile.existsSync(), isTrue, reason: 'icons.json should exist');

    final manifest = json.decode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final icons = (manifest['icons'] as List<dynamic>?) ?? [];

    for (final e in icons) {
      final map = e as Map<String, dynamic>;
      final assetPath = map['assetPath'] as String?;
      expect(assetPath, isNotNull, reason: 'assetPath should be present in manifest entry');
      final file = File(assetPath!);
      expect(file.existsSync(), isTrue, reason: 'asset file referenced by manifest must exist: $assetPath');
    }
  });
}

