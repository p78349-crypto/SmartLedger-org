import 'package:flutter/foundation.dart';

/// 요리 사용 기록: 언제 어떤 요리를 했는지, 어떤 식재료가 사용되었는지 기록
@immutable
class CookingUsageLog {
  final String id;
  final String recipeName; // 요리명: '김치찌개', 'Pasta' 등
  final DateTime usageDate; // 요리한 날짜
  final String memo; // 추가 메모

  /// 이 요리에서 사용된 식재료들의 총 금액 (원)
  /// 계산 방식: 각 재료의 (가격/원래수량 * 사용량)의 합
  final double totalUsedPrice;

  /// 사용된 식재료 목록 (JSON 형식으로 저장)
  /// [{"name": "김치", "used": 0.25, "unit": "포기", "price": 5000}, ...]
  final String usedIngredientsJson;

  /// 냉파 챌린지 기간(20일~말일)에 추가 구매 없이 해결했는가?
  final bool isFromExistingInventory;

  const CookingUsageLog({
    required this.id,
    required this.recipeName,
    required this.usageDate,
    this.memo = '',
    required this.totalUsedPrice,
    this.usedIngredientsJson = '[]',
    this.isFromExistingInventory = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'recipeName': recipeName,
    'usageDate': usageDate.toIso8601String(),
    'memo': memo,
    'totalUsedPrice': totalUsedPrice,
    'usedIngredientsJson': usedIngredientsJson,
    'isFromExistingInventory': isFromExistingInventory,
  };

  static CookingUsageLog fromJson(Map<String, dynamic> json) {
    return CookingUsageLog(
      id: (json['id'] as String?) ?? '',
      recipeName: (json['recipeName'] as String?) ?? '',
      usageDate: json['usageDate'] is String
          ? DateTime.parse(json['usageDate'] as String)
          : DateTime.now(),
      memo: (json['memo'] as String?) ?? '',
      totalUsedPrice: (json['totalUsedPrice'] as num?)?.toDouble() ?? 0.0,
      usedIngredientsJson: (json['usedIngredientsJson'] as String?) ?? '[]',
      isFromExistingInventory:
          (json['isFromExistingInventory'] as bool?) ?? false,
    );
  }
}
