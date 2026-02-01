import 'package:intl/intl.dart';

import '../utils/weather_price_sensitivity.dart';
import '../widgets/weather_alert_widget.dart';
import 'shopping_list_generator_models.dart';
import 'shopping_list_generator_price_db.dart';

/// 쇼핑 리스트 자동 생성 유틸리티
class ShoppingListGenerator {
  static final NumberFormat _priceFormat = NumberFormat('#,##0', 'ko_KR');

  static String formatPrice(num amount) => _priceFormat.format(amount);

  /// 날씨 예보 기반 쇼핑 리스트 생성
  ///
  /// [forecast] 날씨 예보 데이터
  /// [familySize] 가족 구성원 수 (기본 2명)
  static ShoppingListResult generateShoppingList({
    required WeatherForecast forecast,
    int familySize = 2,
  }) {
    if (!forecast.needsPreparation) {
      return ShoppingListResult(
        forecast: forecast,
        items: [],
        urgentMessage: '정상 날씨입니다. 대비 불필요합니다.',
        totalCost: 0,
        potentialSavings: 0,
      );
    }

    final items = <ShoppingListItem>[];
    final condition = forecast.condition;
    final prepItems = weatherPrepDatabase[condition] ?? [];
    final urgency = forecast.urgency;

    // 대비 품목을 쇼핑 리스트로 변환
    for (final prep in prepItems) {
      // 가족 수에 따라 수량 조정
      final adjustedQuantity = _adjustQuantityByFamily(
        prep.quantity,
        familySize,
        prep.category,
      );

      // 긴급도 판단 (안전용품 + 신선식품은 긴급)
      final isUrgent =
          urgency >= 3 &&
          (prep.category == PrepCategory.safety ||
              prep.category == PrepCategory.freshFood);

      // 우선순위 계산
      final priority = _calculatePriority(
        category: prep.category,
        urgency: urgency,
        daysUntil: forecast.daysUntil,
      );

      // 예상 가격
      final estimatedPrice = itemPriceDatabase[prep.name] ?? 5000;

      items.add(
        ShoppingListItem(
          name: prep.name,
          category: prep.category,
          quantity: adjustedQuantity,
          unit: prep.unit,
          reason: prep.reason,
          priority: priority,
          isUrgent: isUrgent,
          estimatedPrice: estimatedPrice,
        ),
      );
    }

    // 우선순위 기준 정렬
    items.sort((a, b) => b.priority.compareTo(a.priority));

    // 총 비용 계산
    final totalCost = items.fold<int>(0, (sum, item) => sum + item.totalCost);

    // 예상 절약액 계산 (가격 변동 예측 기반)
    final potentialSavings = _calculatePotentialSavings(
      items: items,
      condition: condition,
      daysUntil: forecast.daysUntil,
    );

    // 긴급 메시지 생성
    final urgentMessage = _generateUrgentMessage(
      forecast: forecast,
      itemCount: items.length,
      urgentCount: items.where((i) => i.isUrgent).length,
    );

    return ShoppingListResult(
      forecast: forecast,
      items: items,
      urgentMessage: urgentMessage,
      totalCost: totalCost,
      potentialSavings: potentialSavings,
    );
  }

  /// 가족 수에 따른 수량 조정
  static int _adjustQuantityByFamily(
    int baseQuantity,
    int familySize,
    PrepCategory category,
  ) {
    // 안전용품은 고정 수량
    if (category == PrepCategory.safety) {
      return baseQuantity;
    }

    // 식품류는 가족 수 비례 (2명 기준)
    if (category == PrepCategory.freshFood ||
        category == PrepCategory.storableFood ||
        category == PrepCategory.water) {
      return (baseQuantity * familySize / 2).ceil();
    }

    return baseQuantity;
  }

  /// 우선순위 계산 (0.0~1.0)
  static double _calculatePriority({
    required PrepCategory category,
    required int urgency,
    required int daysUntil,
  }) {
    double priority = 0.5;

    // 카테고리별 기본 우선순위
    switch (category) {
      case PrepCategory.safety:
        priority += 0.3; // 안전이 최우선
        break;
      case PrepCategory.water:
        priority += 0.25;
        break;
      case PrepCategory.freshFood:
        priority += 0.2; // 신선식품 (가격 변동 큼)
        break;
      case PrepCategory.medicine:
        priority += 0.15;
        break;
      case PrepCategory.storableFood:
        priority += 0.1;
        break;
      case PrepCategory.energy:
        priority += 0.05;
        break;
    }

    // 긴급도에 따른 가중치
    priority += urgency * 0.1;

    // 며칠 남았는지에 따른 가중치 (급할수록 높음)
    if (daysUntil <= 1) {
      priority += 0.2;
    } else if (daysUntil <= 2) {
      priority += 0.1;
    }

    return priority.clamp(0.0, 1.0);
  }

  /// 예상 절약액 계산
  static int _calculatePotentialSavings({
    required List<ShoppingListItem> items,
    required WeatherCondition condition,
    required int daysUntil,
  }) {
    int savings = 0;

    // 신선식품만 가격 변동 예측
    final freshItems = items.where(
      (item) => item.category == PrepCategory.freshFood,
    );

    for (final item in freshItems) {
      // 가격 변동 예측 조회
      final sensitivity = getWeatherSensitivityByItem(item.name);
      if (sensitivity == null) {
        continue;
      }

      final weatherSensitivity = sensitivity.sensitivity[condition] ?? 0.0;

      // 양수(상승)일 때만 절약 가능
      if (weatherSensitivity <= 0) {
        continue;
      }

      // 예상 상승률 (민감도 * 20%)
      final priceIncreaseRate = weatherSensitivity * 0.20;
      final futureCost = item.totalCost * (1 + priceIncreaseRate);
      final savedAmount = (futureCost - item.totalCost).toInt();
      savings += savedAmount;
    }

    return savings;
  }

  /// 긴급 메시지 생성
  static String _generateUrgentMessage({
    required WeatherForecast forecast,
    required int itemCount,
    required int urgentCount,
  }) {
    final weatherName = weatherConditionNames[forecast.condition] ?? '극한 날씨';
    final timing = forecast.preparationTiming;
    final daysText = forecast.daysUntil == 0
        ? '오늘'
        : forecast.daysUntil == 1
        ? '내일'
        : '${forecast.daysUntil}일 후';

    if (forecast.urgency >= 4) {
      return '🚨 $weatherName $daysText 예상! $timing 장보기 필수! '
          '긴급 품목 $urgentCount개 포함 총 $itemCount개 준비하세요.';
    }

    if (forecast.urgency >= 3) {
      return '⚠️ $weatherName $daysText 예상. $timing 장보기 권장. '
          '총 $itemCount개 품목 미리 확보하세요.';
    }

    return '📋 $weatherName $daysText 예상. $timing 준비하시면 됩니다. '
        '총 $itemCount개 품목.';
  }

  /// 음성 비서용 쇼핑 리스트 요약
  static String generateVoiceSummary({required ShoppingListResult result}) {
    final forecast = result.forecast;
    final weatherName = weatherConditionNames[forecast.condition] ?? '극한 날씨';
    final daysText = forecast.daysUntil == 0
        ? '오늘'
        : forecast.daysUntil == 1
        ? '내일'
        : '${forecast.daysUntil}일 후';

    final buffer = StringBuffer();
    buffer.write('$weatherName $daysText 예상됩니다. ');

    // 긴급 품목
    final urgentItems = result.urgentItems;
    if (urgentItems.isNotEmpty) {
      buffer.write('지금 즉시 구매해야 할 긴급 품목: ');
      final urgentNames = urgentItems.take(3).map((i) => i.name).join(', ');
      buffer.write('$urgentNames. ');
    }

    // 총 비용 및 절약액
    buffer.write('총 ${result.items.length}개 품목, ');
    buffer.write('예상 비용 ${_formatPrice(result.totalCost)}원');

    if (result.potentialSavings > 0) {
      buffer.write(
        '. 미리 사면 ${_formatPrice(result.potentialSavings)}원 '
        '절약 가능합니다',
      );
    }

    buffer.write('.');
    return buffer.toString();
  }

  /// 가격 포맷 (천 단위 쉼표)
  static String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
