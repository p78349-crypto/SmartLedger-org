import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'subscription_access_service.dart';

class SubscriptionPurchaseSyncService {
  factory SubscriptionPurchaseSyncService() => _instance;

  SubscriptionPurchaseSyncService._internal();

  static final SubscriptionPurchaseSyncService _instance =
      SubscriptionPurchaseSyncService._internal();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  String? _userId;

  Future<void> start({required String userId}) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    if (_purchaseSub != null && _userId == userId) return;

    await stop();
    _userId = userId;

    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object _) {},
    );
  }

  Future<void> stop() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _userId = null;
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await SubscriptionAccessService.saveState(
            userId: userId,
            state: SubscriptionAccessState(
              status: SubscriptionAccessStatus.active,
              productId: purchase.productID,
              platform: defaultTargetPlatform.name,
            ),
          );
        case PurchaseStatus.canceled:
          await SubscriptionAccessService.saveState(
            userId: userId,
            state: const SubscriptionAccessState(
              status: SubscriptionAccessStatus.unknown,
            ),
          );
        case PurchaseStatus.error:
          break;
        case PurchaseStatus.pending:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }
}
