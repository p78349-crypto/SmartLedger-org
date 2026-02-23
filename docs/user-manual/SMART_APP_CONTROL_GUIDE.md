# 스마트 앱 제어 가이드

## 🎯 개요

**SmartLedger가 모든 앱을 제어하는 허브로 진화**

Gemini Nano로 자연어 이해 → 다른 앱 자동 실행
- 가계부 기록 + 쇼핑앱 실행 동시 처리
- "말 한마디로 모든 앱 제어"

## 🚀 사용 방법

### 1️⃣ 화면 열기

```dart
Navigator.pushNamed(
  context,
  AppRoutes.smartVoiceCommand,
  arguments: AccountArgs(accountName: 'ROOT'),
);
```

### 2️⃣ 명령 예시

#### 가계부 + 쇼핑 통합
```
"편의점 우유 3000원 기록하고 쿠팡에서 우유 검색"

결과:
✅ 가계부에 우유 3000원 저장
✅ 쿠팡 앱 자동 실행 → 우유 검색 결과
```

#### 배달앱 바로 실행
```
"배민에서 치킨 주문"

결과:
✅ 배달의민족 앱 실행 → 치킨 검색
```

#### 지도 내비게이션
```
"카카오맵으로 강남역 가는 길 찾아줘"

결과:
✅ 카카오맵 앱 실행 → 강남역 길찾기
```

#### 금융앱 연동
```
"토스 열어줘"

결과:
✅ 토스 앱 실행
```

## 💡 지원 기능

### 가계부 기록
- "사과 5000원 기록"
- "편의점에서 우유 3000원 샀어"
- "어제 마트 장보고 2만원 썼어"

### 쇼핑앱 제어
- **쿠팡**: "쿠팡에서 사과 검색"
- **G마켓**: "지마켓에서 노트북 찾아줘"
- **11번가**: "11번가에서 세일 상품"

### 배달앱 제어
- **배달의민족**: "배민에서 치킨 주문"
- **요기요**: "요기요에서 피자 찾아줘"
- **쿠팡이츠**: "쿠팡이츠로 햄버거"

### 지도 내비게이션
- **카카오맵**: "카카오맵으로 강남역"
- **네이버 지도**: "네이버 지도로 서울역"
- **구글 맵**: "구글 맵으로 인천공항"

### 금융앱
- **토스**: "토스 열어줘", "토스로 송금"
- **카카오페이**: "카카오페이 실행"
- **페이코**: "페이코 열어"

## 🔧 동작 원리

```
1. 사용자 명령 입력
   "편의점 우유 3000원 기록하고 쿠팡에서 우유 검색"
   
2. Gemini Nano 파싱 (오프라인)
   {
     "tasks": [
       {
         "type": "record",
         "data": {"store": "편의점", "item": "우유", "amount": 3000}
       },
       {
         "type": "search_shopping",
         "data": {"app": "coupang", "query": "우유"}
       }
     ]
   }
   
3. SmartAppController 실행
   - Task 1: TransactionService로 DB 저장
   - Task 2: URL Launcher로 쿠팡 앱 실행
   
4. 결과 표시
   ✅ 가계부 기록: 저장 완료
   ✅ 쇼핑앱 실행: 앱 실행됨
```

## 📱 실제 코드

### 기본 사용

```dart
final controller = SmartAppController();

final result = await controller.processCommand(
  "편의점 우유 3000원 기록하고 쿠팡에서 우유 검색",
  accountName,
);

if (result['success'] == true) {
  final results = result['results'] as Map;
  
  if (results['record'] == true) {
    print('✅ 가계부 저장 완료');
  }
  
  if (results['shopping'] == true) {
    print('✅ 쿠팡 앱 실행됨');
  }
}
```

### 복합 명령

```dart
// 여러 작업 동시 처리
await controller.processCommand(
  "사과 5000원 기록하고 쿠팡에서 사과 검색하고 카카오맵으로 마트 찾기",
  accountName,
);

// 결과:
// 1. 가계부에 사과 5000원 저장
// 2. 쿠팡 앱 실행 → 사과 검색
// 3. 카카오맵 실행 → 마트 검색
```

## 🔐 보안 및 제한사항

### ✅ 안전한 것
- 앱 실행 (URL Scheme)
- 검색 화면 이동
- 특정 카테고리 열기
- 가계부 기록

### ⚠️ 사용자 확인 필요
- 실제 구매/결제
- 송금
- 민감 정보 접근

### ❌ 불가능한 것
- 다른 앱 내부 버튼 자동 클릭
- 사용자 모르게 결제
- 앱 내부 데이터 직접 수정

## 📊 지원 URL Scheme

```dart
// 쇼핑
coupang://search?q=검색어
gmarket://search?keyword=검색어

// 배달
baeminapp://search?query=음식
yogiyo://search?keyword=음식

// 지도
kakaomap://search?q=목적지
nmap://search?query=목적지

// 금융
supertoss://home
kakaopay://home
```

## 🎨 UI 커스터마이징

### 빠른 명령 추가

```dart
final _quickCommands = [
  "편의점 우유 3000원 기록하고 쿠팡에서 우유 검색",
  "배민에서 치킨 주문",
  "카카오맵으로 강남역",
  "커스텀 명령 추가하기",
];
```

### 커스텀 앱 지원

```dart
// smart_app_controller.dart에 추가
Future<bool> _openCustomApp(Map<String, dynamic> data) async {
  final appUrls = {
    'myapp': 'myapp://action?param=${data['param']}',
  };
  
  return await _launchUrl(appUrls['myapp']!);
}
```

## 🚀 활용 시나리오

### 시나리오 1: 장보기 전
```
"사과 5000원 기록하고 쿠팡에서 사과 검색하고 카카오맵으로 마트 찾기"

1. 예상 지출 미리 기록
2. 온라인 가격 비교
3. 가까운 마트 찾기
```

### 시나리오 2: 배달 주문
```
"배민에서 치킨 검색"

1. 배민 앱 자동 실행
2. 치킨 검색 결과
3. 주문 후 "치킨 2만원 기록" 명령
```

### 시나리오 3: 출근길
```
"카카오맵으로 회사 가는 길"

1. 카카오맵 자동 실행
2. 회사 경로 안내
3. (선택) "택시비 5000원 기록"
```

## 🔄 기존 시스템 통합

### Bixby/Google Assistant와 연동

```dart
// deep_link_handler.dart에 추가
if (uri.path == '/smart-command') {
  final command = uri.queryParameters['cmd'];
  
  // Gemini Nano로 명령 처리
  await SmartAppController().processCommand(
    command,
    accountName,
  );
}
```

이제 Bixby에서:
```
"하이 빅스비, 스마트레저에서 편의점 우유 3000원 기록하고 쿠팡 검색"
```

## 📈 확장 가능성

### Phase 1 (현재)
- 가계부 기록
- 쇼핑/배달/지도 앱 실행

### Phase 2 (향후)
- 자동 가격 비교
- 영수증 자동 분류
- 예산 초과 알림

### Phase 3 (미래)
- AI 추천: "사과 살 시간이에요"
- 자동 쿠폰 적용
- 가계부 분석 기반 쇼핑 제안

## ✅ 체크리스트

- [x] SmartAppController 구현
- [x] SmartVoiceCommandScreen UI
- [x] 라우트 등록
- [x] Gemini Nano 통합
- [ ] 실제 기기 테스트
- [ ] URL Scheme 검증
- [ ] 에러 핸들링 강화
- [ ] 사용자 가이드 완성

**상태**: 코드 구현 완료, 기기 테스트 대기  
**다음 단계**: Android 14+ 기기에서 실제 앱 연동 테스트
