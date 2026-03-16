import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/subscription_access_service.dart';
import 'package:smart_ledger/services/subscription_billing_service.dart';
import 'package:smart_ledger/services/subscription_store_adapter.dart';

class _FakeSubscriptionStoreAdapter implements SubscriptionStoreAdapter {
  _FakeSubscriptionStoreAdapter({
    required this.purchaseResult,
    required this.restoreResult,
  });

  final SubscriptionStoreActionResult purchaseResult;
  final SubscriptionStoreActionResult restoreResult;

  @override
  Future<SubscriptionStoreActionResult> startSubscriptionPurchase({
    required String userId,
  }) async {
    return purchaseResult;
  }

  @override
  Future<SubscriptionStoreActionResult> restorePurchases({
    required String userId,
  }) async {
    return restoreResult;
  }
}

void main() {
  group('SubscriptionBillingService', () {
    const userId = 'billing_user';

    late SubscriptionBillingService service;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      service = SubscriptionBillingService.withAdapter(
        _FakeSubscriptionStoreAdapter(
          purchaseResult: const SubscriptionStoreActionResult(
            outcome: SubscriptionStoreActionOutcome.notAvailable,
            message: 'test: purchase not available',
          ),
          restoreResult: const SubscriptionStoreActionResult(
            outcome: SubscriptionStoreActionOutcome.notAvailable,
            message: 'test: restore not available',
          ),
        ),
      );
    });

    test('checkSubscriptionStatus returns active for active cache', () async {
      final now = DateTime.now();
      await SubscriptionAccessService.saveState(
        userId: userId,
        state: SubscriptionAccessState(
          status: SubscriptionAccessStatus.active,
          expiresAtMs: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
        ),
      );

      final result = await service.checkSubscriptionStatus(userId: userId);
      expect(result.outcome, SubscriptionBillingOutcome.success);
      expect(result.status, SubscriptionAccessStatus.active);
    });

    test('startPurchaseFlow maps notAvailable adapter result', () async {
      final result = await service.startPurchaseFlow(userId: userId);
      expect(result.outcome, SubscriptionBillingOutcome.notImplemented);
      expect(result.message, 'test: purchase not available');
    });

    test('restorePurchases returns success when status is grace', () async {
      final now = DateTime.now();
      await SubscriptionAccessService.saveState(
        userId: userId,
        state: SubscriptionAccessState(
          status: SubscriptionAccessStatus.grace,
          expiresAtMs: now.add(const Duration(hours: 12)).millisecondsSinceEpoch,
        ),
      );

      final result = await service.restorePurchases(userId: userId);
      expect(result.outcome, SubscriptionBillingOutcome.success);
    });

    test('startPurchaseFlow maps success adapter result when status is expired', () async {
      final now = DateTime.now();
      await SubscriptionAccessService.saveState(
        userId: userId,
        state: SubscriptionAccessState(
          status: SubscriptionAccessStatus.expired,
          expiresAtMs: now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        ),
      );

      service = SubscriptionBillingService.withAdapter(
        _FakeSubscriptionStoreAdapter(
          purchaseResult: const SubscriptionStoreActionResult(
            outcome: SubscriptionStoreActionOutcome.success,
            message: 'purchase started',
          ),
          restoreResult: const SubscriptionStoreActionResult(
            outcome: SubscriptionStoreActionOutcome.notAvailable,
            message: 'restore n/a',
          ),
        ),
      );

      final result = await service.startPurchaseFlow(userId: userId);
      expect(result.outcome, SubscriptionBillingOutcome.success);
      expect(result.message, 'purchase started');
    });

    test('restorePurchases maps failed adapter result when status is expired', () async {
      final now = DateTime.now();
      await SubscriptionAccessService.saveState(
        userId: userId,
        state: SubscriptionAccessState(
          status: SubscriptionAccessStatus.expired,
          expiresAtMs: now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        ),
      );

      service = SubscriptionBillingService.withAdapter(
        _FakeSubscriptionStoreAdapter(
          purchaseResult: const SubscriptionStoreActionResult(
            outcome: SubscriptionStoreActionOutcome.notAvailable,
            message: 'purchase n/a',
          ),
          restoreResult: const SubscriptionStoreActionResult(
            outcome: SubscriptionStoreActionOutcome.failed,
            message: 'restore failed',
          ),
        ),
      );

      final result = await service.restorePurchases(userId: userId);
      expect(result.outcome, SubscriptionBillingOutcome.error);
      expect(result.message, 'restore failed');
    });
  });
}
