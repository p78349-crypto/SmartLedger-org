import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../models/shopping_cart_item.dart';
import '../repositories/app_repositories.dart';
import '../services/consumable_inventory_service.dart';
import '../services/activity_household_estimator_service.dart';
import '../services/user_pref_service.dart';

part 'quick_stock_use_utils_helpers.dart';
part 'quick_stock_use_utils_sheet.dart';

/// 식료품/생활용품 사용기록 유틸리티
///
/// 상품명 입력 후 사용량 입력하면 자동 차감되는 기능 제공
class QuickStockUseUtils {
  const QuickStockUseUtils._();

  // ============================================================
  // 한글 초성 테이블
  // ============================================================
  static const List<String> _chosung = [
    'ㄱ',
    'ㄲ',
    'ㄴ',
    'ㄷ',
    'ㄸ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅃ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ',
  ];

  /// 한글 문자의 초성 추출
  static String _getChosung(String char) {
    final code = char.codeUnitAt(0);
    if (code >= 0xAC00 && code <= 0xD7A3) {
      final index = ((code - 0xAC00) / 588).floor();
      return _chosung[index];
    }
    return char;
  }

  /// 문자열의 초성 추출
  static String extractChosung(String text) {
    return text.split('').map(_getChosung).join();
  }

  /// 상품명으로 재고 아이템 검색 (부분 일치 + 초성 검색)
  static List<ConsumableInventoryItem> searchItems(String query) {
    if (query.trim().isEmpty) return [];

    final items = ConsumableInventoryService.instance.items.value;
    final lowerQuery = query.toLowerCase().trim();
    final chosungQuery = extractChosung(lowerQuery);

    final scored = <_ScoredItem>[];

    for (final item in items) {
      final lowerName = item.name.toLowerCase();
      final chosungName = extractChosung(item.name);
      int score = 0;

      if (lowerName == lowerQuery) {
        score = 100;
      } else if (lowerName.startsWith(lowerQuery)) {
        score = 80;
      } else if (lowerName.contains(lowerQuery)) {
        score = 60;
      } else if (chosungName.startsWith(chosungQuery)) {
        score = 50;
      } else if (chosungName.contains(chosungQuery)) {
        score = 40;
      }

      if (score > 0) {
        scored.add(_ScoredItem(item: item, score: score));
      }
    }

    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.item.name.compareTo(b.item.name);
    });

    return scored.map((s) => s.item).toList();
  }

  /// 정확한 이름으로 아이템 찾기
  static ConsumableInventoryItem? findExactItem(String name) {
    final items = ConsumableInventoryService.instance.items.value;
    final lowerName = name.toLowerCase().trim();

    try {
      return items.firstWhere((item) => item.name.toLowerCase() == lowerName);
    } catch (_) {
      return null;
    }
  }

  /// 재고 차감 (부족분은 장바구니에 자동 추가)
  static Future<StockUseResult> useStockWithShortage({
    required String itemId,
    required double amount,
    required String accountName,
  }) async {
    try {
      final items = ConsumableInventoryService.instance.items.value;
      final item = items.firstWhere((e) => e.id == itemId);
      final currentStock = item.currentStock;

      double actualUsed = amount;
      double shortage = 0;

      if (amount > currentStock) {
        shortage = amount - currentStock;
        actualUsed = currentStock;

        await _addToShoppingCart(
          accountName: accountName,
          itemName: item.name,
          shortage: shortage,
          unit: item.unit,
        );
      }

      if (actualUsed > 0) {
        await ConsumableInventoryService.instance.useItem(itemId, actualUsed);
      }

      final updated = ConsumableInventoryService.instance.items.value
          .firstWhere((e) => e.id == itemId, orElse: () => item);

      final trend = await ActivityHouseholdEstimatorService.compareTrend();
      final qtyFactor = _resolveQuantityFactorFromTrend(trend);

      final autoAddDaysThreshold =
          await UserPrefService.getStockUseAutoAddDepletionDaysHouseholdV1();
      final expectedDaysLeft = _calculateExpectedDepletionDays(updated);
      var addedToCartByPrediction = false;
      if (expectedDaysLeft != null &&
          expectedDaysLeft <= autoAddDaysThreshold) {
        addedToCartByPrediction = await _addToShoppingCartWithMemo(
          accountName: accountName,
          itemName: updated.name,
          memo: '예상 소진 임박 ($expectedDaysLeft일 내 소진 예상)',
          quantity: _applyFactorToIntQuantity(1, qtyFactor),
        );
      }

      final remaining = (currentStock - actualUsed).clamp(0.0, double.infinity);

      return StockUseResult(
        success: true,
        actualUsed: actualUsed,
        shortage: shortage,
        remaining: remaining,
        addedToCart: shortage > 0,
        addedToCartByPrediction: addedToCartByPrediction,
        expectedDepletionDays: expectedDaysLeft,
      );
    } catch (e) {
      return StockUseResult(
        success: false,
        actualUsed: 0,
        shortage: 0,
        remaining: 0,
        addedToCart: false,
        addedToCartByPrediction: false,
        expectedDepletionDays: null,
        error: e.toString(),
      );
    }
  }

  /// 재고 차감 (기본 - 호환성 유지)
  static Future<bool> useStock({
    required String itemId,
    required double amount,
  }) async {
    try {
      await ConsumableInventoryService.instance.useItem(itemId, amount);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 빠른 차감 다이얼로그 표시
  static Future<void> showQuickUseDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _QuickStockUseSheet(),
    );
  }
}

/// 재고 차감 결과
class StockUseResult {
  final bool success;
  final double actualUsed;
  final double shortage;
  final double remaining;
  final bool addedToCart;
  final bool addedToCartByPrediction;
  final int? expectedDepletionDays;
  final String? error;

  const StockUseResult({
    required this.success,
    required this.actualUsed,
    required this.shortage,
    required this.remaining,
    required this.addedToCart,
    required this.addedToCartByPrediction,
    required this.expectedDepletionDays,
    this.error,
  });
}

/// 검색 점수 계산용 내부 클래스
class _ScoredItem {
  final ConsumableInventoryItem item;
  final int score;

  _ScoredItem({required this.item, required this.score});
}
