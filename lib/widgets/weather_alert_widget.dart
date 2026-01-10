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

/// 극한 날씨 여부 판단
bool isExtremeWeather(WeatherCondition condition) {
  return condition == WeatherCondition.typhoon ||
      condition == WeatherCondition.coldWave ||
      condition == WeatherCondition.heavyRain ||
      condition == WeatherCondition.heatWave;
}

/// 극한 날씨별 위험도
enum WeatherRiskLevel {
  low,      // 낮음
  medium,   // 중간
  high,     // 높음
  critical, // 매우 높음 (대피 필요)
}

/// 날씨 위험도 평가
WeatherRiskLevel getWeatherRiskLevel(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.typhoon:
      return WeatherRiskLevel.critical; // 태풍: 매우 위험
    case WeatherCondition.coldWave:
      return WeatherRiskLevel.high;     // 한파: 높음
    case WeatherCondition.heavyRain:
      return WeatherRiskLevel.high;     // 폭우: 높음
    case WeatherCondition.heatWave:
      return WeatherRiskLevel.medium;   // 폭염: 중간
    case WeatherCondition.snowy:
      return WeatherRiskLevel.medium;   // 폭설: 중간
    default:
      return WeatherRiskLevel.low;
  }
}

/// 대비 품목 카테고리
enum PrepCategory {
  safety,      // 안전용품
  freshFood,   // 신선식품
  storableFood,// 비축식품
  medicine,    // 의약품
  energy,      // 에너지
  water,       // 물
}

/// 대비 품목 추천
class PrepItem {
  final String name;
  final PrepCategory category;
  final String reason;
  final int quantity;      // 권장 수량
  final String unit;       // 단위 (개, 병, 리터)
  final int daysNeeded;    // 며칠분

  const PrepItem({
    required this.name,
    required this.category,
    required this.reason,
    required this.quantity,
    required this.unit,
    required this.daysNeeded,
  });
}

/// 날씨별 대비 품목 데이터베이스
final Map<WeatherCondition, List<PrepItem>> weatherPrepDatabase = {
  // 태풍 대비
  WeatherCondition.typhoon: [
    const PrepItem(
      name: '생수',
      category: PrepCategory.water,
      reason: '단수 가능성',
      quantity: 20,
      unit: '리터',
      daysNeeded: 3,
    ),
    const PrepItem(
      name: '손전등',
      category: PrepCategory.safety,
      reason: '정전 대비',
      quantity: 2,
      unit: '개',
      daysNeeded: 3,
    ),
    const PrepItem(
      name: '건전지',
      category: PrepCategory.safety,
      reason: '손전등용',
      quantity: 10,
      unit: '개',
      daysNeeded: 3,
    ),
    const PrepItem(
      name: '라면',
      category: PrepCategory.storableFood,
      reason: '조리 간편, 장기 보관',
      quantity: 15,
      unit: '개',
      daysNeeded: 3,
    ),
    const PrepItem(
      name: '통조림',
      category: PrepCategory.storableFood,
      reason: '전기 없이 섭취 가능',
      quantity: 10,
      unit: '개',
      daysNeeded: 3,
    ),
    const PrepItem(
      name: '배추',
      category: PrepCategory.freshFood,
      reason: '태풍 후 가격 폭등 예상',
      quantity: 2,
      unit: '포기',
      daysNeeded: 7,
    ),
    const PrepItem(
      name: '사과',
      category: PrepCategory.freshFood,
      reason: '낙과로 공급 감소',
      quantity: 10,
      unit: '개',
      daysNeeded: 7,
    ),
    const PrepItem(
      name: '구급약',
      category: PrepCategory.medicine,
      reason: '부상 가능성',
      quantity: 1,
      unit: '세트',
      daysNeeded: 3,
    ),
  ],

  // 한파 대비
  WeatherCondition.coldWave: [
    const PrepItem(
      name: '핫팩',
      category: PrepCategory.safety,
      reason: '저체온증 예방',
      quantity: 20,
      unit: '개',
      daysNeeded: 5,
    ),
    const PrepItem(
      name: '생수',
      category: PrepCategory.water,
      reason: '수도관 동파 가능성',
      quantity: 15,
      unit: '리터',
      daysNeeded: 3,
    ),
    const PrepItem(
      name: '배추',
      category: PrepCategory.freshFood,
      reason: '한파로 생육 저하, 가격 상승',
      quantity: 2,
      unit: '포기',
      daysNeeded: 7,
    ),
    const PrepItem(
      name: '상추',
      category: PrepCategory.freshFood,
      reason: '한파 영향으로 가격 급등',
      quantity: 3,
      unit: '봉지',
      daysNeeded: 5,
    ),
    const PrepItem(
      name: '계란',
      category: PrepCategory.freshFood,
      reason: '조류독감 위험, 가격 상승',
      quantity: 30,
      unit: '개',
      daysNeeded: 10,
    ),
    const PrepItem(
      name: '감기약',
      category: PrepCategory.medicine,
      reason: '호흡기 질환 예방',
      quantity: 1,
      unit: '박스',
      daysNeeded: 7,
    ),
  ],

  // 폭우/장마 대비
  WeatherCondition.heavyRain: [
    const PrepItem(
      name: '생수',
      category: PrepCategory.water,
      reason: '수질 오염 가능성',
      quantity: 10,
      unit: '리터',
      daysNeeded: 3,
    ),
    const PrepItem(
      name: '배추',
      category: PrepCategory.freshFood,
      reason: '장마철 밭 침수로 가격 폭등',
      quantity: 2,
      unit: '포기',
      daysNeeded: 7,
    ),
    const PrepItem(
      name: '양배추',
      category: PrepCategory.freshFood,
      reason: '장마철 수급 불안정',
      quantity: 2,
      unit: '개',
      daysNeeded: 7,
    ),
    const PrepItem(
      name: '오이',
      category: PrepCategory.freshFood,
      reason: '습해로 공급 감소',
      quantity: 10,
      unit: '개',
      daysNeeded: 5,
    ),
    const PrepItem(
      name: '고등어',
      category: PrepCategory.freshFood,
      reason: '조업 중단으로 수급 차질',
      quantity: 5,
      unit: '마리',
      daysNeeded: 5,
    ),
    const PrepItem(
      name: '라면',
      category: PrepCategory.storableFood,
      reason: '외출 어려울 때 간편식',
      quantity: 10,
      unit: '개',
      daysNeeded: 3,
    ),
  ],

  // 폭염 대비
  WeatherCondition.heatWave: [
    const PrepItem(
      name: '생수',
      category: PrepCategory.water,
      reason: '탈수 예방',
      quantity: 20,
      unit: '리터',
      daysNeeded: 5,
    ),
    const PrepItem(
      name: '이온음료',
      category: PrepCategory.water,
      reason: '전해질 보충',
      quantity: 10,
      unit: '병',
      daysNeeded: 5,
    ),
    const PrepItem(
      name: '수박',
      category: PrepCategory.freshFood,
      reason: '폭염에 가격 하락, 수분 보충',
      quantity: 2,
      unit: '통',
      daysNeeded: 5,
    ),
    const PrepItem(
      name: '돼지고기',
      category: PrepCategory.freshFood,
      reason: '폭염 전 미리 확보 (가격 상승 전)',
      quantity: 2,
      unit: 'kg',
      daysNeeded: 3,
    ),
    const PrepItem(
      name: '닭고기',
      category: PrepCategory.freshFood,
      reason: '폭염으로 폐사율 증가 전 확보',
      quantity: 2,
      unit: '마리',
      daysNeeded: 3,
    ),
    const PrepItem(
      name: '해열제',
      category: PrepCategory.medicine,
      reason: '온열질환 대비',
      quantity: 1,
      unit: '박스',
      daysNeeded: 7,
    ),
  ],

  // 폭설 대비
  WeatherCondition.snowy: [
    const PrepItem(
      name: '생수',
      category: PrepCategory.water,
      reason: '고립 대비',
      quantity: 10,
      unit: '리터',
      daysNeeded: 3,
    ),
    const PrepItem(
      name: '라면',
      category: PrepCategory.storableFood,
      reason: '외출 불가능 시 식량',
      quantity: 15,
      unit: '개',
      daysNeeded: 5,
    ),
    const PrepItem(
      name: '통조림',
      category: PrepCategory.storableFood,
      reason: '장기 보관 가능',
      quantity: 8,
      unit: '개',
      daysNeeded: 5,
    ),
    const PrepItem(
      name: '배추',
      category: PrepCategory.freshFood,
      reason: '폭설로 운송 마비 전 확보',
      quantity: 1,
      unit: '포기',
      daysNeeded: 5,
    ),
  ],
};

/// 날씨 알림 위젯
class WeatherAlertWidget extends StatelessWidget {
  final WeatherData weather;
  final bool showPrepList;  // 대비 품목 표시 여부

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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
        builder: (context) => ShoppingListScreen(
          shoppingList: shoppingList,
        ),
      ),
    );
  }

  /// 안전 이동 경로 화면으로 이동
  void _goToEvacuationRoutes(BuildContext context) {
    final plan = EvacuationRoutePlanner.generatePlan(
      weather: weather,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvacuationRouteScreen(plan: plan),
      ),
    );
  }

  /// 대비 품목 아이템 빌드
  Widget _buildPrepItem(BuildContext context, PrepItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(item.category).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(item.category),
              color: _getCategoryColor(item.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // 품목 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(item.category).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getCategoryName(item.category),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getCategoryColor(item.category),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '권장: ${item.quantity}${item.unit} (${item.daysNeeded}일분)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.reason,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 경고 제목
  String _getAlertTitle(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.typhoon:
        return '⚠️ 태풍 경보';
      case WeatherCondition.coldWave:
        return '❄️ 한파 특보';
      case WeatherCondition.heavyRain:
        return '🌧️ 폭우/장마 주의보';
      case WeatherCondition.heatWave:
        return '🌡️ 폭염 경보';
      case WeatherCondition.snowy:
        return '🌨️ 폭설 특보';
      default:
        return '날씨 알림';
    }
  }

  /// 대비 행동 메시지
  String _getPreparationMessage(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.typhoon:
        return '🚨 태풍 대비: 창문 점검, 외출 자제, 배추/사과 등 신선식품과 생수/건전지 확보하세요. '
            '정전 가능성이 높습니다!';
      case WeatherCondition.coldWave:
        return '🥶 한파 대비: 수도관 동파 주의, 난방 점검, 채소류 가격 급등 전 미리 구매하세요. '
            '계란은 조류독감 발생 전 확보!';
      case WeatherCondition.heavyRain:
        return '💧 폭우 대비: 침수 지역 피하기, 채소류 가격 폭등 예상, 고등어 등 수산물 미리 확보하세요. '
            '장마철 밭 침수로 공급 감소!';
      case WeatherCondition.heatWave:
        return '🔥 폭염 대비: 수분 섭취, 외출 자제, 닭고기/돼지고기 가격 상승 전 확보하세요. '
            '수박은 오히려 저렴해집니다!';
      case WeatherCondition.snowy:
        return '☃️ 폭설 대비: 외출 자제, 운송 마비 대비 식량 확보, 채소류 미리 구매하세요. '
            '고립 가능성 주의!';
      default:
        return '날씨에 대비하세요.';
    }
  }

  /// 위험도 텍스트
  String _getRiskLevelText(WeatherRiskLevel level) {
    switch (level) {
      case WeatherRiskLevel.critical:
        return '매우 위험 - 즉시 대비 필요';
      case WeatherRiskLevel.high:
        return '높은 위험도 - 적극 대비 권장';
      case WeatherRiskLevel.medium:
        return '중간 위험도 - 대비 권장';
      case WeatherRiskLevel.low:
        return '낮은 위험도';
    }
  }

  /// 위험도 색상
  Color _getRiskColor(WeatherRiskLevel level) {
    switch (level) {
      case WeatherRiskLevel.critical:
        return Colors.red;
      case WeatherRiskLevel.high:
        return Colors.orange;
      case WeatherRiskLevel.medium:
        return Colors.amber;
      case WeatherRiskLevel.low:
        return Colors.blue;
    }
  }

  /// 위험도 아이콘
  IconData _getRiskIcon(WeatherRiskLevel level) {
    switch (level) {
      case WeatherRiskLevel.critical:
        return Icons.warning;
      case WeatherRiskLevel.high:
        return Icons.error_outline;
      case WeatherRiskLevel.medium:
        return Icons.info_outline;
      case WeatherRiskLevel.low:
        return Icons.check_circle_outline;
    }
  }

  /// 카테고리 이름
  String _getCategoryName(PrepCategory category) {
    switch (category) {
      case PrepCategory.safety:
        return '안전';
      case PrepCategory.freshFood:
        return '신선식품';
      case PrepCategory.storableFood:
        return '비축식품';
      case PrepCategory.medicine:
        return '의약품';
      case PrepCategory.energy:
        return '에너지';
      case PrepCategory.water:
        return '물';
    }
  }

  /// 카테고리 아이콘
  IconData _getCategoryIcon(PrepCategory category) {
    switch (category) {
      case PrepCategory.safety:
        return Icons.security;
      case PrepCategory.freshFood:
        return Icons.restaurant;
      case PrepCategory.storableFood:
        return Icons.inventory_2;
      case PrepCategory.medicine:
        return Icons.medical_services;
      case PrepCategory.energy:
        return Icons.bolt;
      case PrepCategory.water:
        return Icons.water_drop;
    }
  }

  /// 카테고리 색상
  Color _getCategoryColor(PrepCategory category) {
    switch (category) {
      case PrepCategory.safety:
        return Colors.red;
      case PrepCategory.freshFood:
        return Colors.green;
      case PrepCategory.storableFood:
        return Colors.brown;
      case PrepCategory.medicine:
        return Colors.purple;
      case PrepCategory.energy:
        return Colors.orange;
      case PrepCategory.water:
        return Colors.blue;
    }
  }
}

/// 간단한 날씨 알림 배너 (홈 화면용)
class WeatherAlertBanner extends StatelessWidget {
  final WeatherData weather;
  final VoidCallback? onTap;

  const WeatherAlertBanner({
    super.key,
    required this.weather,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final condition = weather.effectiveCondition;
    final isExtreme = isExtremeWeather(condition);
    
    if (!isExtreme) {
      return const SizedBox.shrink();
    }

    final riskLevel = getWeatherRiskLevel(condition);
    final prepItems = weatherPrepDatabase[condition] ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getRiskColor(riskLevel).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getRiskColor(riskLevel),
            width: 2,
          ),
        ),
        child: Row(
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getRiskColor(riskLevel),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '대비 품목 ${prepItems.length}개 확인 필요',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _getRiskColor(riskLevel),
            ),
          ],
        ),
      ),
    );
  }

  String _getAlertTitle(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.typhoon:
        return '⚠️ 태풍 경보';
      case WeatherCondition.coldWave:
        return '❄️ 한파 특보';
      case WeatherCondition.heavyRain:
        return '🌧️ 폭우 주의보';
      case WeatherCondition.heatWave:
        return '🌡️ 폭염 경보';
      case WeatherCondition.snowy:
        return '🌨️ 폭설 특보';
      default:
        return '날씨 알림';
    }
  }

  Color _getRiskColor(WeatherRiskLevel level) {
    switch (level) {
      case WeatherRiskLevel.critical:
        return Colors.red;
      case WeatherRiskLevel.high:
        return Colors.orange;
      case WeatherRiskLevel.medium:
        return Colors.amber;
      case WeatherRiskLevel.low:
        return Colors.blue;
    }
  }

  IconData _getRiskIcon(WeatherRiskLevel level) {
    switch (level) {
      case WeatherRiskLevel.critical:
        return Icons.warning;
      case WeatherRiskLevel.high:
        return Icons.error_outline;
      case WeatherRiskLevel.medium:
        return Icons.info_outline;
      case WeatherRiskLevel.low:
        return Icons.check_circle_outline;
    }
  }
}
