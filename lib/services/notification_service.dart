import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }

  Future<void> initialize() async {
    // 초기화 (현재는 필요 없음)
  }

  void showEmergencyFundNotification({
    required double movedAmount,
    required double currentBalance,
  }) {
    _scaffoldMessengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          '💰 비상금 이동 완료\n'
          '이동 금액: ₩${movedAmount.toStringAsFixed(0)}\n'
          '현재 비상금: ₩${currentBalance.toStringAsFixed(0)}',
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  void showInvestmentRecommendation({
    required double emergencyFundAmount,
    required int monthsToComplete,
  }) {
    _scaffoldMessengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          '🌟 예금 투자 가능!\n'
          '비상금: ₩${emergencyFundAmount.toStringAsFixed(0)}\n'
          '$monthsToComplete개월 내 목표 달성 가능',
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.amber.shade700,
      ),
    );
  }
}

