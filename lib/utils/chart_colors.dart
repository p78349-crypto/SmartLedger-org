import 'package:flutter/material.dart';

/// 차트 및 통계 목록에서 사용할 색상 유틸리티
class ChartColors {
  ChartColors._();

  /// 인덱스에 따른 카테고리 색상 반환 (상위 10/20/21 구분)
  static Color getColorForIndex(int index, ThemeData theme) {
    final scheme = theme.colorScheme;

    if (index < 10) {
      // 상위 1-10: 강조색 (Primary 계열)
      final colors = [
        scheme.primary,
        Colors.blue,
        Colors.indigo,
        Colors.cyan,
        Colors.teal,
        Colors.green,
        Colors.lightGreen,
        Colors.lime,
        Colors.yellow,
        Colors.amber,
      ];
      return colors[index % colors.length];
    } else if (index < 20) {
      // 상위 11-20: 보조색 (Secondary 계열)
      final colors = [
        scheme.secondary,
        Colors.orange,
        Colors.deepOrange,
        Colors.red,
        Colors.pink,
        Colors.purple,
        Colors.deepPurple,
        Colors.brown,
        Colors.blueGrey,
        Colors.grey,
      ];
      return colors[(index - 10) % colors.length];
    } else {
      // 21위 이상: 기타색 (Tertiary 계열)
      final colors = [
        scheme.tertiary,
        scheme.outline,
        scheme.onSurfaceVariant,
      ];
      return colors[(index - 20) % colors.length];
    }
  }
}
