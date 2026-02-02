import 'dart:convert';
import 'package:flutter/services.dart';

/// 생활용품 추천 데이터 모델
class HouseholdRecommendedItem {
  final String code;
  final String category1; // 대분류
  final String category2; // 중분류
  final String category3; // 소분류
  final String category4; // 세분류
  final String name;
  final String unit;
  final double defaultQuantity;
  final int frequency; // 추천 빈도 (사용 횟수)

  HouseholdRecommendedItem({
    required this.code,
    required this.category1,
    required this.category2,
    required this.category3,
    required this.category4,
    required this.name,
    required this.unit,
    required this.defaultQuantity,
    this.frequency = 0,
  });

  factory HouseholdRecommendedItem.fromJson(Map<String, dynamic> json) {
    return HouseholdRecommendedItem(
      code: json['code'] ?? '',
      category1: json['category1'] ?? '',
      category2: json['category2'] ?? '',
      category3: json['category3'] ?? '',
      category4: json['category4'] ?? '',
      name: json['name'] ?? '',
      unit: json['unit'] ?? '개',
      defaultQuantity: (json['defaultQuantity'] ?? 1.0).toDouble(),
      frequency: json['frequency'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'category1': category1,
      'category2': category2,
      'category3': category3,
      'category4': category4,
      'name': name,
      'unit': unit,
      'defaultQuantity': defaultQuantity,
      'frequency': frequency,
    };
  }
}

/// 생활용품 추천 아이템 유틸리티
class HouseholdRecommendedItemsUtils {
  static List<HouseholdRecommendedItem>? _cachedItems;

  /// 모든 추천 생활용품 아이템 로드
  static Future<List<HouseholdRecommendedItem>> loadItems() async {
    if (_cachedItems != null) return _cachedItems!;

    final jsonString = await rootBundle.loadString(
      'assets/data/household_products_3089.json',
    );
    final jsonList = jsonDecode(jsonString) as List;
    _cachedItems = jsonList
        .map(
          (e) => HouseholdRecommendedItem.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    return _cachedItems!;
  }

  /// 카테고리 1 (대분류) 목록 조회
  static Future<List<String>> getCategory1List() async {
    final items = await loadItems();
    final categories = <String>{};
    for (final item in items) {
      if (item.category1.isNotEmpty) {
        categories.add(item.category1);
      }
    }
    return categories.toList()..sort();
  }

  /// 카테고리 2 (중분류) 목록 조회
  static Future<List<String>> getCategory2List(String category1) async {
    final items = await loadItems();
    final categories = <String>{};
    for (final item in items) {
      if (item.category1 == category1 && item.category2.isNotEmpty) {
        categories.add(item.category2);
      }
    }
    return categories.toList()..sort();
  }

  /// 상위 추천 아이템 조회 (빈도 기반)
  static Future<List<HouseholdRecommendedItem>> getTopRecommendedItems({
    int limit = 20,
  }) async {
    final items = await loadItems();
    items.sort((a, b) => b.frequency.compareTo(a.frequency));
    return items.take(limit).toList();
  }

  /// 카테고리별 추천 아이템 조회
  static Future<List<HouseholdRecommendedItem>> getRecommendedByCategory(
    String category1,
  ) async {
    final items = await loadItems();
    return items.where((item) => item.category1 == category1).toList()
      ..sort((a, b) => b.frequency.compareTo(a.frequency));
  }

  /// 검색
  static Future<List<HouseholdRecommendedItem>> searchItems(
    String query,
  ) async {
    if (query.trim().isEmpty) return [];
    final items = await loadItems();
    final lowerQuery = query.toLowerCase();
    return items
        .where(
          (item) =>
              item.name.toLowerCase().contains(lowerQuery) ||
              item.category1.toLowerCase().contains(lowerQuery) ||
              item.category2.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// 추천 빈도 업데이트
  static void updateFrequency(String code, int increment) {
    if (_cachedItems == null) return;
    for (final item in _cachedItems!) {
      if (item.code == code) {
        final idx = _cachedItems!.indexOf(item);
        _cachedItems![idx] = HouseholdRecommendedItem(
          code: item.code,
          category1: item.category1,
          category2: item.category2,
          category3: item.category3,
          category4: item.category4,
          name: item.name,
          unit: item.unit,
          defaultQuantity: item.defaultQuantity,
          frequency: item.frequency + increment,
        );
        break;
      }
    }
  }
}
