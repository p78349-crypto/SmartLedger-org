import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/subscription_access_service.dart';

void main() {
  group('SubscriptionAccessService', () {
    const userId = 'u_test';

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('default state is unknown and has no premium access', () async {
      final state = await SubscriptionAccessService.getState(userId);

      expect(state.status, SubscriptionAccessStatus.unknown);
      final hasAccess = await SubscriptionAccessService.hasPremiumAccessForUser(
        userId,
      );
      expect(hasAccess, isFalse);
    });

    test('active status with future expiry grants access', () async {
      final now = DateTime.now();
      await SubscriptionAccessService.saveState(
        userId: userId,
        state: SubscriptionAccessState(
          status: SubscriptionAccessStatus.active,
          productId: 'premium_monthly',
          platform: 'android',
          expiresAtMs: now.add(const Duration(days: 30)).millisecondsSinceEpoch,
        ),
      );

      final hasAccess = await SubscriptionAccessService.hasPremiumAccessForUser(
        userId,
        now: now,
      );
      expect(hasAccess, isTrue);
    });

    test('grace status grants access only when allowGrace is true', () async {
      final now = DateTime.now();
      await SubscriptionAccessService.saveState(
        userId: userId,
        state: SubscriptionAccessState(
          status: SubscriptionAccessStatus.grace,
          expiresAtMs: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
        ),
      );

      final graceAllowed =
          await SubscriptionAccessService.hasPremiumAccessForUser(
            userId,
            now: now,
          );
      final graceBlocked =
          await SubscriptionAccessService.hasPremiumAccessForUser(
            userId,
            now: now,
            allowGrace: false,
          );

      expect(graceAllowed, isTrue);
      expect(graceBlocked, isFalse);
    });

    test('expired status does not grant access', () async {
      final now = DateTime.now();
      await SubscriptionAccessService.saveState(
        userId: userId,
        state: SubscriptionAccessState(
          status: SubscriptionAccessStatus.expired,
          expiresAtMs: now
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
        ),
      );

      final hasAccess = await SubscriptionAccessService.hasPremiumAccessForUser(
        userId,
        now: now,
      );
      expect(hasAccess, isFalse);
    });

    test('clearState removes stored values', () async {
      final now = DateTime.now();
      await SubscriptionAccessService.saveState(
        userId: userId,
        state: SubscriptionAccessState(
          status: SubscriptionAccessStatus.active,
          productId: 'premium_yearly',
          platform: 'ios',
          expiresAtMs: now
              .add(const Duration(days: 365))
              .millisecondsSinceEpoch,
        ),
      );

      await SubscriptionAccessService.clearState(userId);

      final state = await SubscriptionAccessService.getState(userId);
      expect(state.status, SubscriptionAccessStatus.unknown);
      expect(state.productId, isNull);
      expect(state.platform, isNull);
      expect(state.expiresAtMs, isNull);
      expect(state.updatedAtMs, isNull);
    });
  });
}
