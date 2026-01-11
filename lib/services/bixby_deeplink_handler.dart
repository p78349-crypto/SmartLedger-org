import 'package:flutter/material.dart';

import '../models/visit_price_entry.dart';
import '../screens/visit_price_form_screen.dart';

/// Simple handler that parses a Bixby deep link and navigates to VisitPriceFormScreen
class BixbyDeepLinkHandler {
  BixbyDeepLinkHandler._();
  static final instance = BixbyDeepLinkHandler._();

  /// Example URI: smartledger://visit_price_form?storeId=lotte_jamsil&skuId=onion_001&price=2100&quantity=1&discount=onePlusOne
  Future<bool> handleUri(BuildContext context, Uri uri) async {
    if (uri.host != 'visit_price_form' && uri.path != '/visit_price_form') {
      return false;
    }

    final params = uri.queryParameters;
    final storeId = params['storeId'];
    final skuId = params['skuId'];
    final skuName = params['skuName'];
    final price = double.tryParse(params['price'] ?? '');
    final quantity = int.tryParse(params['quantity'] ?? '');
    final discountStr = params['discount'];

    DiscountType discountType = DiscountType.none;
    double multiplier = 1.0;
    if (discountStr != null) {
      switch (discountStr) {
        case 'onePlusOne':
          discountType = DiscountType.onePlusOne;
          multiplier = 0.5;
          break;
        case 'clearance':
          discountType = DiscountType.clearance;
          multiplier = 0.4;
          break;
        case 'timeSale':
          discountType = DiscountType.timeSale;
          multiplier = 0.7;
          break;
        case 'coupon':
          discountType = DiscountType.coupon;
          multiplier = 0.85;
          break;
        default:
          discountType = DiscountType.custom;
          multiplier = double.tryParse(discountStr) ?? 1.0;
      }
    }

    DiscountContext? discount;
    if (discountStr != null) {
      discount = DiscountContext(
        type: discountType,
        multiplier: multiplier,
        label: discountStr,
      );
    }

    // navigate to VisitPriceFormScreen with initial values
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitPriceFormScreen(
          initialStoreId: storeId,
          initialSkuId: skuId,
          initialSkuName: skuName ?? skuId,
          initialUnitPrice: price,
          initialQuantity: quantity,
          initialDiscount: discount,
          regionCode: 'KR',
        ),
      ),
    );

    return true;
  }
}
