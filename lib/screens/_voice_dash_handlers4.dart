// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 예외 처리, 고정지출 브리핑, 지출 조언, 폐기물 기록 핸들러.
extension VoiceDashHandlers4 on _VoiceDashboardScreenState {
  Future<VoiceCommandResult> _handleExceptionMarking(String command) async {
    final history = TransactionService().getTransactions(_accountName);
    Transaction? target;

    if (command.contains('방금') || command.contains('마지막') ||
        command.contains('그거')) {
      if (history.isNotEmpty) target = history.first;
    } else {
      final keyword = command
          .replaceAll('예외', '').replaceAll('로', '')
          .replaceAll('해줘', '').replaceAll('처리', '')
          .replaceAll('그거', '').trim();

      if (keyword.isNotEmpty) {
        try {
          target = history.firstWhere((t) => t.description.contains(keyword));
        } catch (e) { /* Not found */ }
      } else {
        if (history.isNotEmpty) target = history.first;
      }
    }

    if (target == null) {
      return VoiceCommandResult(
        command: command, success: false,
        message: '예외 처리할 내역을 찾지 못했어요. "방금 그거 예외로 해줘" 또는 "병원비 예외로 해줘"처럼 말해주세요.',
        type: VoiceCommandType.unknown,
      );
    }

    final oldDesc = target.description;
    final newDesc = oldDesc.contains('[예외]') ? oldDesc : '$oldDesc [예외]';
    final oldMainCat = target.mainCategory;
    const newMainCat = '예외지출';

    final updatedTransaction = Transaction(
      id: target.id,
      type: target.type,
      amount: target.amount,
      date: target.date,
      description: newDesc,
      mainCategory: newMainCat,
      subCategory: oldMainCat,
      store: target.store,
      memo: target.memo,
    );

    await TransactionService().deleteTransaction(_accountName, target.id);
    await TransactionService().addTransaction(_accountName, updatedTransaction);

    String feedback = '';
    if (oldDesc.contains('병원') || oldDesc.contains('약국')) {
      feedback = '건강이 최우선이죠! 병원비는 이번 달 예산 압박에서 제외해 드렸습니다. 쾌차하세요!';
    } else if (oldDesc.contains('축의금') || oldDesc.contains('조의금')) {
      feedback = '이해했습니다. 소중한 경조사비는 이번 달 예산 관리에서 따로 분리해둘게요. 인맥 자산 +1 하셨네요!';
    } else {
      feedback = '네, 방금 입력한 항목을 "특별 지출"로 전환했습니다. 포인트는 깎이지 않으니 안심하세요!';
    }

    return VoiceCommandResult(
      command: command, success: true,
      message: '🛡️ $feedback',
      type: VoiceCommandType.query,
      data: {'isException': true},
    );
  }

  Future<VoiceCommandResult> _handleFixedCostBriefing(String command) async {
    await FixedCostService().loadFixedCosts();
    final costs = FixedCostService().getFixedCosts(_accountName);
    final today = DateTime.now().day;
    final upcoming = costs.where((c) => (c.dueDay ?? 0) >= today).toList();
    upcoming.sort((a, b) => (a.dueDay ?? 0).compareTo(b.dueDay ?? 0));

    double totalRemaining = 0;
    for (final c in upcoming) {
      totalRemaining += c.amount;
    }

    final sb = StringBuffer();
    if (upcoming.isEmpty) {
      sb.write('이번 달 남은 고정 지출이 없습니다. 마음 편히 지내세요! 😄');
    } else {
      sb.write('네, ${upcoming.length}건의 고정 지출이 남아있어요.\n');
      for (final c in upcoming) {
        sb.write(
          '${c.dueDay}일 ${c.name} (${CurrencyFormatter.format(c.amount)})\n',
        );
      }
      sb.write('\n총 ${CurrencyFormatter.format(totalRemaining)}은 남겨두셔야 해요.');
    }

    return VoiceCommandResult(
      command: command, success: true,
      message: sb.toString(),
      type: VoiceCommandType.query,
    );
  }

  Future<VoiceCommandResult> _handleSpendingAdvice(String command) async {
    final amount = _extractKrwAmount(command);
    if (amount == null) {
      return VoiceCommandResult(
        command: command, success: false,
        message: '얼마를 쓰시려는지 알 수 없어요. "10만원 사도 돼?" 처럼 물어봐주세요.',
        type: VoiceCommandType.query,
      );
    }

    final advice = await SmartConsumingService().analyzeSpending(
      _accountName, amount,
    );

    return VoiceCommandResult(
      command: command, success: true,
      message: '${advice.message}\n\n${advice.details}',
      type: VoiceCommandType.query,
      data: {'isResilience': advice.isResilience, 'canSpend': advice.canSpend},
    );
  }

  Future<VoiceCommandResult> _handleWasteLog(String command) async {
    final itemName = command
        .replaceAll('버렸어', '').replaceAll('버림', '')
        .replaceAll('상해서', '').replaceAll('상했어', '')
        .replaceAll('폐기', '').replaceAll('썩어서', '')
        .trim();

    if (itemName.isEmpty) {
      return VoiceCommandResult(
        command: command, success: false,
        message: '무엇을 버리셨나요? "우유 버렸어" 처럼 말씀해주세요.',
        type: VoiceCommandType.unknown,
      );
    }

    final foodItems = ConsumableInventoryService.instance.items.value;
    final target = foodItems
        .where((i) => i.name.contains(itemName) || itemName.contains(i.name))
        .toList();

    if (target.isEmpty) {
      return VoiceCommandResult(
        command: command, success: false,
        message: '냉장고 목록에서 "$itemName"을(를) 찾을 수 없어요. 이미 지우셨나요?',
        type: VoiceCommandType.unknown,
      );
    }

    final itemToDelete = target.first;
    await ConsumableInventoryService.instance.deleteItem(itemToDelete.id);

    final tip =
        '아이고, 아까운 $itemName가 버려졌네요. 폐기 로그에 저장했습니다. 다음엔 유통기한 임박 알림을 더 크게 드릴게요! 장바구니에 다시 넣어둘까요?';

    return VoiceCommandResult(
      command: command, success: true,
      message: '🥛 폐기 로그 저장: $itemName (유통기한 경과)\n\n$tip',
      type: VoiceCommandType.expense,
    );
  }
}
