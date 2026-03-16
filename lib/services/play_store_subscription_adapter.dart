import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/subscription_product_config.dart';
import 'subscription_store_adapter.dart';

class PlayStoreSubscriptionAdapter implements SubscriptionStoreAdapter {
  PlayStoreSubscriptionAdapter({
    Set<String>? productIds,
  }) : _productIds =
           productIds ?? SubscriptionProductConfig.productIdsForCurrentPlatform();

  final Set<String> _productIds;

  @override
  Future<SubscriptionStoreActionResult> startSubscriptionPurchase({
    required String userId,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SubscriptionStoreActionResult(
        outcome: SubscriptionStoreActionOutcome.notAvailable,
        message: '현재 플랫폼은 Play 결제를 지원하지 않습니다.',
      );
    }

    final iap = InAppPurchase.instance;
    final available = await iap.isAvailable();
    if (!available) {
      return const SubscriptionStoreActionResult(
        outcome: SubscriptionStoreActionOutcome.notAvailable,
        message: 'Google Play 결제 서비스를 사용할 수 없습니다.',
      );
    }

    final productResponse = await iap.queryProductDetails(_productIds);
    if (productResponse.error != null) {
      return SubscriptionStoreActionResult(
        outcome: SubscriptionStoreActionOutcome.failed,
        message: '상품 조회 실패: ${productResponse.error!.message}',
      );
    }

    if (productResponse.productDetails.isEmpty) {
      return const SubscriptionStoreActionResult(
        outcome: SubscriptionStoreActionOutcome.notAvailable,
        message: '등록된 구독 상품이 없습니다. 콘솔 상품 ID를 확인해 주세요.',
      );
    }

    final product = productResponse.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    final started = await iap.buyNonConsumable(purchaseParam: purchaseParam);

    if (!started) {
      return const SubscriptionStoreActionResult(
        outcome: SubscriptionStoreActionOutcome.failed,
        message: '결제 요청을 시작하지 못했습니다.',
      );
    }

    return const SubscriptionStoreActionResult(
      outcome: SubscriptionStoreActionOutcome.success,
      message: '결제 요청을 전송했습니다. 스토어 결제 완료 후 상태를 확인해 주세요.',
    );
  }

  @override
  Future<SubscriptionStoreActionResult> restorePurchases({
    required String userId,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SubscriptionStoreActionResult(
        outcome: SubscriptionStoreActionOutcome.notAvailable,
        message: '현재 플랫폼은 Play 구매 복구를 지원하지 않습니다.',
      );
    }

    final iap = InAppPurchase.instance;
    final available = await iap.isAvailable();
    if (!available) {
      return const SubscriptionStoreActionResult(
        outcome: SubscriptionStoreActionOutcome.notAvailable,
        message: 'Google Play 결제 서비스를 사용할 수 없습니다.',
      );
    }

    await iap.restorePurchases();
    return const SubscriptionStoreActionResult(
      outcome: SubscriptionStoreActionOutcome.success,
      message: '구매 복구 요청을 전송했습니다. 잠시 후 구독 상태를 다시 확인해 주세요.',
    );
  }
}
