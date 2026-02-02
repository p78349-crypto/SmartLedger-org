part of deep_link_handler;

mixin _DeepLinkHandlerStock on _DeepLinkHandlerBase {
  void _handleCheckStock(NavigatorState navigator, CheckStockAction action) {
    final items = ConsumableInventoryService.instance.items.value;
    final product = action.productName.toLowerCase();

    final found = items
        .where(
          (item) =>
              item.name.toLowerCase().contains(product) ||
              product.contains(item.name.toLowerCase()),
        )
        .toList();

    if (found.isEmpty) {
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: AppRoutes.householdConsumables,
        intent: 'check_stock',
        success: false,
        failureReason: 'STOCK_NOT_FOUND',
      );
      _showStockNotFoundDialog(navigator, action.productName);
      return;
    }

    VoiceAssistantAnalytics.logCommand(
      assistant: _detectAssistant(action.params),
      route: AppRoutes.householdConsumables,
      intent: 'check_stock',
      success: true,
    );
    final item = found.first;
    _showStockInfoDialog(navigator, item);
  }

  void _handleUseStock(NavigatorState navigator, UseStockAction action) {
    final accounts = AccountService().accounts;
    if (accounts.isEmpty) {
      debugPrint('DeepLinkHandler: No accounts available');
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: AppRoutes.quickStockUse,
        intent: 'use_stock',
        success: false,
        failureReason: 'ACCOUNT_REQUIRED',
      );
      return;
    }

    final accountName = accounts.first.name;

    double? initialAmount = action.amount;
    if (initialAmount == null) {
      final items = ConsumableInventoryService.instance.items.value;
      final product = action.productName.toLowerCase();
      final found = items
          .where(
            (item) =>
                item.name.toLowerCase().contains(product) ||
                product.contains(item.name.toLowerCase()),
          )
          .toList();
      if (found.isNotEmpty) {
        initialAmount = found.first.currentStock;
      }
    }

    void logSuccess() {
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: AppRoutes.quickStockUse,
        intent: 'use_stock',
        success: true,
      );
    }

    if (action.autoSubmit && !action.confirmed) {
      _showStockUseConfirmDialog(
        navigator,
        productName: action.productName,
        amount: initialAmount,
        onProceed: () {
          logSuccess();
          navigator.pushNamed(
            AppRoutes.quickStockUse,
            arguments: QuickStockUseArgs(
              accountName: accountName,
              initialProductName: action.productName,
              initialAmount: initialAmount,
              autoSubmit: true,
            ),
          );
        },
        onCancel: () {
          logSuccess();
          navigator.pushNamed(
            AppRoutes.quickStockUse,
            arguments: QuickStockUseArgs(
              accountName: accountName,
              initialProductName: action.productName,
              initialAmount: initialAmount,
            ),
          );
        },
      );
      return;
    }

    logSuccess();
    navigator.pushNamed(
      AppRoutes.quickStockUse,
      arguments: QuickStockUseArgs(
        accountName: accountName,
        initialProductName: action.productName,
        initialAmount: initialAmount,
        autoSubmit: action.autoSubmit,
      ),
    );
  }

  void _showStockUseConfirmDialog(
    NavigatorState navigator, {
    required String productName,
    required double? amount,
    required VoidCallback onProceed,
    required VoidCallback onCancel,
  }) {
    final context = navigator.context;
    final qtyLabel = amount == null ? '전량' : _formatQty(amount);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('재고 차감 확인'),
          ],
        ),
        content: Text(
          '"$productName" $qtyLabel 차감을 실행할까요?\n'
          '확인하면 즉시 차감이 진행됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCancel();
            },
            child: const Text('아니요'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onProceed();
            },
            child: const Text('실행'),
          ),
        ],
      ),
    );
  }

  void _showStockNotFoundDialog(NavigatorState navigator, String productName) {
    final context = navigator.context;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('재고 없음'),
          ],
        ),
        content: Text(
          '"$productName" 상품을 찾을 수 없습니다.\n'
          '재고에 등록되어 있는지 확인해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              navigator.pushNamed(AppRoutes.householdConsumables);
            },
            child: const Text('재고 등록하기'),
          ),
        ],
      ),
    );
  }

  void _showStockInfoDialog(NavigatorState navigator, dynamic item) {
    final context = navigator.context;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.inventory_2, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              '📦 현재 재고',
              '${_formatQty(item.currentStock)}${item.unit}',
              item.currentStock <= item.threshold
                  ? Colors.orange
                  : Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('📍 보관 위치', item.location, Colors.grey),
            const Divider(height: 24),
            const Text(
              '🎤 "응" 또는 "전량 사용"이라고 말하면\n재고 차감을 진행합니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              final accounts = AccountService().accounts;
              if (accounts.isNotEmpty) {
                navigator.pushNamed(
                  AppRoutes.quickStockUse,
                  arguments: QuickStockUseArgs(
                    accountName: accounts.first.name,
                    initialProductName: item.name,
                    initialAmount: item.currentStock,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: Text('전량 사용 (${_formatQty(item.currentStock)}${item.unit})'),
          ),
        ],
      ),
    );
  }
}
