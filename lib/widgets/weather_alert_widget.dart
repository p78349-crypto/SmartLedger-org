// 날씨 알림 위젯: 극한 날씨 사전 경고 및 대비 품목 추천
//
// 태풍, 한파, 폭설, 폭우 등 극한 날씨를 미리 알려주고
// 안전 확보 및 신선식품 확보 등 대비 행동을 추천합니다.

import 'package:flutter/material.dart';
import '../utils/weather_utils.dart';
import '../utils/weather_price_sensitivity.dart';
import '../utils/shopping_list_generator.dart';
import '../utils/evacuation_route_utils.dart';
import '../screens/shopping_list_screen.dart';
import '../screens/evacuation_route_screen.dart';

part 'weather_alert_widget_prep_data.dart';
part 'weather_alert_widget_helpers.dart';
part 'weather_alert_widget_banner.dart';

/// 극한 날씨 여부 판단
bool isExtremeWeather(WeatherCondition condition) {
  return condition == WeatherCondition.typhoon ||
      condition == WeatherCondition.coldWave ||
      condition == WeatherCondition.heavyRain ||
      condition == WeatherCondition.heatWave;
}

/// 극한 날씨별 위험도
enum WeatherRiskLevel {
  low, // 낮음
  medium, // 중간
  high, // 높음
  critical, // 매우 높음 (대피 필요)
}

/// 날씨 위험도 평가
WeatherRiskLevel getWeatherRiskLevel(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.typhoon:
      return WeatherRiskLevel.critical; // 태풍: 매우 위험
    case WeatherCondition.coldWave:
      return WeatherRiskLevel.high; // 한파: 높음
    case WeatherCondition.heavyRain:
      return WeatherRiskLevel.high; // 폭우: 높음
    case WeatherCondition.heatWave:
      return WeatherRiskLevel.medium; // 폭염: 중간
    case WeatherCondition.snowy:
      return WeatherRiskLevel.medium; // 폭설: 중간
    default:
      return WeatherRiskLevel.low;
  }
}

/// 날씨 알림 위젯 (상세 대비 품목 포함)
class WeatherAlertWidget extends StatelessWidget {
  final WeatherData weather;
  final bool showPrepList;

  const WeatherAlertWidget({
    super.key,
    required this.weather,
    this.showPrepList = true,
  });

  @override
  Widget build(BuildContext context) {
    final condition = weather.effectiveCondition;
    final isExtreme = isExtremeWeather(condition);

    if (!isExtreme) {
      return const SizedBox.shrink(); // 극한 날씨 아니면 표시 안 함
    }

    final riskLevel = getWeatherRiskLevel(condition);
    final prepItems = weatherPrepDatabase[condition] ?? [];

    return Card(
      color: _getRiskColor(riskLevel).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 경고 헤더
            Row(
              children: [
                Icon(
                  _getRiskIcon(riskLevel),
                  color: _getRiskColor(riskLevel),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAlertTitle(condition),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(riskLevel),
                        ),
                      ),
                      Text(
                        _getRiskLevelText(riskLevel),
                        style: TextStyle(
                          fontSize: 14,
                          color: _getRiskColor(riskLevel),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 날씨 정보
            Text(
              '${weather.location} • ${weather.temperature.toStringAsFixed(1)}°C • 습도 ${weather.humidity}%',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 대비 행동 요약
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getRiskColor(riskLevel)),
              ),
              child: Text(
                _getPreparationMessage(condition),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            if (showPrepList) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // 대비 품목 제목
              Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '필수 대비 품목 (${prepItems.length}개)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 대비 품목 리스트
              ...prepItems.map((item) => _buildPrepItem(context, item)),

              const SizedBox(height: 16),

              // 장보기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _goToShoppingList(context),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text(
                    '지금 장보러 가기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getRiskColor(riskLevel),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              if (riskLevel == WeatherRiskLevel.high ||
                  riskLevel == WeatherRiskLevel.critical) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _goToEvacuationRoutes(context),
                    icon: const Icon(Icons.route),
                    label: const Text(
                      '안전한 이동 경로 보기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _getRiskColor(riskLevel),
                      side: BorderSide(color: _getRiskColor(riskLevel)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// 쇼핑 리스트 화면으로 이동
  void _goToShoppingList(BuildContext context) {
    // WeatherData를 WeatherForecast로 변환
    final forecast = WeatherForecast(
      condition: weather.effectiveCondition,
      forecastDate: DateTime.now(),
      daysUntil: 0, // 당일
      temperature: weather.temperature,
      location: weather.location,
      confidence: 0.9,
    );

    // 쇼핑 리스트 생성
    final shoppingList = ShoppingListGenerator.generateShoppingList(
      forecast: forecast,
    );

    // 화면 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingListScreen(shoppingList: shoppingList),
      ),
    );
  }

  /// 안전 이동 경로 화면으로 이동
  void _goToEvacuationRoutes(BuildContext context) {
    final plan = EvacuationRoutePlanner.generatePlan(weather: weather);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvacuationRouteScreen(plan: plan),
      ),
    );
  }
}
