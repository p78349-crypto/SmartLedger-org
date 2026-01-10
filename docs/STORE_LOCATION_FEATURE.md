# 마트 상품 위치 기록 기능

## 📍 개요

장바구니에 상품을 추가할 때 마트 내 위치를 기록하고, 재방문 시 자동으로 위치를 제안하는 기능입니다.

## ✨ 주요 기능

### 1. 위치 학습 시스템
- 상품별로 마지막 기록된 위치를 자동 저장
- 재방문 시 이전 위치 자동 표시
- 계정별 독립적인 위치 데이터 관리

### 2. 위치 입력 방법

#### 방법 1: 장바구니 화면에서 직접 입력
1. 장바구니에 상품 추가
2. 상품 항목의 위치 아이콘(📍) 클릭
3. 위치 입력 또는 자주 사용하는 위치 선택
4. 저장

#### 방법 2: 음성 어시스턴트로 추가
```
# 빅스비
"빅스비, 우유 장바구니에 담아"
"빅스비, 우유 3번 통로에 있어 장바구니에 담아"
"빅스비, 냉장고에 있는 계란 장바구니에 담아"

# 구글 어시스턴트
"Hey Google, SmartLedger 장바구니에 우유 담아"

# 시리
"시리야, SmartLedger 장바구니에 우유 추가"
```

#### 방법 3: 딥링크
```
smartledger://shopping/cart/add?name=우유&location=냉장고
smartledger://shopping/cart/add?name=커피&location=3번 통로
```

### 3. 자주 사용하는 위치 제안
위치 입력 시 다음 항목을 빠르게 선택 가능:
- 입구, 1층, 2층, 지하
- 냉장고, 냉동실
- 채소 코너, 과일 코너
- 정육 코너, 생선 코너
- 유제품 코너, 빵 코너
- 과자 코너, 음료 코너
- 라면 코너, 통조림 코너
- 생활용품, 화장품
- 계산대 근처
- 1~10번 통로

### 4. 위치 정보 표시
- 위치가 있는 항목: 파란색 배지로 위치 표시
- 위치가 없는 항목: 회색 아이콘 표시
- 마우스 오버 시 툴팁으로 전체 위치 표시

## 🔧 기술 구현

### 1. 데이터 모델
**ShoppingCartItem** ([lib/models/shopping_cart_item.dart](../lib/models/shopping_cart_item.dart))
```dart
class ShoppingCartItem {
  final String name;
  final String storeLocation; // 새로 추가된 필드
  // ...
}
```

### 2. 위치 학습 서비스
**ProductLocationService** ([lib/services/product_location_service.dart](../lib/services/product_location_service.dart))
- 상품명을 정규화하여 저장 (대소문자, 공백 무시)
- 계정별 독립 저장소 (SharedPreferences)
- 최대 500개 항목 유지 (오래된 항목 자동 제거)

주요 메서드:
```dart
// 위치 저장
await ProductLocationService.instance.saveLocation(
  accountName: accountName,
  productName: '우유',
  location: '3번 통로',
);

// 위치 조회
final location = await ProductLocationService.instance.getLocation(
  accountName: accountName,
  productName: '우유',
);
```

### 3. UI 구현
**ShoppingCartScreen** ([lib/screens/shopping_cart_screen.dart](../lib/screens/shopping_cart_screen.dart))
- 상품 추가 시 이전 위치 자동 로드
- 위치 편집 다이얼로그
- 인라인 위치 표시 (와이드 레이아웃)

### 4. 딥링크 통합
**DeepLinkService** ([lib/services/deep_link_service.dart](../lib/services/deep_link_service.dart))
- `smartledger://shopping/cart/add?name=우유&location=냉장고` 지원
- AddToCartAction 추가

**DeepLinkHandler** ([lib/navigation/deep_link_handler.dart](../lib/navigation/deep_link_handler.dart))
- 장바구니 추가 딥링크 처리
- 위치 학습 자동 저장
- 음성 어시스턴트 분석 로깅

## 📱 사용 시나리오

### 시나리오 1: 첫 방문
1. 마트 방문 전 장바구니에 "우유" 추가
2. 마트에서 우유를 "3번 통로 냉장고"에서 발견
3. 장바구니 앱에서 "우유" 항목의 위치 아이콘 클릭
4. "3번 통로" 입력 후 저장
5. ✅ 위치가 파란색 배지로 표시됨

### 시나리오 2: 재방문
1. 다음 주 마트 방문 전 "우유" 추가
2. ✨ 자동으로 "💡 지난번 위치: 3번 통로" 표시
3. 바로 해당 위치로 이동하여 찾기

### 시나리오 3: 음성으로 추가
1. "빅스비, 우유 3번 통로에 있어 장바구니에 담아"
2. 자동으로 위치 포함하여 장바구니에 추가됨
3. 다음번 "우유" 추가 시 "3번 통로" 자동 제안

## 🔐 개인정보 보호

- 모든 위치 데이터는 **로컬 저장소**에만 저장 (SharedPreferences)
- 서버 전송 없음
- 계정별 독립 관리
- 계정 삭제 시 위치 데이터도 함께 삭제

## 🎯 활용 팁

1. **주요 상품만 위치 기록**: 자주 구매하는 상품(우유, 계란 등)의 위치를 기록하면 효율적
2. **마트별로 다른 위치**: 같은 상품이라도 마트마다 위치가 다를 수 있으므로, 메모에 마트명 기록 권장
3. **음성 활용**: 마트에서 바로 "빅스비, 요거트 5번 통로에 있어 장바구니에 담아"로 실시간 추가

## 📊 데이터 구조

### SharedPreferences 저장 형식
키: `product_location_v1_{계정명}_map`

```json
{
  "우유": {
    "location": "3번 통로",
    "updatedAt": "2026-01-10T14:30:00.000Z",
    "originalName": "우유"
  },
  "계란": {
    "location": "냉장고",
    "updatedAt": "2026-01-10T14:35:00.000Z",
    "originalName": "계란"
  }
}
```

### ShoppingCartItem JSON
```json
{
  "id": "shop_1704877800000000",
  "name": "우유",
  "quantity": 1,
  "unitPrice": 3500,
  "storeLocation": "3번 통로",
  "isPlanned": true,
  "isChecked": false,
  "createdAt": "2026-01-10T14:30:00.000Z",
  "updatedAt": "2026-01-10T14:30:00.000Z"
}
```

## 🚀 향후 개선 방향

1. **마트별 위치 매핑**: 같은 상품이라도 마트별로 다른 위치 저장
2. **위치 공유**: 가족 구성원 간 위치 정보 공유
3. **지도 통합**: 마트 내부 지도와 연동하여 시각적 표시
4. **AI 위치 예측**: 상품명으로 자동 위치 예측 (예: "요거트" → "유제품 코너")
5. **위치 기반 쇼핑 경로 최적화**: 통로 순서대로 장바구니 정렬

## 📄 관련 문서

- [음성 어시스턴트 통합 가이드](VOICE_ASSISTANT_INTEGRATION.md)
- [장바구니 기능 가이드](SHOPPING_CART_EXPENSE_INPUT_ROUTINE_REPORT.md)
- [기능 상태 체크리스트](feature_status_checklist.md)

## 🐛 문제 해결

### Q: 위치가 저장되지 않아요
A: 위치 입력 후 반드시 "저장" 버튼을 눌러야 합니다.

### Q: 이전 위치가 표시되지 않아요
A: 상품명이 정확히 일치해야 합니다. 대소문자와 공백은 무시됩니다.

### Q: 음성으로 위치 포함이 안 돼요
A: 빅스비 캡슐 설정을 확인하세요. `bixby-capsule/` 폴더의 설정이 필요합니다.

### Q: 위치 데이터를 초기화하고 싶어요
A: 현재는 개별 상품의 위치만 편집 가능합니다. 전체 초기화 기능은 향후 추가 예정입니다.

---

**구현 날짜**: 2026-01-10  
**버전**: 1.0.0  
**담당**: AI Assistant
