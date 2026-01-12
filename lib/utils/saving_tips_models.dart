/// 절약 팁: 타입/모델 정의
library saving_tips_models;

/// 절약 팁 타입
enum SavingTipType {
  challenge, // 챌린지 형 (주 1회 집밥 등)
  comparison, // 비교 제안 (대용량 vs 소량)
  timing, // 타이밍 제안 (할인일 구매)
  alternative, // 대안 제안 (외식 대신 밀키트)
  habit, // 습관 변경 (커피 줄이기)
  bulk, // 대량 구매 추천
  subscription, // 구독/정기배송 추천
  loyalty, // 포인트/멤버십 활용
}

/// 개별 절약 팁
class SavingTip {
  final String title;
  final String description;
  final SavingTipType type;
  final String? category;
  final double? estimatedMonthlySaving;
  final List<String> actionItems;
  final int priority;
  final String? relatedItem;

  const SavingTip({
    required this.title,
    required this.description,
    required this.type,
    this.category,
    this.estimatedMonthlySaving,
    this.actionItems = const [],
    this.priority = 5,
    this.relatedItem,
  });
}
