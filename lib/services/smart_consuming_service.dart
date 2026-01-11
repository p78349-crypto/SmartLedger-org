import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/fixed_cost_service.dart';
import '../services/budget_service.dart';

class SmartConsumingService {
  static final SmartConsumingService _instance =
      SmartConsumingService._internal();

  factory SmartConsumingService() => _instance;

  SmartConsumingService._internal();

  /// 소비 가능 여부 분석
  Future<ConsumptionAdvice> analyzeSpending(
    String accountName,
    double amount,
  ) async {
    final now = DateTime.now();
    final budgetService = BudgetService();
    // 예산 로드 필요시 호출
    await budgetService.loadBudgets();

    // 1. 현재 예산 상태
    final monthlyBudget = budgetService.getBudget(accountName);
    if (monthlyBudget <= 0) {
      return ConsumptionAdvice(
        canSpend: true,
        message: '예산이 설정되지 않았습니다. 자유롭게 사용하시되, 기록을 잊지 마세요.',
        details: '예산 미설정',
      );
    }

    // 2. 현재 지출 내역 (이번 달)
    final service = TransactionService();
    // 트랜잭션 로드가 상위에서 이미 되었거나, 여기서 확인
    await service.loadTransactions(); // Ensure loaded

    final transactions = service.getTransactions(accountName).where((tx) {
      return tx.date.year == now.year &&
          tx.date.month == now.month &&
          (tx.type == TransactionType.expense ||
              tx.type == TransactionType.refund);
    }).toList();

    final currentSpent = transactions.fold(0.0, (sum, tx) {
      if (tx.type == TransactionType.expense) return sum + tx.amount;
      if (tx.type == TransactionType.refund) return sum - tx.amount;
      return sum;
    });
    final remainingBudget = monthlyBudget - currentSpent;

    // 3. 다가오는 고정 지출 확인 (이번 달 남은 기간)
    final fixedCosts = FixedCostService().getFixedCosts(accountName);
    double upcomingFixedCosts = 0;

    // 간단한 로직: 고정 지출 날짜가 오늘 이후이고 이번 달 내인 경우
    for (var fc in fixedCosts) {
      final day = fc.dueDay;
      if (day != null && day > now.day) {
        upcomingFixedCosts += fc.amount;
      }
    }

    final safeToSpend = remainingBudget - upcomingFixedCosts;

    // A. 안전하게 사용 가능
    if (amount <= safeToSpend) {
      return ConsumptionAdvice(
        canSpend: true,
        message: '네, 사용하셔도 안전합니다.',
        details:
            '남은 예산: ${remainingBudget.toInt()}원\n'
            '예정된 고정 지출: ${upcomingFixedCosts.toInt()}원 제외 후\n'
            '가용 자금: ${(safeToSpend - amount).toInt()}원 남음',
      );
    }

    // B. 예산 부족 (회복 탄력성 포인트 제안)
    // 1. 단순 예산 초과
    if (amount > remainingBudget) {
      return _generateResilienceAdvice(
        shortage: amount - remainingBudget,
        transactions: transactions,
        upcomingFixedCosts: upcomingFixedCosts,
      );
    }

    // 2. 예산은 남았지만 고정 지출 고려 시 부족
    return ConsumptionAdvice(
      canSpend: false,
      message: '잔액은 있지만, 곧 나갈 고정 지출을 고려하면 부족합니다.',
      details:
          '현재 잔액: ${remainingBudget.toInt()}원\n'
          '예정된 고정 지출(${upcomingFixedCosts.toInt()}원)을 빼면\n'
          '${safeToSpend.toInt()}원만 쓸 수 있어요.',
    );
  }

  ConsumptionAdvice _generateResilienceAdvice({
    required double shortage, // 부족분
    required List<Transaction> transactions,
    required double upcomingFixedCosts,
  }) {
    // 1. 줄일 수 있는 카테고리 분석 (식비, 카페/간식 등 변동비)
    final flexibleCategories = ['식비', '카페/간식', '쇼핑/생활', '취미/여가'];

    // 카테고리별 지출 집계
    final Map<String, double> catSpent = {};
    for (var tx in transactions) {
      if (flexibleCategories.contains(tx.mainCategory)) {
        catSpent[tx.mainCategory] =
            (catSpent[tx.mainCategory] ?? 0) + tx.amount;
      }
    }

    // 예: 전체 기간 대비 일일 평균 지출을 줄이는 제안 등.
    // 여기서는 간단히 "커피 N잔"으로 환산하거나 구체적 삭감 제안

    // 부족분이 크지 않다면 (예: 5만원 이하)
    if (shortage < 50000) {
      final coffeeCount = (shortage / 5000).ceil();
      return ConsumptionAdvice(
        canSpend: true, // 조건부 승인
        message: '예산이 부족하지만, 회복 가능합니다.',
        details:
            '부족한 ${shortage.toInt()}원은\n'
            '이번 주 커피 $coffeeCount잔을 줄이거나\n'
            '외식을 한 번 줄이면 메꿀 수 있습니다.\n'
            '진행하시겠습니까?',
        isResilience: true,
      );
    }

    return ConsumptionAdvice(
      canSpend: false,
      message: '현재 예산으로는 무리입니다.',
      details:
          '부족금액: ${shortage.toInt()}원\n'
          '이번 달 남은 예산이 이미 초과되었습니다.\n'
          '이번 달 남은 예산이 이미 초과되었습니다.\n'
          '다음 달 예산이 갱신될 때까지 기다리시는 게 좋겠습니다.',
    );
  }

  /// 주간 점검 로직 (Weekly Logic)
  /// - Weekly Sector: 주차별 목표
  /// - Burn Rate: 예산 소진 속도
  /// - Tactical Shift: 동적 목표 수정
  Future<WeeklyReport> analyzeWeeklyStatus(String accountName) async {
    final now = DateTime.now();
    final budgetService = BudgetService();
    await budgetService.loadBudgets();

    final monthlyBudget = budgetService.getBudget(accountName);
    if (monthlyBudget <= 0) {
      return WeeklyReport(
        currentWeek: 1,
        weeklyBudget: 0,
        burnRate: 0,
        recommendedLimit: 0,
        message: '예산 미설정',
        subMessage: '월 예산을 먼저 설정해주세요.',
      );
    }

    // 1. Weekly Sector (이번 달 총 주수 및 현재 주차)
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final totalWeeks = (daysInMonth / 7).ceil();
    final currentWeek = ((now.day - 1) / 7).floor() + 1;

    // 기본 주간 목표 (단순 균등 분배)
    final standardWeeklyBudget = monthlyBudget / totalWeeks;

    // 2. Burn Rate (지출 속도)
    final txService = TransactionService();
    await txService.loadTransactions();
    final transactions = txService.getTransactions(accountName).where((tx) {
      return tx.date.year == now.year &&
          tx.date.month == now.month &&
          (tx.type == TransactionType.expense ||
              tx.type == TransactionType.refund);
    }).toList();

    final totalSpent = transactions.fold(0.0, (sum, tx) {
      if (tx.type == TransactionType.expense) return sum + tx.amount;
      if (tx.type == TransactionType.refund) return sum - tx.amount;
      return sum;
    });

    // 시간 경과율 vs 예산 소진율
    final timeRatio = now.day / daysInMonth; // 예: 10일/30일 = 0.33
    final budgetRatio = totalSpent / monthlyBudget; // 예: 50만원/100만원 = 0.5

    // 번 레이트: 1.0이 적정. 높을수록 과소비 중.
    final burnRate = timeRatio > 0 ? budgetRatio / timeRatio : 0.0;

    // 3. Tactical Shift (전술 수정)
    // 앞으로 나갈 고정 지출을 미리 뺍니다.
    final fixedCosts = FixedCostService().getFixedCosts(accountName);
    double upcomingFixedCosts = 0;
    for (var fc in fixedCosts) {
      final day = fc.dueDay;
      if (day != null && day > now.day) {
        upcomingFixedCosts += fc.amount;
      }
    }

    // 실제 가용 잔액 (Safe to Spend Remaining)
    final realRemaining = monthlyBudget - totalSpent - upcomingFixedCosts;

    // 남은 기간 (이번 주 포함)
    // 예: 2주차라면, 남은 주는 총주수 - 1주(지난주) = 아니, 지금부터 말일까지니까
    // 그냥 남은 주 = totalWeeks - (currentWeek - 1) 로 계산해서 N분의 1
    final remainingWeeks = totalWeeks - (currentWeek - 1);

    double recommendedLimit = 0;
    String tacticalMessage = '';

    if (realRemaining <= 0) {
      recommendedLimit = 0;
      tacticalMessage = '긴급: 이미 가용 예산을 초과했습니다. 지출을 멈춰야 합니다.';
    } else {
      // 남은 돈을 남은 주 수로 나눔 (Tactical Adjustment)
      recommendedLimit = realRemaining / remainingWeeks;

      final diffRatio = recommendedLimit / standardWeeklyBudget;

      if (diffRatio < 0.8) {
        tacticalMessage = '지난 과소비로 인해 이번 주는 긴축 재정이 필요합니다. ($currentWeek주차)';
      } else if (diffRatio > 1.2) {
        tacticalMessage = '여유가 있습니다! 작은 보상을 즐기셔도 좋습니다. ($currentWeek주차)';
      } else {
        tacticalMessage = '페이스가 아주 좋습니다. 이대로 유지하세요. ($currentWeek주차)';
      }
    }

    return WeeklyReport(
      currentWeek: currentWeek,
      weeklyBudget: standardWeeklyBudget,
      burnRate: burnRate,
      recommendedLimit: recommendedLimit,
      message: '현재 $currentWeek주차, 번 레이트 ${burnRate.toStringAsFixed(2)}배',
      subMessage: tacticalMessage,
    );
  }
}

class WeeklyReport {
  final int currentWeek;
  final double weeklyBudget; // 월초 설정된 주간 균등 목표
  final double burnRate; // 속도 지표
  final double recommendedLimit; // 전술 수정된 이번 주 목표
  final String message;
  final String subMessage;

  WeeklyReport({
    required this.currentWeek,
    required this.weeklyBudget,
    required this.burnRate,
    required this.recommendedLimit,
    required this.message,
    required this.subMessage,
  });
}

class ConsumptionAdvice {
  final bool canSpend;
  final String message;
  final String details;
  final bool isResilience;

  ConsumptionAdvice({
    required this.canSpend,
    required this.message,
    required this.details,
    this.isResilience = false,
  });
}
