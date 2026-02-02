import 'dart:convert';
import 'package:flutter/services.dart';

/// 생활용품 데이터 모델
class HouseholdItem {
  const HouseholdItem({
    required this.code,
    required this.name,
    required this.category1,
    required this.category2,
    required this.category3,
    required this.category4,
    this.unit = '',
    this.defaultQuantity = 1,
  });

  final String code;
  final String name;
  final String category1;
  final String category2;
  final String category3;
  final String category4;
  final String unit;
  final int defaultQuantity;

  factory HouseholdItem.fromJson(Map<String, dynamic> json) {
    return HouseholdItem(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category1: json['category1'] as String? ?? '',
      category2: json['category2'] as String? ?? '',
      category3: json['category3'] as String? ?? '',
      category4: json['category4'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      defaultQuantity: json['defaultQuantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'category1': category1,
      'category2': category2,
      'category3': category3,
      'category4': category4,
      'unit': unit,
      'defaultQuantity': defaultQuantity,
    };
  }
}

/// 생활용품 데이터 로더
class HouseholdItemsUtils {
  HouseholdItemsUtils._();

  static List<HouseholdItem>? _cachedItems;
  static List<String>? _cachedCategories;

  /// 전체 데이터 로드
  static Future<List<HouseholdItem>> loadItems() async {
    if (_cachedItems != null) return _cachedItems!;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/household_products_3089.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      _cachedItems = jsonList
          .map((json) => HouseholdItem.fromJson(json as Map<String, dynamic>))
          .toList();

      return _cachedItems!;
    } catch (e) {
      _cachedItems = [];
      return _cachedItems!;
    }
  }

  /// 대분류(category1) 목록
  static Future<List<String>> getCategory1List() async {
    if (_cachedCategories != null) return _cachedCategories!;

    final items = await loadItems();
    final categorySet = <String>{};

    for (final item in items) {
      if (item.category1.isNotEmpty) {
        categorySet.add(item.category1);
      }
    }

    _cachedCategories = categorySet.toList()..sort();
    return _cachedCategories!;
  }

  /// 대분류로 중분류(category2) 목록 가져오기
  static Future<List<String>> getCategory2List(String category1) async {
    final items = await loadItems();
    final categorySet = <String>{};

    for (final item in items) {
      if (item.category1 == category1 && item.category2.isNotEmpty) {
        categorySet.add(item.category2);
      }
    }

    return categorySet.toList()..sort();
  }

  /// 중분류로 소분류(category3) 목록 가져오기
  static Future<List<String>> getCategory3List(
    String category1,
    String category2,
  ) async {
    final items = await loadItems();
    final categorySet = <String>{};

    for (final item in items) {
      if (item.category1 == category1 &&
          item.category2 == category2 &&
          item.category3.isNotEmpty) {
        categorySet.add(item.category3);
      }
    }

    return categorySet.toList()..sort();
  }

  /// 소분류로 세분류(category4) 목록 가져오기
  static Future<List<String>> getCategory4List(
    String category1,
    String category2,
    String category3,
  ) async {
    final items = await loadItems();
    final categorySet = <String>{};

    for (final item in items) {
      if (item.category1 == category1 &&
          item.category2 == category2 &&
          item.category3 == category3 &&
          item.category4.isNotEmpty) {
        categorySet.add(item.category4);
      }
    }

    return categorySet.toList()..sort();
  }

  /// 특정 카테고리의 아이템 목록
  static Future<List<HouseholdItem>> getItemsByCategory({
    required String category1,
    String? category2,
    String? category3,
    String? category4,
  }) async {
    final items = await loadItems();
    return items.where((item) {
      if (item.category1 != category1) return false;
      if (category2 != null && item.category2 != category2) {
        return false;
      }
      if (category3 != null && item.category3 != category3) {
        return false;
      }
      if (category4 != null && item.category4 != category4) {
        return false;
      }
      return true;
    }).toList();
  }

  /// 검색
  static Future<List<HouseholdItem>> searchItems(String query) async {
    if (query.trim().isEmpty) return [];

    final items = await loadItems();
    final lowerQuery = query.toLowerCase().trim();
    final results = <HouseholdItem>[];

    for (final item in items) {
      if (item.name.toLowerCase().contains(lowerQuery) ||
          item.category1.toLowerCase().contains(lowerQuery) ||
          item.category2.toLowerCase().contains(lowerQuery) ||
          item.category3.toLowerCase().contains(lowerQuery) ||
          item.category4.toLowerCase().contains(lowerQuery)) {
        results.add(item);
      }
    }

    return results;
  }

  /// 캐시 초기화
  static void clearCache() {
    _cachedItems = null;
    _cachedCategories = null;
  }
}
