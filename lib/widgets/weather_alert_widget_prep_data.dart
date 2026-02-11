part of 'weather_alert_widget.dart';

/// 대비 품목 카테고리
enum PrepCategory {
  safety, // 안전용품
  freshFood, // 신선식품
  storableFood, // 비축식품
  medicine, // 의약품
  energy, // 에너지
  water, // 물
}

/// 대비 품목 추천
class PrepItem {
  final String name;
  final PrepCategory category;
  final String reason;
  final int quantity; // 권장 수량
  final String unit; // 단위 (개, 병, 리터)
  final int daysNeeded; // 며칠분

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
