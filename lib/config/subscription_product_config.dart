import 'package:flutter/foundation.dart';

class SubscriptionProductConfig {
  const SubscriptionProductConfig._();

  static const String _defaultAndroidProducts = 'smartledger_premium_monthly';
  static const String _defaultIosProducts = 'smartledger_premium_monthly_ios';

  static Set<String> productIdsForCurrentPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _parseCsv(
        const String.fromEnvironment(
          'SUBSCRIPTION_PRODUCT_IDS_ANDROID',
          defaultValue: _defaultAndroidProducts,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _parseCsv(
        const String.fromEnvironment(
          'SUBSCRIPTION_PRODUCT_IDS_IOS',
          defaultValue: _defaultIosProducts,
        ),
      );
    }

    return <String>{};
  }

  static Set<String> _parseCsv(String raw) {
    return raw
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet();
  }
}
