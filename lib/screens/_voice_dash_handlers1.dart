// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 월말정산, 재고 보고, 화면 네비게이션 핸들러.
extension VoiceDashHandlers1 on _VoiceDashboardScreenState {
  Future<VoiceCommandResult> _handleMonthlyClosing(String command) async {
    await _loadBudgetData();

    final budget = BudgetService().getBudget(_accountName);
    if (budget <= 0) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '설정된 예산이 없습니다. 예산을 먼저 설정해주세요.',
        type: VoiceCommandType.query,
      );
    }

    final now = DateTime.now();
    final history = TransactionService().getTransactions(_accountName);
    final monthSpent = history.fold(0.0, (sum, t) {
      if (t.type == TransactionType.expense &&
          t.date.year == now.year && t.date.month == now.month) {
        return sum + t.amount;
      }
      return sum;
    });

    final remaining = budget - monthSpent;
    final sb = StringBuffer();

    if (remaining < 0) {
      final over = remaining.abs();
      sb.write('이번 달은 설정한 예산보다 많이 사용하셨네요. 😥\n');
      sb.write(
        '총 ${CurrencyFormatter.format(over)} 초과되었습니다. 다음 달엔 조금 더 아껴볼까요?',
      );
    } else {
      sb.write(
        '축하해요! 이번 달 예산이 ${CurrencyFormatter.format(remaining)} 남았습니다. 🎉\n\n',
      );
      sb.write('💡 남은 돈은 이렇게 할 수 있어요:\n');
      sb.write('1. 이월하기 (다음 달 지출 예산에 마음속으로 합산)\n');
      sb.write('2. 비상금이나 자산(현금)으로 보내기');
    }

    return VoiceCommandResult(
      command: command,
      success: true,
      message: sb.toString(),
      type: VoiceCommandType.query,
    );
  }

  Future<VoiceCommandResult> _handleInventoryReport(String command) async {
    final foodItems = ConsumableInventoryService.instance.items.value;
    final now = DateTime.now();
    final expiringFood = foodItems.where((i) {
      final expiryDate = i.expiryDate;
      if (expiryDate == null) return false;
      final days = expiryDate.difference(now).inDays;
      return days >= 0 && days <= 3;
    }).toList();

    final consumableItems = ConsumableInventoryService.instance.items.value;
    final lowStockItems = consumableItems
        .where((i) => i.currentStock <= i.threshold)
        .toList();

    final sb = StringBuffer();
    bool hasIssue = false;

    if (expiringFood.isEmpty && lowStockItems.isEmpty) {
      return VoiceCommandResult(
        command: command,
        success: true,
        message:
            '유통기한 임박 식재료나 부족한 생필품이 없습니다.\n\n💡 사용내역을 입력하시면 외출해서도 냉장고 안을 볼 수 있습니다.',
        type: VoiceCommandType.query,
      );
    }

    if (expiringFood.isNotEmpty) {
      hasIssue = true;
      sb.write('유통기한 임박 재료가 ${expiringFood.length}개 있습니다. ');
      if (expiringFood.length <= 3) {
        final names = expiringFood.map((e) => e.name).join(', ');
        sb.write('($names) ');
      }
    }

    if (lowStockItems.isNotEmpty) {
      if (hasIssue) sb.write('\n');
      sb.write('부족한 생필품이 ${lowStockItems.length}개 있습니다. ');
      if (lowStockItems.length <= 3) {
        final names = lowStockItems.map((e) => e.name).join(', ');
        sb.write('($names)');
      }
    }

    sb.write('\n\n💡 사용내역을 입력하시면 외출해서도 냉장고 안을 볼 수 있습니다.');

    return VoiceCommandResult(
      command: command,
      success: true,
      message: sb.toString().trim(),
      type: VoiceCommandType.query,
    );
  }

  Future<VoiceCommandResult> _handleNavigationCommand(String cmd) async {
    String? route;
    String screenName = '';
    int? mainPageIndex;

    if (cmd.contains('1페이지') ||
        (cmd.contains('대시보드') && (cmd.contains('가줘') || cmd.contains('이동')))) {
      mainPageIndex = 0;
      screenName = '대시보드';
    } else if (cmd.contains('2페이지') || cmd.contains('요리') ||
        cmd.contains('쇼핑') || cmd.contains('지출')) {
      if (!(cmd.contains('통계') || cmd.contains('현황') || cmd.contains('내역'))) {
        mainPageIndex = 1;
        screenName = '요리/쇼핑/지출';
      }
    } else if (cmd.contains('3페이지') || cmd.contains('수입')) {
      if (!(cmd.contains('입력') || cmd.contains('추가'))) {
        mainPageIndex = 2;
        screenName = '수입';
      }
    } else if (cmd.contains('4페이지') ||
        (cmd.contains('통계') && !cmd.contains('지출'))) {
      mainPageIndex = 3;
      screenName = '통계';
    } else if (cmd.contains('5페이지') ||
        cmd.contains('자산') || cmd.contains('통장')) {
      mainPageIndex = 4;
      screenName = '자산';
    } else if (cmd.contains('6페이지') ||
        cmd.contains('루트') || cmd.contains('관리자')) {
      mainPageIndex = 5;
      screenName = 'ROOT 관리';
    } else if (cmd.contains('7페이지') ||
        cmd.contains('설정') || cmd.contains('세팅')) {
      mainPageIndex = 6;
      screenName = '설정';
    }

    if (mainPageIndex != null) {
      _suspendAutoListen = true;
      if (_isListening) await _stopListening();
      if (!mounted) return _buildClosedResult(cmd);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AccountMainScreen(
            accountName: _accountName,
            initialIndex: mainPageIndex!,
          ),
        ),
      );
      _suspendAutoListen = false;
      return VoiceCommandResult(
        command: cmd, success: true,
        message: '$screenName(으)로 이동합니다.',
        type: VoiceCommandType.navigation,
      );
    }

    if (cmd.contains('가계부') || cmd.contains('대시보드') || cmd.contains('홈')) {
      route = '/';
      screenName = '메인 대시보드';
    } else if (cmd.contains('자산') || cmd.contains('통장')) {
      route = '/asset/dashboard';
      screenName = '자산 대시보드';
    } else if (cmd.contains('지출') &&
        (cmd.contains('현황') || cmd.contains('통계') || cmd.contains('내역'))) {
      route = '/stats/spending-analysis';
      screenName = '지출 통계';
    } else if (cmd.contains('유통기한') || cmd.contains('냉장고') ||
        cmd.contains('재료') || cmd.contains('식재료')) {
      route = '/food/expiry';
      screenName = '식재료 관리';
    } else if (cmd.contains('저축') || cmd.contains('적금')) {
      route = '/nudges/micro-savings';
      screenName = '저축 관리';
    } else if (cmd.contains('달력') || cmd.contains('캘린더')) {
      route = '/calendar';
      screenName = '달력';
    } else if (cmd.contains('장바구니') || cmd.contains('쇼핑')) {
      route = '/shopping/cart';
      screenName = '장바구니';
    } else if (cmd.contains('생필품') || cmd.contains('소모품')) {
      if (cmd.contains('입력') || cmd.contains('추가')) {
        route = '/household/consumables';
        screenName = '생필품 입력';
      } else {
        route = '/household/inventory';
        screenName = '생필품 재고';
      }
    } else if (cmd.contains('설정')) {
      route = '/settings';
      screenName = '설정';
    }

    if (route == null) {
      return VoiceCommandResult(
        command: cmd, success: false,
        message: '이동할 화면을 찾지 못했어요.',
        type: VoiceCommandType.navigation,
      );
    }

    _suspendAutoListen = true;
    if (_isListening) await _stopListening();
    if (!mounted) {
      _suspendAutoListen = false;
      return VoiceCommandResult(
        command: cmd, success: false,
        message: '화면이 닫혀서 이동할 수 없습니다.',
        type: VoiceCommandType.navigation,
      );
    }
    Navigator.of(context).pushNamed(route);
    _suspendAutoListen = false;
    return VoiceCommandResult(
      command: cmd, success: true,
      message: '$screenName(으)로 이동합니다.',
      type: VoiceCommandType.navigation,
    );
  }
}
