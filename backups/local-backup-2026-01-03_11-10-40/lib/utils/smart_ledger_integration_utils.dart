import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/market_analysis_utils.dart';
import 'package:smart_ledger/utils/shopping_workflow_utils.dart';
import 'package:smart_ledger/utils/weather_capture_utils.dart';

/// Smart Ledger 통합 유틸리티
/// 날씨 수집 + 쇼핑 워크플로우 + 시장 분석을 통합 관리

class SmartLedgerIntegrationUtils {
  /// 앱 시작 시 초기화
  static Future<SmartLedgerSession> initializeSession() async {
    final weather = await WeatherCaptureUtils.captureWeather(isAuto: true);
    return SmartLedgerSession(
      sessionId: DateTime.now().toString(),
      startedAt: DateTime.now(),
      weather: weather,
      cartItems: [],
      transactions: [],
    );
  }

  /// 세션 상태 업데이트
  static SmartLedgerSession updateSessionWithCart(
    SmartLedgerSession session,
    List<CartItem> cartItems,
  ) {
    return SmartLedgerSession(
      sessionId: session.sessionId,
      startedAt: session.startedAt,
      weather: session.weather,
      cartItems: cartItems,
      transactions: session.transactions,
    );
  }

  /// 세션 상태 업데이트 (거래)
  static SmartLedgerSession updateSessionWithTransactions(
    SmartLedgerSession session,
    List<Transaction> transactions,
  ) {
    return SmartLedgerSession(
      sessionId: session.sessionId,
      startedAt: session.startedAt,
      weather: session.weather,
      cartItems: session.cartItems,
      transactions: transactions,
    );
  }

  /// 세션 통계
  static SessionStatistics getSessionStatistics(SmartLedgerSession session) {
    final checkedItems = ShoppingWorkflowUtils.getCheckedItems(
      session.cartItems,
    );
    final totalCart = ShoppingWorkflowUtils.calculateTotal(session.cartItems);
    final categorySpending = MarketAnalysisUtils.getCategorySpending(
      session.transactions,
    );
    final topItems = MarketAnalysisUtils.getTopPurchasedItems(
      session.transactions,
      limit: 3,
    );

    return SessionStatistics(
      totalItems: session.cartItems.length,
      checkedItems: checkedItems.length,
      totalCartAmount: totalCart,
      transactionCount: session.transactions.length,
      totalSpent: session.transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount),
      topCategories: categorySpending,
      topItems: topItems,
      weather: session.weather,
    );
  }

  /// 세션 요약 리포트
  static String generateSessionReport(SmartLedgerSession session) {
    final stats = getSessionStatistics(session);
    final aiReport = MarketAnalysisUtils.generateAIReport(session.transactions);

    return '''
📊 Smart Ledger 세션 리포트
─────────────────────
🛒 쇼핑 카트: ${stats.totalItems}개 (체크됨: ${stats.checkedItems}개)
💰 장바구니 총액: ₩${stats.totalCartAmount.toStringAsFixed(0)}
📝 기록된 거래: ${stats.transactionCount}개
💸 총 지출: ₩${stats.totalSpent.toStringAsFixed(0)}

🌤️ 오늘의 날씨: ${stats.weather.condition} (${stats.weather.tempC}°C)

🤖 AI 리포트:
$aiReport
─────────────────────
세션: ${session.sessionId}
시작: ${session.startedAt}
''';
  }
}

/// 세션 정보
class SmartLedgerSession {
  final String sessionId;
  final DateTime startedAt;
  final WeatherSnapshot weather;
  final List<CartItem> cartItems;
  final List<Transaction> transactions;

  SmartLedgerSession({
    required this.sessionId,
    required this.startedAt,
    required this.weather,
    required this.cartItems,
    required this.transactions,
  });

  /// 세션 경과 시간
  Duration get elapsedTime => DateTime.now().difference(startedAt);

  @override
  String toString() {
    return 'SmartLedgerSession('
        '$sessionId, '
        '${cartItems.length} items, '
        '${transactions.length} txns)';
  }
}

/// 세션 통계
class SessionStatistics {
  final int totalItems;
  final int checkedItems;
  final double totalCartAmount;
  final int transactionCount;
  final double totalSpent;
  final Map<String, double> topCategories;
  final List<String> topItems;
  final WeatherSnapshot weather;

  SessionStatistics({
    required this.totalItems,
    required this.checkedItems,
    required this.totalCartAmount,
    required this.transactionCount,
    required this.totalSpent,
    required this.topCategories,
    required this.topItems,
    required this.weather,
  });

  /// 평균 아이템 가격
  double get avgItemPrice => totalItems > 0 ? totalCartAmount / totalItems : 0;

  /// 평균 거래 금액
  double get avgTransactionAmount =>
      transactionCount > 0 ? totalSpent / transactionCount : 0;

  @override
  String toString() {
    return 'SessionStatistics('
        '$totalItems items, '
        '₩$totalSpent spent)';
  }
}
