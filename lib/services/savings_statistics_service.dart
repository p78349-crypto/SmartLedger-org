import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cooking_usage_log.dart';
import '../shared/errors.dart';
import '../shared/result.dart';
import 'reward_badge_service.dart';
import 'transaction_service.dart';
import '../utils/savings_statistics_utils.dart';

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
      isFromExistingInventory: isFromExistingInventory,
    );
    logs.value = [...logs.value, log];
    await _save();

    // Reward: food-rescue medal (best-effort).
    try {
      final hasUsed =
          totalUsedPrice > 0 ||
          (usedIngredientsJson.trim().isNotEmpty &&
              usedIngredientsJson.trim() != '[]');
      if (hasUsed) {
        await RewardBadgeService.instance.awardOnce(
          accountName: 'default',
          type: RewardBadgeService.typeFoodRescue,
          dedupeKey: id,
        );
      }
    } catch (_) {
      // Ignore reward failures.
    }
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
  Future<Result<Map<String, double>>> calculateMonthlyFoodExpenses() async {
    try {
      const accountName = 'default';
      final service = TransactionService();
      final transactions = service.getTransactions(accountName);
      return Success(
        SavingsStatisticsUtils.calculateMonthlyFoodExpenses(transactions),
      );
    } catch (e) {
      return Failure(StorageError('월별 식비 계산 실패: $e'));
    }
  }

  /// 챌린지 도입 전(1개월 이전)과 현재(이번 달) 식비 비교
  Future<
    Result<
      ({
        double beforePrice,
        double afterPrice,
        double savingsAmount,
        double savingsPercent,
      })
    >
  >
  calculateSavingsCompare() async {
    final expenseResult = await calculateMonthlyFoodExpenses();
    return expenseResult.when(
      success: (data) {
        try {
          return Success(SavingsStatisticsUtils.compareSavings(data));
        } catch (e) {
          return Failure(StorageError('절약 비교 계산 실패: $e'));
        }
      },
      failure: Failure.new,
    );
  }
}
