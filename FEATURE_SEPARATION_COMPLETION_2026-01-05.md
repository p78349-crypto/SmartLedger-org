## UI 재배치: 레시피/식재료 검색 & 재고확인/요리시작 분리

완료 날짜: 2026-01-05

### 변경 사항 요약

기존에 함께 표시되던 "식재료 재고/유통기한"과 "요리 레시피/식재료 검색" 기능을 다음과 같이 분리 및 재배치했습니다.

#### 1. 새로운 라우트 추가 (app_routes.dart)
- `foodInventoryCheck` - 재고 확인 전용 라우트 추가
- `foodCookingStart` - 요리 시작 전용 라우트 추가

#### 2. 새로운 스크린 생성

**food_inventory_check_screen.dart**
- 용도: 식재료 재고 및 유통기한 확인
- FoodExpiryMainScreen을 감싼 래퍼 스크린
- `autoUsageMode: false`로 설정 (재고 확인 모드)

**food_cooking_start_screen.dart**
- 용도: 요리 시작 및 식재료 사용 추적
- FoodExpiryMainScreen을 감싼 래퍼 스크린
- `autoUsageMode: true`로 설정 (요리/사용 모드)

#### 3. 메인 피처 아이콘 카탈로그 업데이트 (main_feature_icon_catalog.dart)

**기존 (2개 아이콘)**
```
🔹 '식재료 재고/유통기한' → foodExpiry 라우트
🔹 '요리 레시피/식재료 검색' → nutritionReport 라우트
```

**변경 후 (3개 아이콘)**
```
🔹 '재고 확인' (Inventory Check) → foodInventoryCheck 라우트
   아이콘: inventory2

🔹 '요리 시작' (Start Cooking) → foodCookingStart 라우트
   아이콘: soupKitchen (soup_kitchen)

🔹 '요리 레시피/식재료 검색' (Recipe/Ingredient Search) → nutritionReport 라우트
   아이콘: articleOutlined (변동 없음)
```

#### 4. 라우터 등록 (app_router.dart)

두 새로운 라우트에 대한 네비게이션 핸들러 추가:
- `AppRoutes.foodInventoryCheck` → FoodInventoryCheckScreen()
- `AppRoutes.foodCookingStart` → FoodCookingStartScreen()

### 기술적 세부사항

- **기존 기능 보존**: FoodExpiryMainScreen의 `autoUsageMode` 파라미터를 활용하여 모드 선택
- **아이콘 분리**: 각 기능에 서로 다른 아이콘으로 구분 가능
- **별도 라우트**: 사용자가 명확한 진입점을 통해 원하는 기능에 접근 가능
- **호환성**: 기존 `foodExpiry` 라우트는 유지 (이전 코드 호환성)

### 사용자 경험 개선

1. **명확한 기능 분리**: "재고 확인"과 "요리 시작"이 시각적으로 분리됨
2. **빠른 접근**: 각 기능에 개별 아이콘으로 원클릭 접근 가능
3. **직관적인 네비게이션**: 사용자의 의도에 따라 명확한 선택지 제공

### 파일 변경 목록

1. `lib/navigation/app_routes.dart` - 2개 라우트 추가
2. `lib/screens/food_inventory_check_screen.dart` - 신규 작성
3. `lib/screens/food_cooking_start_screen.dart` - 신규 작성
4. `lib/utils/main_feature_icon_catalog.dart` - 아이콘 업데이트 (1→3개)
5. `lib/navigation/app_router.dart` - 2개 라우트 핸들러 추가 및 import 추가
