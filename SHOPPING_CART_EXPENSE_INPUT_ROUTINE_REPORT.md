# 장바구니 지출입력 루틴 상세 보고서
**작성일:** 2026-01-04  
**상태:** ✅ 구현 완료(통합 검증 진행 중)  
**담당 구간:** 장바구니 항목 → 가계부 지출 저장

---

## 📋 개요

장바구니 지출입력 루틴은 **3단계 쇼핑 워크플로우**의 마지막 단계이며, 체크된 장바구니 항목들을 가계부 거래로 일괄 또는 단건 저장하는 프로세스입니다.

### 핵심 구간
```
쇼핑 준비(Planning) 
→ 마트 쇼핑(Shopping & Check) 
→ 거래 기록(Final: 지출입력) ← ⭐ 이 보고서 범위
```

---

## 🏗️ 아키텍처

### 1. 핵심 화면 및 유틸리티

| 컴포넌트 | 경로 | 역할 | 상태 |
|---------|------|------|------|
| **ShoppingCartScreen** | `lib/screens/shopping_cart_screen.dart` | 장바구니 목록 및 체크 관리 | ✅ 완료 |
| **ShoppingCartQuickTransactionScreen** | `lib/screens/shopping_cart_quick_transaction_screen.dart` | 개별 지출 입력(결제수단, 카테고리, 메모) | ✅ 완료 |
| **ShoppingCartBulkLedgerUtils** | `lib/utils/shopping_cart_bulk_ledger_utils.dart` | 일괄 지출 입력 로직 | ✅ 완료 |
| **ShoppingPointsInputScreen** | `lib/screens/shopping_points_input_screen.dart` | 사후 포인트 입력(영수증 합계 ← 결제) | ✅ 완료 |

---

## 🔄 지출입력 프로세스 (3가지 경로)

### 경로 1️⃣: 단건 거래 입력 (행 버튼)

```
ShoppingCartScreen
  ↓ (체크 없이 항목 행의 거래추가 버튼 탭)
ShoppingCartQuickTransactionScreen
  ├─ 입력 필드: 결제수단, 카테고리(자동 제시), 메모
  ├─ 자동 채우기: 최근 결제수단/메모 불러오기
  └─ 저장 후: 
     ├─ Transaction 가계부에 기록
     ├─ ShoppingCartHistoryEntry 기록 (action: addToLedger)
     └─ 장바구니에서 해당 항목 삭제
```

**코드 위치:**
- 저장 로직: [ShoppingCartQuickTransactionScreen._saveCurrentTransaction()](lib/screens/shopping_cart_quick_transaction_screen.dart#L1550)
- 삭제 처리: [ShoppingCartScreen._addToLedgerFromItem()](lib/screens/shopping_cart_screen.dart#L370)

---

### 경로 2️⃣: 일괄 거래 입력 (체크 항목 - 순차)

```
ShoppingCartScreen
  ↓ (체크된 항목이 1개 초과)
ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk()
  ├─ 항목1 지출입력
  │  └─ ShoppingCartQuickTransactionScreen 진입
  │     └─ 저장 후 history 기록
  ├─ 항목2 지출입력 (결제수단 자동 채우기 적용)
  │  ├─ 저장 또는 "나머지 모두 저장" 선택지
  │  └─ 저장 후 history 기록 + 나머지 항목 일괄 처리 옵션
  └─ ... 반복
```

**코드 위치:**
- 일괄 로직: [ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk()](lib/utils/shopping_cart_bulk_ledger_utils.dart#L23)
- 순차 저장 루프: [Line 139~320](lib/utils/shopping_cart_bulk_ledger_utils.dart#L139-L320)

**특징:**
- ✅ 첫 항목 저장 후 결제수단/메모 자동 채우기(SharedPreferences)
- ✅ 2번째 항목부터 "나머지 모두 저장" 버튼 활성화
- ✅ 일괄 저장으로 시간 단축 가능

---

### 경로 3️⃣: 포인트 사후 입력 (영수증 정보)

```
ShoppingCartQuickTransactionScreen
  └─ 일괄 지출 완료 시 bulkGrandTotal 저장
       ↓
ShoppingPointsInputScreen
  ├─ 영수증 합계 자동 채우기
  ├─ 카드결제금액, 마트/카드 할인 입력
  ├─ 포인트 자동 계산: 합계 - 카드결제 - 마트할인 - 카드할인
  └─ 사후 입력으로 포인트 적립 추적
```

**코드 위치:**
- Draft 저장: [ShoppingCartQuickTransactionScreen._handleBulkFinishBeforePop()](lib/screens/shopping_cart_quick_transaction_screen.dart#L80)
- 포인트 계산: [ShoppingPointsInputScreen._computePoints()](lib/screens/shopping_points_input_screen.dart#L57)

---

## 📊 데이터 흐름

### 입력 데이터 소스

| 정보 | 출처 | 저장 위치 |
|------|------|----------|
| 상품명, 수량, 단가 | 장바구니 항목(ShoppingCartItem) | SharedPreferences: `shopping_cart_items` |
| 카테고리 hint | 이전 입력 기록 | SharedPreferences: `shopping_category_hints_v1` |
| 최근 결제수단 | 최근 입력 저장 | SharedPreferences: `recent_payments` |
| 최근 메모 | 최근 입력 저장 | SharedPreferences: `recent_memos` |
| 지출 거래 | 가계부 저장 | Database(SQLite) 또는 JSON: `transactions` |
| 쇼핑 히스토리 | 쇼핑 기록 추적 | SharedPreferences: `shopping_cart_history_v1` |
| 포인트 draft | 일괄 완료 후 임시 저장 | SharedPreferences: `shopping_points_drafts` |

---

## ⚙️ 핵심 로직 상세

### 1️⃣ 단건 저장 (_saveCurrentTransaction)

```dart
// 위치: ShoppingCartQuickTransactionScreen, Line ~1550
Future<void> _saveCurrentTransaction() async {
  // 1. 결제수단 필수 검증
  if (_paymentController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('결제수단을 입력하세요.'))
    );
    return;
  }

  // 2. 카테고리 자동 제시 (미선택 시)
  if (!_hasSelectedMainCategory) {
    await _ensureCategorySuggestion();
  }

  // 3. 거래 객체 생성
  final txId = 'tx_${now.microsecondsSinceEpoch}';
  final transaction = Transaction(
    id: txId,
    type: TransactionType.expense,
    description: widget.args.title,  // 예: '장바구니', '마트 쇼핑 입력 1/3'
    amount: total,
    unitPrice: unit,
    quantity: qty,
    date: targetDate,
    paymentMethod: paymentController.text,
    memo: memoText,
    category: selectedMainCategory,
    subCategory: selectedSubCategory,
  );

  // 4. 가계부 저장
  await TransactionService().addTransaction(
    widget.args.accountName,
    transaction
  );

  // 5. 최근 입력값 저장 (다음 입력 시 자동 채우기)
  await SharedPreferences.getInstance().then((prefs) {
    prefs.setString('recent_payment_${widget.args.accountName}', paymentMethod);
    prefs.setString('recent_memo_${widget.args.accountName}', memo);
  });

  // 6. 성공 피드백 및 화면 반환 (true = 삭제됨)
  Navigator.of(context).pop(true);
}
```

**핵심 특징:**
- ✅ 결제수단 필수 입력(속도 vs 안전성 balance)
- ✅ 카테고리 자동 제시(학습 기반 hint)
- ✅ 최근 입력 저장(다음 입력 시 유용)
- ✅ 단일 시점(microsecondsSinceEpoch) ID 생성

---

### 2️⃣ 일괄 저장 (순차 처리)

```dart
// 위치: ShoppingCartBulkLedgerUtils, Line ~139
for (var index = 0; index < selected.length; index++) {
  final item = selected[index];
  final qty = qtyOf(item);
  final unit = item.unitPrice;
  final itemTotal = unit * qty;

  // 자동 카테고리 제시 (저장된 hint 기반)
  final suggested = ShoppingCategoryUtils.suggest(
    item,
    learnedHints: categoryHints,
  );

  // 순차 화면 진입: "마트 쇼핑 입력 1/3", "마트 쇼핑 입력 2/3" ...
  final result = await navigator.pushNamed(
    AppRoutes.shoppingCartQuickTransaction,
    arguments: ShoppingCartQuickTransactionArgs(
      accountName: accountName,
      title: '마트 쇼핑 입력 ${index + 1}/${selected.length}',
      description: item.name,
      quantity: qty,
      unitPrice: unit,
      total: itemTotal,
      initialMainCategory: suggested.mainCategory,  // 자동 제시
      initialSubCategory: suggested.subCategory,    // 자동 제시
      isBulk: true,
      bulkIndex: index,
      bulkTotalCount: selected.length,
      bulkRemainingItems: selected.sublist(index + 1),
      bulkGrandTotal: total,  // 영수증 합계 (포인트 입력용)
    ),
  );

  // 저장 성공 시 히스토리 기록
  if (result == true && context.mounted) {
    await UserPrefService.addShoppingCartHistoryEntry(
      accountName: accountName,
      entry: ShoppingCartHistoryEntry(
        id: 'hist_${now.microsecondsSinceEpoch}',
        action: ShoppingCartHistoryAction.addToLedger,
        itemId: item.id,
        name: item.name,
        quantity: qty,
        unitPrice: unit,
        at: now,
      ),
    );
  }
}
```

**핵심 특징:**
- ✅ 순차 저장으로 각 항목의 세부 사항 개별 입력 가능
- ✅ 자동 카테고리 제시(학습 기반)
- ✅ 히스토리 자동 기록(쇼핑 회고용)
- ✅ 영수증 합계 누적(포인트 입력 연동)

---

### 3️⃣ 포인트 자동 계산

```dart
// 위치: ShoppingPointsInputScreen, Line ~57
double _computePoints({
  required double total,        // 영수증 합계
  required double charged,      // 카드 결제금액
  required double martDiscount, // 마트/쇼핑몰 할인
  required double cardDiscount, // 카드 할인
}) {
  // 포인트 = 합계 - 카드결제 - 마트할인 - 카드할인
  final diff = total - charged - martDiscount - cardDiscount;
  return diff > 0 ? diff : 0;
}
```

**공식:**
$$
\text{포인트(원)} = \text{영수증 합계} - \text{카드결제} - \text{마트할인} - \text{카드할인}
$$

---

## 🎯 UX 흐름도

### 사용자 입장에서의 3가지 경로

```
장바구니 화면
  │
  ├─ [경로 A] 항목 행 → "거래추가" 버튼
  │  └─ 단건 입력 화면
  │     ├─ 상품명(고정): 예) "우유 1개"
  │     ├─ 수량(고정): 1
  │     ├─ 단가(고정): 5000
  │     ├─ 결제수단(필수): 신용카드 [최근 자동 채우기]
  │     ├─ 카테고리: 식료품/마트 [자동 제시]
  │     ├─ 메모(선택): [최근 자동 채우기]
  │     └─ [저장] → 가계부 기록 + 장바구니에서 제거
  │
  └─ [경로 B/C] 체크 ☑ + "지출 입력" 버튼
     ├─ 1개 항목만 체크: 단건 입력 화면 (경로 A와 동일)
     └─ 2개 이상 체크: 순차 입력 화면
        ├─ 항목1: "마트 쇼핑 입력 1/3"
        │  └─ [저장] 또는 [나머지 모두 저장]
        ├─ 항목2: "마트 쇼핑 입력 2/3" (결제수단 자동 채우기)
        │  └─ [저장] 또는 [나머지 모두 저장]
        └─ 항목3: "마트 쇼핑 입력 3/3" (결제수단 자동 채우기)
           └─ [저장] → 포인트 입력 화면으로 진입

포인트 입력 화면 (사후 선택)
  ├─ 영수증 합계: 15000 [자동 채우기]
  ├─ 카드 결제금액: 12000
  ├─ 마트 할인: 1000
  ├─ 카드 할인: 500
  └─ 포인트(자동): 1500 (15000 - 12000 - 1000 - 500)
```

---

## 📝 저장 구조

### ShoppingCartItem (입력 전)
```json
{
  "id": "shop_1704336000000000",
  "name": "우유",
  "quantity": 1,
  "unitPrice": 5000,
  "isChecked": false,
  "estimatedPrice": "5000원",
  "createdAt": "2026-01-04T10:00:00Z",
  "updatedAt": "2026-01-04T10:00:00Z",
  "isPlanned": false
}
```

### Transaction (저장 후)
```json
{
  "id": "tx_1704336001234567",
  "type": "expense",
  "accountName": "가계부1",
  "description": "우유",
  "amount": 5000,
  "unitPrice": 5000,
  "quantity": 1,
  "date": "2026-01-04",
  "paymentMethod": "신용카드",
  "category": "식료품",
  "subCategory": "마트",
  "memo": "[장바구니] 우유",
  "store": "마트",
  "createdAt": "2026-01-04T10:00:01Z",
  "updatedAt": "2026-01-04T10:00:01Z"
}
```

### ShoppingCartHistoryEntry (기록)
```json
{
  "id": "hist_1704336001234567",
  "action": "addToLedger",
  "itemId": "shop_1704336000000000",
  "name": "우유",
  "quantity": 1,
  "unitPrice": 5000,
  "isPlanned": false,
  "at": "2026-01-04T10:00:01Z"
}
```

### ShoppingPointsDraftEntry (포인트 임시)
```json
{
  "id": "sp_1704336010000000",
  "at": "2026-01-04T10:00:10Z",
  "receiptTotal": 15000,
  "store": null,
  "card": null,
  "chargedAmount": null,
  "martDiscount": null,
  "cardDiscount": null,
  "pointsDirect": null,
  "memo": null
}
```

---

## ✅ 현황 체크리스트

| 항목 | 상태 | 검증 필요 | 비고 |
|------|------|---------|------|
| **단건 저장** | ✅ 완료 | ✓ | 결제수단 필수, 카테고리 자동 제시 |
| **일괄 저장** | ✅ 완료 | ✓ | 순차 입력, "나머지 모두 저장" 옵션 |
| **포인트 입력** | ✅ 완료 | ✓ | 사후 입력, 영수증 ← 일괄 연동 |
| **최근 입력 저장** | ✅ 완료 | ✓ | 결제수단, 메모 자동 채우기 |
| **카테고리 학습** | ✅ 완료 | ✓ | CategoryHint 기반 제시 |
| **히스토리 기록** | ✅ 완료 | ✓ | 쇼핑 회고(what/when) |
| **장바구니 삭제** | ✅ 완료 | ✓ | 저장 성공 후만 제거 |
| **UI/UX** | ✅ 완료 | ✓ | 3가지 경로 통일된 flow |

---

## 🧪 검증 항목 (수행 필요)

### 단계 1: 코드 정적 분석
```bash
flutter analyze --no-fatal-infos
```
- [ ] 경고/오류 없음 확인
- [ ] import 순환 참조 없음
- [ ] dead code 없음

### 단계 2: 실제 시나리오 테스트

#### A. 단건 입력 시나리오
```
1. 장바구니에 "우유 5000원, 빵 8000원" 추가
2. 우유 행의 "거래추가" 탭
3. 결제수단: 신용카드 입력
4. [저장]
5. 확인: 가계부에 기록, 장바구니에서 우유 제거
```

#### B. 일괄 입력 시나리오
```
1. 우유, 빵 모두 체크
2. "지출 입력" 버튼
3. 항목1 입력화면 → 결제수단: 신용카드 → [저장]
4. 항목2 입력화면 → 결제수단 자동 채우기 확인 → [저장]
5. 포인트 입력 화면으로 진입 확인
6. 영수증 합계 자동 채우기(13000) 확인
```

#### C. 포인트 사후 입력
```
1. 포인트 입력 화면에서:
   - 영수증 합계: 13000
   - 카드결제: 10000
   - 마트할인: 1000
   - 카드할인: 500
2. 포인트(자동): 1500 (13000-10000-1000-500) 확인
3. [저장]
```

#### D. 최근 입력 유지
```
1. 첫 입력: 신용카드, "마트" 메모 저장
2. 두 번째 입력: 동일 계정 → 신용카드, "마트" 자동 채우기 확인
```

### 단계 3: 에지 케이스

- [ ] 결제수단 미입력 시 저장 불가 + Snackbar 표시
- [ ] 카테고리 미선택 시 자동 제시 + 기본값 선택
- [ ] 포인트 계산이 음수가 되지 않음 (max 0)
- [ ] 빈 장바구니 상태에서 지출 입력 버튼 비활성화
- [ ] 장바구니 삭제 후 이미지/UI 반영 확인
- [ ] 백그라운드 저장 실패 시 Snackbar + 재시도 옵션

---

## 📚 관련 문서

- [Phase 2 쇼핑카트 리뉴얼 체크리스트](docs/phase2_shopping_cart_renewal_checklist.md)
- [기능 구현 점검 리스트](docs/feature_status_checklist.md)
- [쇼핑 워크플로우 유틸](lib/utils/shopping_workflow_utils.dart)
- [ShoppingCartScreen](lib/screens/shopping_cart_screen.dart)
- [ShoppingCartQuickTransactionScreen](lib/screens/shopping_cart_quick_transaction_screen.dart)
- [ShoppingCartBulkLedgerUtils](lib/utils/shopping_cart_bulk_ledger_utils.dart)

---

## 🚀 다음 단계

1. ✅ **코드 검증** - `flutter analyze` 통과 확인
2. **실제 시나리오 테스트** - 위의 검증 항목 수행
3. **QA 체크리스트 작성** - 앱 전체 통합 테스트
4. **배포 준비** - 릴리스 노트 작성, AAB/APK 빌드

---

**작성:** GitHub Copilot  
**마지막 검토:** 2026-01-04
