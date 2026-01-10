### 4. 안전 이동 경로 안내 (허리케인/태풍)

#### 기본 명령어
```
빅스비, 안전한 이동경로
빅스비, 대피 경로 안내
빅스비, 허리케인 대피
빅스비, 마이애미 대피 경로
```

#### 지역별 명령어 (미국)
- **Miami, FL**: "빅스비, 마이애미 허리케인 경로"
- **New Orleans, LA**: "빅스비, 뉴올리언스 대피"
- **Houston/Galveston, TX**: "빅스비, 휴스턴 대피 경로"

**응답 예시 (Miami Beach, FL):**
```
⚠️ Miami Beach: 허리케인 대피 권고 발령. 즉시 안전 경로로 이동하세요.

추천 경로 2개:
1) Marlins Park Shelter (11.4km / 35분)
   - Julia Tuttle Cswy 서행, I-95 South → Downtown 출구
   - 비상 편의시설: FEMA 의료팀, 발전기, Wi-Fi

2) North Miami High School (18.2km / 42분)
   - Collins Ave 북쪽 이동 → Broad Causeway → Biscayne Blvd
   - 애완동물 동반 가능, 이동 통신 중계차 운영

체크포인트:
- FEMA Hurricane Zone C: 의무 대피 구역
- 연료 70% 이상, 현금 $200 이상 준비
- 교량/Interstate 폐쇄 여부 라디오로 확인

즉시 차량으로 이동하거나 교량 폐쇄 전 출발하세요.
```

**응답 예시 (New Orleans, LA):**
```
⚠️ French Quarter: 허리케인 경보. 즉시 Smoothie King Center로 이동
우회 경로: I-10 West → I-12 West → Baton Rouge (110분)
```

**응답 예시 (한국 폭우)**
```
⚠️ 서울 강남: 폭우 대비. 오늘 중 고지대 시민센터로 이동 경로를 확인하세요.
- 경로 1: 차량 6.2km / 18분, 고지대 시민센터
- 경로 2: 지하철 7호선 → 시립 체육관 대피소
```

---

## Deep Link 스키마

### 날씨 알림 화면
```
smartledger://weather/alert
```

### 특정 날씨별 대비 화면
```
smartledger://weather/alert?condition=typhoon
smartledger://weather/alert?condition=coldWave
smartledger://weather/alert?condition=heavyRain
smartledger://weather/alert?condition=heatWave
smartledger://weather/alert?condition=snowy
```

### 안전 이동 경로 화면
```
smartledger://weather/evacuation?condition=typhoon&location=Miami%2C%20FL
```

---

## 위험도 등급

| 등급 | 날씨 | 색상 | 조치 |
|------|------|------|------|
| **매우 위험** | 태풍 | 🔴 빨강 | 즉시 대비 필수 |
| **높은 위험** | 한파, 폭우 | 🟠 주황 | 적극 대비 권장 |
| **중간 위험** | 폭염, 폭설 | 🟡 노랑 | 대비 권장 |
| **낮은 위험** | 맑음, 흐림 | 🔵 파랑 | 정상 |

---

**필수 대비 품목 (6개):**
- 🥗 **양배추** 2개 (7일분) - 수급 불안정
- 🥒 **오이** 10개 (5일분) - 습해 공급 감소
- 🍜 **라면** 10개 (3일분) - 간편식

#### 폭염 대비
```
빅스비, 폭염 대비
빅스비, 더위 준비
```

**필수 대비 품목 (6개):**
- 🌊 **생수** 20리터 (5일분) - 탈수 예방
- 🥤 **이온음료** 10병 (5일분) - 전해질 보충
- 🍉 **수박** 2통 (5일분) - 폭염에 오히려 저렴
- 🥩 **돼지고기** 2kg (3일분) - 가격 상승 전
- 🍗 **닭고기** 2마리 (3일분) - 폐사율 증가 전
- 💊 **해열제** 1박스 (7일분) - 온열질환

#### 폭설 대비
```
빅스비, 폭설 대비
빅스비, 눈 대비
```
**필수 대비 품목 (4개):**
- 🌊 **생수** 10리터 (3일분) - 고립 대비
- 🍜 **라면** 15개 (5일분) - 외출 불가
- 🥫 **통조림** 8개 (5일분) - 장기 보관
- 🥬 **배추** 1포기 (5일분) - 운송 마비 전

### 3. 가격 변동 확인

빅스비, 날씨 물가
빅스비, 날씨로 가격 확인
```

**응답 예시 (장마철):**
```
폭우/장마입니다.

가격 상승 예상:
- 배추 +18% 상승
- 오이 +18% 상승  
- 상추 +16% 상승

지금 포도 -8% 하락, 토마토 -6% 하락 예상이니 구매 적기입니다.
```

---

## Deep Link 스키마

### 날씨 알림 화면
```
smartledger://weather/alert
```

### 특정 날씨별 대비 화면
```
smartledger://weather/alert?condition=typhoon
smartledger://weather/alert?condition=coldWave
smartledger://weather/alert?condition=heavyRain
smartledger://weather/alert?condition=heatWave
smartledger://weather/alert?condition=snowy

## 위험도 등급


### 4. 안전 이동 경로 안내 (허리케인/태풍)

#### 기본 명령어
```
빅스비, 안전한 이동경로
빅스비, 대피 경로 안내
빅스비, 허리케인 대피
빅스비, 마이애미 대피 경로
```

#### 지역별 명령어 (미국)
- **Miami, FL**: "빅스비, 마이애미 허리케인 경로"
- **New Orleans, LA**: "빅스비, 뉴올리언스 대피"
- **Houston/Galveston, TX**: "빅스비, 휴스턴 대피 경로"

**응답 예시 (Miami Beach, FL):**
```
⚠️ Miami Beach: 허리케인 대피 권고 발령. 즉시 안전 경로로 이동하세요.

추천 경로 2개:
1) Marlins Park Shelter (11.4km / 35분)
  - Julia Tuttle Cswy 서행, I-95 South → Downtown 출구
  - 비상 편의시설: FEMA 의료팀, 발전기, Wi-Fi

2) North Miami High School (18.2km / 42분)
  - Collins Ave 북쪽 이동 → Broad Causeway → Biscayne Blvd
  - 애완동물 동반 가능, 이동 통신 중계차 운영

체크포인트:
- FEMA Hurricane Zone C: 의무 대피 구역
- 연료 70% 이상, 현금 $200 이상 준비
- 교량/Interstate 폐쇄 여부 라디오로 확인

즉시 차량으로 이동하거나 교량 폐쇄 전 출발하세요.
```

**응답 예시 (New Orleans, LA):**
```
⚠️ French Quarter: 허리케인 경보. 즉시 Smoothie King Center로 이동
우회 경로: I-10 West → I-12 West → Baton Rouge (110분)
```

**응답 예시 (한국 폭우)**
```
⚠️ 서울 강남: 폭우 대비. 오늘 중 고지대 시민센터로 이동 경로를 확인하세요.
- 경로 1: 차량 6.2km / 18분, 고지대 시민센터
- 경로 2: 지하철 7호선 → 시립 체육관 대피소
```
| 등급 | 날씨 | 색상 | 조치 |
| **매우 위험** | 태풍 | 🔴 빨강 | 즉시 대비 필수 |
| **높은 위험** | 한파, 폭우 | 🟠 주황 | 적극 대비 권장 |
| **중간 위험** | 폭염, 폭설 | 🟡 노랑 | 대비 권장 |
| **낮은 위험** | 맑음, 흐림 | 🔵 파랑 | 정상 |

---

smartledger://weather/evacuation?condition=typhoon&location=Miami%2C%20FL
## 실제 사용 시나리오
### 시나리오 1: 태풍 경보 (3일 전)

**사용자:** "빅스비, 날씨 알림"

**빅스비:**
```
⚠️ 태풍 경보가 발령되었습니다. 
3일 후 태풍이 상륙할 예정입니다.

지금 즉시 준비하세요:

1. 안전용품 (정전 대비)
   - 생수 20리터
   - 손전등 2개
   - 건전지 10개

2. 신선식품 (가격 폭등 전)
   - 배추 2포기 (태풍 후 +20% 예상)
   - 사과 10개 (낙과로 공급 감소)

3. 비축식품
   - 라면 15개
   - 통조림 10개

총 8개 품목, 3일분 대비하세요!
```

### 시나리오 2: 한파 특보 (당일)

**사용자:** "빅스비, 한파 대비"

**빅스비:**
```
❄️ 한파 특보가 발령되었습니다.
현재 -12°C, 체감온도 -18°C입니다.

긴급 대비 필요:

1. 안전 (저체온증 예방)
   - 핫팩 20개 즉시 구매

2. 신선식품 (조류독감 전)
   - 계란 30개 (지금 안 사면 2배 오를 수 있음)
   - 배추 2포기 (한파로 생육 저하)

3. 의약품
   - 감기약 확인

수도관 동파 주의!
생수 15리터 확보하세요.
```

### 시나리오 3: 장마철 시작 (1주일 전)

**사용자:** "빅스비, 폭우 대비"

**빅스비:**
```
🌧️ 장마철이 시작됩니다.
이번 주부터 2주간 집중 호우 예상됩니다.

채소값 폭등 전에 지금 구매하세요:

- 배추 2포기 → 장마 후 +18% 예상
- 양배추 2개 → 수급 불안정
- 오이 10개 → 습해로 공급 감소

수산물도 조업 중단 예상:
- 고등어 5마리 → +14% 상승

총 예상 절약액: 15,000원
```

---

## UI 통합

### 홈 화면 배너

극한 날씨 발생 시 홈 화면 상단에 알림 배너 표시:

```dart
WeatherAlertBanner(
  weather: currentWeather,
  onTap: () {
    // 상세 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeatherAlertDetailScreen(
          weather: currentWeather,
        ),
      ),
    );
  },
)
```

**표시 예:**
```
┌─────────────────────────────────┐
│ ⚠️ 태풍 경보                     │
│ 대비 품목 8개 확인 필요       ▶  │
└─────────────────────────────────┘
```

### 상세 화면

`WeatherAlertDetailScreen`에서 표시:
- 날씨 정보 (온도, 습도, 위치)
- 위험도 등급
- 대비 행동 메시지
- 필수 대비 품목 리스트 (수량, 이유)
- 가격 변동 예측
- 음성 명령어 안내

---

## 데이터 확장

### 새로운 대비 품목 추가

`lib/widgets/weather_alert_widget.dart`의 `weatherPrepDatabase`에 추가:

```dart
PrepItem(
  name: '손소독제',
  category: PrepCategory.safety,
  reason: '방역 대비',
  quantity: 3,
  unit: '개',
  daysNeeded: 7,
),
```

### 권장 수량 조정

```dart
// 수정 전
quantity: 20,  // 생수 20리터

// 수정 후 (가족 4인 기준)
quantity: 40,  // 생수 40리터
```

---

## 성능 최적화

### 캐싱
- 날씨 데이터: 5분 TTL
- 가격 예측: SimpleCache 사용
- 대비 품목: 정적 데이터 (메모리 상주)

### 알림 표시 조건
```dart
// 극한 날씨만 표시
if (isExtremeWeather(condition)) {
  // 배너 표시
}
```

---

## 향후 확장

### 1. 푸시 알림
```dart
// 태풍 3일 전 푸시 알림
sendPushNotification(
  title: '⚠️ 태풍 경보',
  body: '3일 후 태풍 예상. 지금 대비하세요!',
);
```

### 2. 자동 구매 제안
```dart
// 필수 품목을 쇼핑 리스트에 자동 추가
addToShoppingList(prepItems);
```

### 3. 지역별 맞춤 알림
```dart
// 강원도: 폭설 알림 강화
// 제주도: 태풍 알림 강화
```

### 4. 과거 날씨 학습
```dart
// 작년 장마철 실제 가격 변동률 반영
// AI 학습으로 예측 정확도 향상
```

---

## 문의

- 대비 품목 추가/수정: `lib/widgets/weather_alert_widget.dart`
- 날씨 민감도 조정: `lib/utils/weather_price_sensitivity.dart`
- UI 커스터마이징: `WeatherAlertWidget`, `WeatherAlertBanner`

**실용성 우선**: 모든 메시지는 한국어로, 구체적 수량과 이유를 명시하여 실질적 도움 제공
