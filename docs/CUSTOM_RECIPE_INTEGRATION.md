# 사용자 레시피 통합 가이드

## 개요

SmartLedger는 사용자가 직접 만든 레시피(닭고기, 돼지고기 등)를 음성 추천 시스템에 자동으로 통합합니다. 사용자 레시피는 기본 레시피와 함께 유통기한 임박 재료 활용 및 건강 점수 기반으로 추천됩니다.

## 주요 기능

### 1. 사용자 레시피 자동 포함
- RecipeService에 저장된 모든 사용자 레시피가 자동으로 추천 대상에 포함됨
- 기본 레시피와 동일한 우선순위 알고리즘 적용
- 별도 설정 불필요

### 2. 건강 점수 시스템
```dart
class Recipe {
  final int healthScore; // 1-5 척도
  // 5 = 💚 매우 건강
  // 4 = 💚 건강
  // 3 = 🟡 보통 (기본값)
  // 2 = 🟠 주의
  // 1 = 🔴 비건강
}
```

### 3. 추천 우선순위
1. **유통기한 임박 재료 활용** (3일 이내)
   - 유통기한이 가까운 재료를 사용하는 레시피 최우선
   
2. **건강 점수**
   - 높은 건강 점수(4-5)를 가진 레시피 우선 추천
   
3. **재료 매칭률**
   - 현재 냉장고 재료와의 일치율 (최소 50% 이상)

4. **사용자 학습 가중치**
   - 자주 만드는 레시피에 최대 2배 가중치 적용

### 4. UI에서 사용자 레시피 구분
```dart
// 사용자 레시피는 특별한 아이콘과 라벨 표시
if (match.isUserRecipe) {
  // 👤 아이콘 표시
  // "👤 내가 만든 레시피" 라벨
}
```

## 레시피 생성 시 건강 점수 설정

### 자동 추정 (현재)
```dart
// 기본값으로 3점(보통) 할당
Recipe(
  id: 'user_001',
  name: '닭고기볶음',
  cuisine: '한식',
  ingredients: [...],
  healthScore: 3, // 자동으로 보통 점수
);
```

### 향후 개선 계획
사용자가 레시피 생성/수정 시 건강 점수를 직접 입력할 수 있도록 UI 추가 예정:
- 조리 방법 (삶기=5, 굽기=4, 볶기=3, 튀기기=2)
- 채소 비율 (70%이상=+1점)
- 나트륨/지방 함량 (낮음=+1점)

## 음성 명령 예시

### 사용자 레시피 포함 추천
```
"빅스비, 점심 뭐 해먹지?"
→ 기본 레시피 + 사용자 레시피 모두 검색

"냉장고에 닭고기랑 양파 있는데 뭐 만들까?"
→ 사용자의 '닭고기볶음' 레시피도 추천 대상
```

### 유통기한 임박 재료 활용
```
"유통기한 얼마 안남은 재료로 요리 추천해줘"
→ 사용자 레시피 중 임박 재료 활용 가능한 것 우선 추천
```

## 기술적 구현

### Recipe 모델 업데이트
```dart
class Recipe {
  final String id;
  final String name;
  final String cuisine;
  final List<RecipeIngredient> ingredients;
  final int healthScore; // NEW: 건강 점수 필드 추가

  Recipe({
    required this.id,
    required this.name,
    this.cuisine = '한식',
    required this.ingredients,
    this.healthScore = 3, // 기본값: 보통
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      cuisine: json['cuisine'] as String? ?? '기타',
      ingredients: ...,
      healthScore: json['healthScore'] as int? ?? 3, // 하위 호환성
    );
  }
}
```

### RecipeRecommendationUtils 통합
```dart
static Future<Map<String, RecipeMatch>> getRecommendedRecipes(
  List<FoodExpiryItem> availableIngredients, {
  bool prioritizeExpiring = true,
  bool prioritizeHealth = true,
  bool includeUserRecipes = true, // 사용자 레시피 포함 옵션
}) async {
  // 1. 기본 레시피 추천
  for (final recipeData in defaultRecipes) {
    // ...
  }

  // 2. 사용자 레시피 추가
  if (includeUserRecipes) {
    final userRecipes = RecipeService.instance.recipes.value;
    for (final recipe in userRecipes) {
      // 동일한 매칭 알고리즘 적용
      // healthScore 필드 활용
    }
  }

  // 3. 통합 정렬: 유통기한 → 건강 → 매칭률
  return sortedRecommendations;
}
```

### RecipeMatch 클래스 확장
```dart
class RecipeMatch {
  final bool isUserRecipe; // 사용자 레시피 여부
  
  String get message {
    final parts = <String>[];
    
    if (isUserRecipe) {
      parts.add('👤 내 레시피');
    }
    
    if (usesExpiringIngredients) {
      parts.add('⚠️ 유통기한 임박 재료 활용');
    }
    
    if (isVeryHealthy) {
      parts.add('💚 매우 건강한 요리');
    }
    
    return parts.join(' • ');
  }
}
```

## 학습 시스템 통합

### RecipeLearningService 연동
사용자가 "그것 좋겠다!" 버튼으로 선택한 레시피는 자동으로 학습:
```dart
await RecipeLearningService.instance.recordRecipeUsage(
  recipeId: recipe.id,
  recipeName: recipe.name,
  ingredients: recipe.ingredients.map((i) => i.name).toList(),
  healthScore: recipe.healthScore,
  mealTime: '점심', // 음성 명령에서 추출
);
```

### 개인화 가중치
```dart
// 자주 만드는 사용자 레시피에 가중치 적용
final weights = await RecipeLearningService.instance.getPersonalizedWeights();

// 추천 점수 계산 시
finalScore = baseScore * (1.0 + weights[recipeName] ?? 0.0);
// weights는 0.0 ~ 1.0 범위 (최대 2배 증폭)
```

## 데이터 관리

### 저장 위치
- **기본 레시피**: `lib/utils/recipe_recommendation_utils.dart` (hardcoded)
- **사용자 레시피**: SharedPreferences via RecipeService
  - Key: `recipes_v1`
  - Format: JSON array

### 마이그레이션
기존 레시피 데이터에 healthScore 없을 경우:
```dart
healthScore: json['healthScore'] as int? ?? 3
```
자동으로 기본값(3점) 할당하여 하위 호환성 보장

## 테스트 시나리오

### 1. 사용자 레시피 추가
1. 앱에서 "닭고기볶음" 레시피 생성
2. 재료: 닭고기 300g, 양파 1개, 간장 2T
3. healthScore는 자동으로 3점

### 2. 음성 추천 요청
```
사용자: "빅스비, 닭고기로 뭐 해먹지?"
시스템: 
  1. 기본 레시피 검색 (닭볶음탕, 삼계탕 등)
  2. 사용자 레시피 검색 (닭고기볶음)
  3. 모두 통합하여 추천
```

### 3. UI 확인
- 사용자 레시피는 👤 아이콘 표시
- "👤 내가 만든 레시피" 라벨
- 건강 점수 표시 (🟡 보통)
- 유통기한 임박 재료 강조

### 4. 학습 효과
사용자가 "닭고기볶음"을 3회 선택 후:
- 추천 가중치 증가 (frequency: 3)
- 다음 추천 시 상위 노출 확률 증가

## 향후 개선 사항

### Phase 1 (완료)
- ✅ Recipe 모델에 healthScore 추가
- ✅ RecipeRecommendationUtils에 사용자 레시피 통합
- ✅ UI에서 사용자 레시피 구분 표시
- ✅ 학습 시스템과 연동

### Phase 2 (예정)
- [ ] 레시피 생성/수정 UI에 건강 점수 입력 추가
- [ ] 건강 점수 자동 추정 알고리즘 개선
  - 조리 방법 분석
  - 채소/단백질 비율 계산
  - 칼로리/나트륨 추정
- [ ] 사용자 레시피 카테고리 필터
  - "내 닭고기 레시피만 보기"
  - "건강한 내 레시피만 보기"

### Phase 3 (검토 중)
- [ ] 레시피 공유 기능
- [ ] 가족 구성원 간 레시피 공유
- [ ] 레시피 평가 시스템 (맛 점수)
- [ ] 계절별 추천 (여름=냉면, 겨울=찌개)

## 문제 해결

### Q: 사용자 레시피가 추천에 안 나와요
**A:** 재료 매칭률이 50% 미만일 수 있습니다.
- 레시피 재료 수 확인
- 냉장고 재료와 일치 여부 확인
- 재료 이름 정확히 입력 (예: "달고기" ❌, "닭고기" ✅)

### Q: 건강 점수를 변경하고 싶어요
**A:** 현재는 기본값(3점) 사용. Phase 2에서 UI 추가 예정.
임시 방법: 개발자 도구로 SharedPreferences 직접 수정

### Q: 기본 레시피와 사용자 레시피 우선순위는?
**A:** 동일한 알고리즘 적용. 차별 없이 추천됩니다.
- 유통기한 임박 재료 활용도가 같으면
- 건강 점수가 같으면
- 재료 매칭률로 최종 결정

## 참고 문서
- [음성 비서 통합 가이드](VOICE_ASSISTANT_INTEGRATION.md)
- [AI 학습 시스템](AI_CODE_RULES.md)
- [레시피 서비스 API](../lib/services/recipe_service.dart)
