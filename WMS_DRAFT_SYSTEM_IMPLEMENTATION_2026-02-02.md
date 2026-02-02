# WMS Draft 시스템 구현 기록

**작성일**: 2026-02-02  
**목적**: 재고관리 임시저장 시스템 구축 (1단계)

---

## 📋 작업 개요

ShoppingPointsDraftEntry 패턴을 참고하여 **WMS 재고 입력 임시저장** 시스템 구축.
점진적 고도화를 위한 기반 인프라 완성.

---

## 🎯 구현 목표

1. 재고 입력 중 종료 시 자동 저장
2. 장바구니 자동등록 체크 항목 임시 저장
3. 나중에 일괄 등록 기능
4. 생활용품/식료품/유통기한 관리 확장 가능한 구조

---

## ✅ 구현 완료 항목

### 1. WmsInventoryDraftEntry 모델
**파일**: `lib/models/wms_inventory_draft_entry.dart` (191 lines)

```dart
class WmsInventoryDraftEntry {
  final String id;              // 고유 ID
  final DateTime at;            // 임시저장 시각
  final String name;            // 상품명 (필수)
  final double? currentStock;   // 현재 재고량
  final String? unit;           // 단위
  final String? category;       // 카테고리
  final String? location;       // 보관 위치
  final DateTime? expiryDate;   // 유통기한
  final String? source;         // 입력 경로 추적
  // ... 기타 필드
}
```

**주요 기능**:
- JSON 직렬화/역직렬화
- `quick()`: 간단한 재고 입력용 생성자
- `fromShoppingCart()`: 장바구니 자동등록용 생성자
- `copyWith()`: 수정 편의 메서드

---

### 2. UserPrefService Draft 메서드 추가
**파일**: `lib/services/user_pref_service.dart`

**추가 메서드**:
- `getWmsInventoryDrafts()`: Draft 목록 조회
- `setWmsInventoryDrafts()`: Draft 목록 저장
- `addWmsInventoryDraft()`: Draft 추가 (최대 30개, 중복 제거)
- `updateWmsInventoryDraft()`: Draft 수정
- `removeWmsInventoryDraft()`: Draft 삭제
- `clearAllWmsInventoryDrafts()`: 전체 삭제

**저장 위치**: SharedPreferences  
**키**: `wms_inventory_drafts_v1` (계정별)

---

### 3. WmsDraftManager 클래스
**파일**: `lib/utils/wms_data_gateway.dart` (181 lines 추가)

**주요 메서드**:

#### 기본 CRUD
```dart
// 조회
Future<List<WmsInventoryDraftEntry>> getDrafts({
  required String accountName,
})

// 추가
Future<WmsOperationResult<WmsInventoryDraftEntry>> addDraft({
  required String accountName,
  required WmsInventoryDraftEntry draft,
})

// 수정
Future<WmsOperationResult<WmsInventoryDraftEntry>> updateDraft({
  required String accountName,
  required WmsInventoryDraftEntry draft,
})

// 삭제
Future<WmsOperationResult<void>> removeDraft({
  required String accountName,
  required String draftId,
})
```

#### Draft → 재고 변환
```dart
// 단일 변환
Future<WmsOperationResult<ConsumableInventoryItem>> convertToInventory({
  required String accountName,
  required WmsInventoryDraftEntry draft,
})

// 일괄 변환
Future<List<WmsOperationResult<ConsumableInventoryItem>>> 
convertMultipleDrafts({
  required String accountName,
  required List<WmsInventoryDraftEntry> drafts,
})
```

**특징**:
- WmsInventoryGateway와 통합
- 변환 성공 시 Draft 자동 삭제
- 로깅: `[WMS Draft][READ/WRITE/ERROR]`

---

### 4. WmsInputSource enum 확장
**파일**: `lib/utils/wms_data_gateway.dart`

**기존**:
```dart
enum WmsInputSource {
  manual,
  quickUse,
  shoppingCart,
  voiceCommand,
  autoSync,
}
```

**추가**:
```dart
enum WmsInputSource {
  // ... 기존 항목
  draftRestore,  // 임시저장 복원
}
```

---

## 🔄 데이터 흐름

### 1. 임시저장 생성
```
재고 입력 화면
  ↓
사용자 입력 (상품명, 수량 등)
  ↓
onChanged / 화면 종료 시
  ↓
WmsInventoryDraftEntry 생성
  ↓
WmsDraftManager.addDraft()
  ↓
UserPrefService.addWmsInventoryDraft()
  ↓
SharedPreferences 저장
```

### 2. 임시저장 → 재고 변환
```
Draft 목록 표시
  ↓
사용자 "일괄 등록" 선택
  ↓
WmsDraftManager.convertToInventory()
  ↓
WmsInventoryInput 생성
  ↓
WmsInventoryGateway.addItem()
  ↓
ConsumableInventoryService.addItem()
  ↓
Draft 자동 삭제
```

### 3. 장바구니 자동등록 임시저장
```
장바구니 화면
  ↓
"재고 자동등록" 체크
  ↓
WmsInventoryDraftEntry.fromShoppingCart()
  ↓
WmsDraftManager.addDraft()
  ↓
나중에 일괄 변환
```

---

## 📊 코드 통계

| 항목 | 수량 |
|------|------|
| **새 파일** | 1개 |
| **수정 파일** | 2개 |
| **총 추가 라인** | ~370 lines |
| **컴파일 에러** | 0개 ✅ |

### 파일별 변경사항

1. **lib/models/wms_inventory_draft_entry.dart** (신규)
   - 191 lines
   - Draft 데이터 모델

2. **lib/services/user_pref_service.dart** (수정)
   - Import 추가: `wms_inventory_draft_entry.dart`
   - 6개 메서드 추가
   - ~90 lines 추가

3. **lib/utils/wms_data_gateway.dart** (수정)
   - Import 추가: `wms_inventory_draft_entry.dart`, `user_pref_service.dart`
   - WmsDraftManager 클래스 추가
   - WmsInputSource.draftRestore 추가
   - ~190 lines 추가

---

## 🎯 활용 시나리오

### 시나리오 1: 재고 입력 중 앱 종료
```dart
// 1. 입력 중 자동 저장
final draft = WmsInventoryDraftEntry(
  id: 'wms_draft_${DateTime.now().microsecondsSinceEpoch}',
  at: DateTime.now(),
  name: '두루마리 휴지',
  currentStock: 30,
  unit: '개',
  source: 'manual',
);

await WmsDraftManager.instance.addDraft(
  accountName: accountName,
  draft: draft,
);

// 2. 다음 진입 시
final drafts = await WmsDraftManager.instance.getDrafts(
  accountName: accountName,
);

if (drafts.isNotEmpty) {
  // "이전 입력 이어하기?" 다이얼로그 표시
}
```

### 시나리오 2: 장바구니 자동등록
```dart
// 1. 장바구니에서 "재고 등록" 체크
for (final item in checkedItems) {
  final draft = WmsInventoryDraftEntry.fromShoppingCart(
    id: 'cart_${item.id}',
    name: item.name,
    quantity: item.quantity,
    unit: item.unit,
    category: '식료품',
  );
  
  await WmsDraftManager.instance.addDraft(
    accountName: accountName,
    draft: draft,
  );
}

// 2. 나중에 일괄 등록
final results = await WmsDraftManager.instance.convertMultipleDrafts(
  accountName: accountName,
  drafts: drafts,
);

final successCount = results.where((r) => r.success).length;
print('$successCount/${drafts.length}개 등록 완료');
```

### 시나리오 3: Draft 수정
```dart
// 1. Draft 조회
final drafts = await WmsDraftManager.instance.getDrafts(
  accountName: accountName,
);

// 2. 수정
final updated = drafts[0].copyWith(
  currentStock: 50,
  location: '욕실',
);

await WmsDraftManager.instance.updateDraft(
  accountName: accountName,
  draft: updated,
);
```

---

## 🔧 기술 세부사항

### 데이터 저장
- **저장소**: SharedPreferences
- **키**: `{accountName}_wms_inventory_drafts_v1`
- **형식**: JSON Array
- **최대 항목**: 30개 (자동 trim)
- **중복 처리**: ID 기반 중복 제거

### 로깅
```
[WMS Draft][READ] Loaded 5 WMS drafts
[WMS Draft][WRITE] Added draft: 두루마리 휴지 (source: manual)
[WMS Draft][WRITE] Converted draft to inventory: 두루마리 휴지
[WMS Draft][ERROR] Get drafts failed: ...
```

### 에러 처리
- try-catch로 안전하게 감싸기
- 실패 시 빈 목록 반환 (조회)
- WmsOperationResult로 성공/실패 명확히 전달

---

## 🚀 향후 고도화 계획

### 2단계: UI 통합
- [ ] 재고 관리 화면에 Draft 목록 표시
- [ ] "임시저장 복원" 버튼 추가
- [ ] Draft 개수 배지 표시
- [ ] 일괄 등록 버튼

### 3단계: 자동화
- [ ] 입력 중 onChanged 이벤트로 자동 Draft 저장
- [ ] 화면 종료 시 자동 Draft 생성
- [ ] 디바운스 처리 (너무 자주 저장 방지)

### 4단계: 만료 처리
- [ ] 7일 이상 된 Draft 자동 삭제
- [ ] 만료 예정 Draft 알림
- [ ] "오래된 임시저장 정리" 기능

### 5단계: 확장
- [ ] FoodExpiryDraftEntry 모델 추가
- [ ] HouseholdConsumableDraftEntry 모델 추가
- [ ] WmsUnifiedDraft (통합 Draft) 고려
- [ ] Draft 동기화 (계정 간)

### 6단계: 분석
- [ ] Draft 생성/변환 통계
- [ ] 가장 많이 임시저장하는 품목 분석
- [ ] 변환율 추적 (저장 → 실제 등록 비율)

---

## ⚠️ 주의사항

### 1. 데이터 정합성
- Draft는 어디까지나 **임시저장**
- 실제 재고와 동기화되지 않음
- 변환 시 중복 체크 필수

### 2. 저장 공간
- Draft 최대 30개 제한
- 오래된 Draft 수동 삭제 필요 (현재)
- 향후 자동 만료 처리 구현 예정

### 3. 성능
- Draft 조회는 매번 SharedPreferences 접근
- 캐싱 없음 (빈번한 접근 시 고려 필요)

### 4. 에러 처리
- Draft 저장 실패 시 사용자에게 알림 필요
- 변환 실패 시 Draft 유지 (재시도 가능)

---

## 📝 참고 자료

### 기존 패턴
- **ShoppingPointsDraftEntry**: 포인트 임시저장
  - 위치: `lib/models/shopping_points_draft_entry.dart`
  - 패턴: SharedPreferences + JSON
  - 최대: 60개

### 관련 문서
- **WMS_DATA_GATEWAY_DESIGN.md**: Gateway 패턴 설계
- **DATA_STRUCTURE_REPORT_2026-02-02.md**: 데이터 구조 분석
- **WMS Gateway 사용 예제**: `lib/utils/wms_gateway_usage_example.dart`

---

## 🎉 결론

**WMS Draft 시스템 1단계 성공적으로 완료!**

- ✅ 기본 인프라 구축 완료
- ✅ 모든 컴파일 에러 해결
- ✅ flutter analyze 통과
- ✅ 확장 가능한 구조 설계

점진적으로 UI 통합 → 자동화 → 고도화 단계로 발전 가능.

---

**작성자**: AI Code Assistant  
**검증 상태**: ✅ flutter analyze 통과  
**커밋 준비**: 완료  
**최종 업데이트**: 2026-02-02
