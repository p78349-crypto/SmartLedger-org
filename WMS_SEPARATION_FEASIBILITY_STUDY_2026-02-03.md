# WMS 기능 독립 분리 검토 보고서

**작성일**: 2026-02-03  
**대상**: SmartLedger의 WMS(Warehouse Management System) / 생활용품 재고 관리 기능  
**핵심 질문**: WMS 기능을 별도 모듈/패키지로 분리하는 것이 좋은가?

---

## 📊 Executive Summary

**권장 의견: 현재로서는 분리가 필요하지 않음 ✅**

WMS 기능은 SmartLedger의 **핵심 재정 관리 체계의 일부**이며, 기존 의존성 구조상 완전한 분리가 어렵습니다. 대신 **계층 구조 강화**와 **모듈 정리**로 충분합니다.

---

## 🔍 현재 WMS 구조 분석

### 1. 관련 파일 목록 (28개)

#### 📁 스크린 (4개)
- `lib/screens/wms_io_screen.dart` - 입출고 (입고/출고 탭)
- `lib/screens/consumable_inventory_screen.dart` - 재고 관리 메인
- `lib/screens/quick_stock_use_screen.dart` - 빠른 차감
- `lib/screens/consumable_inventory_dialogs.dart` - 다이얼로그 모음

#### 📁 서비스 (2개)
- `lib/services/consumable_inventory_service.dart` - 재고 핵심 로직
- `lib/services/stock_depletion_notification_service.dart` - 부족 알림

#### 📁 유틸 (5개)
- `lib/utils/wms_data_gateway.dart` - 데이터 경유지 (**750 lines**)
- `lib/utils/wms_unified_gateway.dart` - 통합 검색
- `lib/utils/quick_stock_use_utils.dart` - 차감 유틸
- `lib/utils/household_consumables_utils.dart` - 생활용품 분류
- `lib/utils/wms_gateway_usage_example.dart` - 사용 예시

#### 📁 모델 (2개)
- `lib/models/consumable_inventory_item.dart` - 재고 아이템
- `lib/models/wms_inventory_draft_entry.dart` - 임시저장

#### 📁 저장소 (2개)
- `lib/repositories/consumable_inventory_repository.dart` - 추상
- `lib/repositories/firebase/firebase_consumable_inventory_repository.dart` - Firebase 구현

#### 📁 네비게이션 (3개)
- `lib/navigation/app_router_shopping.dart` - 라우팅
- `lib/navigation/app_routes_paths.dart` - 경로 정의
- `lib/navigation/app_routes_args.dart` - 인자 정의

#### 📁 설정/테스트 (3개)
- `lib/utils/main_feature_icon_catalog.dart` - 메인 화면 통합
- `test/utils/household_consumables_utils_test.dart` - 테스트
- `pubspec.yaml` - 의존성

#### 📁 문서 (6개)
- `WMS_DRAFT_SYSTEM_IMPLEMENTATION_2026-02-02.md`
- `HOUSEHOLD_CONSUMABLES_FEATURE_REPORT.md`
- `HOUSEHOLD_CONSUMABLES_IMPROVEMENT_PROPOSAL.md`
- `FEATURE_REORGANIZATION_PLAN_2026-02-02.md`
- `DATA_STRUCTURE_REPORT_2026-02-02.md`
- `WMS_INPUT_SAVING_DUPLICATE_ANALYSIS.md` (새로 생성)

---

## 🔗 의존성 구조 분석

### 스크린 계층 의존성

```
메인 대시보드 (app_shell.dart)
└─ 기능 탭
   └─ 쇼핑 탭 (shopping_feature_tab.dart)
      └─ ConsumableInventoryScreen ← 진입점
         ├─ WmsIoScreen (입출고)
         ├─ QuickStockUseScreen (빠른 차감)
         ├─ ConsumableInventoryDialogs (다이얼로그)
         └─ ConsumableInventoryWidgets (위젯)
```

### 데이터 계층 의존성

```
Firebase / SQLite 데이터베이스
   ↓
AppRepositories (저장소 팩토리)
   ├─ ConsumableInventoryRepository (추상)
   └─ FirebaseConsumableInventoryRepository (구현)
   ↓
ConsumableInventoryService (싱글톤 서비스)
   ├─ Health/Notification Services
   └─ ValueNotifier<List<ConsumableInventoryItem>>
   ↓
Screen UI Components
```

### 비즈니스 로직 의존성

```
WmsInventoryGateway (중앙 Gateway)
├─ 데이터 캐싱 (30초)
├─ 중복 체크
├─ 유효성 검사
└─ ConsumableInventoryService 호출

WmsDraftManager (임시저장 관리)
├─ UserPrefService (SharedPreferences)
├─ WmsInventoryDraftEntry 모델
└─ WmsInventoryGateway 호출

Voice/Deep Link 통합
├─ VoiceDashboardScreen
├─ DeepLinkHandler
└─ ConsumableInventoryService 직접 호출
```

---

## ⚠️ 분리 시 문제점 (Why Not Separate)

### 1️⃣ 강한 결합도 (Tight Coupling)

| 의존성 | 분리 난도 | 이유 |
|--------|---------|------|
| ConsumableInventoryService | 🔴 높음 | 앱의 3개 이상 모듈에서 사용 |
| WmsInventoryGateway | 🔴 높음 | 캐싱/조회/추가를 일괄 관리 |
| ConsumableInventoryItem | 🔴 높음 | 데이터 모델로 광범위 사용 |
| AppRepositories | 🟡 중간 | 저장소 팩토리에 통합 |

**구체적인 의존 위치:**
```
voice_dashboard_screen.dart         (음성 입력 시 부족 여부 체크)
deep_link_handler.dart               (음성/심링크 → 재고 추가)
household_consumables_screen.dart    (생활용품 관리)
stock_depletion_notification.dart    (부족 알림 스케줄)
```

### 2️⃣ 공유 데이터 모델

```dart
class ConsumableInventoryItem {
  final String id;
  final String name;
  final double currentStock;
  final DateTime createdAt;
  final List<ConsumableUsageRecord> usageHistory;
  // ... 10+ fields
}
```

- 7개 파일에서 import
- 데이터베이스 스키마와 1:1 매핑
- 분리 시 모델 복제 또는 의존성 순환 발생

### 3️⃣ 데이터 계층 통합

**현재 구조:**
```
AppRepositories
├─ transactionRepository
├─ accountRepository
├─ consumableInventoryRepository ← WMS 데이터
├─ expenseDataRepository
└─ ...
```

**분리 시 문제:**
- 저장소를 별도 패키지로 분리하면?
- 팩토리 패턴 재설계 필요
- 의존성 주입 복잡화

### 4️⃣ 라우팅 통합

현재 WMS는 메인 `AppRoutes`의 일부:
```dart
// lib/navigation/app_routes_paths.dart
class AppRoutes {
  static const consumableInventory = 'shopping/consumable-inventory';
  static const wmsInOut = 'shopping/wms-io';
  static const quickStockUse = 'shopping/quick-stock-use';
}
```

분리하면:
- ❌ 라우팅 경로 변경
- ❌ 네비게이션 호출부 수정 (5+ 파일)
- ❌ 심링크 경로 마이그레이션

### 5️⃣ 메인 화면 통합

```dart
// lib/utils/main_feature_icon_catalog.dart
FeatureIcon(
  id: 'household_consumables',
  labelKo: '생활용품',
  routeName: AppRoutes.householdConsumables, ← 직접 연결
)
```

분리하면:
- ❌ 플러그인 시스템 구축 필요
- ❌ 동적 라우팅 설정

---

## ✅ 분리가 이상적인 경우 (대안)

### Case 1: 마이크로앱 아키텍처
```
smartledger/
├─ smartledger_core/        (공유 모델, 서비스)
├─ smartledger_transaction/ (거래 관리)
├─ smartledger_wms/         (별도 패키지)
└─ smartledger_app/         (메인 앱)
```

**비용:**
- Gradle/build 설정 복잡화
- 의존성 관리 어려움
- 로컬 개발 속도 저하

**이득:**
- 독립적 배포 가능
- 팀 분리 (WMS 팀 vs Transaction 팀)
- 재사용 가능한 패키지

**현재 SmartLedger에 필요한가?**
→ ❌ **아니오.** 단일 팀 개발 + 통합 앱 배포

---

## 📈 현재 추천: 모듈 정리 전략

### 1. 계층 강화 (Layer Separation)

```
Presentation Layer
├─ screens/wms_io_screen.dart
├─ screens/consumable_inventory_screen.dart
└─ screens/quick_stock_use_screen.dart

Business Logic Layer (← 정리 필요)
├─ services/consumable_inventory_service.dart
├─ utils/wms_data_gateway.dart
├─ utils/wms_unified_gateway.dart
└─ utils/quick_stock_use_utils.dart

Data Layer
├─ repositories/consumable_inventory_repository.dart
├─ models/consumable_inventory_item.dart
└─ services/stock_depletion_notification_service.dart
```

### 2. 명확한 폴더 구조

```
lib/
└─ features/
   └─ wms/  ← 새로운 폴더
      ├─ presentation/
      │  ├─ screens/
      │  │  ├─ consumable_inventory_screen.dart
      │  │  ├─ wms_io_screen.dart
      │  │  └─ quick_stock_use_screen.dart
      │  ├─ dialogs/
      │  │  └─ consumable_inventory_dialogs.dart
      │  └─ widgets/
      │     └─ consumable_inventory_widgets.dart
      ├─ domain/  (비즈니스 로직)
      │  └─ use_cases/
      │     ├─ add_stock_usecase.dart
      │     ├─ use_stock_usecase.dart
      │     └─ get_low_stock_usecase.dart
      ├─ data/
      │  ├─ datasources/
      │  ├─ models/
      │  └─ repositories/
      └─ shared/
         └─ utils/
            ├─ wms_data_gateway.dart
            ├─ wms_unified_gateway.dart
            └─ quick_stock_use_utils.dart
```

### 3. 구체적 개선 작업

#### A. Use Cases 도입 (Domain 계층)

**현재 코드 (서비스에 모든 로직):**
```dart
// ConsumableInventoryService에 모두 있음
addItem()
updateItem()
deleteItem()
useItem()
```

**개선 (Use Case 분리):**
```dart
// domain/use_cases/add_stock_usecase.dart
class AddStockUseCase {
  final WmsInventoryGateway gateway;
  Future<Result<ConsumableInventoryItem>> call(WmsInventoryInput input);
}

// domain/use_cases/use_stock_usecase.dart
class UseStockUseCase {
  final ConsumableInventoryService service;
  Future<Result<void>> call(String itemId, double amount);
}
```

#### B. 의존성 주입 정리

**현재:**
```dart
// Service 싱글톤 직접 접근
ConsumableInventoryService.instance.addItem(...)
WmsInventoryGateway.instance.addItem(...)
```

**개선:**
```dart
// Get_it 또는 Riverpod으로 주입
final getIt = GetIt.instance;
getIt.registerSingleton<WmsDataGateway>(WmsDataGateway());
getIt.registerSingleton<ConsumableInventoryService>(...);

// 사용
getIt<WmsDataGateway>().addItem(...)
```

#### C. 이벤트/상태 관리

**현재:**
```dart
ValueNotifier<List<ConsumableInventoryItem>> items;
```

**개선:**
```dart
// BLoC 또는 Riverpod으로 확장
final inventoryProvider = 
  StateNotifierProvider<InventoryNotifier, InventoryState>(...);
```

---

## 📊 분리 vs 통합 비교표

| 항목 | 분리 (패키지화) | 통합 (현재) | 정리된 모듈 (권장) |
|------|-----------|---------|------------|
| **조직화** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| **의존성 관리** | 🔴 복잡 | 🟢 단순 | 🟡 중간 |
| **재사용성** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| **배포 속도** | 🔴 느림 | 🟢 빠름 | 🟢 빠름 |
| **로컬 개발** | 🔴 복잡 | 🟢 단순 | 🟢 단순 |
| **테스트 용이** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **팀 협업** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **구현 난도** | 🔴 높음 | 🟢 없음 | 🟡 중간 |

---

## 🎯 최종 권장사항

### 1단계: 현재 구조 유지
- ✅ 분리하지 말 것
- 이미 충분히 모듈화되어 있음
- 분리 비용이 이득보다 큼

### 2단계: 폴더 정리 (우선순위 높음)
```
features/wms/ 폴더 생성
├─ presentation/
├─ domain/        ← Use Cases 추가
├─ data/
└─ shared/
```

### 3단계: 비즈니스 로직 정제 (우선순위 중간)
- Use Cases 도입
- Get_it / Riverpod 의존성 주입
- 단일 책임 원칙 강화

### 4단계: 테스트 강화 (우선순위 중간)
- Unit Test: Use Cases
- Widget Test: 스크린
- Integration Test: 라우팅

### 5단계: 문서화 (우선순위 낮음)
- WMS 사용 가이드 작성
- API 문서화

---

## 향후 검토

### Case A: WMS가 너무 커지면?

**임계값:**
- 200+ 스크린
- 50+ 비즈니스 로직 함수
- 3개 이상의 팀 개발

**그때 분리:**
```
wms_feature/     (이 시점에 플러그인으로 분리)
├─ pubspec.yaml
├─ lib/
└─ test/
```

### Case B: 다른 앱에서 재사용?

**예: WMS만 따로 쓰고 싶다면?**
```
wms_feature/
├─ example/
└─ README.md (독립 사용 가이드)
```

→ 이때 패키지화

---

## 체크리스트

- [ ] 현재 구조 유지 (분리 금지)
- [ ] `features/wms/` 폴더 생성으로 정리
- [ ] Use Cases 4-5개 추출 시작
- [ ] 의존성 주입 정책 수립
- [ ] 단위 테스트 200+ 커버리지 달성
- [ ] WMS 아키텍처 문서 작성

---

## 결론

**WMS 기능을 별도로 분리할 필요는 없습니다.** ✅

대신:
1. **폴더 정리**로 명확한 계층 구조 유지
2. **Use Cases 도입**으로 비즈니스 로직 분리
3. **테스트 강화**로 안정성 확보
4. **문서화 개선**으로 유지보수성 향상

이 전략이 현재 SmartLedger의 개발 속도와 품질을 모두 극대화할 수 있습니다.
