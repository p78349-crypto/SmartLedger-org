import 'package:shared_preferences/shared_preferences.dart';

import '../utils/pref_keys.dart';

enum SubscriptionAccessStatus {
  active,
  grace,
  paused,
  expired,
  refunded,
  revoked,
  unknown,
}

class SubscriptionAccessState {
  const SubscriptionAccessState({
    required this.status,
    this.productId,
    this.platform,
    this.expiresAtMs,
    this.updatedAtMs,
  });

  final SubscriptionAccessStatus status;
  final String? productId;
  final String? platform;
  final int? expiresAtMs;
  final int? updatedAtMs;
}

class SubscriptionAccessService {
  const SubscriptionAccessService._();

  static Future<SubscriptionAccessState> getState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final statusRaw = prefs.getString(
      PrefKeys.userKey(userId, PrefKeys.subscriptionStatusSuffix),
    );
    final productId = prefs.getString(
      PrefKeys.userKey(userId, PrefKeys.subscriptionProductIdSuffix),
    );
    final platform = prefs.getString(
      PrefKeys.userKey(userId, PrefKeys.subscriptionPlatformSuffix),
    );
    final expiresAtMs = prefs.getInt(
      PrefKeys.userKey(userId, PrefKeys.subscriptionExpiresAtMsSuffix),
    );
    final updatedAtMs = prefs.getInt(
      PrefKeys.userKey(userId, PrefKeys.subscriptionUpdatedAtMsSuffix),
    );

    return SubscriptionAccessState(
      status: _parseStatus(statusRaw),
      productId: productId,
      platform: platform,
      expiresAtMs: expiresAtMs,
      updatedAtMs: updatedAtMs,
    );
  }

  static Future<void> saveState({
    required String userId,
    required SubscriptionAccessState state,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PrefKeys.userKey(userId, PrefKeys.subscriptionStatusSuffix),
      _statusToWire(state.status),
    );

    if (state.productId == null || state.productId!.isEmpty) {
      await prefs.remove(
        PrefKeys.userKey(userId, PrefKeys.subscriptionProductIdSuffix),
      );
    } else {
      await prefs.setString(
        PrefKeys.userKey(userId, PrefKeys.subscriptionProductIdSuffix),
        state.productId!,
      );
    }

    if (state.platform == null || state.platform!.isEmpty) {
      await prefs.remove(
        PrefKeys.userKey(userId, PrefKeys.subscriptionPlatformSuffix),
      );
    } else {
      await prefs.setString(
        PrefKeys.userKey(userId, PrefKeys.subscriptionPlatformSuffix),
        state.platform!,
      );
    }

    if (state.expiresAtMs == null) {
      await prefs.remove(
        PrefKeys.userKey(userId, PrefKeys.subscriptionExpiresAtMsSuffix),
      );
    } else {
      await prefs.setInt(
        PrefKeys.userKey(userId, PrefKeys.subscriptionExpiresAtMsSuffix),
        state.expiresAtMs!,
      );
    }

    final updatedAtMs = state.updatedAtMs ?? DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(
      PrefKeys.userKey(userId, PrefKeys.subscriptionUpdatedAtMsSuffix),
      updatedAtMs,
    );
  }

  static bool hasPremiumAccess(
    SubscriptionAccessState state, {
    DateTime? now,
    bool allowGrace = true,
  }) {
    final currentMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final isWithinExpiry =
        state.expiresAtMs == null || state.expiresAtMs! > currentMs;

    switch (state.status) {
      case SubscriptionAccessStatus.active:
        return isWithinExpiry;
      case SubscriptionAccessStatus.grace:
        return allowGrace && isWithinExpiry;
      case SubscriptionAccessStatus.paused:
      case SubscriptionAccessStatus.expired:
      case SubscriptionAccessStatus.refunded:
      case SubscriptionAccessStatus.revoked:
      case SubscriptionAccessStatus.unknown:
        return false;
    }
  }

  static Future<bool> hasPremiumAccessForUser(
    String userId, {
    DateTime? now,
    bool allowGrace = true,
  }) async {
    final state = await getState(userId);
    return hasPremiumAccess(state, now: now, allowGrace: allowGrace);
  }

  static Future<void> clearState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefKeys.userKey(userId, PrefKeys.subscriptionStatusSuffix));
    await prefs.remove(
      PrefKeys.userKey(userId, PrefKeys.subscriptionProductIdSuffix),
    );
    await prefs.remove(
      PrefKeys.userKey(userId, PrefKeys.subscriptionPlatformSuffix),
    );
    await prefs.remove(
      PrefKeys.userKey(userId, PrefKeys.subscriptionExpiresAtMsSuffix),
    );
    await prefs.remove(
      PrefKeys.userKey(userId, PrefKeys.subscriptionUpdatedAtMsSuffix),
    );
  }

  static SubscriptionAccessStatus _parseStatus(String? value) {
    switch (value) {
      case 'active':
        return SubscriptionAccessStatus.active;
      case 'grace':
        return SubscriptionAccessStatus.grace;
      case 'paused':
        return SubscriptionAccessStatus.paused;
      case 'expired':
        return SubscriptionAccessStatus.expired;
      case 'refunded':
        return SubscriptionAccessStatus.refunded;
      case 'revoked':
        return SubscriptionAccessStatus.revoked;
      default:
        return SubscriptionAccessStatus.unknown;
    }
  }

  static String _statusToWire(SubscriptionAccessStatus status) {
    switch (status) {
      case SubscriptionAccessStatus.active:
        return 'active';
      case SubscriptionAccessStatus.grace:
        return 'grace';
      case SubscriptionAccessStatus.paused:
        return 'paused';
      case SubscriptionAccessStatus.expired:
        return 'expired';
      case SubscriptionAccessStatus.refunded:
        return 'refunded';
      case SubscriptionAccessStatus.revoked:
        return 'revoked';
      case SubscriptionAccessStatus.unknown:
        return 'unknown';
    }
  }
}
