// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 장바구니 추가 + _buildClosedResult 헬퍼.
extension VoiceDashHandlers2 on _VoiceDashboardScreenState {
  VoiceCommandResult _buildClosedResult(String cmd) {
    _suspendAutoListen = false;
    return VoiceCommandResult(
      command: cmd,
      success: false,
      message: '화면이 닫혀서 이동할 수 없습니다.',
      type: VoiceCommandType.navigation,
    );
  }

  Future<VoiceCommandResult> _handleShoppingCartAdd(String command) async {
    final itemName = command
        .replaceAll('장바구니', '').replaceAll('쇼핑', '')
        .replaceAll('리스트', '').replaceAll('목록', '')
        .replaceAll('추가', '').replaceAll('담아', '')
        .replaceAll('넣어', '').replaceAll('해줘', '')
        .replaceAll('에', '').replaceAll('을', '')
        .replaceAll('를', '').replaceAll('좀', '')
        .trim();

    if (itemName.isEmpty) {
      return VoiceCommandResult(
        command: command, success: false,
        message: '어떤 상품을 추가할까요? "우유 장바구니에 담아줘" 처럼 말해주세요.',
        type: VoiceCommandType.unknown,
      );
    }

    // 중복 구매 방지 알림
    String warningMsg = '';
    final inventory = ConsumableInventoryService.instance.items.value;
    final inStock = inventory
        .where((i) => i.name.contains(itemName) || itemName.contains(i.name))
        .toList();

    if (inStock.isNotEmpty) {
      final item = inStock.first;
      warningMsg =
          '⚠️ 냉장고에 이미 ${item.name} (${item.currentStock}${item.unit}) 있습니다.';
    } else {
      final item = inventory.firstWhere(
        (i) => i.name.contains(itemName) || itemName.contains(i.name),
        orElse: () => inventory.first,
      );
      if (inventory.isNotEmpty && item.currentStock > item.threshold) {
        warningMsg = '⚠️ 집에 이미 ${item.name} 재고가 넉넉합니다.';
      }
    }

    // 최근 구매 이력 확인
    if (warningMsg.isEmpty) {
      final history = TransactionService().getTransactions(_accountName);
      final recentThreshold = DateTime.now().subtract(const Duration(days: 7));
      final recentPurchase = history.where((t) {
        if (t.type != TransactionType.expense) return false;
        if (t.date.isBefore(recentThreshold)) return false;
        return t.description.contains(itemName);
      }).toList();

      if (recentPurchase.isNotEmpty) {
        recentPurchase.sort((a, b) => b.date.compareTo(a.date));
        final last = recentPurchase.first;
        final daysAgo = DateTime.now().difference(last.date).inDays;
        final timeStr = daysAgo == 0 ? '오늘' : '$daysAgo일 전';
        warningMsg =
            '⚠️ $timeStr에 "${last.description}" 구매 내역이 있어요. 냉장고를 확인해보세요.';
      }
    }

    // 장바구니 중복 확인
    final currentItems = await UserPrefService.getShoppingCartItems(
      accountName: _accountName,
    );
    final isDuplicate = currentItems.any((i) => i.name == itemName);
    if (isDuplicate) {
      return VoiceCommandResult(
        command: command, success: false,
        message: '이미 장바구니에 "$itemName"이(가) 있습니다.',
        type: VoiceCommandType.unknown,
      );
    }

    final newItem = ShoppingCartItem(
      id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
      name: itemName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final nextItems = [...currentItems, newItem];
    await UserPrefService.setShoppingCartItems(
      accountName: _accountName, items: nextItems,
    );

    // 가격 비교 로직
    String priceFeedback = '';
    try {
      final history = TransactionService().getTransactions(_accountName);
      final relevantParams = history.where((t) {
        if (t.type != TransactionType.expense) return false;
        return t.description.contains(itemName);
      }).toList();

      if (relevantParams.isNotEmpty) {
        final recentThreshold = DateTime.now().subtract(
          const Duration(days: 90),
        );
        final recent = relevantParams
            .where((t) => t.date.isAfter(recentThreshold))
            .toList();

        if (recent.isNotEmpty) {
          final Map<String, double> storeMinPrices = {};
          for (final t in recent) {
            final storeName = t.store ?? '알수없음';
            if (storeName != '알수없음' && t.amount > 0) {
              if (!storeMinPrices.containsKey(storeName) ||
                  t.amount < storeMinPrices[storeName]!) {
                storeMinPrices[storeName] = t.amount;
              }
            }
          }
          if (storeMinPrices.isNotEmpty) {
            final bestEntry = storeMinPrices.entries.reduce(
              (a, b) => a.value < b.value ? a : b,
            );
            final formattedPrice = CurrencyFormatter.format(bestEntry.value);
            priceFeedback =
                '최근 ${bestEntry.key}에서 $formattedPrice에 가장 저렴하게 구매하셨네요.';
          } else {
            final minPrice = recent
                .map((t) => t.amount)
                .reduce((a, b) => a < b ? a : b);
            priceFeedback =
                '최근 최저가는 ${CurrencyFormatter.format(minPrice)}이었습니다.';
          }
        }
      }
    } catch (e) {
      debugPrint('Price check error: $e');
    }

    final sb = StringBuffer();
    sb.write('$itemName, 장바구니에 담았습니다.');
    if (warningMsg.isNotEmpty) {
      sb.write('\n$warningMsg');
    } else if (priceFeedback.isNotEmpty) {
      sb.write('\n💡 $priceFeedback');
    }

    return VoiceCommandResult(
      command: command, success: true,
      message: sb.toString(),
      type: VoiceCommandType.unknown,
    );
  }
}
