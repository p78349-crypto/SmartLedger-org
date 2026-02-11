// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 지출 기록 명령 처리.
extension VoiceDashExpense on _VoiceDashboardScreenState {
  Future<VoiceCommandResult> _handleExpenseCommand(String command) async {
    final extractedAmount = _extractKrwAmount(command);
    var amount = extractedAmount ?? 0.0;

    debugPrint('[Voice] 금액 추출: $amount from "$command"');
    if (extractedAmount == null) {
      if (!command.contains('무지출')) {
        return VoiceCommandResult(
          command: command,
          success: false,
          message: '금액을 인식하지 못했어요. "지출 5천원 커피 입력"처럼 말해주세요.',
          type: VoiceCommandType.expense,
        );
      }
    }

    if (amount < 0) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '유효하지 않은 금액입니다.',
        type: VoiceCommandType.expense,
      );
    }

    final description = _extractExpenseDescription(command);

    // [1억 프로젝트] 포인트 적립 감지
    final isPointAccumulation =
        description.contains('포인트') ||
        command.contains('적립') ||
        description.contains('무지출');
    TransactionType type = TransactionType.expense;
    String customFeedback = '';

    var (mainCategory, subCategory) = _inferCategory(description);

    if (isPointAccumulation) {
      type = TransactionType.income;
      mainCategory = '기타수입';
      subCategory = '포인트적립';

      final history = TransactionService().getTransactions(_accountName);
      final prevPoints = history.where(
        (t) =>
            (t.description.contains('포인트') ||
                (t.subCategory ?? '').contains('포인트')) &&
            t.type == TransactionType.income,
      );

      double bonusPoints = 0;
      final now = DateTime.now();

      // Golden Time Bonus
      final todayExpenses = history.where((t) {
        if (t.type != TransactionType.expense) return false;
        if (t.date.year != now.year ||
            t.date.month != now.month ||
            t.date.day != now.day) {
          return false;
        }
        final desc = t.description;
        return desc.contains('병원') || desc.contains('약국') ||
            desc.contains('치료') || desc.contains('축의금') ||
            desc.contains('조의금') || desc.contains('수리') ||
            desc.contains('과태료');
      }).toList();

      if (todayExpenses.isNotEmpty && description.contains('무지출')) {
        bonusPoints += 500;
        customFeedback +=
            '\n\n🛡️ 갑작스러운 지출에 놀라셨죠? 그래도 다른 소비를 잘 참아내셨네요! '
            '대견함의 의미로 보너스 포인트를 드립니다.';
      }

      // Payback (Recovery Points within 3 days)
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final recentShock = history.where((t) {
        if (t.type != TransactionType.expense) return false;
        if (t.date.isBefore(threeDaysAgo)) return false;
        final desc = t.description;
        return desc.contains('병원') || desc.contains('약국') ||
            desc.contains('치료') || desc.contains('축의금') ||
            desc.contains('조의금') || desc.contains('수리') ||
            desc.contains('과태료');
      }).toList();

      if (recentShock.isNotEmpty && description.contains('무지출')) {
        bonusPoints += 300;
        customFeedback +=
            '\n\n🔄 지난번 갑작스러운 지출 이후 바로 허리띠를 졸라매셨군요! 회복 탄력성이 대단하십니다. '
            '"회복 포인트" 적립해 드려요!';
      }

      amount += bonusPoints;

      final pointCount = prevPoints.length;
      final prevTotal = prevPoints.fold(0.0, (sum, t) => sum + t.amount);
      final currentTotal = prevTotal + amount;
      final double progressPercent = (currentTotal / 100000000.0) * 100;
      final String progressStr = progressPercent.toStringAsFixed(4);

      if (prevTotal < 100000 && currentTotal >= 100000) {
        customFeedback =
            '\n🎉 대단해요! 드디어 10만원을 모으셨습니다!\n'
            '🏦 이제 예금 상품으로 돈을 불릴 차례예요. 1억 프로젝트의 첫 단계 달성을 축하드립니다!';
      } else if (prevTotal < 70000 && currentTotal >= 70000) {
        customFeedback = '\n🔥 7만원 돌파! 이제 고지가 눈앞입니다. 조금만 더 힘내세요!';
      } else if (prevTotal < 50000 && currentTotal >= 50000) {
        customFeedback = '\n✨ 벌써 절반인 5만원을 모으셨네요! 시작이 반이라더니, 정말 대단합니다. 👏';
      } else if (prevTotal < 30000 && currentTotal >= 30000) {
        customFeedback = '\n🍗 3만원 달성! 치킨 한 마리 값은 벌었네요! 하지만 우린 1억을 향해 계속 갑니다!';
      } else if (prevTotal < 10000 && currentTotal >= 10000) {
        customFeedback = '\n☕ 와! 첫 1만원을 돌파했습니다! 작은 돈도 모이면 이렇게 커집니다. 계속 가볼까요?';
      } else if (pointCount == 0) {
        customFeedback = '\n🎉 첫 포인트 적립이네요! 포인트를 모아보세요. "1억 프로젝트"를 시작할 수 있습니다.';
      } else {
        customFeedback =
            '\n👍 ${pointCount + 1}번째 포인트 적립! 현재까지 총 ${CurrencyFormatter.format(currentTotal)} '
            '모으셨어요.';
      }
      customFeedback += '\n\n📈 현재 1억 중 $progressStr% 달성하셨습니다.';
    }

    String feedbackMsg =
        '🏪 $description ${CurrencyFormatter.format(amount)} 저장 완료!';
    if (customFeedback.isNotEmpty) {
      feedbackMsg += customFeedback;
    } else if (mainCategory != '미분류') {
      feedbackMsg += '\n분류: $mainCategory';
      if (subCategory != null && subCategory.isNotEmpty) {
        feedbackMsg += ' > $subCategory';
      }
    } else {
      feedbackMsg += '\n(카테고리를 찾지 못해 "미분류"로 저장했습니다)';
    }

    if (type == TransactionType.income && isPointAccumulation) {
      feedbackMsg =
          '저장 완료했습니다. 첫 포인트가 적립되었네요! 이제 1억 프로젝트의 첫발을 떼셨습니다. 이 기세로 쭉 가보시죠!\n'
          '\n(텍스트) 🏪 $description ${CurrencyFormatter.format(amount)} 저장 완료!';
    }

    final transaction = Transaction(
      id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      amount: amount,
      date: DateTime.now(),
      description: description,
      mainCategory: mainCategory,
      subCategory: subCategory,
    );

    // [음성 비서 잔소리 & 칭찬 & 위로 로직]
    await _applyExpenseNagLogic(
      type: type,
      isPointAccumulation: isPointAccumulation,
      mainCategory: mainCategory,
      description: description,
      amount: amount,
    );

    await TransactionService().addTransaction(_accountName, transaction);

    return VoiceCommandResult(
      command: command,
      success: true,
      message: feedbackMsg,
      type: VoiceCommandType.expense,
      data: {
        'amount': amount,
        'description': description,
        'category': mainCategory,
        'subCategory': subCategory,
      },
    );
  }
}
