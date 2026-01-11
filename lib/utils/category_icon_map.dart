import 'package:flutter/material.dart';
import 'icon_catalog.dart';

/// Small map of main-category names to icons used across stats screens.
/// Extend this map as categories evolve in the app.
class CategoryIcon {
  static const _map = <String, IconData>{
    '식비': IconCatalog.restaurant,
    '장보기': IconCatalog.shoppingCart,
    '교통': IconCatalog.moveDown,
    '쇼핑': IconCatalog.shoppingCart,
    '저축': IconCatalog.savings,
    '수입': IconCatalog.attachMoney,
    '생활': IconCatalog.localOffer,
    '결제수단': IconCatalog.payment,
    '기타': IconCatalog.categoryOutlined,
  };

  static IconData getIcon(String? mainCategory) {
    if (mainCategory == null) return IconCatalog.categoryOutlined;
    return _map[mainCategory] ?? IconCatalog.categoryOutlined;
  }
}
