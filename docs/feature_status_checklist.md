# 기능 구현 점검 체크리스트 (Screen/Feature Status)

> 목적: 화면별로 **완성/미완성**, **저장 방식**, **반영 범위(홈/통계/자산 등)** 를 한눈에 점검하고, 다음 작업 순서를 결정하기 위한 체크리스트입니다.

## 범례
- ✅ 완료: 기능/저장/반영이 일관되게 동작
- ⚠️ 부분완료: 일부 동작/정책이 미완 또는 반영 범위가 제한
- ❌ 미완성: UI는 있으나 실제 로직이 빠짐
- 🔍 확인필요: 코드상 가능성은 있으나 실제 UX/흐름 추가 확인 필요

---

## ROOT

### 월말 정산 (ROOT)
- 화면: `lib/screens/root_month_end_screen.dart`
- 다이얼로그: `lib/widgets/month_end_carryover_dialog.dart`
- 저장: `AccountService.updateMonthEndData()` → SharedPreferences(`PrefKeys.accountMonthEnd`)
- 홈 반영: `AccountHomeScreen`에서 `carryoverAmount - overdraftAmount`를 예산에 가감
  - 코드: `lib/screens/account_home_screen.dart`의 `monthEndAdjustment`
- 상태: ✅ 완료(현 구현 기준)
  - `carryover`: 남은 돈 전체를 다음달 예산 이월로 반영
  - `custom`: “기타용도 금액” 입력값을 **수동 이월(carryover)** 로 반영(남은 돈 범위로 clamp)
  - `emergency`: 남은 돈을 비상금에 `EmergencyTransaction`(입금)으로 기록
  - `savings`: 남은 돈을 예금(저금통) `TransactionType.savings`(자산 증가)로 기록

### 전체 거래 관리 (ROOT)
- 화면: `lib/screens/root_transaction_manager_screen.dart`
- 데이터: `TransactionService.getAllTransactions()`
- 상태: ✅ 완료(기본 CRUD + 표시)
- 참고: 삭제는 `TransactionService.deleteTransaction(..., moveToTrash:true)`를 통해 휴지통으로 이동

### 통합 검색 (ROOT)
- 화면: `lib/screens/root_search_screen.dart`
- 상태: ✅ 완료(현 구현 기준)
  - 전체 계정 거래 통합 검색(설명/메모/금액/지불수단) ✅
  - 검색 결과에 계정명 표시 ✅
  - 결과 탭 시 해당 계정의 거래 상세로 이동(타입 프리셋) ✅

### 계정 관리/삭제 (ROOT)
- 화면: `lib/screens/root_account_manage_screen.dart`
- 상태: 🔍 확인필요(계정 삭제 시 각 서비스 데이터 정리 범위 확인)

---

## 거래(Transactions)

### 지출입력
- 화면: `lib/screens/transaction_add_screen.dart`
- 저장: `TransactionService` → SharedPreferences(`PrefKeys.transactions`)에 계정별 JSON 저장
- 상태: ✅ 완료
- 최근 변경: 저장 UI를 텍스트 버튼 → 저장 아이콘 버튼으로 변경(기능 유지)

### 거래 상세(월/일/타입별 목록 + 편집/삭제/반품/이동)
- 화면: `lib/screens/transaction_detail_screen.dart`
- 상태: ✅ 완료(현 구현 기준)
  - 편집/삭제: ✅
  - 반품: ✅(원본 거래 수량/금액 조정 + 환불 거래 생성)
  - 수입 이동(지출예산/비상금/자산): ✅
    - `지출 예산`: 예산 증감 반영(이동 변경 시 되돌림 포함)
    - `비상금`: `EmergencyTransaction(id: income_move_<txId>)`로 잔액 반영
    - `자산`: `수입 이동 예금`(deposit) 자산 금액 증감 + `AssetMove(id: income_move_<txId>)`로 타임라인 반영

### 일일 거래
- 화면: `lib/screens/daily_transactions_screen.dart`
- 상태: ✅ 완료(현 구현 기준)
  - 일자별 그룹/이동/합계 표시 ✅
  - 리스트 탭: 바텀시트(편집/삭제) 제공 ✅

### 거래 저장소
- 서비스: `lib/services/transaction_service.dart`
- 저장: SharedPreferences(`PrefKeys.transactions`)에 계정별 거래 리스트(JSON)
- 삭제: 기본적으로 휴지통(`TrashService`)로 이동
- 상태: ✅ 완료

---

## 통계(Stats)

### 계정 통계
- 화면: `lib/screens/account_stats_screen.dart`
- 집계 규칙: `SavingsAllocation`에 따라 예금이 지출로 카운트되는 케이스 분리
- 상태: ✅ 완료(현 구조 기준)

### 기간 상세 통계
- 화면: `lib/screens/period_detail_stats_screen.dart`
- 상태: ✅ 완료(현 구현 기준)
  - 기간 이동(월/분기/반기/연/10년) ✅
  - 고정비 포함 토글(지출만) ✅
  - 평균 금액은 거래 기준으로 계산(고정비 포함 시 왜곡 방지) ✅

---

## 수입 분배(Income Split)

### 수입 분배 설정 화면
- 화면: `lib/screens/income_split_screen.dart`
- 저장: `IncomeSplitService`가 문서 디렉터리의 `income_splits.json`에 저장
- 상태: ✅ 완료
- 참고: 저장 UI는 아이콘화(테스트 호환을 위해 내부적으로 `Text('저장')`이 남아있을 수 있음)

### 수입 분배 서비스
- 서비스: `lib/services/income_split_service.dart`
- 부가 동작: 설정 저장 시 `AssetMoveService` 기록 생성 옵션 존재(`createAssetMoves`)
- 상태: ✅ 완료(구조적으로는 완성)

---

## 자산/비상금(Assets / Emergency Fund)

### 비상금
- 화면: `lib/screens/emergency_fund_screen.dart`, `lib/screens/emergency_fund_list_screen.dart`
- 서비스: `lib/services/emergency_fund_service.dart`
- 저장: SharedPreferences 기반(JSON)
- 상태: ✅ 완료(최근 삭제/선택삭제 구조 문제 수정 포함)
- 정책 포인트(유지): 비상금 삭제 시 “단순 삭제 vs 자산/현금 반영” 선택 정책

### 자산
- 화면: `lib/screens/asset_list_screen.dart`, `lib/screens/asset_detail_screen.dart`
- 서비스: `lib/services/asset_service.dart`, `lib/services/asset_move_service.dart`
- 상태: 🔍 확인필요(자산/이동 반영이 홈/통계/거래와 기대대로 연결되는지)

---

## 휴지통/백업

### 휴지통
- 화면: `lib/screens/trash_screen.dart`
- 서비스: `lib/services/trash_service.dart`
- 저장: SharedPreferences(`PrefKeys.trash`) 리스트(JSON), 최대 60MB 유지
- 복원:
  - 거래/자산: 해당 서비스로 add 후 entry 삭제
  - 계정: 스냅샷 기반으로 `BackupService.importAccountData()`로 복원
- 상태: ✅ 완료

### 백업
- 화면: `lib/screens/backup_screen.dart`
- 서비스: `lib/services/backup_service.dart`
- export 포함 범위: account / transactions / assets / fixedCosts / budget
- 상태: ✅ 완료

---

## 쇼핑(Shopping)

### 장바구니(쇼핑 준비)
- 화면: `lib/screens/shopping_cart_screen.dart`
- 저장: `UserPrefService` → SharedPreferences(계정별)
  - items: `shopping_cart_items`
  - history: `shopping_cart_history_v1`
  - template: `shopping_grocery_template_v1`
  - category hints: `shopping_category_hints_v1`
- 상태: ✅ 완료(현 구현 기준)
  - 항목 추가/체크/수정/삭제 ✅
  - 결제 전 반환 기록(History) ✅
  - 가계부 입력(단건/일괄) ✅
    - 저장 확정 후에만 `addToLedger` 히스토리 기록
    - 단건 저장 확정 시 장바구니에서 자동 제거
  - 다음 쇼핑 준비(템플릿/지난 구매 복원/식비 추천) ✅

---

## 메인 페이지(2페이지=지출입력, 3페이지=수입)
- 화면: `lib/screens/account_main_screen.dart`
- 상태: ✅ 완료 (2026-01-30)
  - 페이지2 이름: "거래" → "지출입력" 으로 변경
  - 관련 문서 모두 업데이트됨

---

## 다음 작업 추천 순서(최소 리스크)
1) 월말 정산 옵션(`emergency/savings/custom`) 실제 반영 로직 구현
2) 거래 상세의 "수입 이동(비상금/자산)"을 실제 자산/비상금 데이터에 반영할지 정책 확정 후 구현
3) 일일 거래 리스트 탭 동작(상세 이동) 필요 여부 결정 후 연결
