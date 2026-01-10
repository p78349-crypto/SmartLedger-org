# SmartLedger 음성 어시스턴트 통합 가이드

## 📱 지원되는 음성 어시스턴트

### 1. Google Assistant (App Actions) - Android
Android 기기에서 Google Assistant를 통해 SmartLedger를 음성으로 제어할 수 있습니다.

### 2. Samsung Bixby (Capsule) - Samsung Android
삼성 기기에서 Bixby를 통해 SmartLedger를 음성으로 제어할 수 있습니다.

### 3. Apple Siri (App Intents) - iOS 16+
iPhone/iPad에서 Siri를 통해 SmartLedger를 음성으로 제어할 수 있습니다.


## 🎤 지원되는 음성 명령

### 지출 입력
```
# Google Assistant
"Hey Google, 지출 기록"
"Hey Google, 5000원 지출 추가"

# Samsung Bixby
"빅스비, 지출 기록"
"빅스비, 커피 5천원 지출"
"빅스비, 커피 2잔 단가 2500원 지출 저장"

# Apple Siri
"시리야, 지출 기록"
"시리야, 지출 추가"
```

관련 정책(데이터 접근/보관 기준):
- [VOICE_ASSISTANT_DATA_ACCESS_POLICY.md](VOICE_ASSISTANT_DATA_ACCESS_POLICY.md)

### 반품/환불 입력
```
# Samsung Bixby
"빅스비, 커피 5000원 반품 저장"
"빅스비, 옷 3만원 환불 저장"
```

### 수입 입력
```
# Google Assistant
"Hey Google, 수입 기록"

# Samsung Bixby
"빅스비, 월급 기록"

# Apple Siri
"시리야, 수입 기록"
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

### 장바구니 보기
```
# Samsung Bixby
"빅스비, 장바구니 보여줘"
"하이 빅스비, 장보기 목록 다 보여줘"
"빅스비, 여기서 장보기 목록 보여줘"
"빅스비, SmartLedger 장바구니 열어"

# Google Assistant  
"Hey Google, SmartLedger 장바구니 열어"

# Apple Siri
"시리야, SmartLedger 장바구니 보여줘"
```

### 장바구니에 추가
```
# Google Assistant
"Hey Google, SmartLedger 장바구니에 우유 담아"

# Samsung Bixby
"빅스비, 우유 장바구니에 담아"
"빅스비, 우유 3번 통로에 있어 장바구니에 담아"
"빅스비, 냉장고에 있는 우유 장바구니에 담아"

# Apple Siri
"시리야, SmartLedger 장바구니에 우유 추가"
```

### 쇼핑 안내 (마트에서)
```
# Samsung Bixby
"빅스비, 쇼핑 안내 시작"
"빅스비, 다음 어디 가야 돼?"
"빅스비, 장바구니 남은 거 어디 있어?"

# Google Assistant
"Hey Google, 쇼핑 가이드 열어"

# Apple Siri
"시리야, 쇼핑 안내"
```

### 요리 추천 (냉장고 재료 기반)
```
# Samsung Bixby
"빅스비, 요리 뭐로 하지?"
"빅스비, 오늘 점심 뭐 먹지?"
"빅스비, 저녁 메뉴 추천"
"빅스비, 닭고기랑 양파로 뭐 만들지?"
"빅스비, 냉장고 재료로 요리 추천"

# 유통기한 임박 재료 우선
"빅스비, 유통기한 임박 재료로 요리 추천"
"빅스비, 빨리 먹어야 할 거로 뭐 만들지?"
"빅스비, 상하기 전에 먹을 요리 추천"

# Google Assistant
"Hey Google, 요리 추천"
"Hey Google, 점심 메뉴 추천"
"Hey Google, 유통기한 임박 요리"

# Apple Siri
"시리야, 요리 추천"
"시리야, 저녁 메뉴 추천"
"시리야, 유통기한 임박 요리"
```

**작동 방식:**
1. **현재 재고 분석** - 냉장고에 있는 재료를 자동 확인
2. **만들 수 있는 요리** - 보유 재료로 가능한 레시피 우선 표시
3. **부족한 재료 안내** - 없는 재료는 빨간색으로 표시
4. **장바구니 자동 추가** - 부족한 재료를 장바구니에 원클릭 추가
5. **유통기한 우선** - 임박 재료부터 사용하도록 제안 (FIFO)
6. **🧠 AI 학습 기능** - 사용자 패턴 자동 학습 및 맞춤 추천

**🧠 스마트 학습 시스템:**
- **자주 만드는 요리 학습** - 반복 패턴 인식
- **선호 재료 학습** - 자주 쓰는 재료 우선 추천
- **시간대별 학습** - 아침/점심/저녁 선호 요리 기억
- **건강 선호도 학습** - 건강식 선택 빈도 추적
- **개인화 추천** - 사용할수록 똑똑해짐
- **👤 사용자 레시피 통합** - 내가 만든 닭고기/돼지고기 레시피도 자동 추천

**사용자 레시피 포함:**
- ✅ RecipeService에 저장된 모든 사용자 레시피 자동 추천 대상 포함
- ✅ 기본 레시피와 동일한 우선순위 알고리즘 (유통기한 → 건강 → 매칭률)
- ✅ UI에서 👤 아이콘으로 사용자 레시피 구분 표시
- ✅ 건강 점수(1-5) 지원으로 맞춤 추천
- ✅ 학습 시스템과 완전 통합 (자주 만드는 레시피 우선 추천)
- 📖 자세한 내용: [사용자 레시피 통합 가이드](CUSTOM_RECIPE_INTEGRATION.md)

**다양한 환경 대응:**
- 👨‍👩‍👧‍👦 **가족 구성**: 인원수별 레시피 자동 조정
- 🌍 **지역별**: 한식/양식/중식 선호도 학습
- 🎯 **목적별**: 다이어트/근육/건강 목표 반영
- 📅 **계절별**: 봄/여름/가을/겨울 제철 재료 우선
- 💰 **예산별**: 경제적 요리 vs 프리미엄 요리

**유통기한 임박 모드 (`expiring=true`):**
- ⚠️ 3일 이내 유통기한 재료만 필터링
- 🕒 가장 빨리 상하는 재료부터 우선 사용
- 🗑️ 음식물 쓰레기 줄이기
- 💰 식재료 낭비 방지

**예시:**
- 냉장고에 닭고기, 양파, 감자가 있으면 → "닭볶음탕" 추천
- 당근이 없으면 → "당근 부족" 표시 + 장바구니 추가 제안
- 유통기한 2일 남은 우유가 있으면 → "크림 스프", "푸딩" 우선 추천

### 영수증 건강도 분석
```
# Samsung Bixby
"빅스비, 영수증 건강도 분석"
"빅스비, 영수증 분석"
"빅스비, 마트 재료 건강 점수"

# Google Assistant
"Hey Google, 영수증 분석"
"Hey Google, 건강도 분석"

# Apple Siri
"시리야, 영수증 분석"
"시리야, 건강도 분석"
```

**작동 방식:**
1. **신속 건강 분석 화면 열림** - 17개 주요 재료 체크박스 표시
2. **재료 선택** - 영수증 보고 구매한 재료 체크
3. **실시간 점수 계산** - 선택할 때마다 건강 점수 업데이트
4. **건강 통계 표시** - 평균 점수, 건강한 재료 비율, 카테고리별 분석
5. **색상 코드 표시** - 💚(5점), 🟢(4점), 🟡(3점), 🟠(2점), 🔴(1점)

**건강 점수 기준:**
- **5점 (매우 건강)** - 채소류, 버섯류, 해조류
- **4점 (건강)** - 생선, 해산물, 콩류
- **3점 (보통)** - 닭고기, 계란, 쌀, 우유
- **2점 (주의)** - 돼지고기, 소고기, 빵류
- **1점 (비건강)** - 튀김, 과자, 라면, 탄산음료

**주요 기능:**
- ✅ **200+ 재료 건강 점수 DB** - 한국 식재료 대부분 지원
- ✅ **실시간 통계** - 평균 점수, 건강 비율, 카테고리 분석
- ✅ **간편 체크박스 UI** - 빠른 선택으로 시간 절약
- ✅ **색상 코드** - 직관적인 건강도 파악
- 📖 자세한 내용: [영수증 건강도 분석 가이드](RECEIPT_HEALTH_ANALYZER.md)

**예시:**
- 양배추(5), 브로콜리(5), 닭고기(3), 라면(1) → 평균 3.5점
- 건강한 재료(4-5점) 비율: 50%
- 카테고리: 채소 2개, 육류 1개, 가공식품 1개

**참고사항:**
- � **책스캔 PDF 앱 연계** - ML Kit OCR 처리 전담
- 현재는 체크박스로 수동 선택 (빠르고 정확)
- 책스캔앱에서 OCR 처리 후 자동 연계

### 책스캔 OCR 자동 연계 (영수증 입력)
```
# Samsung Bixby
"빅스비, 영수증 지출 기록"
"빅스비, 영수증 기록"
"빅스비, 영수증 입력"

# Google Assistant
"Hey Google, 영수증 기록"

# Apple Siri
"시리야, 영수증 기록"
```

**작동 방식:**
1. **책스캔 PDF 앱에서 촬영** - 영수증 사진 촬영 및 OCR 처리
2. **텍스트 추출 대기** - 상점명, 금액, 항목들 파싱
3. **음성 명령 사용** - "빅스비, 영수증 지출 기록"
4. **책스캔 → SmartLedger** - 자동으로 딥링크 호출
5. **지출 입력 화면 열림** - 모든 필드 자동 채워짐
6. **확인 후 저장** - 사용자가 확인만 하면 끝

**딥링크 형식:**
```
# 기본 형식
smartledger://transaction/add?
  amount=45800&
  store=이마트&
  items=양배추,닭고기,우유&
  source=ocr

# 상세 정보 포함
smartledger://transaction/add?
  amount=128500&
  description=식료품&
  store=코스트코&
  items=양배추,브로콜리,닭고기,돼지고기,우유&
  source=ocr&
  date=2026-01-10
```

**자동 채워지는 필드:**
- ✅ **금액** - OCR에서 추출한 합계 금액
- ✅ **상점** - OCR에서 추출한 상점명
- ✅ **메모** - 항목 목록 (📋 이모지 표시)
- ✅ **발생일** - 영수증 날짜 (선택 사항)
- ✅ **출처 태그** - source=ocr로 구분

**예시:**
- 책스캔에서 영수증 OCR 완료
- "빅스비, 영수증 지출 기록"
- SmartLedger 자동 실행 → 지출 입력 화면
- 금액: 45,800원, 상점: 이마트
- 메모: 📋 양배추, 닭고기, 우유
- 확인 버튼 클릭 → 저장 완료

**장점:**
- ✅ 수동 입력 불필요 (OCR이 다 처리)
- ✅ 음성 명령 한 번으로 자동화
- ✅ 영수증 항목들을 메모에 자동 기록
- ✅ 상점명/금액/날짜 자동 추출
- ✅ 앱 용량 최소화 (ML Kit 없음)

**책스캔앱 구현 필요 사항:**
```dart
// 1. OCR 처리 완료 후
// 2. 추출된 데이터를 Deep Link로 전송
final deepLink = 'smartledger://transaction/add?'
    'amount=45800&'
    'store=이마트&'
    'items=양배추,닭고기,우유&'
    'source=ocr';

// 3. URL Launcher로 호출
await launchUrl(Uri.parse(deepLink));
```

**참고사항:**

### 특정 기능 열기
```
# Google Assistant
"Hey Google, 유통기한 확인"
"Hey Google, 장바구니 열어"

# Samsung Bixby
"빅스비, 냉장고 열어"
"빅스비, 레시피 추천"

# Apple Siri
"시리야, 유통기한 확인"
"시리야, 장바구니 열어"
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

# 수량/단위/단가
smartledger://transaction/add?type=expense&description=커피&quantity=2&unit=잔&unitPrice=2500

# 반품/환불
smartledger://transaction/add?type=refund&amount=5000&description=커피
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

### 장바구니에 상품 추가
```
smartledger://shopping/cart/add?name=우유
smartledger://shopping/cart/add?name=우유&location=냉장고
smartledger://shopping/cart/add?name=우유&location=3번 통로
smartledger://shopping/cart/add?name=계란&location=냉장고&quantity=2
smartledger://shopping/cart/add?name=커피&location=음료 코너&price=3500
```

### 요리 추천
```
smartledger://recipe/recommend                        # 냉장고 재료 기반 추천
smartledger://recipe/recommend?meal=lunch              # 점심 메뉴 추천
smartledger://recipe/recommend?meal=dinner             # 저녁 메뉴 추천
smartledger://recipe/recommend?meal=breakfast          # 아침 메뉴 추천
smartledger://recipe/recommend?ingredients=닭고기,양파 # 특정 재료로 추천
smartledger://recipe/recommend?expiring=true           # 유통기한 임박 재료 우선
smartledger://recipe/recommend?meal=dinner&expiring=true  # 저녁 + 임박 재료
smartledger://recipe/recommend?meal=dinner&ingredients=닭고기,양파
```

**파라미터:**
- `meal` (선택) - 끼니 종류: breakfast, lunch, dinner
- `ingredients` (선택) - 사용할 재료 (쉼표로 구분)
- `expiring` (선택) - true로 설정 시 유통기한 임박 재료 우선

**기능:**
- 냉장고 화면을 열고 레시피 추천 다이얼로그 자동 표시
- 유통기한 임박 재료 우선 활용
- 보유 재료로 만들 수 있는 레시피만 표시

**파라미터:**
- `name` (필수) - 상품명
- `location` (선택) - 마트 내 위치 (예: "3번 통로", "냉장고", "1층 입구")
- `quantity` (선택) - 수량 (기본값: 1)
- `price` (선택) - 예상 가격

**위치 학습:**
- 상품을 장바구니에 추가할 때 위치를 기록하면, 다음 방문 시 자동으로 위치 제안
- 음성 명령으로도 위치 포함 가능: "빅스비, 우유 냉장고에 있어 장바구니에 담아"

---

## 음성 기반 3단계 자동화(Preview → Confirm → App Auto-Submit)

SmartLedger는 음성에서 “바로 실행”을 목표로 하되, 상태 변경(저장/차감)은 안전을 위해 `confirmed=true`를 요구합니다.
즉, Bixby(또는 다른 어시스턴트)는 기본적으로 2단계 확인(미리보기 → 확인)을 거쳐 `confirmed` 딥링크를 반환하고,
앱은 `autoSubmit=true&confirmed=true`일 때만 자동 저장/자동 차감을 수행합니다.

### 1) Deep Link + 화이트리스트로 화면 진입
앱은 `smartledger://nav/open` 형태로 **허용된 route만** 열 수 있습니다.

예: 유통기한 등록(프리필 포함)
```
smartledger://nav/open?route=/food/expiry&intent=upsert&name=우유&quantity=1&unit=팩&expiryDays=1
```

예: 보관 위치만 포함(프리필)
```
smartledger://nav/open?route=/food/expiry&intent=upsert&name=우유&location=냉장
```

예: 가격 포함(프리필)
```
smartledger://nav/open?route=/food/expiry&intent=upsert&name=우유&price=3900
```

예: 카테고리 포함(프리필)
```
smartledger://nav/open?route=/food/expiry&intent=upsert&name=우유&category=유제품
```

예: 구매처 포함(프리필)
```
smartledger://nav/open?route=/food/expiry&intent=upsert&name=우유&supplier=이마트
```

예: 메모 포함(프리필)
```
smartledger://nav/open?route=/food/expiry&intent=upsert&name=우유&memo=행사상품
```

예: 구매일 포함(프리필)
```
smartledger://nav/open?route=/food/expiry&intent=upsert&name=우유&purchaseDate=오늘
```

예: 건강 태그 포함(프리필)
```
smartledger://nav/open?route=/food/expiry&intent=upsert&name=우유&healthTags=당류
```

권장 발화 예시(Bixby)
 - "요거트 메모 행사라서요! 내일 등록해"
 - "우유 메모 1+1이라서요 등록해"
- "우유 메모 행사라서 등록해"
- "오늘 산 우유 내일 등록해"
- "어제 산 요거트 등록해"
- "방금 산 치즈 모레 등록해"
- "우유 오늘까지 등록해"
- "치즈 내일까지 등록해"
- "요거트 이번주까지 등록해"
- "우유 주말까지 등록해"
- "치즈 토요일까지 등록해"
- "요거트 일요일까지 등록해"
- "우유 토까지 등록해"
- "치즈 일까지 등록해"

카테고리 값 예시(앱 선택지 기준)

파라미터 호환(동일 의미)
- `name` 또는 `item` 또는 `product`
- `quantity` 또는 `qty`
- `expiryDate` 또는 `expiry` (ISO-8601, 예: 2026-01-10)
- `expiryDays` 또는 `days` (상대 일수)

추가 프리필 파라미터
- `supplier` (구매처/구입처)
- `memo` (메모)
- `purchaseDate` (구매일 - 예: 오늘/어제/2026-01-09/1월 3일)
- `healthTags` (건강 태그 - 예: 탄수화물, 당류, 주류)

추가 예: 레시피 추천 섹션으로 이동(네비게이션 전용, 상태 변경 없음)
```
smartledger://nav/open?route=/food/expiry&intent=recipe_recommendation
```

권장 발화 예시(Bixby)
- "레시피 추천해줘"
- "뭐 해먹지"
- "오늘 뭐 먹을까"

추가 예: 보관 중인 식재료 요리 피커 열기(네비게이션 전용, 상태 변경 없음)
```
smartledger://nav/open?route=/food/expiry&intent=cookable_recipe_picker
```

권장 발화 예시(Bixby)
- "냉장고 재료로 요리 추천해줘"
- "보관 중인 식재료로 요리 보여줘"

추가 예: 유통기한 사용(차감) 모드 열기(네비게이션 전용, 상태 변경 없음)
```
smartledger://nav/open?route=/food/expiry&intent=usage_mode
```

권장 발화 예시(Bixby)
- "유통기한 사용 모드 열어"
- "식재료 차감 모드 열어"

### 2) Intent 기반 프리필(Pre-fill) + 자동 저장
자동 저장을 원할 경우, 어시스턴트는 아래처럼 `autoSubmit=true`를 포함해 호출합니다.

```
smartledger://nav/open?route=/food/expiry&intent=upsert&name=우유&quantity=1&unit=팩&expiryDays=1&autoSubmit=true
```

앱 안전 정책
- `autoSubmit=true`인데 `confirmed=true`가 없으면: 앱이 **자체 확인 다이얼로그**를 한 번 더 띄운 뒤에만 자동 등록을 진행합니다.
- `autoSubmit=true&confirmed=true`이면: 앱 진입 후 자동 등록을 시도합니다.

확인 완료(confirmed) 호출 예시
```
smartledger://nav/open?route=/food/expiry&intent=upsert&name=우유&quantity=1&unit=팩&expiryDays=1&autoSubmit=true&confirmed=true
```

### 3) Bixby 자연어 날짜 인식 보강
Bixby는 날짜 표현을 개념(예: `ExpiryPhrase`, `ExpiryDays`)으로 파싱한 뒤, 앱에는 `expiryDate`(절대일자) 또는 `expiryDays`(상대일수)로 전달하는 방식을 권장합니다.

권장 발화 패턴 예시
- "내일 우유 등록해"
- "모레 아욱 등록해"
- "3일 뒤에 치즈 등록"
- "1월 20일에 요구르트 등록"

### 전체 UX 예시(권장)
1) 사용자: "우유 1팩 내일 등록해줘"
2) Bixby: 미리보기 카드로 요약(등록 내용) 표시
3) 사용자: "응, 등록해" (Confirm)
4) Bixby: `confirmed=true` 딥링크 반환 + "앱 열기"로 이어서 진행 유도

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
