# 식료품/생활용품 및 재고관리 데이터 구조 보고서

**작성일**: 2026-02-02  
**목적**: 식료품/생활용품, 재고관리(Inventory), 유통기한 관리 데이터 구조 분석

---

## 🔷 1. 생활용품 기본 항목 (HouseholdConsumableItem)

**파일**: `lib/utils/household_consumables_utils.dart`

**용도**: 10개 기본 생활용품 템플릿 정의 (UI 표시용)

### 데이터 구조

```dart
class HouseholdConsumableItem {
  final String name;              // "두루마리 휴지"
  final String mainCategory;      // "생활용품비"
  final String subCategory;       // "화장지/일회용품"
  final String? detailCategory;   // "두루마리 휴지"
  final IconData icon;            // 아이콘
  final double defaultBundleSize; // 기본 묶음 크기 (30.0)
}
```

### 특징
- 정적 데이터 (코드에 하드코딩)
- 거래 입력 시 초기값 제공
- UI 그리드 표시용 템플릿
- 10개 항목: 두루마리 휴지, 미용티슈, 키친타월, 냅킨, 비누, 치약, 샴푸, 주방세제, 세탁세제, 물티슈

---

## 🔷 2. 재고 관리 (ConsumableInventoryItem)

**파일**: `lib/models/consumable_inventory_item.dart`

**용도**: 식료품/생활용품의 실제 재고 추적

### 데이터 구조

```dart
class ConsumableInventoryItem {
  // 기본 정보
  final String id;                // 고유 ID (예: "ci_1234567890")
  final String name;              // 상품명
  final String category;          // "생활용품" 또는 "식료품"
  final String? detailCategory;   // 상세 분류
  
  // 재고 정보
  final double currentStock;      // 현재 재고량
  final String unit;              // 단위 (개, 병, 묶음, 팩 등)
  final double threshold;         // 알림 임계값 (재고 부족 알림)
  final double bundleSize;        // 묶음 크기 (구입 단위)
  
  // 위치 및 시간
  final String location;          // 보관 위치 (욕실, 주방, 거실, 침실, 창고, 기타)
  final DateTime createdAt;       // 생성일 (FIFO 정렬용)
  final DateTime lastUpdated;     // 최종 수정일
  
  // 유통기한 및 건강
  final DateTime? expiryDate;     // 유통기한 (옵션)
  final List<String> healthTags;  // 건강 태그 (탄수화물, 당류, 주류 등)
  
  // 사용 이력
  final List<ConsumableUsageRecord> usageHistory; // 사용 기록
}

class ConsumableUsageRecord {
  final DateTime timestamp;       // 사용 시각
  final double amount;            // 사용량
}
```

### 주요 기능

**서비스**: `ConsumableInventoryService`
- `load()`: 저장소에서 재고 목록 로드
- `addItem()`: 새 재고 항목 추가
- `updateItem()`: 재고 항목 수정
- `deleteItem()`: 재고 항목 삭제
- `useItem()`: 재고 사용 기록 및 차감

**저장소**: `AppRepositories.consumableInventory`

### 위치 옵션
```dart
static const List<String> locationOptions = [
  '욕실',
  '주방',
  '거실',
  '침실',
  '창고',
  '기타',
];
```

### 특징
- FIFO (First In First Out) 정렬: `createdAt` 기준
- 사용 이력 최대 60개 보관 (저장 공간 절약)
- 유통기한 옵션: 필요한 경우만 입력
- 건강 태그로 건강 주의 알림 가능

---

## 🔷 3. 유통기한 관리 (FoodExpiryItem)

**파일**: `lib/models/food_expiry_item.dart`

**용도**: 식료품 유통기한 전용 관리 (더 상세한 식품 정보)

### 데이터 구조

```dart
class FoodExpiryItem {
  // 기본 정보
  final String id;                // 고유 ID
  final String name;              // 식품명
  final String category;          // 카테고리 (채소, 육류, 유제품 등)
  final String location;          // 보관 위치 (냉장, 냉동, 실온)
  
  // 날짜 정보
  final DateTime purchaseDate;    // 구입일 (필수)
  final DateTime expiryDate;      // 유통기한 (필수)
  final DateTime createdAt;       // 등록일
  
  // 수량 및 가격
  final double quantity;          // 수량
  final String unit;              // 단위
  final double price;             // 가격
  
  // 추가 정보
  final String memo;              // 메모
  final String supplier;          // 구입처
  final List<String> healthTags;  // 건강 태그
}
```

### 주요 메서드

```dart
int daysLeft(DateTime now) {
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
  return end.difference(start).inDays;
}
```

### 주요 기능

**서비스**: `FoodExpiryService`
- `load()`: 저장소에서 식료품 목록 로드
- `addItem()`: 새 식료품 추가
- `updateItem()`: 식료품 정보 수정
- `deleteById()`: 식료품 삭제

**저장소**: `AppRepositories.foodExpiry`

### 특징
- 유통기한 필수 입력
- 구입일, 가격, 구입처 등 상세 정보 관리
- D-day 계산 기능 내장
- 유통기한 임박/경과 알림용

---

## 🔗 데이터 구조 관계도

```
┌─────────────────────────────────────────┐
│  HouseholdConsumableItem (템플릿)       │
│  - 10개 기본 생활용품 정의               │
│  - UI 표시 및 초기값 제공                │
└──────────────┬──────────────────────────┘
               │ 참조
               ↓
┌──────────────────────────────────────────┐
│  ConsumableInventoryItem (재고 관리)      │
│  - 식료품 + 생활용품 통합 재고            │
│  - 현재고, 사용 이력, 위치 관리           │
│  - 유통기한 옵션 (expiryDate?)           │
└──────────────┬───────────────────────────┘
               │
               │ expiryDate 있는 경우
               ↓
┌──────────────────────────────────────────┐
│  FoodExpiryItem (유통기한 전용)           │
│  - 식료품 전용 상세 관리                  │
│  - 유통기한 필수                         │
│  - 구입일, 가격, 구입처 등 상세 정보      │
└──────────────────────────────────────────┘
```

---

## 📋 주요 차이점 비교

| 항목 | ConsumableInventoryItem | FoodExpiryItem |
|------|------------------------|----------------|
| **대상** | 식료품 + 생활용품 | 식료품 전용 |
| **유통기한** | 옵션 (expiryDate?) | 필수 (expiryDate) |
| **재고 추적** | ✅ 현재고, 사용 이력 | ❌ |
| **가격/구입처** | ❌ | ✅ |
| **위치** | 보관 위치 (욕실, 주방) | 보관 방식 (냉장, 냉동) |
| **사용 목적** | 재고 관리 중심 | 유통기한 알림 중심 |
| **FIFO 정렬** | ✅ createdAt 기준 | ✅ createdAt 기준 |
| **건강 태그** | ✅ | ✅ |

---

## 🔄 데이터 흐름

### 1. 생활용품 입력 흐름
```
사용자 → 생활용품 화면 선택
       → HouseholdConsumableItem (템플릿) 선택
       → 거래 입력 화면 (자동 채우기)
       → Transaction 생성 (지출 기록)
       → (옵션) ConsumableInventoryItem 생성 (재고 등록)
```

### 2. 재고 관리 흐름
```
재고 등록 → ConsumableInventoryItem 생성
         → 사용 기록 (useItem)
         → usageHistory 누적
         → currentStock 자동 차감
         → threshold 도달 시 알림
```

### 3. 유통기한 관리 흐름
```
식료품 등록 → FoodExpiryItem 생성
           → expiryDate 필수 입력
           → daysLeft() 계산
           → D-2, D-0, 경과 알림
```

### 4. 통합 시나리오
```
생활용품 구입 → Transaction (거래 기록)
             → ConsumableInventoryItem (재고 등록)
             → expiryDate 입력 (옵션)
             → 유통기한 필터링 표시
             
식료품 구입   → Transaction (거래 기록)
             → FoodExpiryItem (유통기한 전용)
             → ConsumableInventoryItem (재고 등록, 옵션)
```

---

## 📍 저장소 위치

### ConsumableInventoryItem
- **저장소**: `AppRepositories.consumableInventory`
- **저장 방식**: SharedPreferences 또는 DB
- **키 형식**: 계정별 독립 저장

### FoodExpiryItem
- **저장소**: `AppRepositories.foodExpiry`
- **저장 방식**: SharedPreferences 또는 DB
- **키 형식**: 계정별 독립 저장

### 특징
- 각 데이터 모델은 독립적으로 저장/관리
- 계정별로 분리된 저장 공간 사용
- JSON 직렬화/역직렬화 지원

---

## 🎯 사용 사례

### 사례 1: 생활용품만 관리
```
1. 생활용품 화면에서 "두루마리 휴지" 선택
2. 거래 입력 (30개, 12,000원)
3. 재고 등록 (ConsumableInventoryItem)
   - currentStock: 30개
   - threshold: 5개
   - location: 욕실
4. 사용 시마다 -1개 차감
5. 5개 이하 시 쇼핑 카트 추가 알림
```

### 사례 2: 식료품 유통기한 관리
```
1. 유통기한 관리 화면에서 "우유" 등록
2. FoodExpiryItem 생성
   - expiryDate: 2026-02-10
   - purchaseDate: 2026-02-02
3. 매일 daysLeft() 계산
4. D-2: "우유 유통기한 2일 남음" 알림
5. D-0: "우유 오늘 유통기한 만료" 알림
```

### 사례 3: 통합 관리 (식료품 + 재고)
```
1. 유통기한 관리 화면에서 "계란" 등록
2. FoodExpiryItem 생성 (유통기한 관리)
3. ConsumableInventoryItem 생성 (재고 관리)
   - expiryDate 입력
4. 유통기한 필터링: expiryDate가 있는 항목만 표시
5. 재고 사용 시 usageHistory 기록
6. 유통기한 임박 시 우선 소비 권장
```

---

## 🔍 필터링 로직

### 유통기한이 있는 재고만 표시
```dart
final expiryItems = allItems
    .where((item) => item.expiryDate != null)
    .toList();
```

### 위치별 필터링
```dart
final filteredItems = location == '전체'
    ? items
    : items.where((e) => e.location == location).toList();
```

### 임계값 이하 재고 필터링
```dart
final lowStockItems = items
    .where((item) => item.currentStock <= item.threshold)
    .toList();
```

---

## 📊 통계 및 분석 가능 데이터

### ConsumableInventoryItem 기반
- 월별 소비량 통계 (usageHistory)
- 평균 소비 주기 계산
- 위치별 재고 현황
- 카테고리별 지출 분석
- 재고 회전율 분석

### FoodExpiryItem 기반
- 유통기한 임박 품목 목록
- 폐기율 통계 (경과된 품목)
- 카테고리별 유통기한 패턴
- 구입처별 가격 비교
- 월별 식료품 지출 추이

---

## ⚠️ 주의사항

### 1. 데이터 중복
- `ConsumableInventoryItem`과 `FoodExpiryItem`은 독립적
- 같은 식료품을 양쪽에 등록 가능 (중복 허용)
- 사용자가 선택하여 관리 방식 결정

### 2. 유통기한 필드
- `ConsumableInventoryItem.expiryDate`: 옵션 (null 가능)
- `FoodExpiryItem.expiryDate`: 필수 (null 불가)

### 3. 사용 이력
- `ConsumableInventoryItem`: usageHistory 최대 60개 보관
- 오래된 기록 자동 삭제 (저장 공간 절약)

### 4. 건강 태그
- 양쪽 모델 모두 healthTags 지원
- 건강 주의 알림 기능과 연동

---

## 🚀 향후 확장 가능성

### 1. 통합 검색
- ConsumableInventoryItem + FoodExpiryItem 통합 검색
- 이름, 카테고리, 위치 등 통합 필터링

### 2. 자동 재고 업데이트
- Transaction 생성 시 자동으로 ConsumableInventoryItem 업데이트
- 구입 거래 → 재고 자동 증가

### 3. AI 기반 소비 예측
- usageHistory 기반 소비 패턴 학습
- 재고 소진 예상 일자 자동 계산
- 최적 구입 시점 추천

### 4. 레시피 연동
- FoodExpiryItem → 레시피 추천
- 유통기한 임박 식재료 우선 사용 레시피

---

## 📝 결론

### 데이터 구조 설계 장점
1. **유연성**: 재고 관리와 유통기한 관리 독립 운영
2. **확장성**: 필요에 따라 추가 필드 쉽게 확장
3. **효율성**: FIFO 정렬, 사용 이력 제한 등 최적화
4. **사용자 선택**: 필요한 기능만 선택적 사용 가능

### 개선 권장사항
1. 데이터 중복 최소화 방안 검토
2. 통합 검색/필터링 기능 추가
3. 자동 재고 업데이트 로직 구현
4. 유통기한 알림 고도화

---

**작성자**: AI Code Assistant  
**문서 상태**: ✅ 완료  
**최종 업데이트**: 2026-02-02
