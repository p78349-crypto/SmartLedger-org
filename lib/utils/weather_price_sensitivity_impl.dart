import 'weather_price_sensitivity_database.dart';
import 'weather_price_sensitivity_models.dart';

/// 품목명으로 날씨 민감도 데이터 조회
WeatherPriceSensitivity? getWeatherSensitivityByItem(String itemName) {
  try {
    return weatherPriceSensitivityDatabase.firstWhere(
      (item) => item.itemName == itemName,
    );
  } catch (_) {
    return null;
  }
}

/// 카테고리별 민감도 데이터 조회
List<WeatherPriceSensitivity> getWeatherSensitivityByCategory(
  PriceCategory category,
) {
  return weatherPriceSensitivityDatabase
      .where((item) => item.category == category)
      .toList();
}

/// 특정 날씨 조건에 가장 민감한 품목들 조회
List<WeatherPriceSensitivity> getMostSensitiveItems(
  WeatherCondition condition, {
  int limit = 10,
}) {
  final items = weatherPriceSensitivityDatabase.where((item) {
    return item.sensitivity.containsKey(condition);
  }).toList();

  items.sort((a, b) {
    final aValue = a.sensitivity[condition] ?? 0.0;
    final bValue = b.sensitivity[condition] ?? 0.0;
    return bValue.compareTo(aValue);
  });

  return items.take(limit).toList();
}
