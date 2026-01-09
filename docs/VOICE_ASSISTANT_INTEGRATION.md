# SmartLedger 음성 어시스턴트 통합 가이드

## 📱 지원되는 음성 어시스턴트

### 1. Google Assistant (App Actions) - Android
Android 기기에서 Google Assistant를 통해 SmartLedger를 음성으로 제어할 수 있습니다.

### 2. Samsung Bixby (Capsule) - Samsung Android
삼성 기기에서 Bixby를 통해 SmartLedger를 음성으로 제어할 수 있습니다.

### 3. Apple Siri (App Intents) - iOS 16+
iPhone/iPad에서 Siri를 통해 SmartLedger를 음성으로 제어할 수 있습니다.

---

## 🎤 지원되는 음성 명령

### 지출 입력
```
# Google Assistant
"Hey Google, SmartLedger에서 지출 기록해"
"Hey Google, SmartLedger에서 5000원 지출 추가해"

# Samsung Bixby
"빅스비, 지출 기록해"
"빅스비, 커피 5천원 지출"

# Apple Siri
"시리야, SmartLedger 지출 기록"
"시리야, SmartLedger에서 지출 추가"
```

### 수입 입력
```
# Google Assistant
"Hey Google, SmartLedger에서 수입 기록해"

# Samsung Bixby
"빅스비, 월급 기록해"

# Apple Siri
"시리야, SmartLedger 수입 기록"
```

### 대시보드 열기
```
# Google Assistant
"Hey Google, SmartLedger 열어"
"Hey Google, SmartLedger에서 지출 현황 보여줘"

# Samsung Bixby
"빅스비, 가계부 열어"
"빅스비, 이번달 지출 확인"

# Apple Siri
"시리야, SmartLedger 열어"
"시리야, SmartLedger 가계부 확인"
```

### 특정 기능 열기
```
# Google Assistant
"Hey Google, SmartLedger에서 유통기한 확인해"
"Hey Google, SmartLedger에서 장바구니 열어"

# Samsung Bixby
"빅스비, 냉장고 열어"
"빅스비, 레시피 추천해줘"

# Apple Siri
"시리야, SmartLedger 유통기한 확인"
"시리야, SmartLedger 장바구니 열어"
```

---

## 🔧 딥링크 스킴

앱은 `smartledger://` 스킴을 사용합니다.

### 지출/수입 입력
```
smartledger://transaction/add?type=expense
smartledger://transaction/add?type=expense&amount=5000
smartledger://transaction/add?type=expense&amount=5000&description=커피
smartledger://transaction/add?type=income&amount=3000000
```

### 대시보드
```
smartledger://dashboard
```

### 기능 열기
```
smartledger://feature/food_expiry      # 유통기한 관리
smartledger://feature/shopping_cart    # 장바구니
smartledger://feature/assets           # 자산 현황
smartledger://feature/recipe           # 레시피
smartledger://feature/consumables      # 소모품 관리
smartledger://feature/calendar         # 캘린더
smartledger://feature/savings          # 저축 계획
smartledger://feature/emergency_fund   # 비상금
smartledger://feature/stats            # 통계
```

---

## 📁 프로젝트 구조

### Flutter (클라이언트)
```
lib/
├── services/
│   ├── deep_link_service.dart       # 딥링크 파싱 및 스트림
│   └── category_keyword_service.dart # 오프라인 카테고리 분류
├── navigation/
│   └── deep_link_handler.dart       # 딥링크 → 라우팅 처리
```

### Android (네이티브)
```
android/app/src/main/
├── AndroidManifest.xml              # 딥링크 intent-filter
├── res/
│   ├── xml/shortcuts.xml            # App Actions 정의
│   └── values/shortcuts_strings.xml # 문자열 리소스
└── kotlin/.../MainActivity.kt       # 딥링크 채널 핸들러
```

### iOS (네이티브)
```
ios/Runner/
├── AppDelegate.swift                # 딥링크 + Siri 핸들러
├── SmartLedgerIntents.swift         # Siri App Intents (iOS 16+)
└── Info.plist                       # URL 스킴 + Siri 권한
```

### Bixby Capsule
```
bixby-capsule/
├── capsule.bxb                      # 캡슐 메타데이터
├── models/
│   ├── concepts.model.bxb           # 개념 정의
│   └── actions.model.bxb            # 액션 정의
├── code/
│   ├── endpoints.js                 # 딥링크 생성 로직
│   ├── AddTransaction.js            # 거래 추가 핸들러
│   ├── OpenDashboard.js             # 대시보드 핸들러
│   └── OpenFeature.js               # 기능 열기 핸들러
└── resources/ko-KR/
    ├── training/                    # 훈련 발화
    ├── vocab/                       # 어휘 정의
    └── views/                       # 결과 화면 레이아웃
```

---

## 🚀 배포 방법

### Google App Actions
1. Google Play Console에서 앱 등록
2. App Actions 설정에서 `shortcuts.xml` 업로드
3. App Actions Test Tool로 테스트
4. 출시 전 Google 검토 요청

### Samsung Bixby Capsule
1. Bixby Developer Studio에서 캡슐 등록
2. `bixby-capsule/` 디렉토리 업로드
3. Private 테스트 후 Public 배포 요청

### Apple Siri Shortcuts
1. Xcode에서 앱 빌드 시 자동으로 Siri Shortcuts 등록
2. iOS 16+: App Intents 자동 노출
3. 사용자가 설정 > Siri > SmartLedger에서 단축어 확인 가능
4. "Siri에게 추가" 버튼으로 사용자 정의 단축어 생성 가능

---

## 🧪 테스트 방법

### Android - ADB로 딥링크 테스트
```bash
# 지출 입력 화면 열기
adb shell am start -d "smartledger://transaction/add?type=expense"

# 금액 미리 입력
adb shell am start -d "smartledger://transaction/add?type=expense&amount=5000"

# 대시보드 열기
adb shell am start -d "smartledger://dashboard"

# 유통기한 기능 열기
adb shell am start -d "smartledger://feature/food_expiry"
```

### iOS - 딥링크 테스트
```bash
# Simulator에서 딥링크 테스트
xcrun simctl openurl booted "smartledger://transaction/add?type=expense"
xcrun simctl openurl booted "smartledger://dashboard"
```

### iOS - Siri 테스트
1. 실제 기기에서 앱 설치 후 한 번 실행
2. 설정 > Siri 및 검색 > SmartLedger에서 단축어 확인
3. "시리야, SmartLedger 지출 기록" 음성 명령 테스트

### App Actions Test Tool (Android)
1. Android Studio의 App Actions Test Tool 플러그인 설치
2. 앱 실행 후 테스트 도구에서 Built-In Intent 테스트
3. "지출 5000원 기록해" 같은 발화로 테스트

---

## 🔒 권한 및 보안
- 딥링크는 앱 내부에서만 처리됨
- 외부에서 전달된 데이터는 검증 후 사용
- 민감한 금융 데이터는 딥링크로 전송하지 않음

---

## 📝 향후 개선 사항
1. **멀티 계정 지원**: 딥링크에서 특정 계정 지정
2. **영수증 스캔 연동**: "영수증 스캔해서 지출 기록해"
3. **자연어 처리 강화**: "어제 스타벅스에서 아메리카노 4500원 썼어"
4. **정기 결제 알림**: "다음 주 넷플릭스 결제일 알려줘"
