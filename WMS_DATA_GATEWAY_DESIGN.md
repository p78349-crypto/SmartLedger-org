# WMS 데이터 Gateway 설계 문서

**작성일**: 2026-02-02  
**목적**: WMS 입력 일원화를 위한 데이터 경유지(Gateway) 패턴 설계

---

## 🎯 설계 목표

### 1. 데이터 흐름 중앙화
```
기존: UI → Service → Repository
변경: UI → Gateway → Service → Repository
```

### 2. Gateway의 역할
- ✅ **유효성 검사**: 입력 데이터 자동 검증
- ✅ **중복 체크**: 동일 품목 자동 감지
- ✅ **캐싱**: 30초 TTL 캐시로 성능 최적화
- ✅ **로깅**: 모든 입출력 추적
- ✅ **에러 처리**: 일관된 결과 반환
- ✅ **소스 추적**: 입력 경로 기록

---

## 📦 파일 구조

### 1. wms_data_gateway.dart
**위치**: `lib/utils/wms_data_gateway.dart`

**포함 내용**:
- `WmsInventoryGateway`: 재고 관리 Gateway (싱글톤)
- `WmsExpiryGateway`: 유통기한 관리 Gateway (싱글톤)
- `WmsInventoryInput`: 재고 입력 데이터 클래스
- `WmsExpiryInput`: 유통기한 입력 데이터 클래스
- `WmsOperationResult<T>`: 작업 결과 래퍼
- `WmsValidationResult`: 유효성 검사 결과

### 2. wms_unified_gateway.dart
**위치**: `lib/utils/wms_unified_gateway.dart`

**포함 내용**:
- `WmsUnifiedGateway`: 통합 Gateway (싱글톤)
- `WmsUnifiedSearchResult`: 통합 검색 결과
- `WmsAlertSummary`: 알림 요약 (재고 부족 + 유통기한 임박)

### 3. wms_gateway_usage_example.dart
**위치**: `lib/utils/wms_gateway_usage_example.dart`

**포함 내용**:
- 6가지 사용 예시
- 기존 코드 → Gateway 마이그레이션 가이드

---

## 🔄 데이터 흐름

### 기존 방식 (문제점)
```
[consumable_inventory_screen.dart]
  ↓ 직접 호출
ConsumableInventoryService.addItem()
  ↓
Repository.saveItems()
  
문제점:
- 유효성 검사 없음
- 중복 체크 없음
- 에러 처리 불일치
- 캐시 없음 (매번 로드)
```

### Gateway 방식 (개선)
```
[consumable_inventory_screen.dart]
  ↓
WmsInventoryInput (데이터 클래스)
  ↓
WmsInventoryGateway.addItem()
  ├─ validate() ✅ 유효성 검사
  ├─ findByName() ✅ 중복 체크
  ├─ Service.addItem() ✅ 실제 저장
  ├─ _invalidateCache() ✅ 캐시 갱신
  └─ _logWrite() ✅ 로깅
  ↓
WmsOperationResult<T> (결과 반환)

장점:
- 자동 검증
- 중복 방지
- 일관된 에러 처리
- 30초 캐싱 (성능 향상)
- 소스 추적 가능
```

---

## 📋 주요 클래스

### WmsInventoryGateway

#### 조회 메서드
```dart
// 전체 목록 (캐싱 적용)
Future<List<ConsumableInventoryItem>> getItems({bool forceRefresh})

// 이름으로 검색 (중복 체크용)
Future<ConsumableInventoryItem?> findByName(String name)

// ID로 검색
Future<ConsumableInventoryItem?> findById(String id)

// 위치별 필터링
Future<List<ConsumableInventoryItem>> getItemsByLocation(String location)

// 재고 부족 아이템
Future<List<ConsumableInventoryItem>> getLowStockItems()
```

#### 변경 메서드
```dart
// 아이템 추가 (유효성 검사 + 중복 체크)
Future<WmsOperationResult<ConsumableInventoryItem>> addItem({
  required WmsInventoryInput input,
  WmsInputSource source,
})

// 아이템 수정
Future<WmsOperationResult<ConsumableInventoryItem>> updateItem({
  required ConsumableInventoryItem item,
})

// 아이템 삭제
Future<WmsOperationResult<void>> deleteItem(String id)

// 아이템 사용
Future<WmsOperationResult<void>> useItem({
  required String id,
  required double amount,
})

// 강제 리로드 (캐시 무효화)
Future<void> reload()
```

### WmsInventoryInput

#### Factory 생성자
```dart
// 빠른 입력 (품목명만)
WmsInventoryInput.quick({required String name})

// 전체 정보 입력
WmsInventoryInput.full({
  required String name,
  required double currentStock,
  required String unit,
  required double threshold,
  // ...
})
```

#### 유효성 검사
```dart
WmsValidationResult validate() {
  // ✅ 품목명 빈 문자열 체크
  // ✅ 재고 음수 체크
  // ✅ 임계값 음수 체크
  // ✅ 묶음 크기 0 이하 체크
  // ✅ 위치 유효성 체크
}
```

### WmsOperationResult<T>

#### 결과 타입
```dart
enum WmsOperationType {
  success,   // 성공
  failure,   // 실패
  duplicate, // 중복
  warning,   // 경고 (성공이지만 주의 필요)
}
```

#### Factory 생성자
```dart
WmsOperationResult.success(T? data)
WmsOperationResult.failure(String message)
WmsOperationResult.duplicate(T existingData)
WmsOperationResult.warning(T? data, String message)
```

### WmsUnifiedGateway

#### 통합 기능
```dart
// 통합 검색 (재고 + 유통기한)
Future<WmsUnifiedSearchResult> search(String query)

// 알림 요약 (재고 부족 + 유통기한 임박/경과)
Future<WmsAlertSummary> getAlerts()

// 전체 리로드
Future<void> reloadAll()
```

---

## 🔧 캐싱 전략

### 캐시 정책
```dart
static const _cacheDuration = Duration(seconds: 30);

// 캐시 히트 조건
if (!forceRefresh &&
    _cachedItems != null &&
    _lastCacheTime != null &&
    now.difference(_lastCacheTime!) < _cacheDuration) {
  return _cachedItems!; // 캐시 반환
}
```

### 캐시 무효화 시점
- ✅ addItem() 호출 후
- ✅ updateItem() 호출 후
- ✅ deleteItem() 호출 후
- ✅ useItem() 호출 후
- ✅ reload() 명시적 호출

### 성능 효과
```
기존: 매번 SharedPreferences 읽기 (느림)
Gateway: 30초 내 재사용 (빠름)

예상 성능 향상:
- 목록 조회: ~500ms → ~5ms (100배)
- 검색: ~500ms × N → ~5ms (캐시 히트 시)
```

---

## 📊 로깅 전략

### 로그 레벨
```dart
_logRead()   // [WMS Gateway][READ] 조회 작업
_logWrite()  // [WMS Gateway][WRITE] 변경 작업
_logError()  // [WMS Gateway][ERROR] 에러 발생
```

### 로그 예시
```
[WMS Gateway][READ] Loaded 42 inventory items
[WMS Gateway][WRITE] Added item: 두루마리 휴지 (source: manual)
[WMS Gateway][WRITE] Used item: ci_123456 (amount: 1.0)
[WMS Gateway][ERROR] Add item failed: Validation failed
```

### 분석 활용
- 입력 소스별 통계 (manual, quickUse, shoppingCart 등)
- 에러 발생 빈도
- 캐시 히트율
- 성능 병목 지점

---

## 🚀 마이그레이션 가이드

### Phase 1: Gateway 파일 생성 (✅ 현재 단계)
```
1. wms_data_gateway.dart 생성
2. wms_unified_gateway.dart 생성
3. wms_gateway_usage_example.dart 생성
4. flutter analyze 검증
```

### Phase 2: 첫 번째 입력 지점 변경
```
대상: consumable_inventory_screen.dart

기존:
  await ConsumableInventoryService.instance.addItem(
    name: name,
    currentStock: stock,
    // ...
  );

변경:
  final input = WmsInventoryInput.full(
    name: name,
    currentStock: stock,
    // ...
  );
  
  final result = await WmsInventoryGateway.instance.addItem(
    input: input,
    source: WmsInputSource.manual,
  );
  
  if (result.success) {
    // 성공 처리
  } else if (result.type == WmsOperationType.duplicate) {
    // 중복 처리
  } else {
    // 실패 처리
  }
```

### Phase 3: 나머지 입력 지점 변경
```
1. quick_stock_use_screen.dart
   → WmsInventoryInput.quick() 사용
   → source: WmsInputSource.quickUse

2. shopping_cart_quick_transaction_screen.dart
   → source: WmsInputSource.shoppingCart

3. 기타 입력 지점 (있다면)
```

### Phase 4: 조회 최적화
```
기존:
  ConsumableInventoryService.instance.items.value

변경:
  await WmsInventoryGateway.instance.getItems()
  // 캐싱 자동 적용
```

### Phase 5: 기존 메서드 deprecate
```dart
@Deprecated('Use WmsInventoryGateway.instance.addItem() instead')
Future<void> addItem(...) async {
  // 경고 로깅
  debugPrint('⚠️ Deprecated method called: addItem()');
  
  // 기존 로직 유지 (호환성)
}
```

---

## ✅ 유효성 검사 규칙

### ConsumableInventoryItem
```dart
✅ name: trim() 후 빈 문자열 체크
✅ currentStock: 0 이상
✅ threshold: 0 이상
✅ bundleSize: 0 초과
✅ location: locationOptions 범위 내
✅ healthTags: 빈 문자열 필터링
```

### FoodExpiryItem
```dart
✅ name: trim() 후 빈 문자열 체크
✅ purchaseDate ≤ expiryDate
✅ quantity: 0 초과
✅ price: 0 이상
✅ healthTags: 빈 문자열 필터링
```

---

## 🔒 안정성 보장

### 1. 타입 안전성
```dart
// ✅ 강타입 결과
WmsOperationResult<ConsumableInventoryItem> result = ...;

// ❌ 런타임 에러 방지
if (result.success) {
  final item = result.data!; // non-null 보장
}
```

### 2. 불변성
```dart
// ✅ 캐시 데이터 불변
_cachedItems = List.unmodifiable(items);

// ❌ 외부 수정 방지
final items = await gateway.getItems();
items.add(...); // 컴파일 에러
```

### 3. 에러 복구
```dart
try {
  await gateway.addItem(...);
} catch (e) {
  // ✅ Gateway 내부에서 catch
  return WmsOperationResult.failure(e.toString());
}
```

### 4. 데이터 무결성
```dart
// ✅ 추가 전 중복 체크
final existing = await findByName(name);
if (existing != null) {
  return WmsOperationResult.duplicate(existing);
}
```

---

## 📈 성능 메트릭

### 측정 지표
```dart
// 캐시 히트율
final cacheHits = _cacheHitCount / _totalRequests;

// 평균 응답 시간
final avgResponseTime = _totalTime / _requestCount;

// 에러율
final errorRate = _errorCount / _totalRequests;
```

### 목표 성능
```
캐시 히트율: > 70%
평균 응답 시간: < 50ms (캐시 히트)
에러율: < 1%
```

---

## 🔍 테스트 전략

### 단위 테스트
```dart
test('WmsInventoryInput validation - empty name', () {
  final input = WmsInventoryInput.quick(name: '  ');
  final result = input.validate();
  
  expect(result.isValid, false);
  expect(result.errors, contains('품목명을 입력하세요'));
});

test('WmsInventoryGateway - duplicate check', () async {
  // Given: 기존 아이템 존재
  await gateway.addItem(
    input: WmsInventoryInput.quick(name: '휴지'),
  );
  
  // When: 동일 이름 추가 시도
  final result = await gateway.addItem(
    input: WmsInventoryInput.quick(name: '휴지'),
  );
  
  // Then: 중복 에러
  expect(result.type, WmsOperationType.duplicate);
});
```

### 통합 테스트
```dart
testWidgets('Inventory screen - add via gateway', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // 재고 관리 화면으로 이동
  await tester.tap(find.text('재고 관리'));
  await tester.pumpAndSettle();
  
  // + 버튼 클릭
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  
  // 정보 입력
  await tester.enterText(find.byType(TextField).at(0), '두루마리 휴지');
  await tester.enterText(find.byType(TextField).at(1), '30');
  
  // 저장 (Gateway를 통한 추가)
  await tester.tap(find.text('저장'));
  await tester.pumpAndSettle();
  
  // 검증
  expect(find.text('두루마리 휴지'), findsOneWidget);
});
```

---

## 📝 코드 리뷰 체크리스트

### Gateway 구현
- [ ] 싱글톤 패턴 적용
- [ ] 캐싱 로직 정상 작동
- [ ] 캐시 무효화 시점 적절
- [ ] 유효성 검사 누락 없음
- [ ] 중복 체크 정확
- [ ] 에러 처리 일관성
- [ ] 로깅 충분

### Input 클래스
- [ ] 필수/선택 필드 명확
- [ ] Factory 생성자 편리
- [ ] validate() 로직 완전
- [ ] 불변 객체

### Result 클래스
- [ ] 타입 안전성
- [ ] 모든 케이스 처리
- [ ] 에러 메시지 명확

### 사용 예시
- [ ] 6가지 예시 완전
- [ ] 마이그레이션 가이드 명확
- [ ] 주석 충분

---

## 🎯 향후 확장

### Phase 6: 고급 기능
```dart
// 1. 배치 작업
Future<List<WmsOperationResult>> addItemsBatch(
  List<WmsInventoryInput> inputs,
)

// 2. 트랜잭션
Future<void> executeTransaction(WmsTransaction transaction)

// 3. 옵저버 패턴
void addListener(WmsGatewayListener listener)

// 4. 메트릭 수집
WmsMetrics getMetrics()

// 5. A/B 테스트
void enableExperiment(String experimentId)
```

### Phase 7: Firebase 동기화
```dart
// 로컬 → Firebase 자동 동기화
Future<void> syncToFirebase()

// Firebase → 로컬 병합
Future<void> mergeFromFirebase()

// 충돌 해결 전략
ConflictResolution resolveConflict(
  ConsumableInventoryItem local,
  ConsumableInventoryItem remote,
)
```

---

## 📚 참고 자료

### 디자인 패턴
- **Gateway Pattern**: Martin Fowler's PoEAA
- **Repository Pattern**: DDD (Domain-Driven Design)
- **Data Transfer Object**: DTO Pattern

### Flutter 모범 사례
- **Singleton**: 앱 전체에서 단일 인스턴스
- **Immutable**: 불변 데이터 클래스
- **Future<Result<T>>**: 에러를 값으로 처리

### 성능 최적화
- **Caching**: TTL 기반 메모리 캐시
- **Lazy Loading**: 필요 시에만 로드
- **Batch Operations**: 여러 작업 한 번에

---

## ⚠️ 주의사항

### 1. 캐시 일관성
```dart
// ❌ 직접 Service 호출 시 캐시 불일치
await ConsumableInventoryService.instance.addItem(...);
// Gateway 캐시는 갱신 안 됨!

// ✅ 항상 Gateway를 통해 호출
await WmsInventoryGateway.instance.addItem(...);
```

### 2. 동시성 제어
```dart
// ⚠️ 동시 추가 시 중복 가능
// 해결: Service 레벨에서 Lock 필요 (향후)
```

### 3. 메모리 관리
```dart
// ✅ 캐시 크기 제한
// 현재: 전체 목록 (수십~수백 항목)
// 향후: LRU 캐시 도입 검토
```

---

## 🎉 기대 효과

### 개발 생산성
- ✅ 일관된 API로 학습 비용 감소
- ✅ 유효성 검사 자동화로 버그 감소
- ✅ 명확한 에러 처리로 디버깅 시간 단축

### 사용자 경험
- ✅ 캐싱으로 앱 반응성 향상
- ✅ 중복 방지로 데이터 정확성 증가
- ✅ 일관된 에러 메시지

### 유지보수성
- ✅ 중앙 집중식 로직으로 변경 용이
- ✅ 로깅으로 문제 추적 간편
- ✅ 테스트 작성 용이

---

**작성자**: AI Code Assistant  
**문서 상태**: ✅ 설계 완료  
**다음 단계**: Phase 1 구현 (파일 생성)  
**최종 업데이트**: 2026-02-02
