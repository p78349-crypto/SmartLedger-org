enum SubscriptionStoreActionOutcome {
  success,
  cancelled,
  notAvailable,
  failed,
}

class SubscriptionStoreActionResult {
  const SubscriptionStoreActionResult({
    required this.outcome,
    required this.message,
  });

  final SubscriptionStoreActionOutcome outcome;
  final String message;
}

abstract class SubscriptionStoreAdapter {
  Future<SubscriptionStoreActionResult> startSubscriptionPurchase({
    required String userId,
  });

  Future<SubscriptionStoreActionResult> restorePurchases({
    required String userId,
  });
}

class NoopSubscriptionStoreAdapter implements SubscriptionStoreAdapter {
  const NoopSubscriptionStoreAdapter();

  @override
  Future<SubscriptionStoreActionResult> startSubscriptionPurchase({
    required String userId,
  }) async {
    return const SubscriptionStoreActionResult(
      outcome: SubscriptionStoreActionOutcome.notAvailable,
      message: '스토어 결제 SDK가 아직 연결되지 않았습니다.',
    );
  }

  @override
  Future<SubscriptionStoreActionResult> restorePurchases({
    required String userId,
  }) async {
    return const SubscriptionStoreActionResult(
      outcome: SubscriptionStoreActionOutcome.notAvailable,
      message: '스토어 구매 복구 SDK가 아직 연결되지 않았습니다.',
    );
  }
}
