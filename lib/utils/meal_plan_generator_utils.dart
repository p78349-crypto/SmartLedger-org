import 'package:smart_ledger/models/food_expiry_item.dart';

/// 3일/1주일 식단표 자동 제안 유틸리티
class MealPlanGeneratorUtils {
  /// 기본 식사 계획 템플릿
  static const Map<String, Map<String, List<String>>> mealTemplates = {
    '한식 중심': {
      '아침': ['계란프라이/계란말이', '밥', '미역국/된장국'],
      '점심': ['비빔밥', '김치찌개', '된장국'],
      '저녁': ['고등어구이', '두부구이', '나물무침'],
    },
    '간편식 중심': {
      '아침': ['계란스크램블', '식빵', '우유'],
      '점심': ['파스타/우동', '샐러드'],
      '저녁': ['계란볶음밥', '스프'],
    },
    '채식 중심': {
      '아침': ['두부스크램블', '채소 샐러드', '요거트'],
      '점심': ['채소볶음밥', '버섯스프'],
      '저녁': ['두부 카레', '현미밥'],
    },
    '저가 중심': {
      '아침': ['계란말이', '밥', '된장국'],
      '점심': ['계란 우동', '김'],
      '저녁': ['계란 스크램블', '쌀밥'],
    },
  };

  /// 3일 식단 생성
  static List<DayMealPlan> generate3DayMealPlan(
    List<FoodExpiryItem> items, {
    String preference = '한식 중심',
  }) {
    final ingredientNames = items.map((e) => e.name.toLowerCase()).toList();
    final plans = <DayMealPlan>[];

    for (int i = 0; i < 3; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final meals = _generateDayMeals(
        ingredientNames,
        preference,
        dayOfWeek: date.weekday,
      );
      plans.add(DayMealPlan(date: date, meals: meals));
    }

    return plans;
  }

  /// 1주일 식단 생성
  static List<DayMealPlan> generate1WeekMealPlan(
    List<FoodExpiryItem> items, {
    String preference = '한식 중심',
  }) {
    final ingredientNames = items.map((e) => e.name.toLowerCase()).toList();
    final plans = <DayMealPlan>[];

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final meals = _generateDayMeals(
        ingredientNames,
        preference,
        dayOfWeek: date.weekday,
      );
      plans.add(DayMealPlan(date: date, meals: meals));
    }

    return plans;
  }

  /// 하루 식사 생성
  static DayMeals _generateDayMeals(
    List<String> ingredients,
    String preference, {
    required int dayOfWeek,
  }) {
    final template = mealTemplates[preference] ?? mealTemplates['한식 중심']!;

    // 요일별 변화 추가
    final mealOptions = {
      '아침': _filterMealsByIngredients(template['아침']!, ingredients, dayOfWeek),
      '점심': _filterMealsByIngredients(template['점심']!, ingredients, dayOfWeek),
      '저녁': _filterMealsByIngredients(template['저녁']!, ingredients, dayOfWeek),
    };

    return DayMeals(
      breakfast: mealOptions['아침']?.first ?? template['아침']!.first,
      lunch: mealOptions['점심']?.first ?? template['점심']!.first,
      dinner: mealOptions['저녁']?.first ?? template['저녁']!.first,
      breakfastOptions: mealOptions['아침'] ?? template['아침']!,
      lunchOptions: mealOptions['점심'] ?? template['점심']!,
      dinnerOptions: mealOptions['저녁'] ?? template['저녁']!,
    );
  }

  /// 보유한 식재료로 가능한 식사 필터링
  static List<String> _filterMealsByIngredients(
    List<String> meals,
    List<String> ingredients,
    int dayOfWeek,
  ) {
    if (ingredients.isEmpty) return meals;

    // 요일별 선택지 다양화
    final dayOffset = dayOfWeek % meals.length;
    return [
      meals[dayOffset % meals.length],
      meals[(dayOffset + 1) % meals.length],
    ];
  }

  /// 식사 추천 이유 설명
  static String getMealExplanation(
    String meal,
    List<FoodExpiryItem> items,
  ) {
    final hasRelevantIngredients = items
        .where((item) => meal.toLowerCase().contains(item.name.toLowerCase()))
        .isNotEmpty;

    if (hasRelevantIngredients) {
      return '✅ 현재 보유한 식재료로 만들 수 있습니다.';
    }

    return '🍽️ 추천 식사입니다. 필요한 재료를 구입하세요.';
  }

  /// 식사 계획 요약
  static String getMealPlanSummary(List<DayMealPlan> plans) {
    if (plans.isEmpty) return '식사 계획이 없습니다.';

    final firstDay = plans.first.date;
    final lastDay = plans.last.date;
    final dayCount = plans.length;

    final dateRange = dayCount == 3
        ? '향후 3일'
        : dayCount == 7
            ? '향후 1주일'
            : '향후 $dayCount일';

    return '$dateRange의 식사 계획이 준비되었습니다. ($firstDay ~ $lastDay)';
  }

  /// 영양가 분석
  static String analyzeMealNutrition(DayMeals meals) {
    final allMeals =
        '${meals.breakfast}${meals.lunch}${meals.dinner}'.toLowerCase();

    int proteinCount = 0;
    int vegetableCount = 0;
    int carbohydrateCount = 0;

    // 단백질 음식 감지
    if (allMeals.contains('계란') ||
        allMeals.contains('고기') ||
        allMeals.contains('생선') ||
        allMeals.contains('두부')) {
      proteinCount++;
    }

    // 채소 감지
    if (allMeals.contains('채소') ||
        allMeals.contains('나물') ||
        allMeals.contains('샐러드')) {
      vegetableCount++;
    }

    // 탄수화물 감지
    if (allMeals.contains('밥') ||
        allMeals.contains('면') ||
        allMeals.contains('빵')) {
      carbohydrateCount++;
    }

    return proteinCount > 0 && vegetableCount > 0 && carbohydrateCount > 0
        ? '🌟 영양 밸런스가 좋습니다!'
        : '⚠️ 영양소가 부족할 수 있습니다.';
  }

  /// 식사 선호도 목록
  static List<String> getPreferenceOptions() {
    return mealTemplates.keys.toList();
  }

  /// 조리 난이도 평가
  static String getCookingDifficulty(String meal) {
    final simpleMeals = [
      '계란',
      '밥',
      '스프',
      '샐러드',
      '우동',
      '면',
      '국',
    ];

    final complexMeals = [
      '조림',
      '구이',
      '전',
      '찜',
      '국수',
      '카레',
    ];

    for (final simple in simpleMeals) {
      if (meal.contains(simple)) return '⭐ 쉬움';
    }

    for (final complex in complexMeals) {
      if (meal.contains(complex)) return '⭐⭐⭐ 어려움';
    }

    return '⭐⭐ 보통';
  }
}

/// 하루 식사 계획
class DayMealPlan {
  final DateTime date;
  final DayMeals meals;

  DayMealPlan({required this.date, required this.meals});

  String get formattedDate => '${date.month}월 ${date.day}일';

  String get dayOfWeek {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[date.weekday - 1];
  }

  String get displayDate => '$formattedDate($dayOfWeek)';
}

/// 하루의 아침/점심/저녁
class DayMeals {
  final String breakfast;
  final String lunch;
  final String dinner;
  final List<String> breakfastOptions;
  final List<String> lunchOptions;
  final List<String> dinnerOptions;

  DayMeals({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.breakfastOptions,
    required this.lunchOptions,
    required this.dinnerOptions,
  });
}
