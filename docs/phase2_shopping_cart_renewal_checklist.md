# Phase 2 — 장바구니(Shopping Cart) 리뉴얼 체크리스트

목표: 사용자가 원한 **"쉽고 간결한 쇼핑 준비"** 흐름을 Flutter 현재 구조에 맞게 구현/검증한다.

적용 대상(현 구조 기준):
- 화면: `lib/screens/shopping_cart_screen.dart`
- 쇼핑 준비(보관/재활용): `lib/utils/shopping_cart_next_prep_utils.dart`, `lib/utils/shopping_cart_next_prep_dialog_utils.dart`
- 체크 항목 일괄 가계부 입력: `lib/utils/shopping_cart_bulk_ledger_utils.dart`
- 저장/히스토리/힌트: `lib/services/user_pref_service.dart`

---

## A. 쇼핑 준비(Planning) 모드

핵심 컨셉: "준비는 빠르게 리스트업 + 정리", 가격/수량 등은 **확인용** 또는 이후 단계에서.

체크리스트
- [ ] 입력 UX는 "품명 1개"로 일체화되어 있다.
  - 기대 동작: 상단 입력창에 품명 입력 → `추가` 또는 키보드 제출로 즉시 리스트에 추가
  - 구현 포인트: `ShoppingCartScreen._addItem()` / AppBar `TextField(onSubmitted)` / `FilledButton(onPressed)`

- [ ] 자주 산 물품(마스터/추천) 추가가 "한 번 탭"으로 가능하다.
  - 최소 요구: 칩/리스트 형태로 추천 후보를 노출하고 터치 시 바로 장바구니에 추가
  - 구현 후보:
    - (현재 보관된 기능 활용) `ShoppingCartNextPrepUtils`의 추천/복원/템플릿 불러오기 결과를 곧바로 장바구니에 merge
    - (추가 확장 시) 화면 상단에 추천 후보를 chips로 노출

- [ ] 준비 단계 정리는 "빠른 삭제"가 최우선이다.
  - 기대 동작: 각 행 우측에 삭제 버튼(또는 X) 1개로 즉시 삭제
  - 실수 방지(선택): 삭제 확인 다이얼로그 유지 여부 결정
  - 구현 포인트: `ShoppingCartScreen._confirmAndDeleteItem()` / trailing `IconButton(Icons.delete_outline)`

- [ ] 준비 단계에서 수량/금액은 "조작 대상"이 아니다.
  - 기대 동작: 리스트에서 품명 외 정보(수량/금액 입력 UI)가 노출되지 않거나, 노출되더라도 편집 UI는 제공하지 않음
  - 구현 포인트: 현재 `ListTile.title = item.name` 유지

---

## B. 마트 쇼핑(Shopping) 모드

핵심 컨셉: "체크(담기)"에 집중 + 체크된 항목의 합계만 즉시 확인.

체크리스트
- [ ] 탭/체크 시 시각적 강조가 명확하다.
  - 기대 동작: 체크박스 선택 시 행 전체 강조(배경색/강조선 등)
  - 구현 포인트: `ListTile`의 `tileColor` 또는 `Container` wrapping으로 `item.isChecked` 기반 스타일

- [ ] 체크된 항목만 합산되어 하단에 표시된다.
  - 기대 동작: 체크 개수 + 체크된 항목 합계(원) 표시
  - 구현 포인트: `ShoppingCartScreen`의 `checkedCount`, `checkedTotalWon`, `_buildCheckedSummaryBar(...)`

---

## C. 거래 기록(Final)

핵심 컨셉: "버튼 1개로 일괄 기록" + 기록된 항목은 장바구니에서 사라짐.

체크리스트
- [ ] 하단 버튼 1개로 체크된 항목을 일괄 가계부 입력한다.
  - 구현 포인트: `ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk(...)`

- [ ] 가계부 저장이 "성공"한 항목은 장바구니에서 제거된다.
  - 구현 포인트: bulk utils 내부에서 저장 성공 후 `saveItems(next)`로 체크 항목 제거

- [ ] 단건 거래추가(행의 거래추가 버튼)도 "저장 확인 후 제거"가 보장된다.
  - 구현 포인트: `ShoppingCartScreen._addToLedgerFromItem()` → `Navigator.pushNamed(... ) as bool?` 결과가 true일 때만 제거 + `UserPrefService.addShoppingCartHistoryEntry(...)`

---

## D. 쇼핑 준비(Next Prep)과의 연결(2단계에서의 최소 정리)

목적: 2단계에서도 "쇼핑 준비"가 사용을 방해하지 않도록, 기본 동작과 노출 방식만 정리한다.

체크리스트
- [ ] `쇼핑 준비` 버튼/아이콘은 1~2개의 대표 동작(기본값)을 제공한다.
  - 구현 포인트: `ShoppingCartNextPrepUtils.run(...)` 호출 구조 유지 또는 "기본 실행" 엔트리 추가

- [ ] 쇼핑 준비 진입 라우트(`/shopping/prep`)는 필요 시 자동 실행(또는 즉시 기본 실행)한다.
  - 구현 포인트: `ShoppingCartScreen(openPrepOnStart: true)` + `_didAutoOpenPrep` 가드

---

## E. 검증(수정 후 꼭 확인)

체크리스트
- [ ] `flutter analyze --no-fatal-infos` 통과
- [ ] 실제 시나리오:
  - [ ] 품명 입력 → 추가 → 리스트 반영
  - [ ] 체크 토글 → 합계/개수 반영
  - [ ] 단건 거래추가 저장(true) → 장바구니에서 제거 + 히스토리 기록
  - [ ] 일괄 입력 저장 → 체크 항목 제거
  - [ ] 쇼핑 준비(추천/복원/템플릿) 실행 → 중복 merge 동작 + snackbar 확인
