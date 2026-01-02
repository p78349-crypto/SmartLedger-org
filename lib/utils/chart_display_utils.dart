/// 차트 디스플레이 유틸리티 - 공용 `ChartDisplayType` 재사용
library;
import 'package:smart_ledger/utils/chart_utils.dart';

class ChartDisplayUtils {
  ChartDisplayUtils._();

  /// 차트 디스플레이 타입에 따른 라벨 반환
  static String getDisplayLabel(ChartDisplayType display) {
    switch (display) {
      case ChartDisplayType.bar:
        return '막대형';
      case ChartDisplayType.line:
        return '선형';
      case ChartDisplayType.pie:
        return '원형';
      case ChartDisplayType.all:
        return '전체';
    }
  }

  /// 차트 디스플레이 타입에 따른 위젯 타입 반환
  static String getDisplayType(ChartDisplayType display) {
    switch (display) {
      case ChartDisplayType.bar:
        return 'BarChart';
      case ChartDisplayType.line:
        return 'LineChart';
      case ChartDisplayType.pie:
        return 'PieChart';
      case ChartDisplayType.all:
        return 'CombinedChart';
    }
  }

  /// 다음 차트 디스플레이로 전환
  static ChartDisplayType nextDisplay(ChartDisplayType current) {
    const values = ChartDisplayType.values;
    final currentIndex = values.indexOf(current);
    return values[(currentIndex + 1) % values.length];
  }
}

