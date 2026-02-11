part of 'voice_dashboard_screen.dart';

/// 명령어 감지 bool 메서드 + 금액 추출 + 설명 추출 + 카테고리 추론.
extension VoiceDashCmdCheck on _VoiceDashboardScreenState {
  bool _isMonthlyClosingCommand(String cmd) {
    return (cmd.contains('월말') ||
            cmd.contains('이번 달') ||
            cmd.contains('이번달')) &&
        (cmd.contains('정산') || cmd.contains('마감') ||
         cmd.contains('결산') || cmd.contains('어때') ||
         cmd.contains('남았'));
  }

  bool _containsAmountHint(String cmd) {
    return RegExp(r'\d').hasMatch(cmd) ||
        cmd.contains('원') || cmd.contains('만') ||
        cmd.contains('천') || cmd.contains('백') ||
        cmd.contains('십');
  }

  bool _isExpenseCommand(String cmd) {
    final hasSaveVerb = cmd.contains('기록') || cmd.contains('저장') ||
        cmd.contains('추가') || cmd.contains('썼어') ||
        cmd.contains('썼다') || cmd.contains('샀어') ||
        cmd.contains('샀다') || cmd.contains('결제') ||
        cmd.contains('지불') || cmd.contains('지출') ||
        cmd.contains('적립') || cmd.contains('받았');
    if (!hasSaveVerb) return false;
    if (!_containsAmountHint(cmd)) return false;
    return true;
  }

  bool _isExpenseInputWithAmountCommand(String cmd) {
    if (!cmd.contains('지출')) return false;
    final hasInput = cmd.contains('입력') || cmd.contains('입력창');
    return hasInput && _containsAmountHint(cmd);
  }

  bool _isOpenExpenseInputCommand(String cmd) {
    final hasExpense = cmd.contains('지출');
    if (!hasExpense) return false;
    final hasInput = cmd.contains('입력') || cmd.contains('입력창');
    final hasOpen = cmd.contains('열어') || cmd.contains('열러') ||
        cmd.contains('켜') || cmd.contains('띄워');
    final hasMove = cmd.contains('가') || cmd.contains('이동') ||
        cmd.contains('진입');
    final hasRecord = cmd.contains('기록') || cmd.contains('저장') ||
        cmd.contains('추가');
    if ((hasInput && (hasOpen || hasMove)) || cmd.contains('지출입력')) {
      return true;
    }
    if (hasRecord && !_containsAmountHint(cmd)) return true;
    return false;
  }

  bool _isOpenIncomeInputCommand(String cmd) {
    final hasIncome = cmd.contains('수입') || cmd.contains('월급');
    if (!hasIncome) return false;
    final hasInput = cmd.contains('입력') || cmd.contains('입력창');
    final hasOpen = cmd.contains('열어') || cmd.contains('열러') ||
        cmd.contains('켜') || cmd.contains('띄워');
    final hasMove = cmd.contains('가') || cmd.contains('이동') ||
        cmd.contains('진입');
    final hasRecord = cmd.contains('기록') || cmd.contains('저장') ||
        cmd.contains('추가');
    if ((hasInput && (hasOpen || hasMove)) || cmd.contains('수입입력')) {
      return true;
    }
    if (hasRecord && !_containsAmountHint(cmd)) return true;
    return false;
  }

  bool _isIngredientQueryCommand(String cmd) {
    return cmd.contains('남은') || cmd.contains('얼마나') ||
        cmd.contains('있어') && (cmd.contains('재료') || cmd.contains('식재료'));
  }

  bool _isBudgetQueryCommand(String cmd) {
    return cmd.contains('예산') || cmd.contains('얼마 남았') ||
        cmd.contains('남은 돈') || cmd.contains('오늘 예산');
  }

  bool _isMenuRecommendCommand(String cmd) {
    if (cmd.contains('뭐 먹') || cmd.contains('메뉴 추천') ||
        cmd.contains('뭐 해먹') || cmd.contains('요리 추천') ||
        cmd.contains('레시피 추천') || cmd.contains('뭐해먹') ||
        cmd.contains('뭐하지')) {
      return true;
    }
    if ((cmd.contains('아침') || cmd.contains('점심') || cmd.contains('저녁')) &&
        (cmd.contains('뭐') || cmd.contains('추천'))) {
      return true;
    }
    return false;
  }

  bool _isShoppingCartCommand(String cmd) => _isShoppingCartAddCommand(cmd);

  bool _isShoppingCartAddCommand(String cmd) {
    return (cmd.contains('장바구니') || cmd.contains('쇼핑') ||
            cmd.contains('사야')) &&
        (cmd.contains('추가') || cmd.contains('담아') ||
         cmd.contains('넣어') || cmd.contains('기록') ||
         cmd.contains('해줘'));
  }

  bool _isTodaySummaryCommand(String cmd) {
    return cmd.contains('오늘') &&
        (cmd.contains('얼마') || cmd.contains('지출') || cmd.contains('요약'));
  }

  bool _isNavigationCommand(String cmd) {
    if (cmd.contains('가계부') || cmd.contains('대시보드') ||
        cmd.contains('홈')) {
      return true;
    }
    if (cmd.contains('자산') || cmd.contains('통장')) {
      return true;
    }
    final isStatus = cmd.contains('현황') || cmd.contains('통계') ||
        cmd.contains('내역');
    if (cmd.contains('지출') && isStatus) {
      return true;
    }
    final isFood = cmd.contains('냉장고') || cmd.contains('식재료');
    final isOpen = cmd.contains('열어') || cmd.contains('가줘') ||
        cmd.contains('보여줘');
    if (isFood && isOpen) {
      return true;
    }
    if (cmd.contains('유통기한') &&
        (cmd.contains('관리') || cmd.contains('화면'))) {
      return true;
    }
    if (cmd.contains('저축') || cmd.contains('적금')) {
      return true;
    }
    if (cmd.contains('달력') || cmd.contains('캘린더')) {
      return true;
    }
    if (cmd.contains('장바구니') || cmd.contains('쇼핑리스트')) {
      return true;
    }
    if (cmd.contains('생필품') || cmd.contains('소모품')) {
      return true;
    }
    if (cmd.contains('설정') || cmd.contains('세팅')) {
      return true;
    }
    if (_containsPageNavigation(cmd)) {
      return true;
    }
    return false;
  }

  bool _containsPageNavigation(String cmd) {
    if (cmd.contains('페이지')) {
      return cmd.contains('가줘') || cmd.contains('이동') ||
          cmd.contains('보여줘') || cmd.contains('열어');
    }
    return false;
  }

  bool _isInventoryReportCommand(String cmd) {
    final isQuery = cmd.contains('재고') || cmd.contains('남은') ||
        cmd.contains('유통기한') || cmd.contains('부족한');
    final isAction = cmd.contains('알려줘') || cmd.contains('뭐야') ||
        cmd.contains('확인') || cmd.contains('체크') ||
        cmd.contains('조회');
    return isQuery && isAction;
  }

  bool _isFixedCostBriefingCommand(String cmd) {
    final isFixed = (cmd.contains('고정') &&
            (cmd.contains('지출') || cmd.contains('비용'))) ||
        cmd.contains('공과금');
    final isDue = (cmd.contains('낼 거') || cmd.contains('낼거')) &&
        cmd.contains('남았');
    return isFixed || isDue;
  }

  bool _isSpendingAdviceCommand(String cmd) {
    final isBuying = cmd.contains('사도') || cmd.contains('써도') ||
        cmd.contains('지러도') || cmd.contains('질러도') ||
        cmd.contains('살까');
    final isAsking = cmd.contains('돼') || cmd.contains('되') ||
        cmd.contains('될까') || cmd.contains('까요');
    return isBuying && isAsking;
  }

  bool _isExceptionMarkingCommand(String cmd) {
    return cmd.contains('예외') &&
        (cmd.contains('해줘') || cmd.contains('처리') || cmd.contains('등록'));
  }

  bool _isWasteLogCommand(String cmd) {
    return cmd.contains('버렸') || cmd.contains('상해서') ||
        cmd.contains('상했') || cmd.contains('폐기');
  }

  double? _extractKrwAmount(String command) {
    final withWon = RegExp(r'(\d[\d,]*)\s*원').firstMatch(command);
    if (withWon != null) {
      final amountStr = withWon.group(1)!.replaceAll(',', '');
      final amount = double.tryParse(amountStr);
      if (amount != null && amount > 0) return amount;
    }
    final unitRegex = RegExp(r'(\d+)\s*(만|천|백|십)');
    final matches = unitRegex.allMatches(command).toList();
    if (matches.isNotEmpty) {
      double sum = 0;
      for (final m in matches) {
        final raw = m.group(1);
        final unit = m.group(2);
        if (raw == null || unit == null) continue;
        final v = double.tryParse(raw);
        if (v == null) continue;
        switch (unit) {
          case '만': sum += v * 10000;
          case '천': sum += v * 1000;
          case '백': sum += v * 100;
          case '십': sum += v * 10;
        }
      }
      final last = matches.last;
      final tail = command.substring(last.end);
      final tailDigits = RegExp(r'(\d[\d,]*)').firstMatch(tail);
      if (tailDigits != null) {
        final raw = tailDigits.group(1)!.replaceAll(',', '');
        final v = double.tryParse(raw);
        if (v != null) sum += v;
      }
      if (sum > 0) return sum;
    }
    final digits = RegExp(r'(\d[\d,]*)').firstMatch(command);
    if (digits != null) {
      final raw = digits.group(1)!.replaceAll(',', '');
      final amount = double.tryParse(raw);
      if (amount != null && amount > 0) return amount;
    }
    return null;
  }

  String _extractExpenseDescription(String command) {
    var text = command;
    text = text.replaceAll(RegExp(r'\d[\d,]*\s*원'), '');
    text = text.replaceAll(RegExp(r'(\d+)\s*(만|천|백|십)'), '');
    text = text
        .replaceAll('지출', '').replaceAll('기록', '')
        .replaceAll('저장', '').replaceAll('추가', '')
        .replaceAll('입력', '').replaceAll('열어', '')
        .replaceAll('열러', '').replaceAll('켜', '')
        .replaceAll('띄워', '').trim();
    if (text.isEmpty) return '음성 입력';
    return text;
  }

  (String, String?) _inferCategory(String description) {
    try {
      final history = TransactionService().getTransactions(_accountName);
      final search = description.replaceAll(' ', '').toLowerCase();
      for (int i = history.length - 1; i >= 0; i--) {
        final t = history[i];
        if (t.type != TransactionType.expense) continue;
        final tDesc = t.description.replaceAll(' ', '').toLowerCase();
        if (tDesc == search ||
            (search.length > 1 && tDesc.contains(search))) {
          return (t.mainCategory, t.subCategory);
        }
      }
    } catch (_) {}
    final keywordMatch = CategoryKeywordService.instance.classify(description);
    if (keywordMatch != null) return keywordMatch;
    return ('미분류', null);
  }
}
