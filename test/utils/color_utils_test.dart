import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/color_utils.dart';

void main() {
  group('ColorUtils', () {
    group('withOpacity', () {
      test('applies opacity to color', () {
        final color = Colors.red;
        final result = ColorUtils.withOpacity(color, 0.5);
        expect(result.a, closeTo(0.5, 0.01));
      });

      test('clamps opacity to 0-1 range', () {
        final result1 = ColorUtils.withOpacity(Colors.blue, -0.5);
        expect(result1.a, 0.0);

        final result2 = ColorUtils.withOpacity(Colors.blue, 1.5);
        expect(result2.a, 1.0);
      });
    });

    group('adjustBrightness', () {
      test('darkens color with factor < 1', () {
        final original = Colors.blue;
        final darker = ColorUtils.adjustBrightness(original, 0.5);

        final originalHsl = HSLColor.fromColor(original);
        final darkerHsl = HSLColor.fromColor(darker);

        expect(darkerHsl.lightness, lessThan(originalHsl.lightness));
      });

      test('lightens color with factor > 1', () {
        final original = Colors.blue;
        final lighter = ColorUtils.adjustBrightness(original, 1.5);

        final originalHsl = HSLColor.fromColor(original);
        final lighterHsl = HSLColor.fromColor(lighter);

        expect(lighterHsl.lightness, greaterThan(originalHsl.lightness));
      });

      test('clamps lightness to valid range', () {
        final original = Colors.white;
        final result = ColorUtils.adjustBrightness(original, 2.0);

        final resultHsl = HSLColor.fromColor(result);
        expect(resultHsl.lightness, lessThanOrEqualTo(1.0));
      });
    });

    group('darken', () {
      test('makes color darker', () {
        final original = Colors.green;
        final darkened = ColorUtils.darken(original, 0.2);

        final originalHsl = HSLColor.fromColor(original);
        final darkenedHsl = HSLColor.fromColor(darkened);

        expect(darkenedHsl.lightness, lessThan(originalHsl.lightness));
      });

      test('uses default amount of 0.1', () {
        final original = Colors.blue;
        final darkened = ColorUtils.darken(original);

        final originalHsl = HSLColor.fromColor(original);
        final darkenedHsl = HSLColor.fromColor(darkened);

        expect(darkenedHsl.lightness, lessThan(originalHsl.lightness));
      });
    });

    group('lighten', () {
      test('makes color lighter', () {
        final original = Colors.purple;
        final lightened = ColorUtils.lighten(original, 0.2);

        final originalHsl = HSLColor.fromColor(original);
        final lightenedHsl = HSLColor.fromColor(lightened);

        expect(lightenedHsl.lightness, greaterThan(originalHsl.lightness));
      });

      test('uses default amount of 0.1', () {
        final original = Colors.red;
        final lightened = ColorUtils.lighten(original);

        final originalHsl = HSLColor.fromColor(original);
        final lightenedHsl = HSLColor.fromColor(lightened);

        expect(lightenedHsl.lightness, greaterThan(originalHsl.lightness));
      });
    });
  });
}
