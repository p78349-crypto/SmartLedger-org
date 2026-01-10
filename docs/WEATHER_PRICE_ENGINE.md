# 날씨 기반 물가 예측 엔진 (Weather-Price Engine)

## 개요

날씨 정보를 기반으로 식료품 가격 변동을 예측하고, 사용자에게 구매 타이밍을 추천하는 시스템입니다.

**핵심 특징:**
- ✅ **한국 특화**: 장마철, 태풍, 한파 등 한국의 계절적 특수성 반영
- ✅ **재사용 가능**: WeatherUtils로 분리되어 어디서든 호출 가능
- ✅ **음성 비서 통합**: "날씨 물가 확인" 명령으로 즉시 조회
- ✅ **실시간 예측**: 현재 날씨 기반 가격 변동률 계산 (-20% ~ +20%)
- ✅ **성능 최적화**: SimpleCache로 5분 캐싱

---

## 날씨 민감도 지수

품목별 날씨 민감도를 **-1.0 ~ +1.0** 스케일로 정의:

| 지수 | 의미 | 예상 가격 변동 | 사용자 추천 |
|------|------|----------------|-------------|
| **+1.0** | 큰 폭 상승 | +20% | 🔴 빨리 구매하세요! |
| **+0.5** | 소폭 상승 | +10% | 🟡 구매 고려하세요 |
| **0.0** | 영향 없음 | 0% | ⚪ 가격 안정적 |
| **-0.5** | 소폭 하락 | -10% | 🔵 구매 적기! |
| **-1.0** | 큰 폭 하락 | -20% | 🟢 지금이 최저가! |

---

## 날씨 조건별 영향

### 1. 장마철/폭우 (6~7월)
```dart
채소류: +0.8 ~ +1.0 (밭 침수, 병해충 증가)
- 배추: +0.9 (밭 침수로 공급 감소)
- 상추: +0.8 (습해로 병해 증가)
- 오이: +0.9 (뿌리 썩음)

과일류: +0.6 ~ +0.7 (병해 증가)
- 포도: +0.7 (곰팡이 병)

수산물: +0.7 ~ +1.0 (출항 불가)
- 고등어: +0.7 (조업 중단)
- 오징어: +0.8 (수급 차질)
```

### 2. 태풍 (8~9월)
```dart
채소류: +1.0 (밭 파괴, 도복 피해)
- 배추: +1.0 (최고 등급 피해)
- 무: +1.0 (뿌리 채소 피해)

과일류: +1.0 (낙과 피해)
- 사과: +1.0 (낙과로 수확량 급감)
- 배: +1.0 (같은 피해)

수산물: +1.0 (전면 조업 중단)
- 고등어: +1.0
- 오징어: +1.0
```

### 3. 한파 (12~2월, -10도 이하)
```dart
채소류: +0.5 ~ +0.7 (생육 저해)
- 배추: +0.6 (생육 지연)
- 상추: +0.7 (한파에 약함)

축산물: +0.5 ~ +0.6 (난방비 증가)
- 닭고기: +0.6 (조류독감 위험)
- 계란: +0.6 (산란율 저하)

에너지: +1.0 (난방비 급등)
- 난방비: +1.0 (난방 수요 폭증)
- 전기요금: +0.7 (전기 난방)

수산물: -0.3 (한류성 어종)
- 명태: -0.3 (한류에서 어획 증가)
```

### 4. 폭염 (7~8월, 33도 이상)
```dart
채소류: +0.3 ~ +0.5 (생육 저하)
- 배추: +0.4
- 상추: +0.5

축산물: +0.5 ~ +0.7 (스트레스)
- 닭고기: +0.7 (폐사율 증가)
- 돼지고기: +0.6 (사육비 증가)

과일류: -0.1 (일부 작물)
- 수박: -0.1 (폭염에 오히려 적합)

에너지: +0.8 (냉방비)
- 전기요금: +0.8 (에어컨 사용 급증)
```

### 5. 맑음/햇볕 (정상 기후)
```dart
채소류: -0.1 ~ -0.3 (생육 양호)
- 상추: -0.2 (햇볕 필요)
- 토마토: -0.3 (햇볕 작물)

과일류: -0.3 ~ -0.4 (당도 증가)
- 사과: -0.3 (당도 상승)
- 포도: -0.4 (당도 최고)
- 수박: -0.3 (풍작)

수산물: -0.2 (출항 가능)
- 고등어: -0.2 (조업 원활)
```

---

## 사용법

### 1. 기본 사용: 가격 변동 예측

```dart
import 'package:smartledger/utils/weather_utils.dart';
import 'package:smartledger/utils/weather_price_sensitivity.dart';

// 1. 현재 날씨 정보 생성
final weather = WeatherData(
  condition: WeatherCondition.heavyRain, // 장마철
  temperature: 25.0,
  humidity: 85,
  timestamp: DateTime.now(),
  location: '서울',
);

// 2. 가격 변동 예측
final predictions = WeatherUtils.predictPriceChanges(
  weather: weather,
  minSensitivity: 0.3, // 30% 이상 민감한 품목만
);

// 3. 결과 출력
for (final prediction in predictions) {
  print('${prediction.itemName}: ${prediction.predictedChange}%');
  print('추천: ${prediction.recommendation}');
  print('이유: ${prediction.reason}\n');
}

/* 출력 예:
배추: +18.0%
추천: 🔴 배추 가격 급등 예상 (폭우/장마) - 빨리 구매하세요!
이유: 장마철/태풍: 밭 침수로 공급 감소, 한파: 생육 지연

상추: +16.0%
추천: 🔴 상추 가격 급등 예상 (폭우/장마) - 빨리 구매하세요!
이유: 햇볕: 생육 양호, 장마철: 병해충 증가로 수확 감소
*/
```

### 2. 특정 품목만 조회

```dart
// 냉장고에 있는 재료들만 확인
final predictions = WeatherUtils.predictPriceChanges(
  weather: weather,
  items: ['배추', '돼지고기', '사과'],
  minSensitivity: 0.3,
);
```

### 3. 구매 추천 품목 (가격 하락)

```dart
// 지금 사면 저렴한 품목들
final buyRecommendations = WeatherUtils.getBuyRecommendations(
  predictions,
  limit: 5,
);

print('지금 구매하면 좋은 품목:');
for (final item in buyRecommendations) {
  print('- ${item.itemName}: ${item.predictedChange.abs().toStringAsFixed(0)}% 저렴');
}

/* 출력 예 (맑은 날):
지금 구매하면 좋은 품목:
- 포도: 8% 저렴
- 토마토: 6% 저렴
- 사과: 6% 저렴
*/
```

### 4. 구매 보류 추천 품목 (가격 상승)

```dart
// 지금 사면 비싼 품목들
final avoidRecommendations = WeatherUtils.getAvoidRecommendations(
  predictions,
  limit: 5,
);

print('구매를 미루면 좋은 품목:');
for (final item in avoidRecommendations) {
  print('- ${item.itemName}: ${item.predictedChange.toStringAsFixed(0)}% 상승 예상');
}

/* 출력 예 (장마철):
구매를 미루면 좋은 품목:
- 배추: 18% 상승 예상
- 오이: 18% 상승 예상
- 상추: 16% 상승 예상
*/
```

### 5. 카테고리별 요약

```dart
final categorySummary = WeatherUtils.summarizeByCategory(predictions);

for (final entry in categorySummary.entries) {
  final categoryName = priceCategoryNames[entry.key];
  final change = entry.value;
  print('$categoryName: ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%');
}

/* 출력 예:
채소류: +15.3%
과일류: -5.2%
축산물: +8.1%
수산물: +14.0%
*/
```

### 6. 음성 비서용 요약

```dart
final summary = WeatherUtils.generateVoiceSummary(
  weather: weather,
  predictions: predictions,
  maxItems: 3,
);

print(summary);

/* 출력 예:
폭우/장마입니다. 배추은 18% 상승 예상, 오이은 18% 상승 예상, 상추은 16% 상승 예상입니다. 
지금 포도은 8% 하락, 토마토은 6% 하락 예상이니 구매 적기입니다.
*/
```

---

## 음성 비서 통합

### Bixby 명령어

#### 1. 날씨 물가 확인
```
빅스비, 날씨 물가 확인
빅스비, 오늘 날씨로 물가 어때?
빅스비, 장마철 물가
```

#### 2. 특정 품목 확인
```
빅스비, 배추 가격 어때?
빅스비, 사과 지금 살까?
```

### Deep Link 스키마

```
smartledger://weather/check
smartledger://weather/check?items=배추,돼지고기,사과
```

---

## 데이터베이스 확장

### 새로운 품목 추가

`lib/utils/weather_price_sensitivity.dart`에서 품목 추가:

```dart
WeatherPriceSensitivity(
  category: PriceCategory.vegetable,
  itemName: '양파',
  sensitivity: {
    WeatherCondition.sunny: -0.2,
    WeatherCondition.rainy: 0.3,
    WeatherCondition.heavyRain: 0.8,
    WeatherCondition.typhoon: 1.0,
    WeatherCondition.coldWave: 0.5,
  },
  reason: '장마철 밭 침수, 태풍 피해',
),
```

### 민감도 지수 조정

기존 품목의 민감도 수정:

```dart
// 수정 전
WeatherCondition.heavyRain: 0.9,

// 수정 후 (더 민감하게)
WeatherCondition.heavyRain: 1.0,
```

---

## UI 통합 예제

### 위젯 예시

```dart
class WeatherPriceWidget extends StatelessWidget {
  final WeatherData weather;

  const WeatherPriceWidget({required this.weather});

  @override
  Widget build(BuildContext context) {
    final predictions = WeatherUtils.predictPriceChanges(
      weather: weather,
      minSensitivity: 0.3,
    );

    final rising = WeatherUtils.getAvoidRecommendations(predictions, limit: 3);
    final falling = WeatherUtils.getBuyRecommendations(predictions, limit: 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날씨: ${weatherConditionNames[weather.effectiveCondition]} ${weather.temperature}°C',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        
        // 가격 상승 품목
        if (rising.isNotEmpty) ...[
          Text('⚠️ 가격 상승 예상', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final item in rising)
            ListTile(
              leading: Text('🔴'),
              title: Text(item.itemName),
              subtitle: Text(item.recommendation),
              trailing: Text('+${item.predictedChange.toStringAsFixed(0)}%'),
            ),
        ],
        
        // 가격 하락 품목 (구매 추천)
        if (falling.isNotEmpty) ...[
          Text('✅ 구매 적기', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final item in falling)
            ListTile(
              leading: Text('🟢'),
              title: Text(item.itemName),
              subtitle: Text(item.recommendation),
              trailing: Text('${item.predictedChange.toStringAsFixed(0)}%'),
            ),
        ],
      ],
    );
  }
}
```

---

## 성능 최적화

### 캐싱 전략

```dart
// 자동 캐싱 (5분 TTL)
final predictions1 = WeatherUtils.predictPriceChanges(weather: weather);
final predictions2 = WeatherUtils.predictPriceChanges(weather: weather); // 캐시 히트

// 캐시 초기화
WeatherUtils.clearCache();
```

### 민감도 필터링

```dart
// 높은 민감도만 (50% 이상)
final highSensitivity = WeatherUtils.predictPriceChanges(
  weather: weather,
  minSensitivity: 0.5, // +10% 이상만
);

// 낮은 민감도 포함 (30% 이상)
final allSensitivity = WeatherUtils.predictPriceChanges(
  weather: weather,
  minSensitivity: 0.3, // +6% 이상
);
```

---

## 디버깅

### 모든 민감도 데이터 출력

```dart
WeatherUtils.printAllSensitivity();

/* 출력:
========== 채소류 ==========
배추:
  맑음: 0.0
  비: 0.3
  폭우/장마: 0.9
  태풍: 1.0
  한파: 0.6
  폭염: 0.4
  이유: 장마철/태풍: 밭 침수로 공급 감소, 한파: 생육 지연
...
*/
```

### 날씨 조건 파싱 테스트

```dart
// 문자열로 날씨 조건 변환
final condition1 = WeatherUtils.parseWeatherCondition('맑음');
print(condition1); // WeatherCondition.sunny

final condition2 = WeatherUtils.parseWeatherCondition('장마');
print(condition2); // WeatherCondition.heavyRain

// 온도로 추론
final condition3 = WeatherUtils.inferConditionFromTemperature(
  -12.0, 
  WeatherCondition.snowy,
);
print(condition3); // WeatherCondition.coldWave
```

---

## 테스트 시나리오

### 1. 장마철 시나리오

```dart
final weather = WeatherData(
  condition: WeatherCondition.heavyRain,
  temperature: 24.0,
  humidity: 90,
  timestamp: DateTime(2026, 7, 1), // 7월 장마철
  location: '서울',
);

final predictions = WeatherUtils.predictPriceChanges(weather: weather);

// 기대 결과:
// - 채소류 +15~18% 상승
// - 수산물 +14~20% 상승
```

### 2. 폭염 시나리오

```dart
final weather = WeatherData(
  condition: WeatherCondition.sunny,
  temperature: 35.0, // 폭염
  humidity: 60,
  timestamp: DateTime(2026, 8, 10),
  location: '대구',
);

final predictions = WeatherUtils.predictPriceChanges(weather: weather);

// 기대 결과:
// - 닭고기 +14% 상승
// - 전기요금 +16% 상승
// - 수박 -2% 하락 (폭염에 적합)
```

### 3. 한파 시나리오

```dart
final weather = WeatherData(
  condition: WeatherCondition.snowy,
  temperature: -12.0, // 한파
  humidity: 40,
  timestamp: DateTime(2026, 1, 15),
  location: '강원도',
);

final predictions = WeatherUtils.predictPriceChanges(weather: weather);

// 기대 결과:
// - 난방비 +20% 상승
// - 계란 +12% 상승 (조류독감 위험)
// - 명태 -6% 하락 (한류성 어종)
```

---

## 확장 계획

### 1. 실시간 날씨 API 연동
```dart
// 향후 구현 예정
Future<WeatherData> fetchCurrentWeather(String location) async {
  // OpenWeatherMap API 호출
  // 또는 기상청 API 연동
}
```

### 2. 과거 데이터 학습
```dart
// AI 학습으로 민감도 자동 조정
// 실제 가격 데이터와 비교하여 민감도 보정
```

### 3. 지역별 차이 반영
```dart
// 서울, 경기, 강원, 제주 등 지역별 민감도 차별화
```

---

## 문의

- 민감도 조정: `lib/utils/weather_price_sensitivity.dart` 수정
- 새 품목 추가: 같은 파일에서 `weatherPriceSensitivityDatabase` 배열에 추가
- 로직 수정: `lib/utils/weather_utils.dart` 수정

**한국어 우선 원칙**: 모든 메시지, 이유, 추천 문구는 한국어로 작성하여 실질적인 도움 제공
