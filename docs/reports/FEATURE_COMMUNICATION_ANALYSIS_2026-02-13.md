# 🔗 SmartLedger 기능 간 소통 정밀 분석 보고서

**작성일자**: 2026년 2월 13일  
**앱 버전**: 1.0.0+1  
**분석 범위**: 전체 아키텍처 통신 메커니즘

---

## 📋 Executive Summary

SmartLedger는 **Singleton Service 패턴 + Repository 추상화 + Navigation Args**를 조합한 **계층형 통신 아키텍처**를 사용합니다. Provider 같은 반응형 상태 관리 대신, **서비스 계층의 직접 호출 + Stream 기반 이벤트**로 기능 간 소통을 구현했습니다.

### 🎯 핵심 통신 메커니즘 (5가지)

1. **Singleton Service Layer** - 100+ 서비스가 전역 싱글톤으로 비즈니스 로직 공유
2. **Repository Pattern** - 데이터 계층 추상화 (ConsumableInventory, ShoppingCart)
3. **Navigation Args** - 화면 간 타입 안전 데이터 전달 (19개 Args 클래스)
4. **DatabaseProvider Singleton** - Drift DB 인스턴스 전역 공유
5. **Stream Events** - DeepLinkService, NotificationService가 이벤트 브로드캐스트

---

## 🏗️ 아키텍처 계층 구조

```
┌─────────────────────────────────────────┐
│         UI Layer (Screens)              │  ← 300+ 화면
│  - StatefulWidget/StatelessWidget       │
│  - 화면별 _build/_logic/_widgets 분리   │
└─────────────────────────────────────────┘
                   ↓ ↑
            Navigation Args
         (타입 안전 데이터 전달)
                   ↓ ↑
┌─────────────────────────────────────────┐
│       Service Layer (Singleton)         │  ← 100+ 서비스
│  - TransactionService                   │
│  - FoodExpiryService                    │
│  - RecipeService                        │
│  - DeepLinkService (Stream)             │
│  - NotificationService                  │
│  - GeminiAiService                      │
│  - BackupService                        │
└─────────────────────────────────────────┘
                   ↓ ↑
┌─────────────────────────────────────────┐
│     Repository Layer (Interface)        │  ← 데이터 추상화
│  - ConsumableInventoryRepository        │
│  - ShoppingCartRepository               │
│  - VisitPriceRepository                 │
└─────────────────────────────────────────┘
                   ↓ ↑
┌─────────────────────────────────────────┐
│        Data Layer (Persistence)         │
│  - DatabaseProvider (Drift/SQLite)      │
│  - SharedPreferences                    │
│  - Firebase Storage                     │
│  - SecureStorage                        │
└─────────────────────────────────────────┘
                   ↓ ↑
┌─────────────────────────────────────────┐
│     Platform Layer (Native)             │
│  - MethodChannel (DeepLink, Assistant)  │
│  - PlatformException Handling           │
└─────────────────────────────────────────┘
```

---

## 1. 🔌 Singleton Service 패턴 (100+ 서비스)

### 1.1 구현 패턴

모든 서비스가 **Singleton Factory 패턴**으로 구현되어 있습니다:

```dart
class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();
  
  // ... 비즈니스 로직
}

class FoodExpiryService {
  static final FoodExpiryService _instance = FoodExpiryService._internal();
  factory FoodExpiryService() => _instance;
  FoodExpiryService._internal();
  
  // ... 비즈니스 로직
}
```

### 1.2 주요 서비스 목록 (100개)

#### 핵심 금융 서비스 (10개)
- `TransactionService` - 거래 데이터 관리
- `AccountService` - 계정 관리
- `AssetService` - 자산 관리
- `AssetMoveService` - 자산 이동
- `BudgetService` - 예산 관리
- `FixedCostService` - 고정비용
- `FixedCostAutoRecordService` - 고정비용 자동 기록
- `EmergencyFundService` - 긴급 자금
- `SavingsPlanService` - 저축 계획
- `SavingsStatisticsService` - 저축 통계

#### 쇼핑 및 재고 서비스 (12개)
- `ConsumableInventoryService` - 소모품 재고
- `StockDepletionNotificationService` - 재고 부족 알림
- `ReplacementCycleNotificationService` - 교체 주기 알림
- `HouseholdDataService` - 생필품 데이터
- `ActivityHouseholdEstimatorService` - 활동 기반 소모량 추정
- `AnnualHouseholdReportService` - 연간 생필품 보고서
- `ProductLocationService` - 제품 위치
- `StoreAliasService` - 상점 별칭
- `StoreLayoutService` - 상점 레이아웃
- `PriceCorrectionService` - 가격 보정
- `CategoryKeywordService` - 카테고리 키워드
- `CategoryUsageService` - 카테고리 사용 통계

#### 식품 및 레시피 서비스 (8개)
- `FoodExpiryService` - 유통기한 관리
- `FoodExpiryMigrationService` - 유통기한 데이터 마이그레이션
- `FoodExpiryNotificationService` - 유통기한 알림
- `RecipeService` - 레시피 관리
- `RecipeLearningService` - 레시피 학습
- `RecipeKnowledgeService` - 레시피 지식베이스
- `UnifiedRecipeRecommendationService` - 통합 레시피 추천
- `SmartConsumingService` - 스마트 소비

#### AI 및 음성 서비스 (8개)
- `GeminiAiService` - Gemini AI 통합
- `GeminiNanoService` - Gemini Nano 온디바이스
- `AICoreGeminiService` - AI Core 서비스
- `GemmaApiService` - Gemma API
- `OfflineAiService` - 오프라인 AI
- `VoiceAssistantAnalytics` - 음성 어시스턴트 분석
- `VoiceAssistantSettings` - 음성 어시스턴트 설정
- `VoiceInputBridge` - 음성 입력 브릿지

#### 통계 및 분석 서비스 (6개)
- `MonthlyAggCacheService` - 월별 집계 캐시
- `TransactionBenefitMonthlyAggService` - 거래 혜택 월별 집계
- `RootOverviewService` - 루트 개요
- `SearchService` - 검색
- `CategoryUsageService` - 카테고리 사용
- `InputStatsService` (추정) - 입력 통계

#### 시스템 서비스 (15개)
- `AuthService` - 인증
- `UserPinService` - PIN 관리
- `UserPasswordService` - 비밀번호 관리
- `SecureStorageService` - 보안 저장소
- `BackupService` - 백업
- `TrashService` - 휴지통
- `NotificationService` - 알림
- `DeepLinkService` - 딥링크 (Stream 기반)
- `ThemeService` - 테마
- `BackgroundService` - 백그라운드
- `AppIconService` - 앱 아이콘
- `DeviceLocationService` - 위치 정보
- `FeedbackService` - 피드백
- `PrivacyService` - 개인정보
- `PolicyService` - 정책

#### 데이터베이스 및 마이그레이션 (5개)
- `TransactionDbStore` - 거래 DB 저장소
- `TransactionDbMigrationService` - 거래 DB 마이그레이션
- `TransactionFtsIndexService` - 전문 검색 인덱스
- `FoodExpiryMigrationService` - 식품 마이그레이션
- `DatabaseProvider` (Singleton) - DB 인스턴스 관리

#### 사용자 환경설정 서비스 (10개 파일)
- `UserPrefService` (core) - 핵심 환경설정
- `UserPrefService` (drafts) - 임시 저장
- `UserPrefService` (icons) - 아이콘 설정
- `UserPrefService` (main_page) - 메인 페이지
- `UserPrefService` (main_page_mgmt) - 메인 페이지 관리
- `UserPrefService` (policy) - 정책
- `UserPrefService` (shopping) - 쇼핑 설정
- `UserPrefService` (shopping_hints) - 쇼핑 힌트
- `UserPrefService` (theme) - 테마 설정
- `UserPrefService` (전체 export)

#### 기타 서비스 (26개)
- `AccountOptionService` - 계정 옵션
- `AssetSecurityService` - 자산 보안
- `AssistantLauncher` - 어시스턴트 런처
- `BixbyDeeplinkHandler` - Bixby 딥링크
- `DeepLinkDiagnostics` - 딥링크 진단
- `EvacuationWorkflowMonitor` - 대피 워크플로우 모니터
- `HealthGuardrailService` - 건강 가드레일
- `IncomeSplitService` - 수입 분할
- `LastInputService` - 마지막 입력
- `RecentInputService` - 최근 입력
- `QuickSimpleExpenseInputHistoryService` - 빠른 입력 히스토리
- `ReceiptProcessingService` - 영수증 처리
- `SmartAppController` - 스마트 앱 컨트롤러
- `WeatherService` (추정) - 날씨
- `BackupService` (서브모듈 5개)
  - export, favorites, import, parse, save, share

### 1.3 서비스 간 의존성 패턴

#### 예제 1: TransactionService의 의존성
```dart
// lib/services/transaction_service.dart
import '../database/database_provider.dart';  // DB 접근
import 'monthly_agg_cache_service.dart';      // 집계 캐시
import 'transaction_benefit_monthly_agg_service.dart';  // 혜택 집계
import 'transaction_db_migration_service.dart';  // 마이그레이션
import 'transaction_db_store.dart';  // DB 저장소
import 'transaction_fts_index_service.dart';  // 전문 검색
import 'trash_service.dart';  // 휴지통

class TransactionService {
  final TransactionDbStore _dbStore = TransactionDbStore();
  
  // 다른 서비스를 직접 호출
  await MonthlyAggCacheService().invalidate(accountName);
  await TrashService().addEntry(...);
}
```

#### 예제 2: FoodExpiryService의 의존성
```dart
// lib/services/food_expiry_service.dart (추정)
import 'recipe_service.dart';  // 레시피 연동
import 'consumable_inventory_service.dart';  // 재고 연동
import 'notification_service.dart';  // 알림
import 'gemini_ai_service.dart';  // AI 추천

class FoodExpiryService {
  // 다른 서비스 호출
  RecipeService().getRecipesForIngredients(...);
  NotificationService().scheduleExpiryAlert(...);
}
```

### 1.4 서비스 호출 흐름 예제

**시나리오**: 사용자가 식재료를 소비하여 지출 입력

```
[FoodExpiryItemsScreen]
    ↓ 사용 기록
[FoodExpiryService.recordUsage()]
    ↓ 재고 차감
[ConsumableInventoryService.updateStock()]
    ↓ 레시피 학습
[RecipeLearningService.learnUsagePattern()]
    ↓ 지출 기록 생성
[TransactionService.addTransaction()]
    ↓ 통계 캐시 무효화
[MonthlyAggCacheService.invalidate()]
    ↓ 알림 스케줄링
[NotificationService.scheduleStockAlert()]
```

---

## 2. 📦 Repository Pattern (데이터 추상화)

### 2.1 Repository 인터페이스

#### ConsumableInventoryRepository
```dart
abstract class ConsumableInventoryRepository {
  Future<List<ConsumableInventoryItem>> loadItems();
  Future<void> saveItems(List<ConsumableInventoryItem> items);
}
```

#### ShoppingCartRepository
```dart
abstract class ShoppingCartRepository {
  Future<List<ShoppingCartItem>> getItems({required String accountName});
  Future<void> setItems({required String accountName, required List<ShoppingCartItem> items});
  Future<void> clearItems({required String accountName});
  Future<List<ShoppingCartHistoryEntry>> getHistory({required String accountName, int limit});
  Future<void> setHistory({required String accountName, required List<ShoppingCartHistoryEntry> entries});
  Future<void> addHistoryEntry({required String accountName, required ShoppingCartHistoryEntry entry});
}
```

### 2.2 구현체 (Concrete Repository)

#### SharedPrefsConsumableInventoryRepository
```dart
class SharedPrefsConsumableInventoryRepository 
    implements ConsumableInventoryRepository {
  static const String _prefsKey = 'consumable_inventory_items_v1';

  @override
  Future<List<ConsumableInventoryItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    // JSON 파싱...
    return parsed;
  }

  @override
  Future<void> saveItems(List<ConsumableInventoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }
}
```

#### UserPrefShoppingCartRepository
```dart
class UserPrefShoppingCartRepository implements ShoppingCartRepository {
  @override
  Future<List<ShoppingCartItem>> getItems({required String accountName}) {
    return UserPrefService.getShoppingCartItems(accountName: accountName);
  }

  @override
  Future<void> setItems({required String accountName, required List<ShoppingCartItem> items}) {
    return UserPrefService.setShoppingCartItems(accountName: accountName, items: items);
  }
  // ... 기타 메서드
}
```

### 2.3 AppRepositories (Static Registry)

```dart
class AppRepositories {
  static ConsumableInventoryRepository consumableInventory =
      SharedPrefsConsumableInventoryRepository();
  
  static ShoppingCartRepository shoppingCart = 
      UserPrefShoppingCartRepository();
}
```

**사용 예시**:
```dart
// 서비스에서 Repository 호출
final items = await AppRepositories.consumableInventory.loadItems();
await AppRepositories.shoppingCart.setItems(accountName: 'main', items: cart);
```

### 2.4 Repository 패턴의 장점

1. **데이터 소스 교체 용이성**
   - SharedPreferences → Firebase → SQLite 전환 시 인터페이스 유지
   
2. **테스트 용이성**
   - Mock Repository로 테스트 가능
   
3. **비즈니스 로직 분리**
   - 서비스 계층이 저장 구현에 의존하지 않음

---

## 3. 🧭 Navigation Args (화면 간 데이터 전달)

### 3.1 Args 클래스 목록 (19개)

#### 금융 관련 Args (7개)
1. **AccountArgs** - 계정 생성 시 전달
   ```dart
   const AccountArgs({required this.accountName, this.initialIncomeAmount});
   ```

2. **AccountMainArgs** - 계정 메인 화면 진입
   ```dart
   const AccountMainArgs({required this.accountName, this.initialIndex = 0});
   ```

3. **TransactionAddArgs** - 거래 입력 화면
   ```dart
   const TransactionAddArgs({
     required this.accountName,
     this.initialTransaction,
     this.learnCategoryHintFromDescription = false,
     this.confirmBeforeSave = false,
     this.autoSubmit = false,
     this.openReceiptScannerOnStart = false,
     this.initialPaymentMethod,
     this.initialMemo,
   });
   ```

4. **TransactionDetailArgs** - 거래 상세
   ```dart
   const TransactionDetailArgs({
     required this.accountName,
     required this.initialType,
   });
   ```

5. **DailyTransactionsArgs** - 일일 거래 화면
   ```dart
   const DailyTransactionsArgs({
     required this.accountName,
     required this.initialDay,
     this.savedCount,
     this.showShoppingPointsInputCta = false,
   });
   ```

6. **AssetSimpleInputArgs** - 자산 간편 입력
   ```dart
   const AssetSimpleInputArgs({
     required this.accountName,
     this.initialCategory,
     this.initialName,
     this.initialAmount,
     this.autoSubmit = false,
   });
   ```

7. **QuickSimpleExpenseInputArgs** - 빠른 지출 입력
   ```dart
   const QuickSimpleExpenseInputArgs({
     required this.accountName,
     required this.initialDate,
     this.initialLine,
     this.autoSubmit = false,
   });
   ```

#### 쇼핑 및 재고 Args (5개)
8. **ShoppingCartArgs** - 쇼핑 카트
   ```dart
   const ShoppingCartArgs({
     required this.accountName,
     this.openPrepOnStart = false,
     this.initialItems,
   });
   ```

9. **ShoppingGuideArgs** - 쇼핑 가이드
   ```dart
   const ShoppingGuideArgs({
     required this.accountName,
     required this.items
   });
   ```

10. **QuickStockUseArgs** - 빠른 재고 사용
    ```dart
    const QuickStockUseArgs({
      required this.accountName,
      this.initialProductName
    });
    ```

11. **ShoppingPointsInputArgs** - 포인트 입력
    ```dart
    const ShoppingPointsInputArgs({
      required this.accountName,
      this.lastPaymentMethod,
      this.lastMemo,
      this.totalAmount,
      this.chargedAmount,
      this.itemCount,
    });
    ```

12. **FoodExpiryArgs** - 식품 유통기한 (복잡한 Args 예제)
    ```dart
    const FoodExpiryArgs({
      this.initialIngredients,
      this.autoUsageMode = false,
      this.openUpsertOnStart = false,
      this.openCookableRecipePickerOnStart = false,
      this.scrollToDailyRecipeRecommendationOnStart = false,
      this.upsertPrefill,
      this.upsertAutoSubmit = false,
    });
    ```

#### 레시피 Args (3개)
13. **RecipeManagementArgs** - 레시피 관리
14. **RecipeEditArgs** - 레시피 편집
15. **RecipeToCartArgs** - 레시피 → 카트

#### 기타 Args (4개)
16. **AccountSelectArgs** - 계정 선택
17. **IconManagementArgs** - 아이콘 관리
18. **TopLevelStatsDetailArgs** - 최상위 통계 상세
19. **TransactionAddResult** - 거래 입력 결과 (반환값)

### 3.2 Navigation 사용 예제

#### 화면 이동 시 Args 전달
```dart
// 거래 입력 화면으로 이동
Navigator.of(context).pushNamed(
  AppRoutes.transactionAdd,
  arguments: TransactionAddArgs(
    accountName: 'main',
    initialPaymentMethod: '신용카드',
    autoSubmit: false,
  ),
);
```

#### 화면에서 Args 수신
```dart
class TransactionAddScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as TransactionAddArgs;
    
    return Scaffold(
      body: _buildForm(
        accountName: args.accountName,
        initialPaymentMethod: args.initialPaymentMethod,
      ),
    );
  }
}
```

#### 결과 반환 (Pop with Result)
```dart
// 저장 후 결과 반환
Navigator.of(context).pop(
  TransactionAddResult(
    saved: true,
    paymentMethod: '신용카드',
    memo: '스타벅스',
    mainCategory: '식사',
  ),
);

// 호출한 화면에서 결과 수신
final result = await Navigator.of(context).pushNamed(
  AppRoutes.transactionAdd,
  arguments: args,
) as TransactionAddResult?;

if (result?.saved == true) {
  // 다음 입력 시 결과값 재사용
  _paymentMethod = result!.paymentMethod;
  _memo = result!.memo;
}
```

### 3.3 Args 설계 패턴

#### 필수 vs 선택 필드
- **required**: 화면 진입에 반드시 필요한 데이터 (`accountName`, `initialDay`)
- **optional**: 편의 기능 또는 상태 복원 (`initialPaymentMethod`, `savedCount`)

#### Boolean Flag 패턴
- `autoSubmit`: 자동 저장 (딥링크에서 사용)
- `openPrepOnStart`: 진입 시 특정 모드 활성화
- `confirmBeforeSave`: 저장 전 확인 다이얼로그

#### Prefill 패턴
- `FoodExpiryUpsertPrefill`: 복잡한 초기값을 별도 클래스로 분리
- 음성 어시스턴트나 딥링크에서 사용

---

## 4. 🗄️ DatabaseProvider (Singleton DB 인스턴스)

### 4.1 구현
```dart
class DatabaseProvider {
  DatabaseProvider._();
  
  static final DatabaseProvider instance = DatabaseProvider._();
  
  AppDatabase? _database;
  
  AppDatabase get database => _database ??= AppDatabase();
  
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
```

### 4.2 사용 패턴
```dart
// 서비스에서 DB 접근
final db = DatabaseProvider.instance.database;
final transactions = await db.select(db.transactionTable).get();
```

### 4.3 Drift ORM 통합

- **Generated Code**: `app_database.g.dart`로 타입 안전 쿼리
- **테이블 정의**: `app_database.dart`
- **DAO 패턴**: 각 테이블별 Data Access Object 생성 가능

---

## 5. 📡 Stream 기반 이벤트 (Event Broadcasting)

### 5.1 DeepLinkService의 Stream

```dart
class DeepLinkService {
  final _linkController = StreamController<DeepLinkAction>.broadcast();
  
  Stream<DeepLinkAction> get linkStream => _linkController.stream;
  
  // 네이티브에서 딥링크 수신 시
  void _handleUri(String uri) {
    final action = parseUri(uri);
    if (action != null) {
      _linkController.add(action);  // Stream으로 브로드캐스트
    }
  }
}
```

### 5.2 화면에서 Stream 구독

```dart
class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<DeepLinkAction>? _linkSub;
  
  @override
  void initState() {
    super.initState();
    
    // DeepLink 이벤트 구독
    _linkSub = DeepLinkService.instance.linkStream.listen((action) {
      _handleDeepLinkAction(action);
    });
  }
  
  void _handleDeepLinkAction(DeepLinkAction action) {
    switch (action) {
      case AddTransactionAction():
        Navigator.pushNamed(context, AppRoutes.transactionAdd, arguments: ...);
      case OpenDashboardAction():
        setState(() => _selectedIndex = 0);
      // ... 기타 액션
    }
  }
  
  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }
}
```

### 5.3 DeepLink Action Types (8가지)

1. **AddTransactionAction** - 거래 입력
   ```dart
   AddTransactionAction({
     required this.type,  // 'expense', 'income'
     this.amount,
     this.description,
     this.autoSubmit = false,
     this.confirmed = false,
   })
   ```

2. **OpenDashboardAction** - 대시보드 열기
3. **OpenFeatureAction** - 특정 기능 열기 (`featureId`)
4. **AddToCartAction** - 쇼핑 카트 추가
5. **RecipeRecommendAction** - 레시피 추천
6. **ReceiptAnalyzeAction** - 영수증 분석
7. **OpenRouteAction** - 특정 라우트 열기
8. **CheckStockAction** - 재고 확인
9. **UseStockAction** - 재고 사용

### 5.4 NotificationService의 이벤트 (추정)

```dart
class NotificationService {
  final _notificationController = StreamController<NotificationEvent>.broadcast();
  
  Stream<NotificationEvent> get notificationStream => _notificationController.stream;
  
  // 알림 수신 시 이벤트 발생
  void _handleNotificationTap(String payload) {
    _notificationController.add(NotificationEvent(payload));
  }
}
```

---

## 6. 🔌 Platform Channel (네이티브 통신)

### 6.1 DeepLinkService의 MethodChannel

```dart
class DeepLinkService {
  static const _channel = MethodChannel('com.example.smartledger/deeplink');
  
  Future<void> init() async {
    // 네이티브에서 메서드 호출 수신
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final uri = call.arguments as String?;
        // URI 처리...
      }
      return null;
    });
    
    // 네이티브에게 메서드 호출 요청
    final initial = await _channel.invokeMethod<String>('getInitialLink');
  }
}
```

### 6.2 AssistantLauncher의 MethodChannel

```dart
class AssistantLauncher {
  static const MethodChannel _channel = MethodChannel('smart_ledger/assistant');
  
  static Future<bool> openSystemAssistant() async {
    final ok = await _channel.invokeMethod<bool>('openVoiceAssistant');
    return ok == true;
  }
  
  static Future<bool> openBixby() async {
    // Bixby 패키지명으로 앱 실행 시도
    const candidates = [
      'com.samsung.android.bixby.agent',
      'com.samsung.android.bixby.service',
    ];
    for (final pkg in candidates) {
      final ok = await openAppByPackage(pkg);
      if (ok) return true;
    }
    return false;
  }
}
```

### 6.3 네이티브 통신 흐름

```
[Android Native Code]
    ↓ Intent/Deep Link 수신
[MethodChannel: 'onDeepLink']
    ↓
[DeepLinkService._channel.setMethodCallHandler]
    ↓
[DeepLinkService.parseUri(uri)]
    ↓
[DeepLinkService.linkStream.add(action)]
    ↓
[UI Screens subscribe to linkStream]
    ↓
[Navigator.pushNamed() with Args]
```

---

## 7. 🔄 데이터 흐름 시나리오 예제

### 시나리오 1: 음성 명령으로 지출 입력

```
[사용자] "오늘 점심 15,000원 썼어"
    ↓
[AssistantLauncher.openSystemAssistant()] 
    ← Platform Channel
[Android Native: Bixby/Google Assistant]
    ↓ 음성 인식
[Deep Link URI 생성]
    smartledger://transaction/add?type=expense&amount=15000&desc=점심&autoSubmit=true&confirmed=true
    ↓
[DeepLinkService._channel receives 'onDeepLink']
    ↓
[DeepLinkService.parseUri(uri)]
    → AddTransactionAction 객체 생성
    ↓
[DeepLinkService.linkStream.add(action)]
    ↓
[HomeScreen subscribes to linkStream]
    ↓
[_handleDeepLinkAction(action)]
    ↓
[Navigator.pushNamed(
    AppRoutes.transactionAdd,
    arguments: TransactionAddArgs(
      accountName: currentAccount,
      initialAmount: 15000,
      initialDescription: '점심',
      autoSubmit: true,
    ),
)]
    ↓
[TransactionAddScreen receives Args]
    ↓
[TransactionService().addTransaction(...)]
    ↓
[MonthlyAggCacheService().invalidate(accountName)]
    ↓
[DatabaseProvider.instance.database.insert(...)]
    ↓
[Navigator.pop(TransactionAddResult(saved: true))]
    ↓
[HomeScreen updates UI]
```

### 시나리오 2: 레시피에서 재료 사용 후 지출 기록

```
[FoodExpiryItemsScreen] 사용자가 "레시피로 조리" 버튼 클릭
    ↓
[RecipeService().getRecipesForIngredients(ingredients)]
    → Singleton Service 직접 호출
    ↓
[RecipePickerDialog 표시]
    ↓
[사용자가 레시피 선택]
    ↓
[FoodExpiryService().recordUsageForRecipe(recipe)]
    ↓
    ├─→ [ConsumableInventoryService().updateStock(...)]
    │       → AppRepositories.consumableInventory.saveItems(...)
    │       → SharedPreferences 저장
    │
    ├─→ [RecipeLearningService().learnPattern(recipe)]
    │       → 사용 패턴 학습
    │
    └─→ [Show Dialog: "지출 기록하시겠습니까?"]
            ↓ 사용자 확인
        [Navigator.pushNamed(
            AppRoutes.transactionAdd,
            arguments: TransactionAddArgs(
              accountName: accountName,
              initialAmount: recipe.estimatedCost,
              initialDescription: recipe.name,
              initialCategory: '식사',
              closeAfterSave: true,
            ),
        )]
            ↓
        [TransactionAddScreen]
            ↓
        [TransactionService().addTransaction(...)]
            ↓
        [DatabaseProvider DB 저장]
            ↓
        [Pop with Result]
            ↓
        [FoodExpiryItemsScreen shows SnackBar "지출 기록 완료"]
```

### 시나리오 3: 쇼핑 카트 → 지출 입력 → 포인트 입력 체인

```
[ShoppingCartScreen] 사용자가 체크된 항목들 선택
    ↓
[_buildQuickTransactionFlow()] 메서드 호출
    ↓
[for each checked item]
    ↓
    [Navigator.pushNamed(
        AppRoutes.transactionAdd,
        arguments: TransactionAddArgs(
          accountName: accountName,
          initialAmount: item.price * item.quantity,
          initialDescription: item.name,
          initialPaymentMethod: lastPaymentMethod,  // 이전 값 유지
          initialMemo: lastMemo,  // 이전 값 유지
          closeAfterSave: true,
        ),
    )]
        ↓
    [TransactionAddScreen]
        ↓
    [사용자가 저장]
        ↓
    [TransactionService().addTransaction(...)]
        ↓
    [Pop with TransactionAddResult]
        lastPaymentMethod: '신용카드',
        lastMemo: '이마트',
        mainCategory: '식품',
        ↓
    [ShoppingCartScreen receives result]
        → lastPaymentMethod 업데이트 (다음 입력에 사용)
        → savedCount++
        ↓
[모든 항목 입력 완료]
    ↓
[Show Dialog: "포인트/할인 입력하시겠습니까?"]
    ↓ 사용자 확인
[Navigator.pushNamed(
    AppRoutes.shoppingPointsInput,
    arguments: ShoppingPointsInputArgs(
      accountName: accountName,
      lastPaymentMethod: lastPaymentMethod,
      lastMemo: lastMemo,
      totalAmount: totalAmount,
      itemCount: savedCount,
    ),
)]
    ↓
[ShoppingPointsInputScreen]
    ↓
[포인트 적립/할인 정보 입력]
    ↓
[TransactionService().addTransaction(type: 'benefit')]
    ↓
[Pop back to ShoppingCartScreen]
    ↓
[Show completion SnackBar]
```

---

## 8. 🔒 문제점 및 리팩토링 제안

### 8.1 현재 아키텍처의 문제점

#### 🚨 문제 1: 과도한 Singleton 의존성
**증상**: 100+ 싱글톤 서비스로 인한 결합도 증가

**문제**:
- 서비스 간 순환 참조 가능성
- 테스트 어려움 (Mock 주입 불가)
- 전역 상태로 인한 예측 불가능한 부작용

**해결책**:
```dart
// 현재 (Bad)
class TransactionService {
  void addTransaction(...) {
    MonthlyAggCacheService().invalidate(...);  // 직접 호출
  }
}

// 제안 (Good - Dependency Injection)
class TransactionService {
  final MonthlyAggCacheService _cacheService;
  
  TransactionService({required MonthlyAggCacheService cacheService})
      : _cacheService = cacheService;
  
  void addTransaction(...) {
    _cacheService.invalidate(...);
  }
}

// 또는 GetIt 같은 DI 컨테이너 사용
final getIt = GetIt.instance;
getIt.registerSingleton<MonthlyAggCacheService>(MonthlyAggCacheService());
getIt.registerFactory<TransactionService>(
  () => TransactionService(cacheService: getIt<MonthlyAggCacheService>()),
);
```

#### 🚨 문제 2: 화면이 서비스를 직접 호출
**증상**: 화면 위젯이 비즈니스 로직을 직접 처리

**문제**:
- UI 로직과 비즈니스 로직 혼재
- 코드 재사용 어려움
- 테스트 불가능

**해결책**:
```dart
// 현재 (Bad)
class _TransactionAddScreenState extends State<TransactionAddScreen> {
  void _saveTransaction() async {
    final transaction = Transaction(...);
    await TransactionService().addTransaction(accountName, transaction);
    await MonthlyAggCacheService().invalidate(accountName);
    Navigator.pop(context);
  }
}

// 제안 (Good - ViewModel/Cubit 패턴)
class TransactionAddCubit extends Cubit<TransactionAddState> {
  final TransactionService _transactionService;
  final MonthlyAggCacheService _cacheService;
  
  TransactionAddCubit({
    required TransactionService transactionService,
    required MonthlyAggCacheService cacheService,
  })  : _transactionService = transactionService,
        _cacheService = cacheService,
        super(TransactionAddInitial());
  
  Future<void> saveTransaction(Transaction transaction, String accountName) async {
    emit(TransactionAddSaving());
    try {
      await _transactionService.addTransaction(accountName, transaction);
      await _cacheService.invalidate(accountName);
      emit(TransactionAddSuccess());
    } catch (e) {
      emit(TransactionAddError(e.toString()));
    }
  }
}

// UI는 Cubit만 호출
class _TransactionAddScreenState extends State<TransactionAddScreen> {
  late final TransactionAddCubit _cubit;
  
  void _saveTransaction() {
    _cubit.saveTransaction(transaction, accountName);
  }
}
```

#### 🚨 문제 3: Args 클래스의 dynamic 남용
**증상**: `TransactionDetailArgs.initialType`이 `Object` 타입

**문제**:
- 타입 안전성 상실
- 런타임 오류 가능성
- IDE 자동완성 불가

**해결책**:
```dart
// 현재 (Bad)
class TransactionDetailArgs {
  const TransactionDetailArgs({
    required this.accountName,
    required this.initialType,  // Object 타입
  });
  final Object initialType;
}

// 제안 (Good - 구체적 타입 또는 Union Type)
class TransactionDetailArgs {
  const TransactionDetailArgs({
    required this.accountName,
    required this.transaction,  // Transaction 타입
  });
  final Transaction transaction;
}

// 또는 Sealed Class (Union Type)
sealed class TransactionDetailArgs {
  final String accountName;
  const TransactionDetailArgs(this.accountName);
}

class ExpenseDetailArgs extends TransactionDetailArgs {
  final Transaction transaction;
  const ExpenseDetailArgs(String accountName, this.transaction) : super(accountName);
}

class IncomeDetailArgs extends TransactionDetailArgs {
  final Income income;
  const IncomeDetailArgs(String accountName, this.income) : super(accountName);
}
```

#### 🚨 문제 4: Repository가 Static으로 등록
**증상**: `AppRepositories.consumableInventory` 정적 필드

**문제**:
- 운영 중 구현체 교체 어려움
- 테스트 시 Mock 주입 불가
- Firebase 로그인 후 Repository 교체 시 위험

**해결책**:
```dart
// 현재 (Bad)
class AppRepositories {
  static ConsumableInventoryRepository consumableInventory =
      SharedPrefsConsumableInventoryRepository();
}

// 사용
AppRepositories.consumableInventory = FirebaseConsumableInventoryRepository();  // 위험!

// 제안 (Good - Service Locator 패턴)
class AppRepositories {
  static final GetIt _locator = GetIt.instance;
  
  static void setupLocal() {
    _locator.registerSingleton<ConsumableInventoryRepository>(
      SharedPrefsConsumableInventoryRepository(),
    );
  }
  
  static void switchToFirebase(User user) {
    _locator.unregister<ConsumableInventoryRepository>();
    _locator.registerSingleton<ConsumableInventoryRepository>(
      FirebaseConsumableInventoryRepository(user),
    );
  }
  
  static ConsumableInventoryRepository get consumableInventory =>
      _locator<ConsumableInventoryRepository>();
}
```

#### 🚨 문제 5: Stream 구독 해제 누락 가능성
**증상**: StreamSubscription이 State에서 수동 관리

**문제**:
- dispose()에서 cancel() 누락 시 메모리 누수
- 여러 Stream 구독 시 관리 복잡

**해결책**:
```dart
// 현재 (Bad)
class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _linkSub;
  
  @override
  void initState() {
    super.initState();
    _linkSub = DeepLinkService.instance.linkStream.listen(...);
  }
  
  @override
  void dispose() {
    _linkSub?.cancel();  // 누락 가능
    super.dispose();
  }
}

// 제안 (Good - StreamBuilder 또는 BlocListener)
class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DeepLinkAction>(
      stream: DeepLinkService.instance.linkStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _handleDeepLinkAction(snapshot.data!);
        }
        return _buildBody();
      },
    );
  }
}

// 또는 Bloc 패턴
class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<DeepLinkBloc, DeepLinkState>(
      listener: (context, state) {
        if (state is DeepLinkReceived) {
          _handleDeepLinkAction(state.action);
        }
      },
      child: _buildBody(),
    );
  }
}
```

### 8.2 권장 리팩토링 로드맵

#### Phase 1: Dependency Injection 도입 (2주)
- [ ] GetIt 패키지 추가
- [ ] 핵심 서비스 10개를 DI 컨테이너에 등록
- [ ] TransactionService, FoodExpiryService 등 주요 서비스 리팩토링

#### Phase 2: ViewModel/Cubit 계층 추가 (4주)
- [ ] flutter_bloc 패키지 추가
- [ ] 거래 입력 화면에 Cubit 적용
- [ ] 쇼핑 카트 화면에 Cubit 적용
- [ ] 통계 화면에 Cubit 적용

#### Phase 3: Args 타입 안전성 강화 (1주)
- [ ] dynamic/Object 타입을 구체적 타입으로 변경
- [ ] Sealed Class로 Union Type 표현

#### Phase 4: Repository 패턴 개선 (2주)
- [ ] Static Registry → Service Locator 전환
- [ ] Firebase Repository 구현체 추가
- [ ] 로그인 후 Repository 교체 로직 구현

#### Phase 5: Stream 관리 개선 (1주)
- [ ] 수동 구독/해제 → StreamBuilder 전환
- [ ] NotificationService도 Stream 기반으로 통일

---

## 9. 📊 통신 메커니즘 비교표

| 메커니즘 | 사용 사례 | 장점 | 단점 | 예제 |
|---------|---------|------|------|------|
| **Singleton Service** | 비즈니스 로직 공유 | 간단한 구현, 전역 접근 | 테스트 어려움, 결합도↑ | `TransactionService()` |
| **Repository** | 데이터 계층 추상화 | 구현 교체 용이, 테스트 가능 | 추가 추상화 계층 필요 | `AppRepositories.consumableInventory` |
| **Navigation Args** | 화면 간 데이터 전달 | 타입 안전, 명시적 | 보일러플레이트 코드 | `TransactionAddArgs` |
| **Stream Events** | 비동기 이벤트 브로드캐스트 | 1:N 통신, 디커플링 | 구독 관리 필요, 메모리 누수 위험 | `DeepLinkService.linkStream` |
| **MethodChannel** | 네이티브 통신 | 플랫폼 기능 접근 | 플랫폼 의존성, 에러 처리 복잡 | `DeepLinkService._channel` |
| **DatabaseProvider** | DB 인스턴스 공유 | 단일 DB 연결 보장 | 전역 상태, 테스트 어려움 | `DatabaseProvider.instance.database` |

---

## 10. 🎯 결론 및 권장사항

### 10.1 현재 아키텍처 평가

**강점** ✅
1. **명확한 계층 분리**: UI/Service/Repository/Data 계층이 분리됨
2. **타입 안전 Navigation**: Args 클래스로 화면 간 데이터 전달 명시
3. **Repository 추상화**: 데이터 소스 교체 가능한 구조
4. **DeepLink 지원**: 외부(Bixby, Google Assistant) 통합 우수
5. **100+ 서비스**: 기능별로 잘 분산된 비즈니스 로직

**약점** ⚠️
1. **과도한 Singleton**: 100+ 싱글톤 서비스로 테스트/유지보수 어려움
2. **DI 미사용**: 의존성 주입 없이 직접 호출로 결합도 높음
3. **UI 로직 혼재**: 화면이 서비스를 직접 호출하여 비즈니스 로직 산재
4. **타입 안전성 부족**: Args에 dynamic/Object 타입 남용
5. **Stream 관리 위험**: 수동 구독/해제로 메모리 누수 가능성

### 10.2 권장 개선 방향

#### 단기 (1-2개월)
1. **GetIt DI 컨테이너 도입** - 핵심 서비스 10개부터 시작
2. **Args 타입 안전성 강화** - dynamic → 구체적 타입 변경
3. **StreamBuilder 전환** - 수동 구독 제거

#### 중기 (3-6개월)
4. **flutter_bloc 도입** - 주요 화면에 Cubit/Bloc 적용
5. **Repository 패턴 개선** - Static → Service Locator 전환
6. **테스트 커버리지 확대** - 단위 테스트 작성 시작

#### 장기 (6-12개월)
7. **Clean Architecture 완성** - UseCase 계층 추가
8. **멀티플랫폼 지원** - iOS/Web 대응 아키텍처 개선
9. **마이크로서비스 분리** - Firebase Cloud Functions로 일부 로직 이동

### 10.3 최종 평가

SmartLedger의 통신 아키텍처는 **기능적으로는 완성도가 높으나, 확장성과 유지보수성 측면에서 개선이 필요**합니다. 

현재 구조로도 중소규모 앱 운영은 가능하지만, 팀 확장이나 장기 유지보수를 고려하면 **Dependency Injection + ViewModel/Cubit 계층 추가**를 강력히 권장합니다.

---

**보고서 종료**  
**작성자**: GitHub Copilot  
**일자**: 2026년 2월 13일  
**버전**: 1.0.0
