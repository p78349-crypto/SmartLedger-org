part of 'weather_price_prediction_utils.dart';

/// 현재 날씨 기반 가격 알림 생성 (내부 구현)
List<WeatherPriceAlert> _generateAlertsImpl({
  required List<Transaction> transactions,
  required WeatherSnapshot currentWeather,
}) {
  final alerts = <WeatherPriceAlert>[];
  final temp = currentWeather.tempC ?? 20.0;
  final weatherType = _classifyWeather(currentWeather);

  // 폭염 알림
  if (temp >= 30) {
    alerts.add(
      const WeatherPriceAlert(
        itemName: '배추',
        category: '채소',
        triggerWeather: '폭염 (30도 이상)',
        expectedTrend: PriceTrend.rising,
        expectedChangePercent: 20.0,
        daysUntilImpact: 7,
        recommendation: '배추를 미리 구매하세요! 폭염 지속시 가격 상승 예상',
      ),
    );
    alerts.add(
      const WeatherPriceAlert(
        itemName: '시금치',
        category: '채소',
        triggerWeather: '폭염 (30도 이상)',
        expectedTrend: PriceTrend.rising,
        expectedChangePercent: 25.0,
        daysUntilImpact: 5,
        recommendation: '엽채류 미리 구매 추천',
      ),
    );
    alerts.add(
      const WeatherPriceAlert(
        itemName: '수박',
        category: '과일',
        triggerWeather: '폭염 (30도 이상)',
        expectedTrend: PriceTrend.falling,
        expectedChangePercent: -15.0,
        daysUntilImpact: 3,
        recommendation: '수박은 조금 기다리면 더 싸게 살 수 있어요!',
      ),
    );
  }

  // 한파 알림
  if (temp <= -5) {
    alerts.add(
      const WeatherPriceAlert(
        itemName: '채소류',
        category: '채소',
        triggerWeather: '한파 (-5도 이하)',
        expectedTrend: PriceTrend.rising,
        expectedChangePercent: 15.0,
        daysUntilImpact: 5,
        recommendation: '한파 전에 채소를 미리 구매하세요',
      ),
    );
  }

  // 비/장마 알림
  if (weatherType == WeatherConditionType.rainy ||
      (currentWeather.precipitation1hMm ?? 0) > 10) {
    alerts.add(
      const WeatherPriceAlert(
        itemName: '엽채류',
        category: '채소',
        triggerWeather: '장마/폭우',
        expectedTrend: PriceTrend.rising,
        expectedChangePercent: 20.0,
        daysUntilImpact: 7,
        recommendation: '장마 전에 채소를 비축해두세요',
      ),
    );
  }

  return alerts;
}

/// 날씨 종합 리포트 생성 (내부 구현)
String _generateWeatherPriceReportImpl({
  required List<Transaction> transactions,
  required WeatherSnapshot currentWeather,
}) {
  final buffer = StringBuffer();
  final temp = currentWeather.tempC ?? 20.0;
  final now = DateTime.now();
  final month = now.month;

  // 현재 날씨 요약
  buffer.writeln('## 현재 날씨 분석');
  buffer.writeln('기온: ${temp.toStringAsFixed(1)}도');

  if (temp >= 30) {
    buffer.writeln('\n### 폭염 주의보');
    buffer.writeln('• 엽채류(배추, 시금치, 상추) 가격 상승 예상');
    buffer.writeln('• 여름 과일(수박, 참외) 출하량 증가로 가격 하락 예상');
    buffer.writeln('• 추천: 채소는 미리, 과일은 조금 기다렸다 구매');
  } else if (temp <= -5) {
    buffer.writeln('\n### 한파 주의보');
    buffer.writeln('• 채소류 전반 가격 상승 예상');
    buffer.writeln('• 난방 관련 비용 증가');
    buffer.writeln('• 추천: 김장 채소 미리 확보, 뿌리채소 비축');
  } else if (temp >= 25) {
    buffer.writeln('\n### 더운 날씨');
    buffer.writeln('• 냉장 보관 필요 품목 유의');
    buffer.writeln('• 제철 과일 구매 적기');
  }

  // 제철 식품 추천
  buffer.writeln('\n## $month월 제철 식품');
  final seasonal = _seasonalItems[month] ?? [];
  if (seasonal.isNotEmpty) {
    buffer.writeln(seasonal.join(', '));
    buffer.writeln('\n• 제철 식품은 맛과 영양이 좋고 가격도 저렴해요!');
  }

  // 구매 타이밍 조언
  buffer.writeln('\n## 구매 타이밍 조언');
  if (month >= 6 && month <= 8) {
    buffer.writeln('• 여름 과일: 지금이 가장 저렴한 시기');
    buffer.writeln('• 채소류: 장마/폭염 전 미리 구매 추천');
  } else if (month >= 9 && month <= 11) {
    buffer.writeln('• 가을 과일(사과, 배, 포도): 제철로 가격 좋음');
    buffer.writeln('• 김장 채소: 11월 초중순이 가장 적기');
  } else if (month == 12 || month <= 2) {
    buffer.writeln('• 한파 전 채소 비축 추천');
    buffer.writeln('• 겨울 수산물(굴, 명태) 제철');
  } else {
    buffer.writeln('• 봄 채소(냉이, 달래, 미나리) 제철');
    buffer.writeln('• 딸기 시즌 마지막 기회');
  }

  return buffer.toString();
}
