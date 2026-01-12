part of deep_link_handler;

mixin _DeepLinkHandlerOpenRouteAsset on _DeepLinkHandlerBase {
  @override
  bool _handleOpenRouteAsset({
    required NavigatorState navigator,
    required OpenRouteAction action,
    required AssistantRouteSpec spec,
    required Map<String, String> filteredParams,
    required String? accountName,
  }) {
    if (action.routeName != AppRoutes.assetSimpleInput) return false;
    if (action.intent != 'asset_add') return false;

    final p = filteredParams;

    final category = (p['category'] ?? p['assetCategory'] ?? '').trim();
    final name = (p['name'] ?? p['assetName'] ?? '').trim();
    final amount = double.tryParse((p['amount'] ?? '').trim());
    final location = (p['location'] ?? '').trim();
    final memo = (p['memo'] ?? '').trim();

    void openScreen({required bool autoSubmit}) {
      navigator.pushNamed(
        spec.routeName,
        arguments: AssetSimpleInputArgs(
          accountName: _accountNameOrDefault(accountName),
          initialCategory: category.isEmpty ? null : category,
          initialName: name.isEmpty ? null : name,
          initialAmount: amount,
          initialLocation: location.isEmpty ? null : location,
          initialMemo: memo.isEmpty ? null : memo,
          autoSubmit: autoSubmit,
        ),
      );
    }

    if (action.autoSubmit) {
      final missingForAuto = name.isEmpty || amount == null;
      if (missingForAuto) {
        _showSimpleInfoDialog(
          navigator,
          title: '자동 저장 불가',
          message:
              '자동 저장을 위해서는 자산명과 금액이 필요합니다.\n'
              '화면을 열어 입력을 계속 진행하세요.',
        );
        openScreen(autoSubmit: false);
        return true;
      }

      if (!action.confirmed) {
        final categoryText = category.isEmpty ? '현금' : category;
        final amountText = amount == amount.roundToDouble()
            ? amount.toStringAsFixed(0)
            : amount.toString();

        showDialog<bool>(
          context: navigator.context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('저장 전에 확인'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('종류: $categoryText'),
                  Text('자산명: $name'),
                  Text('금액: $amountText'),
                  if (location.isNotEmpty) Text('위치: $location'),
                  if (memo.isNotEmpty) Text('메모: $memo'),
                  const SizedBox(height: 8),
                  const Text('이대로 저장할까요?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        ).then((confirmed) {
          if (confirmed == true) {
            openScreen(autoSubmit: true);
          }
        });
        return true;
      }

      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: action.routeName,
        intent: action.intent ?? 'asset_add',
        success: true,
      );

      openScreen(autoSubmit: true);
      return true;
    }

    VoiceAssistantAnalytics.logCommand(
      assistant: _detectAssistant(action.params),
      route: action.routeName,
      intent: action.intent ?? 'asset_add',
      success: true,
    );

    openScreen(autoSubmit: false);
    return true;
  }
}
