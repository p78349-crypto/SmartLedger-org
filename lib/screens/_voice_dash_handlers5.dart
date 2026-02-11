// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 식재료 조회, 예산 조회, 복합 레시피, 메뉴 추천, 오늘 요약 핸들러.
extension VoiceDashHandlers5 on _VoiceDashboardScreenState {
  VoiceCommandResult _handleIngredientQuery(String command) {
    final items = ConsumableInventoryService.instance.items.value;

    final keywords = command
        .replaceAll('남은', '').replaceAll('얼마나', '')
        .replaceAll('있어', '').replaceAll('재료', '')
        .replaceAll('?', '').trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    if (keywords.isEmpty) {
      final count = items.length;
      final expiringSoon = items.where((i) {
        final expiryDate = i.expiryDate;
        if (expiryDate == null) return false;
        final days = expiryDate.difference(DateTime.now()).inDays;
        return days >= 0 && days <= 3;
      }).length;

      return VoiceCommandResult(
        command: command, success: true,
        message:
            '현재 $count개의 재료가 등록되어 있어요. '
            '${expiringSoon > 0 ? '$expiringSoon개는 곧 유통기한이에요.' : ''}\n\n'
            '💡 등록된 재고가 실제와 다를 수 있어요. 가계부 내역도 함께 참고하세요.',
        type: VoiceCommandType.query,
      );
    }

    for (final keyword in keywords) {
      final matches = items
          .where((i) => i.name.contains(keyword) || keyword.contains(i.name))
          .toList();

      if (matches.isNotEmpty) {
        final item = matches.first;
        final expiryDate = item.expiryDate;
        final daysLeft = expiryDate?.difference(DateTime.now()).inDays;
        final quantityStr = '${item.currentStock}${item.unit}';

        return VoiceCommandResult(
          command: command, success: true,
          message:
              '${item.name} $quantityStr 남아있네요. '
              '${daysLeft == null ? '유통기한 정보가 없습니다.' : (daysLeft >= 0 ? '유통기한은 $daysLeft일 남았어요.' : '유통기한이 지났어요!')}',
          type: VoiceCommandType.query,
          data: {'item': item.name, 'daysLeft': daysLeft},
        );
      }
    }

    // 재고 없으면 최근 구매 이력 확인
    try {
      final history = TransactionService().getTransactions(_accountName);
      final recentPurchase = history.where((t) {
        if (t.type != TransactionType.expense) return false;
        if (DateTime.now().difference(t.date).inDays > 30) return false;
        return keywords.any(
          (k) => t.description.contains(k) ||
              (t.store != null && t.store!.contains(k)),
        );
      }).toList();
      recentPurchase.sort((a, b) => b.date.compareTo(a.date));

      if (recentPurchase.isNotEmpty) {
        final last = recentPurchase.first;
        final daysAgo = DateTime.now().difference(last.date).inDays;
        final timeStr = daysAgo == 0 ? '오늘' : '$daysAgo일 전';
        return VoiceCommandResult(
          command: command, success: true,
          message:
              '재고 목록엔 없지만, $timeStr에 "${last.description}" 구매하신 내역이 있어요. 아직 남아있을 수도 있겠네요!',
          type: VoiceCommandType.query,
        );
      }
    } catch (e) { /* ignore */ }

    return VoiceCommandResult(
      command: command, success: true,
      message: '해당 재료를 찾지 못했어요. 구매하신 지 오래되었거나 내역이 없을 수 있어요.',
      type: VoiceCommandType.query,
    );
  }

  VoiceCommandResult _handleBudgetQuery() {
    final remaining = _todayBudget - _todaySpent;
    final message = remaining >= 0
        ? '오늘 예산 ${CurrencyFormatter.format(remaining)} 남았어요.'
        : '오늘 예산을 ${CurrencyFormatter.format(-remaining)} 초과했어요.';
    return VoiceCommandResult(
      command: '예산 조회', success: true,
      message: message,
      type: VoiceCommandType.query,
      data: {'remaining': remaining, 'budget': _todayBudget, 'spent': _todaySpent},
    );
  }

  Future<VoiceCommandResult> _handleComplexMealQuery(String command) async {
    final recommendationService = UnifiedRecipeRecommendationService.instance;
    final foodItems = ConsumableInventoryService.instance.items.value;
    final now = DateTime.now();

    final expiringFood = foodItems.where((i) {
      final expiryDate = i.expiryDate;
      if (expiryDate == null) return false;
      final days = expiryDate.difference(now).inDays;
      return days >= -1 && days <= 3;
    }).toList();

    expiringFood.sort((a, b) {
      final aDate = a.expiryDate ?? DateTime.now().add(const Duration(days: 3650));
      final bDate = b.expiryDate ?? DateTime.now().add(const Duration(days: 3650));
      return aDate.compareTo(bDate);
    });

    final recommendedRecipe =
        await recommendationService.getRecommendationForVoiceCommand();

    final sb = StringBuffer();
    if (expiringFood.isNotEmpty) {
      final top = expiringFood.take(3).map((e) => e.name).join(', ');
      sb.write('유통기한이 임박한 $top 등이 있어요. 우선 드시는 게 좋겠어요.\n');
    } else {
      sb.write('유통기한 걱정 없는 신선한 냉장고네요!\n');
    }

    if (recommendedRecipe == null) {
      sb.write('현재 재료로 딱 맞는 레시피를 찾지 못했어요. 장을 좀 보셔야 할 것 같아요.');
    } else {
      final rName = (recommendedRecipe['recipe'] as dynamic).name;
      final missingCount = recommendedRecipe['missingCount'] as int;
      final missing = recommendedRecipe['missing'] as List<String>;

      if (missingCount == 0) {
        sb.write('현재 재료로 "$rName" 요리가 가능해요! 바로 해드실 수 있어요.');
      } else {
        final missingStr = missing.join(', ');
        sb.write('"$rName" 어떠세요? $missingStr만 사오면 만들 수 있어요.');
      }
    }

    return VoiceCommandResult(
      command: command, success: true,
      message: sb.toString(),
      type: VoiceCommandType.recommend,
    );
  }

  VoiceCommandResult _handleMenuRecommend() {
    return VoiceCommandResult(
      command: '메뉴 추천', success: false,
      message: '잠시만요...',
      type: VoiceCommandType.unknown,
    );
  }

  VoiceCommandResult _handleTodaySummary() {
    return VoiceCommandResult(
      command: '오늘 요약', success: true,
      message:
          '오늘 ${CurrencyFormatter.format(_todaySpent)} 썼어요. '
          '식재료비 ${CurrencyFormatter.format(_foodExpense)}, '
          '기타 ${CurrencyFormatter.format(_fixedCost)}이에요.',
      type: VoiceCommandType.query,
      data: {'total': _todaySpent, 'food': _foodExpense, 'fixed': _fixedCost},
    );
  }
}
