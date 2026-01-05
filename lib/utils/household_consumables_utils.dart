import 'package:flutter/material.dart';

class HouseholdConsumableItem {
  final String name;
  final String mainCategory;
  final String subCategory;
  final String? detailCategory;
  final IconData icon;
  final double defaultBundleSize;

  const HouseholdConsumableItem({
    required this.name,
    required this.mainCategory,
    required this.subCategory,
    this.detailCategory,
    required this.icon,
    this.defaultBundleSize = 1.0,
  });
}

class HouseholdConsumablesUtils {
  HouseholdConsumablesUtils._();

  static const List<HouseholdConsumableItem> defaultItems = [
    HouseholdConsumableItem(
      name: '두루마리 휴지',
      mainCategory: '생활용품비',
      subCategory: '화장지/일회용품',
      detailCategory: '두루마리 휴지',
      icon: Icons.layers,
      defaultBundleSize: 30.0,
    ),
    HouseholdConsumableItem(
      name: '미용티슈',
      mainCategory: '생활용품비',
      subCategory: '화장지/일회용품',
      detailCategory: '미용티슈',
      icon: Icons.face,
      defaultBundleSize: 3.0,
    ),
    HouseholdConsumableItem(
      name: '키친타월',
      mainCategory: '생활용품비',
      subCategory: '화장지/일회용품',
      detailCategory: '키친타월',
      icon: Icons.kitchen,
      defaultBundleSize: 4.0,
    ),
    HouseholdConsumableItem(
      name: '냅킨',
      mainCategory: '생활용품비',
      subCategory: '화장지/일회용품',
      detailCategory: '냅킨',
      icon: Icons.restaurant,
    ),
    HouseholdConsumableItem(
      name: '비누',
      mainCategory: '생활용품비',
      subCategory: '세면/위생용품',
      detailCategory: '비누',
      icon: Icons.clean_hands,
      defaultBundleSize: 4.0,
    ),
    HouseholdConsumableItem(
      name: '치약',
      mainCategory: '생활용품비',
      subCategory: '세면/위생용품',
      detailCategory: '치약',
      icon: Icons.brush,
      defaultBundleSize: 3.0,
    ),
    HouseholdConsumableItem(
      name: '샴푸',
      mainCategory: '생활용품비',
      subCategory: '세면/위생용품',
      detailCategory: '샴푸',
      icon: Icons.wash,
    ),
    HouseholdConsumableItem(
      name: '주방세제',
      mainCategory: '생활용품비',
      subCategory: '세탁/청소용품',
      detailCategory: '주방세제',
      icon: Icons.soap,
    ),
    HouseholdConsumableItem(
      name: '세탁세제',
      mainCategory: '생활용품비',
      subCategory: '세탁/청소용품',
      detailCategory: '세탁세제',
      icon: Icons.local_laundry_service,
    ),
    HouseholdConsumableItem(
      name: '물티슈',
      mainCategory: '생활용품비',
      subCategory: '화장지/일회용품',
      detailCategory: '물티슈',
      icon: Icons.texture,
      defaultBundleSize: 10.0,
    ),
  ];
}
