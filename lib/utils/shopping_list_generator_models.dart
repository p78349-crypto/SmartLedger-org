import '../utils/weather_price_sensitivity.dart';
import '../widgets/weather_alert_widget.dart';

/// 날씨 예보 데이터
class WeatherForecast {
  final WeatherCondition condition;
  final DateTime forecastDate;
  final int daysUntil; // 며칠 후인지
  final double temperature;
  final String location;
  final double confidence; // 예보 신뢰도 (0.0~1.0)

  const WeatherForecast({
    required this.condition,
    required this.forecastDate,
    required this.daysUntil,
    required this.temperature,
    required this.location,
    required this.confidence,
  });

  /// 사전 대비가 필요한 날씨인지
  bool get needsPreparation => isExtremeWeather(condition);

  /// 긴급도 (1~5, 5가 가장 긴급)
  int get urgency {
    if (daysUntil <= 0) return 5; // 당일
    if (daysUntil == 1) return 4; // 내일
    if (daysUntil == 2) return 3; // 모레
    if (daysUntil <= 4) return 2; // 3~4일 후
    return 1; // 5일 이상
  }

  /// 대비 시작 권장 시점
  String get preparationTiming {
    if (daysUntil <= 0) return '지금 즉시';
    if (daysUntil == 1) return '오늘 안에';
    if (daysUntil == 2) return '내일까지';
    if (daysUntil <= 4) return '이번 주 안에';
    return '여유있게';
  }
}

/// 쇼핑 리스트 아이템
class ShoppingListItem {
  final String name;
  final PrepCategory category;
  final int quantity;
  final String unit;
  final String reason; // 왜 필요한지
  final double priority; // 우선순위 (0.0~1.0)
  final bool isUrgent; // 긴급 품목 여부
  final int estimatedPrice; // 예상 가격 (원)

  const ShoppingListItem({
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.reason,
    required this.priority,
    required this.isUrgent,
    required this.estimatedPrice,
  });

  /// 총 예상 비용
  int get totalCost => estimatedPrice * quantity;
}

/// 쇼핑 리스트 생성 결과
class ShoppingListResult {
  final WeatherForecast forecast;
  final List<ShoppingListItem> items;
  final String urgentMessage; // 긴급 메시지
  final int totalCost; // 총 예상 비용
  final int potentialSavings; // 예상 절약액

  const ShoppingListResult({
    required this.forecast,
    required this.items,
    required this.urgentMessage,
    required this.totalCost,
    required this.potentialSavings,
  });

  /// 긴급 품목만
  List<ShoppingListItem> get urgentItems =>
      items.where((item) => item.isUrgent).toList();

  /// 카테고리별 그룹화
  Map<PrepCategory, List<ShoppingListItem>> get itemsByCategory {
    final grouped = <PrepCategory, List<ShoppingListItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []);
      grouped[item.category]!.add(item);
    }
    return grouped;
  }
}
