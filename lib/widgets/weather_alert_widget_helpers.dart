part of 'weather_alert_widget.dart';

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

/// 대비 품목 아이템 빌드
Widget _buildPrepItem(BuildContext context, PrepItem item) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      color: _getCategoryColor(
                        item.category,
                      ).withValues(alpha: 0.2),
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
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
