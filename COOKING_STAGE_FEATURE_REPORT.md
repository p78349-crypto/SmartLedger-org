# 요리단계(Cooking Stage) 기능 보고서
**작성일:** 2026-01-04  
**상태:** ✅ 구현 완료  
**담당 모듈:** 재고관리 → 요리 선택 → 재료 사용량 입력

---

## 📋 개요

요리단계 기능은 **식품 재고관리(WMS)** 시스템의 3번째 핵심 단계로, 사용자가 요리를 선택하면 해당 레시피의 재료를 자동으로 불러와 재고에서 차감하는 프로세스입니다.

### 1스탬프 루틴(영양-재고-장보기-지출) 내 위치
```
1단계: 영양 정보 입력(Nutrition Input)
   ↓
2단계: 재고 관리(Food Expiry - 현 위치의 상위)
   ├─ 보기(View) → 만료일자 추적
   ├─ 추가(Add) → 신규 식품 입력
   │  └─ 재고단계: 식품 리스트 작성
   │
   ├─ [✅ 요리단계: 요리 선택 → 재료 차감]  ← ⭐ 이 보고서 범위
   │  └─ 요리 추천/검색 → 재료 사용량 입력 → 재고 자동 차감
   │
   └─ 쇼핑 준비(Prep) → 부족한 재료 자동 추가
   ↓
3단계: 장보기(Shopping Cart)
   └─ 장바구니 → 지출 입력
   ↓
4단계: 지출 기록(Expense Ledger)
```

---

## 🏗️ 아키텍처

### 핵심 컴포넌트

| 컴포넌트 | 경로 | 역할 | 상태 |
|---------|------|------|------|
| **Recipe Model** | `lib/models/recipe.dart` | 레시피 데이터 구조(재료 목록) | ✅ 완료 |
| **RecipeService** | `lib/services/recipe_service.dart` | 50개 기본 요리 + CRUD | ✅ 완료 |
| **RecipePickerDialog** | `lib/screens/food_expiry_main_screen.dart` (Line 32~) | 요리 선택 & 검색 UI | ✅ 완료 |
| **RecipeUpsertDialog** | `lib/screens/food_expiry_main_screen.dart` | 커스텀 요리 추가/수정 | ✅ 완료 |
| **재료 사용량 입력** | `lib/screens/food_expiry_main_screen.dart` | 사용한 재료의 수량 차감 | ✅ 완료 |
| **FoodExpiryService** | `lib/services/food_expiry_service.dart` | 재고 업데이트 | ✅ 완료 |

---

## 📊 레시피 데이터 구조

### Recipe Model
```dart
class Recipe {
  final String id;           // 고유 ID: 'r1', 'r2', ..., 'r60'
  final String name;         // 요리명: '김치찌개', 'Pasta' 등
  final String cuisine;      // 요리 종류: 'Korean', 'Western', 'Japanese' 등
  final List<RecipeIngredient> ingredients;  // 재료 목록
}

class RecipeIngredient {
  final String name;         // 재료명: '김치', 'Pork' 등
  final double quantity;     // 수량: 0.25, 200, 1 등
  final String unit;         // 단위: '포기', 'g', '개' 등
}
```

### 기본 제공 레시피 (50+개)

#### 🇰🇷 한식 (Korean Cuisine) - 40개 이상

| 카테고리 | 예시 | 재료 수 |
|----------|------|---------|
| **찌개/탕류** | 김치찌개, 된장찌개, 순두부찌개, 부대찌개, 육개장, 동태찌개, 알탕, 미역국, 떡국, 콩나물국 | 5~6개 |
| **조림/볶음** | 소불고기, 닭갈비, 갈비찜, 찜닭, 고등어조림, 오징어볶음, 제육볶음 | 4~6개 |
| **구이** | 삼겹살 구이, 수육 | 4~5개 |
| **전/튀김** | 호박전, 김치전, 해물파전, 새우튀김, 계란말이 | 4~5개 |
| **밥/면** | 비빔밥, 김치볶음밥, 칼국수, 수제비, 잔치국수, 쫄면 | 5~6개 |
| **반찬** | 나물/볶음(멸치, 진미채, 가지 등), 무침(오이, 콩나물) | 3~4개 |
| **기타** | 카레, 닭볶음탕 | 4~5개 |

#### 🌍 국제 요리 (International) - 10+개

| 카테고리 | 예시 | 특징 |
|----------|------|------|
| **Western** | Steak (스테이크) | 쇠고기, 아스파라거스, 마늘 등 |
| **Japanese** | Udon (우동), Sushi (초밥) | 면/쌀밥 기반 |
| **Chinese** | 마라탕(예정) | 향신료 중심 |

#### 📋 레시피 전체 목록 (ID 기준)
```
r1: 김치찌개               r26: 삼계탕
r2: 된장찌개               r27: 칼국수
r3: 제육볶음               r28: 만두국
r4: Stir-fried Pork        r29: 육개장
r5: 미역국                 r30: 감자채볶음
r6: 닭볶음탕               r31: 호박전
r7: 삼겹살 구이            r32: 김치전
r8: 수육                   r33: 해물파전
r9: 닭갈비                 r34: 계란말이
r10: 카레                  r35: 계란찜
r11: 순두부찌개            r36: 두부조림
r12: 부대찌개              r37: 어묵볶음
r13: 소불고기              r38: 진미채볶음
r14: 갈비찜                r39: 오이무침
r15: 잡채                  r40: 가지볶음
r16: 떡볶이                r41: 닭볶음탕
r17: 비빔밥                r42: 찜닭
r18: 김치볶음밥            r43: 동태찌개
r19: 콩나물국              r44: 알탕
r20: 소고기무국            r45: 미역국
r21: 무국                  r46: 북엇국
r22: 나물/반찬             r47: 떡국
r23: 멸치볶음              r48: 수제비
r24: 고등어조림            r49: 쫄면
r25: 오징어볶음            r50: 잔치국수
                          r51-r60: 국제 요리
```

---

## 🔄 요리단계 프로세스

### 단계 1️⃣: 요리 선택 (RecipePickerDialog)

```
사용자 → "요리 선택" 버튼 탭
   ↓
RecipePickerDialog 팝업 표시
   ├─ 검색창: 요리명 또는 재료명으로 검색
   ├─ 카테고리 필터: All, Korean, Western, Japanese, Chinese, Other
   ├─ 리스트: 레시피 목록 표시
   │  └─ 각 레시피별 재고 상태 표시
   │     ├─ 초록색: 모든 재료 재고 보유(✓ 즉시 요리 가능)
   │     ├─ 주황색: 일부 재료 보유(⚠ 일부 부족)
   │     └─ 회색: 재료 없음(✗ 준비 필요)
   └─ [새 레시피 추가] 버튼: 커스텀 요리 추가
```

**코드 위치:** [RecipePickerDialog._RecipePickerDialogState.build()](lib/screens/food_expiry_main_screen.dart#L75)

**주요 기능:**
- ✅ 실시간 검색(요리명 + 재료명)
- ✅ 다중 카테고리 필터링
- ✅ 재고 상태 표시(3단계 색상 코드)
- ✅ 상세보기: 매칭된 재고 목록 표시
- ✅ 인라인 수정: 레시피 선택 중 편집 가능

**UI 특징:**
```
┌─────────────────────────────────────┐
│ 레시피 선택                    [+추가] │
├─────────────────────────────────────┤
│ [🔍 레시피 또는 식재료 검색]          │
│                                     │
│ [All] [Korean] [Western]...        │
│                                     │
│ ✓ 김치찌개 (재고: 5/5) [상세보기]  │  ← 초록색 (즉시 가능)
│ ⚠ 된장찌개 (재고: 3/6)            │  ← 주황색 (일부 부족)
│ ✗ 수육 (재고: 0/4)                │  ← 회색 (준비 필요)
│ • Steak (재고: 2/3)                │
├─────────────────────────────────────┤
│ [취소]                              │
└─────────────────────────────────────┘
```

---

### 단계 2️⃣: 재료 사용량 입력

```
사용자 → 요리 선택 (예: 김치찌개)
   ↓
_UsageInputFormState 화면 진입
   ├─ 요리 이미지 또는 아이콘 표시
   ├─ 요리명 표시: "김치찌개"
   ├─ 자동 불러온 재료 목록:
   │  └─ 각 재료별 수정 가능한 사용량 입력 폼
   │     ├─ 재료명: 김치
   │     ├─ 기본 수량: 0.25 [사용자 수정 가능]
   │     ├─ 단위: 포기
   │     └─ 현재 재고: 1 포기 ✓
   │
   └─ [사용량 입력 완료] 버튼
      ↓
      재료 사용량 검증
         ├─ 재고 >= 사용량 ? → 차감 진행
         └─ 재고 < 사용량 ? → 경고 + 계속/취소 선택
         ↓
      FoodExpiryService.updateItems()로 재고 차감
         ├─ 재고 수량 감소
         ├─ 갱신일시 업데이트
         └─ 자동 저장(SharedPreferences)
         ↓
      성공 메시지 + 화면 닫기
```

**코드 위치:** [_UsageInputFormState 클래스](lib/screens/food_expiry_main_screen.dart#L~600)

**주요 로직:**
```dart
// 선택된 요리의 재료 가져오기
List<RecipeIngredient> ingredients = selectedRecipe.ingredients;

// 재고와 자동 매칭
List<FoodExpiryItem> inventory = FoodExpiryService.instance.items.value;

// 사용량 입력 폼 생성
for (var ing in ingredients) {
  // 1. 매칭되는 재고 찾기
  final matched = inventory.firstWhere(
    (it) => it.name.contains(ing.name) || ing.name.contains(it.name),
    orElse: () => null
  );

  // 2. 입력 폼 생성 (기본값: 레시피의 수량)
  TextEditingController(text: ing.quantity.toString());

  // 3. 사용 후 재고 차감
  if (matched != null) {
    matched.quantity -= usedQuantity;
    await FoodExpiryService.instance.updateItem(matched);
  }
}
```

---

### 단계 3️⃣: 재고 자동 차감

```
사용량 입력 완료
   ↓
재고 검증
   ├─ 재고 >= 사용량 → 즉시 차감
   └─ 재고 < 사용량 → 확인 후 차감
      ├─ [계속] → 음수 허용 (부채 기록)
      └─ [취소] → 입력 폼으로 복귀
   ↓
FoodExpiryService.updateItems() 호출
   ├─ 각 재료별 quantity 감소
   ├─ updatedAt 갱신
   └─ SharedPreferences 자동 저장
   ↓
UI 갱신
   ├─ 요리단계 화면 닫기
   └─ 메인 화면 재고 리스트 새로고침
```

**차감 함수 (예시):**
```dart
Future<void> _submitUsage(List<({String name, double usedQty})> usage) async {
  final inventory = FoodExpiryService.instance.items.value;
  final updated = List<FoodExpiryItem>.from(inventory);

  for (var u in usage) {
    final item = updated.firstWhere(
      (it) => it.name.contains(u.name) || u.name.contains(it.name),
      orElse: () => null
    );
    
    if (item != null && item.quantity >= u.usedQty) {
      item.quantity -= u.usedQty;  // ← 차감
      await FoodExpiryService.instance.updateItem(item);
    }
  }
  
  Navigator.pop(context);  // 화면 닫기
}
```

---

## 🎯 커스텀 요리 추가 (RecipeUpsertDialog)

사용자가 자신의 요리 스타일에 맞게 커스텀 레시피를 추가할 수 있습니다.

### 추가 방법

```
1. 레시피 선택 다이얼로그에서 [+추가] 버튼
   또는
2. 기존 레시피 편집 시 [편집] 아이콘
   ↓
RecipeUpsertDialog 표시
   ├─ 요리명 입력: 예) "내 맞춤 카레"
   ├─ 카테고리 선택: Korean / Western / Japanese / Chinese / Other
   ├─ 재료 추가 (동적 폼)
   │  └─ 재료 이름 + 수량 + 단위 (여러 개 추가 가능)
   └─ [저장]
      ↓
      RecipeService.addRecipe() 호출
         └─ JSON으로 직렬화해서 recipes.json 저장
```

**저장 위치:** `{Documents}/recipes.json`  
**형식:**
```json
[
  {
    "id": "user_custom_1",
    "name": "내 맞춤 카레",
    "cuisine": "Western",
    "ingredients": [
      {"name": "돼지고기", "quantity": 250, "unit": "g"},
      {"name": "감자", "quantity": 2, "unit": "개"},
      {"name": "양파", "quantity": 2, "unit": "개"}
    ]
  }
]
```

---

## 📊 데이터 흐름

### 요리 선택 → 재료 매칭 → 사용량 입력 → 재고 차감

```
사용자 입력
   ↓
Recipe (선택)
   ├─ id: 'r1'
   ├─ name: '김치찌개'
   ├─ cuisine: 'Korean'
   └─ ingredients: [
        {name: '김치', qty: 0.25, unit: '포기'},
        {name: '돼지고기', qty: 200, unit: 'g'},
        ...
      ]
   ↓
FoodExpiryItem (재고 매칭)
   ├─ id: 'f001'
   ├─ name: '김치'
   ├─ quantity: 1.0 (포기)
   ├─ category: '채소'
   └─ expiryDate: '2026-01-15'
   ↓
사용량 입력 폼
   └─ 사용 수량 확인/수정: 0.25 포기
   ↓
업데이트
   ├─ 재고량: 1.0 - 0.25 = 0.75 포기
   ├─ 갱신일: 2026-01-04
   └─ 저장: SharedPreferences
```

---

## 🎨 UI/UX 특징

### 요리 선택 다이얼로그
- ✅ **직관적 검색:** 요리명 + 재료명 동시 검색
- ✅ **시각적 피드백:** 재고 상태 색상 코드(초록/주황/회색)
- ✅ **빠른 필터링:** 카테고리별 빠른 이동
- ✅ **상세 정보:** 매칭된 재고 목록 확인 가능
- ✅ **즉시 커스터마이징:** 대화상자 내에서 레시피 추가/편집

### 사용량 입력 화면
- ✅ **자동 채우기:** 레시피의 기본 수량으로 폼 미리 채우기
- ✅ **재고 표시:** 각 재료의 현재 재고 표시
- ✅ **유효성 검사:** 재고 초과 시 경고
- ✅ **유연성:** 사용자가 수량 자유롭게 조정 가능

---

## ✅ 현황 체크리스트

| 항목 | 상태 | 검증 필요 | 비고 |
|------|------|---------|------|
| **Recipe 모델** | ✅ 완료 | ✓ | 50+ 기본 레시피 제공 |
| **RecipeService** | ✅ 완료 | ✓ | CRUD + 파일 저장/로드 |
| **요리 선택 UI** | ✅ 완료 | ✓ | 검색/필터/상세보기 |
| **커스텀 요리 추가** | ✅ 완료 | ✓ | 사용자 정의 가능 |
| **재료 매칭** | ✅ 완료 | ✓ | 이름 포함 기반 자동 매칭 |
| **사용량 입력** | ✅ 완료 | ✓ | 동적 폼 + 검증 |
| **재고 자동 차감** | ✅ 완료 | ✓ | FoodExpiryService 통합 |
| **사용자 경험** | ✅ 완료 | ✓ | 3가지 경로(추가/선택/편집) |

---

## 🧪 검증 항목 (수행 필요)

### 단계 1: 요리 선택 테스트

#### A. 기본 요리 선택
```
1. FoodExpiryMainScreen에서 [요리 선택] 버튼 탭
2. 레시피 선택 다이얼로그 표시 확인
3. "김치찌개" 선택 → 사용량 입력 화면 진입 확인
```

#### B. 검색 기능
```
1. 검색창에 "갈비" 입력
   → "갈비찜", "소불고기" 등 관련 레시피 필터링 확인
2. 검색창에 "돼지고기" 입력
   → 돼지고기를 포함한 모든 레시피 표시 확인
3. 검색어 초기화([X]) 클릭 → 전체 리스트 복귀 확인
```

#### C. 카테고리 필터
```
1. [Korean] 선택 → 한식 레시피만 표시 확인
2. [Western] 선택 → 양식 레시피만 표시 확인
3. [All] 선택 → 모든 레시피 표시 확인
```

#### D. 재고 상태 표시
```
1. 김치, 돼지고기 등을 재고에 추가
2. "김치찌개" 선택
   → 모든 재료가 있으면 리스트에 **굵은 글씨** + 초록색 표시 확인
3. 일부 재료만 있으면 주황색 표시 확인
4. 재료가 없으면 회색 표시 확인
```

#### E. 상세보기
```
1. "김치찌개"의 [상세보기] 링크 클릭
2. 매칭된 재고 목록 팝업 표시 확인
3. 각 재료의 카테고리, 위치, 수량, 남은 날 표시 확인
```

### 단계 2: 사용량 입력 테스트

#### A. 기본 사용량
```
1. "김치찌개" 선택 후 사용량 입력 화면 진입
2. 각 재료의 기본 수량 미리 채워짐 확인
   - 김치: 0.25
   - 돼지고기: 200
   - 두부: 0.5
   - 대파: 1
   - 양파: 0.5
3. 현재 재고 표시 확인
```

#### B. 수량 수정
```
1. "김치" 사용량을 0.25 → 0.3으로 수정
2. [사용량 입력 완료] 버튼 탭
3. 재고 업데이트 확인
```

#### C. 재고 초과 경고
```
1. "돼지고기" 재고: 100g (부족)
2. 사용량: 200g 입력
3. 경고 다이얼로그 표시 확인
   - "재고가 부족합니다. 계속하시겠습니까?"
4. [계속] → 음수 허용 (부채 기록) 또는 [취소]
```

#### D. 재고 자동 차감
```
1. 요리 완료 후 [사용량 입력 완료]
2. 메인 화면 복귀 및 재고 리스트 새로고침
3. 각 재료의 수량 감소 확인
   - 예: 김치 1.0 포기 → 0.75 포기
```

### 단계 3: 커스텀 요리 추가

#### A. 새 레시피 추가
```
1. 레시피 선택 다이얼로그에서 [+추가] 버튼 탭
2. RecipeUpsertDialog 표시 확인
3. 요리명: "내 맞춤 불고기"
   카테고리: "Korean"
   재료1: 소고기, 300g
   재료2: 양파, 1개
4. [저장] → recipes.json에 저장 확인
```

#### B. 기존 레시피 편집
```
1. "김치찌개"의 [편집] 아이콘 탭
2. 기존 정보 미리 채워짐 확인
3. 수량 수정: 돼지고기 200g → 250g
4. [저장] → 변경 사항 적용 확인
5. 다시 "김치찌개" 선택 → 수정된 내용 확인
```

### 단계 4: 통합 시나리오

#### "주말 밑반찬 준비" 시뮬레이션
```
1. 재고 추가:
   - 김치 2포기, 돼지고기 500g, 계란 10개, 대파 3대, ...

2. 요리 선택:
   - "김치찌개" 선택
   - 사용량: 기본값 사용
   - 재고 차감: 김치 1.75포기, 돼지고기 300g, ...

3. 다시 요리 선택:
   - "계란말이" 선택
   - 사용량: 기본값 사용
   - 재고 차감: 계란 6개, 대파 0.2대, ...

4. 최종 재고 확인:
   - 김치: 0.25포기 남음 (주의: 2일 이내 사용)
   - 돼지고기: 0 (사용함)
   - 계란: 4개 남음
   - 대파: 0.8대 남음
```

### 단계 5: 에지 케이스

- [ ] 재료가 재고에 없을 때 → 폼에 빈 칸으로 표시되는지 확인
- [ ] 검색 결과가 없을 때 → "검색 결과가 없습니다." 메시지 표시 확인
- [ ] 빈 요리명으로 추가 시도 → 저장 불가 또는 경고 표시
- [ ] 100+ 커스텀 레시피 추가 → 성능 저하 없는지 확인
- [ ] 재고 음수 차감 후 재고 추가 입력 → 누적 합계 정확한지 확인

---

## 📚 관련 문서 및 파일

- [Recipe 모델](lib/models/recipe.dart)
- [RecipeService](lib/services/recipe_service.dart)
- [FoodExpiryMainScreen (요리 선택 포함)](lib/screens/food_expiry_main_screen.dart#L30-L300)
- [FoodExpiryService](lib/services/food_expiry_service.dart)
- [1스탬프 루틴 가이드](UTILS_FEATURE_CALENDAR.md)
- [WMS(식품 재고관리) 가이드](docs/INVENTORY_MANAGEMENT_GUIDE.md)

---

## 🚀 다음 단계

1. ✅ **요리단계 코드 검증** - `flutter analyze` 통과 확인
2. **실제 시나리오 테스트** - 위의 검증 항목 수행
3. **UI/UX 개선 (선택)** - 요리 이미지 추가, 조리 난이도 표시 등
4. **성능 최적화** - 100+ 레시피 로드 시간 개선

---

## 📈 향후 확장 가능성

- 🔮 **요리 이미지:** 각 레시피에 대표 이미지 추가
- 🔮 **조리 시간 정보:** 준비시간, 조리시간 표시
- 🔮 **난이도 표시:** 초급/중급/고급
- 🔮 **영양 정보 연동:** 요리 선택 시 영양 정보 자동 입력
- 🔮 **음성 레시피 검색:** "알렉사, 돼지고기 요리 추천해줄래?"
- 🔮 **요리별 비용 계산:** 재료비 자동 계산
- 🔮 **조리 가이드:** 단계별 조리 방법 표시 (텍스트/영상)
- 🔮 **개인 요리 최적화:** 자주 하는 요리 제시, 즐겨찾기

---

**작성:** GitHub Copilot  
**마지막 검토:** 2026-01-04
