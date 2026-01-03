import 'package:flutter/foundation.dart';

enum FoodExpiryRisk {
  safe,
  caution,
  danger,
  stable,
}

@immutable
class FoodExpiryPrediction {
  final String category;
  final int baseDays;
  final int adjustedDays;
  final FoodExpiryRisk risk;
  final DateTime suggestedExpiryDate;
  final List<String> reasons;

  const FoodExpiryPrediction({
    required this.category,
    required this.baseDays,
    required this.adjustedDays,
    required this.risk,
    required this.suggestedExpiryDate,
    required this.reasons,
  });
}

class FoodExpiryPredictionEngine {
  const FoodExpiryPredictionEngine._();

  static FoodExpiryPrediction? predict({
    required String name,
    required DateTime purchaseDate,
    required String memo,
  }) {
    final normalized = name.trim();
    if (normalized.isEmpty) return null;

    final m = memo.trim();
    final category = _guessCategory(normalized);
    final base = _baseDaysForCategory(category);
    var adjusted = base;
    var risk = _riskForCategory(category);
    final reasons = <String>[
      '표준 신선도 DB: $category → 구매일 + $base일',
    ];

    final memoLower = m.toLowerCase();
    final nameLower = normalized.toLowerCase();

    // Contextual Awareness: 냉동
    if (_containsAny(memoLower, const ['냉동', '[냉동]', 'frozen'])) {
      adjusted += 90;
      reasons.add('메모 감지: 냉동 → +90일');
    }

    // Contextual Awareness: 임박/마감/할인 → 매우 짧게
    if (_containsAny(memoLower, const ['임박', '마감', '마감세일', '할인', '세일'])) {
      // 임박은 당일/익일로 단순화
      adjusted = 1;
      risk = FoodExpiryRisk.danger;
      reasons.add('메모 감지: 임박/마감/할인 → D+1로 조정');
    }

    // 이름 자체에 임박/냉동이 섞인 경우도 보정
    if (_containsAny(nameLower, const ['냉동', '[냉동]']) && adjusted == base) {
      adjusted += 90;
      reasons.add('품목명 감지: 냉동 → +90일');
    }
    if (_containsAny(nameLower, const ['임박', '마감', '할인'])) {
      adjusted = 1;
      risk = FoodExpiryRisk.danger;
      reasons.add('품목명 감지: 임박/마감/할인 → D+1로 조정');
    }

    final suggested = DateTime(
      purchaseDate.year,
      purchaseDate.month,
      purchaseDate.day,
    ).add(Duration(days: adjusted));

    return FoodExpiryPrediction(
      category: category,
      baseDays: base,
      adjustedDays: adjusted,
      risk: risk,
      suggestedExpiryDate: suggested,
      reasons: reasons,
    );
  }

  static String _guessCategory(String name) {
    final s = name.toLowerCase();

    // 신선 육류
    if (_containsAny(s, const ['닭', '돼지', '소', '고기', '삼겹', '목살', '닭가슴', '연어', '참치', '생선'])) {
      return '신선 육류/생선';
    }

    // 버섯류
    if (_containsAny(s, const ['버섯', '표고', '느타리', '팽이', '새송이'])) {
      return '버섯류';
    }

    // 엽채류
    if (_containsAny(s, const ['양배추', '상추', '깻잎', '시금치', '배추', '부추', '샐러드', '엽채'])) {
      return '엽채류';
    }

    // 근채류
    if (_containsAny(s, const ['당근', '양파', '감자', '고구마', '무', '마늘', '대파', '근채'])) {
      return '근채류';
    }

    // 가공식품
    if (_containsAny(s, const ['라면', '과자', '통조림', '즉석', '가공', '냉동식품', '소스'])) {
      return '가공식품';
    }

    return '기타';
  }

  static int _baseDaysForCategory(String category) {
    switch (category) {
      case '신선 육류/생선':
        return 3;
      case '엽채류':
        return 7;
      case '근채류':
        return 25;
      case '버섯류':
        return 4;
      case '가공식품':
        return 180;
      default:
        return 7;
    }
  }

  static FoodExpiryRisk _riskForCategory(String category) {
    switch (category) {
      case '신선 육류/생선':
        return FoodExpiryRisk.danger;
      case '엽채류':
        return FoodExpiryRisk.caution;
      case '근채류':
        return FoodExpiryRisk.safe;
      case '버섯류':
        return FoodExpiryRisk.caution;
      case '가공식품':
        return FoodExpiryRisk.stable;
      default:
        return FoodExpiryRisk.caution;
    }
  }

  static bool _containsAny(String s, List<String> needles) {
    for (final n in needles) {
      if (s.contains(n.toLowerCase())) return true;
    }
    return false;
  }
}

