import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/theme_presets.dart';

void main() {
  group('ThemeVariant', () {
    test('byId returns variant when present and null when missing', () {
      expect(ThemeVariant.byId(ThemeVariant.flSoftPink.id), ThemeVariant.flSoftPink);
      expect(ThemeVariant.byId('does_not_exist'), isNull);
      expect(ThemeVariant.byId(null), isNull);
    });

    test('all ids are unique', () {
      final ids = ThemeVariant.all.map((v) => v.id).toList();
      expect(ids.length, ids.toSet().length);
    });

    test('toJson/fromJson round trip preserves fields', () {
      const original = ThemeVariant.miMidnight;
      final json = original.toJson();
      final restored = ThemeVariant.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.onColor, original.onColor);
      expect(restored.gradient, original.gradient);
    });

    test('toJson stores color ints', () {
      final json = ThemeVariant.flSky.toJson();
      expect(json['onColor'], isA<int>());
      final gradient = json['gradient'] as List;
      expect(gradient, isNotEmpty);
      expect(gradient.first, isA<int>());
      // Ensure int can round trip to Color.
      expect(Color(gradient.first as int), isA<Color>());
    });
  });
}
