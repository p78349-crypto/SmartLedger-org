/// 절약 팁 유틸리티
///
/// 카테고리별 맞춤형 절약 팁, 할인/포인트 활용법 추천,
/// 행동 가이드 제공 등 사용자의 지출 절감을 돕습니다.
library;

import 'spending_analysis_utils.dart';

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
  final String? category; // 관련 카테고리
  final double? estimatedMonthlySaving; // 예상 월 절약 금액
  final List<String> actionItems; // 구체적 실행 항목
  final int priority; // 우선순위 (1이 가장 높음)
  final String? relatedItem; // 관련 품목

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

/// 카테고리별 절약 팁 데이터베이스
class SavingTipsDatabase {
  /// 외식 관련 팁
  static const List<SavingTip> diningOutTips = [
    SavingTip(
      title: '주 1회 집밥 챌린지',
      description: '외식 대신 집에서 간단한 요리를 해보세요. 평균 1회 외식비의 60%를 절약할 수 있습니다.',
      type: SavingTipType.challenge,
      category: '외식',
      actionItems: [
        '매주 요일을 정해 집밥 데이를 만들어보세요',
        '간단한 원팬 요리부터 시작하세요',
        '밀키트를 활용하면 요리 시간을 줄일 수 있어요',
      ],
      priority: 1,
    ),
    SavingTip(
      title: '점심 도시락 챌린지',
      description: '주 2회 도시락을 싸면 월 8만원 이상 절약 가능합니다.',
      type: SavingTipType.challenge,
      category: '외식',
      actionItems: [
        '전날 저녁 반찬을 조금 더 만들어 활용하세요',
        '냉동밥을 미리 준비해두세요',
        '보온 도시락통으로 따뜻하게 드세요',
      ],
      priority: 2,
    ),
    SavingTip(
      title: '외식 예산 설정하기',
      description: '월 외식 예산을 미리 정하고 관리하세요.',
      type: SavingTipType.habit,
      category: '외식',
      actionItems: [
        '월 외식 예산을 현재의 70%로 설정해보세요',
        '특별한 날에만 외식하는 규칙을 만들어보세요',
        '배달비를 아끼려면 포장을 선택하세요',
      ],
      priority: 3,
    ),
  ];

  /// 커피/음료 관련 팁
  static const List<SavingTip> beverageTips = [
    SavingTip(
      title: '주 3회 홈카페 챌린지',
      description: '카페 커피 대신 집에서 내려마시면 1잔당 3,000원 이상 절약됩니다.',
      type: SavingTipType.challenge,
      category: '카페/음료',
      actionItems: [
        '드립백이나 캡슐커피로 시작하세요',
        '텀블러를 활용해 카페처럼 즐겨보세요',
        '원두를 직접 갈면 더 맛있어요',
      ],
      priority: 1,
    ),
    SavingTip(
      title: '구독 서비스 활용하기',
      description: '커피 정기구독 서비스를 이용하면 10~20% 할인받을 수 있습니다.',
      type: SavingTipType.subscription,
      category: '카페/음료',
      actionItems: [
        '자주 가는 카페의 정기권을 확인하세요',
        '원두 정기배송 서비스를 비교해보세요',
        '멤버십 적립을 적극 활용하세요',
      ],
      priority: 2,
    ),
    SavingTip(
      title: '사이즈 다운 챌린지',
      description: '그란데 대신 톨 사이즈로! 매일 700원씩 월 2만원 절약.',
      type: SavingTipType.habit,
      category: '카페/음료',
      actionItems: [
        '한 사이즈 작게 주문해보세요',
        '아메리카노 대신 오늘의 커피를 선택하세요',
        '시럽/샷 추가를 줄여보세요',
      ],
      priority: 3,
    ),
  ];

  /// 생활용품 관련 팁
  static const List<SavingTip> householdTips = [
    SavingTip(
      title: '대용량 구매 전략',
      description: '자주 쓰는 생필품은 대용량으로 구매하면 30% 이상 저렴합니다.',
      type: SavingTipType.bulk,
      category: '생활용품',
      actionItems: [
        '휴지, 세제 등은 대용량이 경제적이에요',
        '창고형 마트 멤버십을 고려해보세요',
        '이웃/친구와 공동구매도 좋은 방법이에요',
      ],
      priority: 1,
    ),
    SavingTip(
      title: '할인일 쇼핑하기',
      description: '마트별 할인일에 맞춰 구매하면 추가 5~10% 절약됩니다.',
      type: SavingTipType.timing,
      category: '생활용품',
      actionItems: [
        '자주 가는 마트의 할인일을 캘린더에 저장하세요',
        '1+1 행사 품목을 체크해두세요',
        '앱 쿠폰을 미리 다운받아두세요',
      ],
      priority: 2,
    ),
    SavingTip(
      title: '정기배송 활용하기',
      description: '생필품 정기배송으로 추가 할인과 편리함을 누리세요.',
      type: SavingTipType.subscription,
      category: '생활용품',
      actionItems: [
        '쿠팡 로켓와우, 마켓컬리 등의 정기배송을 비교하세요',
        '배송비 절약을 위해 합배송을 활용하세요',
        '불필요한 구독은 정리하세요',
      ],
      priority: 3,
    ),
  ];

  /// 식료품/장보기 관련 팁
  static const List<SavingTip> groceryTips = [
    SavingTip(
      title: '장보기 목록 작성하기',
      description: '미리 목록을 작성하고 그 외 품목은 구매하지 않는 습관을 들이세요.',
      type: SavingTipType.habit,
      category: '식료품',
      actionItems: [
        '냉장고 체크 후 필요한 것만 목록에 추가하세요',
        '충동구매를 피하기 위해 배부를 때 장보세요',
        '할인 품목에 휘둘리지 마세요',
      ],
      priority: 1,
    ),
    SavingTip(
      title: '제철 식품 구매하기',
      description: '제철 과일/채소는 맛도 좋고 가격도 30~50% 저렴합니다.',
      type: SavingTipType.timing,
      category: '식료품',
      actionItems: [
        '이번 달 제철 식재료를 확인하세요',
        '냉동 보관 가능한 것은 제철에 대량 구매하세요',
        '지역 농산물 직거래 장터를 이용해보세요',
      ],
      priority: 2,
    ),
    SavingTip(
      title: 'PB 상품 활용하기',
      description: '마트 자체 브랜드(PB) 상품은 20~40% 저렴합니다.',
      type: SavingTipType.alternative,
      category: '식료품',
      actionItems: [
        '노브랜드, 피코크 등 PB 상품을 시도해보세요',
        '기본 식재료는 PB로 충분해요',
        '품질 대비 가격을 비교해보세요',
      ],
      priority: 3,
    ),
  ];

  /// 교통 관련 팁
  static const List<SavingTip> transportTips = [
    SavingTip(
      title: '정기권/충전권 활용',
      description: '대중교통 정기권으로 최대 20% 절약할 수 있습니다.',
      type: SavingTipType.subscription,
      category: '교통',
      actionItems: [
        '월 이용 횟수를 계산해 정기권이 유리한지 확인하세요',
        '기후동행카드 등 정액권을 검토하세요',
        '환승 할인을 최대한 활용하세요',
      ],
      priority: 1,
    ),
    SavingTip(
      title: '카풀/공유 서비스',
      description: '출퇴근 카풀로 주유비를 절반으로 줄일 수 있습니다.',
      type: SavingTipType.alternative,
      category: '교통',
      actionItems: [
        '회사 동료와 카풀을 시도해보세요',
        '카카오카풀 등 카풀 앱을 활용하세요',
        '주 1~2회부터 시작해보세요',
      ],
      priority: 2,
    ),
  ];

  /// 쇼핑/의류 관련 팁
  static const List<SavingTip> shoppingTips = [
    SavingTip(
      title: '시즌오프 구매 전략',
      description: '시즌 끝 세일 때 다음 해 옷을 미리 구매하면 50~70% 절약됩니다.',
      type: SavingTipType.timing,
      category: '쇼핑',
      actionItems: [
        '여름옷은 8~9월, 겨울옷은 2~3월에 구매하세요',
        '아울렛 추가 할인일을 체크하세요',
        '기본 아이템 위주로 구매하세요',
      ],
      priority: 1,
    ),
    SavingTip(
      title: '원인원아웃 규칙',
      description: '새 옷을 살 때 기존 옷 하나를 정리하는 습관을 들이세요.',
      type: SavingTipType.habit,
      category: '쇼핑',
      actionItems: [
        '옷장을 정리하고 비슷한 옷이 있는지 확인하세요',
        '구매 전 24시간 생각하는 시간을 가지세요',
        '충동구매를 위시리스트에 먼저 담아두세요',
      ],
      priority: 2,
    ),
  ];

  /// 포인트/할인 관련 팁
  static const List<SavingTip> loyaltyTips = [
    SavingTip(
      title: '포인트 통합 관리',
      description: '흩어진 포인트를 모아서 관리하면 잊지 않고 사용할 수 있습니다.',
      type: SavingTipType.loyalty,
      actionItems: [
        '포인트 통합 조회 앱(뱅크샐러드 등)을 활용하세요',
        '소멸 예정 포인트를 확인하세요',
        '포인트 전환/합산 서비스를 활용하세요',
      ],
      priority: 1,
    ),
    SavingTip(
      title: '카드사 혜택 최대화',
      description: '자주 가는 곳의 제휴 카드로 결제하면 추가 적립/할인을 받을 수 있습니다.',
      type: SavingTipType.loyalty,
      actionItems: [
        '주 이용 업종에 맞는 카드를 선택하세요',
        '이달의 이벤트/추가적립을 확인하세요',
        '카드 실적 조건을 확인하고 관리하세요',
      ],
      priority: 2,
    ),
    SavingTip(
      title: '앱 쿠폰/할인 활용',
      description: '결제 전 쿠폰 검색 습관으로 5~15% 추가 절약이 가능합니다.',
      type: SavingTipType.loyalty,
      actionItems: [
        '결제 전 "브랜드명 + 쿠폰"으로 검색하세요',
        '마트/브랜드 앱 쿠폰을 미리 다운받으세요',
        '캐시백 앱(토스, 뱅샐 등)을 활용하세요',
      ],
      priority: 3,
    ),
  ];
}

/// 절약 팁 생성 유틸리티
class SavingTipsUtils {
  /// 카테고리별 맞춤 팁 제공
  static List<SavingTip> getTipsForCategory(String category) {
    final normalizedCategory = category.toLowerCase();

    if (normalizedCategory.contains('외식') ||
        normalizedCategory.contains('식당') ||
        normalizedCategory.contains('배달')) {
      return SavingTipsDatabase.diningOutTips;
    }

    if (normalizedCategory.contains('카페') ||
        normalizedCategory.contains('커피') ||
        normalizedCategory.contains('음료')) {
      return SavingTipsDatabase.beverageTips;
    }

    if (normalizedCategory.contains('생활') ||
        normalizedCategory.contains('용품') ||
        normalizedCategory.contains('세제') ||
        normalizedCategory.contains('생필품')) {
      return SavingTipsDatabase.householdTips;
    }

    if (normalizedCategory.contains('식료') ||
        normalizedCategory.contains('마트') ||
        normalizedCategory.contains('장보기') ||
        normalizedCategory.contains('식품') ||
        normalizedCategory.contains('식재료')) {
      return SavingTipsDatabase.groceryTips;
    }

    if (normalizedCategory.contains('교통') ||
        normalizedCategory.contains('주유') ||
        normalizedCategory.contains('택시')) {
      return SavingTipsDatabase.transportTips;
    }

    if (normalizedCategory.contains('쇼핑') ||
        normalizedCategory.contains('의류') ||
        normalizedCategory.contains('패션')) {
      return SavingTipsDatabase.shoppingTips;
    }

    // 기본: 포인트/할인 팁
    return SavingTipsDatabase.loyaltyTips;
  }

  /// 지출 분석 결과 기반 맞춤 팁 생성
  static List<SavingTip> generateTipsFromAnalysis({
    required List<CategorySpendingSummary> topCategories,
    required List<RecurringSpendingPattern> recurringPatterns,
    int maxTips = 5,
  }) {
    final tips = <SavingTip>[];

    // 1. 상위 지출 카테고리별 팁
    for (final category in topCategories.take(3)) {
      final categoryTips = getTipsForCategory(category.category);
      if (categoryTips.isNotEmpty) {
        // 해당 카테고리의 가장 우선순위 높은 팁 추가
        final tip = categoryTips.first;
        // 예상 절약 금액 계산 (현재 지출의 20% 가정)
        final estimatedSaving = category.totalAmount * 0.2;
        tips.add(
          SavingTip(
            title: tip.title,
            description: tip.description,
            type: tip.type,
            category: category.category,
            estimatedMonthlySaving: estimatedSaving,
            actionItems: tip.actionItems,
            priority: tip.priority,
          ),
        );
      }
    }

    // 2. 반복 지출 패턴 기반 팁
    for (final pattern in recurringPatterns.take(3)) {
      if (pattern.frequency >= 4) {
        // 월 4회 이상 반복 구매
        tips.add(
          SavingTip(
            title: '${pattern.name} 구매 패턴 발견',
            description:
                '월 평균 ${pattern.frequency}회 구매 중입니다. '
                '대용량 구매나 구독 서비스를 고려해보세요.',
            type: SavingTipType.bulk,
            category: pattern.category,
            estimatedMonthlySaving:
                pattern.avgAmount * pattern.frequency * 0.15,
            actionItems: [
              '대용량 제품으로 전환 시 약 15% 절약 가능',
              '정기배송 서비스 할인 확인하기',
              '묶음 구매 프로모션 활용하기',
            ],
            priority: 2,
            relatedItem: pattern.name,
          ),
        );
      }
    }

    // 3. 전월 대비 증가 카테고리 경고 팁
    for (final category in topCategories) {
      if (category.monthOverMonthChange > 30) {
        tips.add(
          SavingTip(
            title: '${category.category} 지출 급증 주의',
            description:
                '전월 대비 '
                '${category.monthOverMonthChange.toStringAsFixed(0)}% '
                '증가했습니다. '
                '지출 원인을 점검해보세요.',
            type: SavingTipType.habit,
            category: category.category,
            actionItems: [
              '이번 달 ${category.category} 내역 확인하기',
              '불필요한 지출이 있었는지 검토하기',
              '다음 달 예산 재설정하기',
            ],
            priority: 1,
          ),
        );
      }
    }

    // 4. 항상 포인트/할인 팁 하나 추가
    if (tips.length < maxTips) {
      tips.add(SavingTipsDatabase.loyaltyTips.first);
    }

    // 우선순위 정렬 후 반환
    tips.sort((a, b) => a.priority.compareTo(b.priority));
    return tips.take(maxTips).toList();
  }

  /// 중복 구매 위험 항목에 대한 팁 생성
  static List<SavingTip> generateDuplicatePurchaseWarnings(
    List<RecurringSpendingPattern> risks,
  ) {
    return risks.map((pattern) {
      final daysSinceLast = DateTime.now()
          .difference(pattern.purchaseDates.last)
          .inDays;
      final nextPurchaseIn = pattern.avgInterval.round() - daysSinceLast;

      return SavingTip(
        title: '${pattern.name} 재구매 주의',
        description:
            '최근 $daysSinceLast일 전에 구매했습니다. '
            '평균 구매 주기(${pattern.avgInterval.round()}일)에 따르면 '
            '약 $nextPurchaseIn일 후 구매하면 적절합니다.',
        type: SavingTipType.habit,
        category: pattern.category,
        actionItems: [
          '구매 전 집에 재고가 있는지 확인하세요',
          '장보기 전 목록 작성 습관을 들이세요',
          '필요 시점까지 구매를 미뤄보세요',
        ],
        priority: 1,
        relatedItem: pattern.name,
      );
    }).toList();
  }

  /// 예상 월간 총 절약 금액 계산
  static double calculateTotalPotentialSavings(List<SavingTip> tips) {
    return tips.fold(0.0, (sum, tip) {
      return sum + (tip.estimatedMonthlySaving ?? 0);
    });
  }

  /// 팁 타입별 아이콘 이름
  static String getTipTypeIcon(SavingTipType type) {
    switch (type) {
      case SavingTipType.challenge:
        return 'emoji_events'; // 🏆
      case SavingTipType.comparison:
        return 'compare_arrows'; // ↔️
      case SavingTipType.timing:
        return 'schedule'; // ⏰
      case SavingTipType.alternative:
        return 'swap_horiz'; // 🔄
      case SavingTipType.habit:
        return 'psychology'; // 🧠
      case SavingTipType.bulk:
        return 'inventory_2'; // 📦
      case SavingTipType.subscription:
        return 'autorenew'; // 🔁
      case SavingTipType.loyalty:
        return 'card_giftcard'; // 🎁
    }
  }

  /// 팁 타입 라벨
  static String getTipTypeLabel(SavingTipType type) {
    switch (type) {
      case SavingTipType.challenge:
        return '챌린지';
      case SavingTipType.comparison:
        return '비교 분석';
      case SavingTipType.timing:
        return '타이밍';
      case SavingTipType.alternative:
        return '대안 제안';
      case SavingTipType.habit:
        return '습관 개선';
      case SavingTipType.bulk:
        return '대량 구매';
      case SavingTipType.subscription:
        return '구독 서비스';
      case SavingTipType.loyalty:
        return '포인트/할인';
    }
  }
}
