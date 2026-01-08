import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/cooking_usage_log.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/savings_statistics_utils.dart';

/// 절약 통계를 계산해주는 서비스
/// 1. 냉파 성공 지수 (챌린지 기간 동안 추가 구매 없이 해결한 끼니 수)
/// 2. 구조된 식재료 금액 (유통기한 임박 식재료를 사용한 총 금액)
/// 3. 지출 감소 그래프 (챌린지 도입 전후 월별 식비 변화)
class SavingsStatisticsService {
  SavingsStatisticsService._();
  static final SavingsStatisticsService instance = SavingsStatisticsService._();

  static const String _prefsKey = 'cooking_usage_logs';

  final ValueNotifier<List<CookingUsageLog>> logs = ValueNotifier([]);

  /// 서비스 초기화
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        logs.value = [];
        return;
      }
      final List<dynamic> jsonList = jsonDecode(raw);
      logs.value = jsonList
          .map((json) => CookingUsageLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SavingsStatisticsService: Error loading logs - $e');
      logs.value = [];
    }
  }

  /// 데이터 저장
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(logs.value.map((l) => l.toJson()).toList());
      await prefs.setString(_prefsKey, raw);
    } catch (e) {
      debugPrint('SavingsStatisticsService: Error saving logs - $e');
    }
  }

  /// 요리 사용 기록 추가
  Future<void> addLog({
    required String recipeName,
    required double totalUsedPrice,
    String usedIngredientsJson = '[]',
    bool isFromExistingInventory = false,
  }) async {
    final now = DateTime.now();
    final id = 'log_${now.microsecondsSinceEpoch}';
    final log = CookingUsageLog(
      id: id,
      recipeName: recipeName,
      usageDate: now,
      totalUsedPrice: totalUsedPrice,
      usedIngredientsJson: usedIngredientsJson,
    );
    logs.value = [...logs.value, log];
    await _save();
  }

  /// 냉파 성공 지수: 챌린지 기간(20일~말일) 동안 추가 구매 없이 해결한 끼니 수
  int calculateCookingSuccessIndex() {
    return SavingsStatisticsUtils.calculateCookingSuccessIndex(logs.value);
  }

  /// 구조된 식재료: 유통기한 임박 알림을 받았으나 버리지 않고 요리에 활용한 식재료의 총 가치
  double calculateSavedIngredientsValue() {
    return SavingsStatisticsUtils.calculateSavedIngredientsValue(logs.value);
  }

  /// 지출 감소 그래프: 월별 식비 지출 변화 데이터
  /// 반환: {'2025-12': 500000, '2026-01': 450000, ...}
  Future<Map<String, double>> calculateMonthlyFoodExpenses() async {
    try {
      const accountName = 'default';
      final service = TransactionService();
      final transactions = service.getTransactions(accountName);
      return SavingsStatisticsUtils.calculateMonthlyFoodExpenses(transactions);
    } catch (e) {
      debugPrint('SavingsStatisticsService: Error calculating monthly expenses - $e');
      return {};
    }
  }

  /// 챌린지 도입 전(1개월 이전)과 현재(이번 달) 식비 비교
  Future<({double beforePrice, double afterPrice, double savingsAmount, double savingsPercent})>
      calculateSavingsCompare() async {
    try {
      final monthlyExpenses = await calculateMonthlyFoodExpenses();
      return SavingsStatisticsUtils.compareSavings(monthlyExpenses);
    } catch (e) {
      debugPrint('SavingsStatisticsService: Error calculating savings - $e');
      return (beforePrice: 0.0, afterPrice: 0.0, savingsAmount: 0.0, savingsPercent: 0.0);
    }
  }
}
