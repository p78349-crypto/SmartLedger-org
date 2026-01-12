part of deep_link_handler;

mixin _DeepLinkHandlerHelpers on _DeepLinkHandlerBase {
  @override
  void _showSimpleInfoDialog(
    NavigatorState navigator, {
    required String title,
    required String message,
    // ignore: unused_element_parameter
    List<Widget>? actions,
  }) {
    final context = navigator.context;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions:
            actions ??
            [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인'),
              ),
            ],
      ),
    );
  }

  @override
  String _detectAssistant(Map<String, String>? params) {
    return VoiceAssistantAnalytics.detectAssistant(params);
  }

  @override
  void _logAndShowError({
    required NavigatorState navigator,
    required String errorType,
    required String route,
    String? assistant,
    String? message,
    List<Widget>? actions,
    List<String>? rejectedParams,
  }) {
    debugPrint('DeepLinkHandler Error:');
    debugPrint('  Type: $errorType');
    debugPrint('  Route: $route');
    debugPrint('  Assistant: ${assistant ?? "unknown"}');
    if (rejectedParams != null && rejectedParams.isNotEmpty) {
      debugPrint('  Rejected Params: $rejectedParams');
    }

    VoiceAssistantAnalytics.logError(
      errorType: errorType,
      route: route,
      assistant: assistant,
    );

    if (rejectedParams != null && rejectedParams.isNotEmpty) {
      VoiceAssistantAnalytics.logRejectedParams(
        route: route,
        rejected: rejectedParams,
        assistant: assistant,
      );
    }

    VoiceAssistantAnalytics.logCommand(
      assistant: assistant ?? 'unknown',
      route: route,
      intent: 'open',
      success: false,
      failureReason: errorType,
    );

    final errorMessage = _getErrorMessage(errorType, route, message);

    _showSimpleInfoDialog(
      navigator,
      title: errorMessage.title,
      message: errorMessage.body,
      actions: actions,
    );
  }

  _ErrorMessage _getErrorMessage(
    String errorType,
    String route, [
    String? customMessage,
  ]) {
    if (customMessage != null) {
      final title = errorType == 'ROUTE_NOT_ALLOWED'
          ? '보안 안내'
          : errorType == 'ACCOUNT_REQUIRED'
          ? '계정이 필요합니다'
          : errorType == 'INVALID_PARAMS'
          ? '잘못된 명령입니다'
          : '오류';

      return _ErrorMessage(title: title, body: customMessage);
    }

    switch (errorType) {
      case 'ROUTE_NOT_ALLOWED':
        return const _ErrorMessage(
          title: '보안 안내',
          body: '음성 명령으로는 이 화면을 열 수 없습니다.\n앱에서 직접 열어주세요.',
        );
      case 'ACCOUNT_REQUIRED':
        return const _ErrorMessage(
          title: '계정이 필요합니다',
          body: '먼저 계정을 생성하거나 선택해주세요.',
        );
      case 'INVALID_PARAMS':
        return const _ErrorMessage(
          title: '잘못된 명령입니다',
          body: '음성 명령의 일부를 인식하지 못했습니다.\n다시 시도해주세요.',
        );
      case 'AUTO_SUBMIT_REJECTED':
        return const _ErrorMessage(
          title: '확인이 필요합니다',
          body: '안전을 위해 앱에서 직접 확인해주세요.',
        );
      default:
        return const _ErrorMessage(
          title: '오류',
          body: '처리 중 문제가 발생했습니다.\n다시 시도해주세요.',
        );
    }
  }

  @override
  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  @override
  String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  @override
  String _accountNameOrDefault(String? accountName) {
    return accountName ??
        AssistantRouteCatalog.resolveDefaultAccountName() ??
        '';
  }
}

class _ErrorMessage {
  final String title;
  final String body;

  const _ErrorMessage({required this.title, required this.body});
}

class QuickStockUseArgs {
  final String accountName;
  final String? initialProductName;
  final double? initialAmount;
  final bool autoSubmit;

  const QuickStockUseArgs({
    required this.accountName,
    this.initialProductName,
    this.initialAmount,
    this.autoSubmit = false,
  });
}
