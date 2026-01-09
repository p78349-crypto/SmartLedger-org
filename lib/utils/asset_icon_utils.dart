import 'package:flutter/material.dart';
import '../models/asset.dart';
import 'icon_catalog.dart';

/// 자산 카테고리별 아이콘 및 메타데이터 관리
class AssetIconUtils {
  const AssetIconUtils._();

  /// 자산 카테고리별 아이콘 맵
  static const Map<AssetCategory, AssetCategoryIcon> _categoryIcons = {
    AssetCategory.stock: AssetCategoryIcon(
      id: 'asset_stock',
      label: 'Stock',
      icon: IconCatalog.trendingUp,
    ),
    AssetCategory.bond: AssetCategoryIcon(
      id: 'asset_bond',
      label: 'Bond',
      icon: IconCatalog.assessment,
    ),
    AssetCategory.realEstate: AssetCategoryIcon(
      id: 'asset_real_estate',
      label: 'Real estate',
      icon: IconCatalog.apartment,
    ),
    AssetCategory.deposit: AssetCategoryIcon(
      id: 'asset_deposit',
      label: 'Deposit',
      icon: IconCatalog.accountBalance,
    ),
    AssetCategory.crypto: AssetCategoryIcon(
      id: 'asset_crypto',
      label: 'Crypto',
      icon: IconCatalog.currencyBitcoin,
    ),
    AssetCategory.cash: AssetCategoryIcon(
      id: 'asset_cash',
      label: 'Cash',
      icon: IconCatalog.payments,
    ),
    AssetCategory.other: AssetCategoryIcon(
      id: 'asset_other',
      label: 'Other',
      icon: IconCatalog.categoryOutlined,
    ),
  };

  /// 카테고리별 아이콘 조회
  static AssetCategoryIcon getIcon(AssetCategory category) =>
      _categoryIcons[category]!;

  /// 모든 카테고리 아이콘 목록
  static List<AssetCategoryIcon> getAllIcons() =>
      _categoryIcons.values.toList();

  /// 카테고리별 아이콘만 추출
  static IconData getIconData(AssetCategory category) =>
      _categoryIcons[category]!.icon;

  /// 카테고리별 라벨 조회
  static String getLabel(AssetCategory category) =>
      _categoryIcons[category]!.label;
}

/// 자산 카테고리 아이콘 메타데이터
class AssetCategoryIcon {
  final String id;
  final String label;
  final IconData icon;

  const AssetCategoryIcon({
    required this.id,
    required this.label,
    required this.icon,
  });
}
