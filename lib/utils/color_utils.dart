import 'package:flutter/material.dart';

/// 색상 관련 유틸리티 클래스
class ColorUtils {
  // Private constructor to prevent instantiation
  ColorUtils._();

  /// 금액에 따른 색상 반환 (양수: 파란색, 음수: 빨간색, 0: 회색)
  static Color getAmountColor(num amount, BuildContext context) {
    final theme = Theme.of(context);
    if (amount > 0) {
      return theme.colorScheme.primary;
    } else if (amount < 0) {
      return theme.colorScheme.error;
    } else {
      return theme.colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  /// 수입/지출에 따른 색상 반환
  static Color getIncomeExpenseColor(bool isIncome, BuildContext context) {
    final theme = Theme.of(context);
    return isIncome ? theme.colorScheme.primary : theme.colorScheme.error;
  }

  /// 진행률에 따른 색상 반환 (0-100%)
  static Color getProgressColor(double progress, BuildContext context) {
    final theme = Theme.of(context);
    if (progress < 30) {
      return theme.colorScheme.error;
    } else if (progress < 70) {
      return Colors.orange;
    } else if (progress < 100) {
      return Colors.lightGreen;
    } else {
      return theme.colorScheme.primary;
    }
  }

  /// 색상에 투명도 적용
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity.clamp(0.0, 1.0));
  }

  /// 색상 밝기 조정
  static Color adjustBrightness(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final adjustedLightness = (hsl.lightness * factor).clamp(0.0, 1.0);
    return hsl.withLightness(adjustedLightness).toColor();
  }

  /// 색상 어둡게
  static Color darken(Color color, [double amount = 0.1]) {
    return adjustBrightness(color, 1 - amount);
  }

  /// 색상 밝게
  static Color lighten(Color color, [double amount = 0.1]) {
    return adjustBrightness(color, 1 + amount);
  }

  /// 16진수 문자열을 Color로 변환
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Color를 16진수 문자열로 변환
  static String toHex(Color color, {bool includeAlpha = false}) {
    final argb = color.toARGB32();
    if (includeAlpha) {
      return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    } else {
      final hex = argb
          .toRadixString(16)
          .substring(2)
          .padLeft(6, '0')
          .toUpperCase();
      return '#$hex';
    }
  }

  /// 카테고리별 색상 반환
  static Color getCategoryColor(String category, BuildContext context) {
    final theme = Theme.of(context);
    switch (category.toLowerCase()) {
      case '식비':
      case '음식':
        return Colors.orange;
      case '교통':
      case '교통비':
        return Colors.blue;
      case '쇼핑':
        return Colors.pink;
      case '문화':
      case '여가':
        return Colors.purple;
      case '의료':
      case '건강':
        return Colors.red;
      case '교육':
        return Colors.green;
      case '주거':
      case '관리비':
        return Colors.brown;
      case '통신':
        return Colors.indigo;
      case '예금':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.secondary;
    }
  }

  /// 차트용 색상 팔레트 생성
  static List<Color> generateChartColors(
    int count, {
    double saturation = 0.7,
    double lightness = 0.5,
  }) {
    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      final hue = (i * 360 / count) % 360;
      colors.add(HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor());
    }
    return colors;
  }

  /// 대비되는 텍스트 색상 반환 (배경색에 따라)
  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// 그라데이션 색상 생성
  static LinearGradient createGradient(
    Color startColor,
    Color endColor, {
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [startColor, endColor],
    );
  }
}

