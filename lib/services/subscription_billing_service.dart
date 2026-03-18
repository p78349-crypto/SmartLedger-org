import 'subscription_access_service.dart';
import 'play_store_subscription_adapter.dart';
import 'subscription_store_adapter.dart';

enum SubscriptionBillingOutcome { success, blocked, notImplemented, error }

class SubscriptionBillingResult {
  const SubscriptionBillingResult({
    required this.outcome,
    required this.message,
    this.status,
  });

  final SubscriptionBillingOutcome outcome;
  final String message;
  final SubscriptionAccessStatus? status;
}

class SubscriptionBillingService {
  factory SubscriptionBillingService() => _instance;

  SubscriptionBillingService._internal({SubscriptionStoreAdapter? storeAdapter})
    : _storeAdapter = storeAdapter ?? PlayStoreSubscriptionAdapter();

  SubscriptionBillingService.withAdapter(SubscriptionStoreAdapter storeAdapter)
    : _storeAdapter = storeAdapter;

  static final SubscriptionBillingService _instance =
      SubscriptionBillingService._internal();

  final SubscriptionStoreAdapter _storeAdapter;

  Future<SubscriptionBillingResult> checkSubscriptionStatus({
    required String userId,
  }) async {
    final state = await SubscriptionAccessService.getState(userId);

    switch (state.status) {
      case SubscriptionAccessStatus.active:
        return const SubscriptionBillingResult(
          outcome: SubscriptionBillingOutcome.success,
          message: '구독이 활성 상태입니다.',
          status: SubscriptionAccessStatus.active,
        );
      case SubscriptionAccessStatus.grace:
        return const SubscriptionBillingResult(
          outcome: SubscriptionBillingOutcome.success,
          message: '유예 기간입니다. 결제 수단을 갱신해 주세요.',
          status: SubscriptionAccessStatus.grace,
        );
      case SubscriptionAccessStatus.paused:
        return const SubscriptionBillingResult(
          outcome: SubscriptionBillingOutcome.blocked,
          message: '구독이 일시중지 상태입니다. 재개가 필요합니다.',
          status: SubscriptionAccessStatus.paused,
        );
      case SubscriptionAccessStatus.expired:
        return const SubscriptionBillingResult(
          outcome: SubscriptionBillingOutcome.blocked,
          message: '구독이 만료되었습니다. 재구독이 필요합니다.',
          status: SubscriptionAccessStatus.expired,
        );
      case SubscriptionAccessStatus.refunded:
        return const SubscriptionBillingResult(
          outcome: SubscriptionBillingOutcome.blocked,
          message: '환불 처리된 구독입니다. 접근이 제한됩니다.',
          status: SubscriptionAccessStatus.refunded,
        );
      case SubscriptionAccessStatus.revoked:
        return const SubscriptionBillingResult(
          outcome: SubscriptionBillingOutcome.blocked,
          message: '구독이 취소되어 접근이 제한됩니다.',
          status: SubscriptionAccessStatus.revoked,
        );
      case SubscriptionAccessStatus.unknown:
        return const SubscriptionBillingResult(
          outcome: SubscriptionBillingOutcome.blocked,
          message: '구독 정보가 없습니다. 구독 결제를 진행해 주세요.',
          status: SubscriptionAccessStatus.unknown,
        );
    }
  }

  Future<SubscriptionBillingResult> startPurchaseFlow({
    required String userId,
  }) async {
    final stateResult = await checkSubscriptionStatus(userId: userId);
    if (stateResult.status == SubscriptionAccessStatus.active ||
        stateResult.status == SubscriptionAccessStatus.grace) {
      return const SubscriptionBillingResult(
        outcome: SubscriptionBillingOutcome.success,
        message: '이미 사용 가능한 구독 상태입니다.',
      );
    }

    final storeResult = await _storeAdapter.startSubscriptionPurchase(
      userId: userId,
    );
    return _mapStoreResult(storeResult);
  }

  Future<SubscriptionBillingResult> restorePurchases({
    required String userId,
  }) async {
    final stateResult = await checkSubscriptionStatus(userId: userId);
    if (stateResult.status == SubscriptionAccessStatus.active ||
        stateResult.status == SubscriptionAccessStatus.grace) {
      return const SubscriptionBillingResult(
        outcome: SubscriptionBillingOutcome.success,
        message: '복구 가능한 활성 구독이 확인되었습니다.',
      );
    }

    final storeResult = await _storeAdapter.restorePurchases(userId: userId);
    return _mapStoreResult(storeResult);
  }

  SubscriptionBillingResult _mapStoreResult(
    SubscriptionStoreActionResult storeResult,
  ) {
    switch (storeResult.outcome) {
      case SubscriptionStoreActionOutcome.success:
        return SubscriptionBillingResult(
          outcome: SubscriptionBillingOutcome.success,
          message: storeResult.message,
        );
      case SubscriptionStoreActionOutcome.cancelled:
        return SubscriptionBillingResult(
          outcome: SubscriptionBillingOutcome.blocked,
          message: storeResult.message,
        );
      case SubscriptionStoreActionOutcome.notAvailable:
        return SubscriptionBillingResult(
          outcome: SubscriptionBillingOutcome.notImplemented,
          message: storeResult.message,
        );
      case SubscriptionStoreActionOutcome.failed:
        return SubscriptionBillingResult(
          outcome: SubscriptionBillingOutcome.error,
          message: storeResult.message,
        );
    }
  }
}
