# UTILS: 쇼핑 준비(Shopping Prep) — 기능 설명/재활용 메모

목적
- 장바구니(쇼핑카트)와 별도로, “다음 쇼핑을 미리 준비”하는 기능을 **아이콘 1개로 빠르게 실행**할 수 있게 합니다.
- 쇼핑 준비 기능은 화면 로직에서 분리되어 있어, 향후 다른 화면에서도 재활용이 가능합니다.

---

## 1) 사용자가 보는 동선(아이콘)

- 메인 2페이지(구매 페이지)에 **`쇼핑 준비` 아이콘**이 있습니다.
- 아이콘을 누르면 장바구니 화면이 열리고, **기본 동작이 즉시 실행됩니다.**
  - 탭: `최근 구매 20개` 즉시 추가
  - 길게 누름: 쇼핑 준비 메뉴(2개 옵션) 표시

관련 라우트
- `AppRoutes.shoppingPrep` → 장바구니 화면 진입 + 쇼핑 준비 자동 실행

---

## 2) 쇼핑 준비에서 제공하는 기능(현재)

쇼핑 준비 메뉴에서 아래 2가지만 제공합니다.

1) 최근 구매 20개
- 장바구니 구매 히스토리(`가계부 입력`) 기준으로 최근 구매 품목을 최대 20개 추가

2) 추천 품목 20개
- 구매 이력 **2회 이상**인 품목만 대상으로
- 구매 빈도 높은 순으로 최대 20개 추천
- 구매 회수 기준: 장바구니 → 가계부 입력 히스토리(`addToLedger`)에서 품목명 기준 집계
- 동일 품목 판정: 공백 제거 + 소문자(예: `대파` = `대 파`)
- 계절/단종 품목 대응: 최근 구매가 너무 오래된 품목은 추천에서 제외(과일은 더 엄격)
- 신선식품(유통기간 짧은 품목)을 우선하고, 과일은 상대적으로 우선순위를 낮춤

---

## 3) 구현 구조(재활용 포인트)

핵심 아이디어
- 쇼핑 준비는 UI(다이얼로그) + 로직(템플릿/복원/추천)을 `utils`로 분리하고,
  화면은 `run(...)`만 호출하는 형태를 유지합니다.

진입점(재활용 핵심)
- `ShoppingCartNextPrepUtils.run(...)`
  - 입력: `accountName`, `getItems`, `getCategoryHints`, `saveItems`, `reload`
  - 장점: 화면이 달라도 동일한 인터페이스로 “아이템 목록 + 저장 콜백”만 제공하면 재활용 가능

다이얼로그(UI)
- `ShoppingCartNextPrepDialogUtils.show(...)`
  - 선택지 UI만 담당(기능 구현은 `ShoppingCartNextPrepUtils`가 담당)

데이터 저장소
- `UserPrefService`
  - 장바구니 항목 저장
  - 쇼핑 히스토리 저장
  - (현재 UX에서는 템플릿 기능 노출 없음)

---

## 4) 관련 파일

- 화면/라우팅
  - `lib/screens/shopping_cart_screen.dart`
  - `lib/navigation/app_routes.dart`
  - `lib/navigation/app_router.dart`
  - `lib/utils/icon_launch_utils.dart`

- 쇼핑 준비 유틸
  - `lib/utils/shopping_cart_next_prep_utils.dart`
  - `lib/utils/shopping_cart_next_prep_dialog_utils.dart`

- 장바구니 저장/히스토리
  - `lib/services/user_pref_service.dart`
  - `lib/models/shopping_cart_item.dart`
  - `lib/models/shopping_cart_history_entry.dart`

---

## 5) 주의사항(유지보수)

- 쇼핑 준비는 “장바구니 화면 내부 버튼”에서도 실행될 수 있고,
  `AppRoutes.shoppingPrep`로 진입할 때는 자동 실행됩니다.
- 자동 실행은 화면 로드 완료 후 1회만 트리거되도록 가드가 필요합니다.
