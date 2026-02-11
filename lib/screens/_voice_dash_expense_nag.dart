// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 음성 비서 잔소리 & 칭찬 & 위로 로직 (지출 시 피드백).
extension VoiceDashExpenseNag on _VoiceDashboardScreenState {
  Future<void> _applyExpenseNagLogic({
    required TransactionType type,
    required bool isPointAccumulation,
    required String mainCategory,
    required String description,
    required double amount,
  }) async {
    // ignore: unused_local_variable
    String customFeedback = '';

    if (type == TransactionType.expense) {
      bool isSpecialCase = false;

      // 1. 의료비/병원비
      if (description.contains('병원') || description.contains('약국') ||
          description.contains('치료') || description.contains('진료') ||
          description.contains('비타민') ||
          (mainCategory.contains('건강') || mainCategory.contains('의료'))) {
        isSpecialCase = true;
        const hospitalMsgPart1 =
            '\n\n💊 아이구, 어디 많이 아프신 건 아니죠? 건강을 잃으면 1억 프로젝트도 소용없어요.';
        const hospitalMsgPart2 = '약 잘 챙겨 드시고 오늘은 푹 쉬세요.';
        const hospitalMsgPart3 = '병원비 내역은 제가 알아서 잘 정리해둘게요. (포인트 연속 보호됨)';
        const hospitalMsg =
            '$hospitalMsgPart1\n$hospitalMsgPart2\n$hospitalMsgPart3';
        customFeedback += hospitalMsg;
      }
      // 2. 경조사비
      else if (description.contains('축의금') || description.contains('조의금') ||
          description.contains('부조금') || description.contains('결혼') ||
          description.contains('장례') || description.contains('화환') ||
          mainCategory.contains('경조사')) {
        isSpecialCase = true;
        customFeedback +=
            '\n\n🤝 기쁜 소식이네요! 이런 소중한 지출은 1억 프로젝트 포인트 차감 대상에서 제외됩니다. '
            '인맥이라는 더 큰 자산을 쌓으셨으니까요! (포인트 차감 면제)';
      }
      // 3. 자기계발
      else if (description.contains('도서') || description.contains('책') ||
          description.contains('강의') || description.contains('수강') ||
          description.contains('학원') || description.contains('공부')) {
        isSpecialCase = true;
        customFeedback +=
            '\n\n📚 미래를 위한 투자는 언제나 옳습니다! 1억 프로젝트의 핵심은 결국 "나 자신"의 가치를 높이는 거니까요. '
            '응원합니다!';
      }
      // 4. 공과금/세금
      else if (description.contains('공과금') || description.contains('세금') ||
          description.contains('수도') || description.contains('전기') ||
          description.contains('가스') || description.contains('관리비')) {
        isSpecialCase = true;
        customFeedback +=
            '\n\n💡 숨만 쉬어도 나가는 돈이지만, 연체 없이 깔끔하게 처리하셨네요! 신용 점수도 자산입니다.';
      }
      // 5. 수리/과태료
      else if (description.contains('수리') || description.contains('과태료') ||
          description.contains('벌금') || description.contains('사고')) {
        isSpecialCase = true;
        customFeedback +=
            '\n\n🛠 악! 정말 속상하시겠어요. 예상치 못한 복병이 나타났네요. 하지만 액땜했다고 생각해요! '
            '제가 다음 달 예산 계획을 더 꼼꼼하게 짜서 1억 프로젝트에 차질 없게 도와드릴게요. (연속 보호됨)';
      }

      // 일반적인 잔소리 로직
      if (!isSpecialCase) {
        if (mainCategory == '식비' || mainCategory == '외식') {
          final foodItems = ConsumableInventoryService.instance.items.value;
          final now = DateTime.now();
          final expiringFood = foodItems.where((i) {
            final expiryDate = i.expiryDate;
            if (expiryDate == null) return false;
            final days = expiryDate.difference(now).inDays;
            return days >= 0 && days <= 3;
          }).toList();

          if (expiringFood.isNotEmpty) {
            final msgs = [
              '냉장고 속 우유가 자기 버려달라고 울고 있어요. 외식 말고 집밥으로 우유를 구출해 주세요!',
              '냉장고에 재료가 가득한데 외식이라니요? 이건 냉장고에 대한 예의가 아니라고 생각합니다.',
            ];
            customFeedback += '\n\n😈 ${msgs[Random().nextInt(msgs.length)]}';
          }
        }

        await _loadBudgetData();
        final budget = BudgetService().getBudget(_accountName);
        if (budget > 0) {
          final history = TransactionService().getTransactions(_accountName);
          final now = DateTime.now();
          final thisMonthSpent = history.fold(0.0, (sum, t) {
            if (t.type == TransactionType.expense &&
                t.date.year == now.year && t.date.month == now.month) {
              return sum + t.amount;
            }
            return sum;
          });
          final totalSpent = thisMonthSpent + amount;
          final remaining = budget - totalSpent;

          if (remaining < 0) {
            final msgs = [
              '비상! 현재 예산이 멸종 위기입니다. 이제부터는 숨만 쉬어도 예산 초과예요.',
              '주인님, 우리 당분간은 편의점 앞도 지나가지 말기로 약속해요. 눈 감고 지나가세요!',
              '1억 프로젝트가 지금 잠시 멈춤 상태입니다. 다시 엔진을 돌리려면 "무지출"이라는 기름이 필요해요.',
            ];
            customFeedback += '\n\n🚨 ${msgs[Random().nextInt(msgs.length)]}';
          } else if (remaining < budget * 0.2) {
            final msgs = [
              '주인님, 지금 지갑에 구멍 난 것 같아요! 1억 프로젝트가 1억 년 뒤로 밀리고 있습니다.',
              "방금 지출로 이번 달 '치킨권'이 소멸되었습니다. 오늘 저녁은 냉장고 파먹기 어떠세요?",
              '자산 그래프가 다이어트 중인가 봐요. 주인님 지갑은 홀쭉해지고 제 마음은 무거워지네요.',
            ];
            customFeedback += '\n\n⚠️ ${msgs[Random().nextInt(msgs.length)]}';
          } else {
            final isFixedCost = mainCategory.contains('고정') ||
                mainCategory.contains('월세') || mainCategory.contains('공과금');
            if (!isFixedCost && amount >= 30000) {
              final msgs = [
                '이 물건, 정말 1억 프로젝트보다 중요한가요? 제 인공지능 회로로는 이해가 잘 안 되네요!',
                '지름신이 강림하셨군요. 하지만 그 신은 잔액을 책임져주지 않는다는 사실, 잊지 마세요.',
                "지금 지르시면 '오늘의 행복'은 얻겠지만, '내일의 통장'은 눈물을 흘릴 거예요.",
              ];
              customFeedback += '\n\n🤔 ${msgs[Random().nextInt(msgs.length)]}';
            }
          }
        }
      }
    } else if (type == TransactionType.income && isPointAccumulation) {
      if (description.contains('무지출')) {
        customFeedback +=
            '\n\n🎉 와! 오늘 지갑을 한 번도 안 여셨네요? 1억 프로젝트에 한 걸음 더 가까워졌습니다. 포인트 쏴드릴게요!';
      }
    }
    // NOTE: customFeedback was computed but not surfaced (original behavior).
  }
}
