import 'dart:convert';
import 'package:flutter/services.dart';

/// 글로벌 식료품 데이터 모델 (FoodData Central)
class GlobalFoodItem {
  const GlobalFoodItem({
    required this.fdcId,
    required this.name,
    required this.category,
    required this.type,
    this.brand,
    this.nutrients,
    this.servingSize,
    this.servingSizeUnit,
    this.unit = '',
  });

  final int fdcId;
  final String name;
  final String category;
  final String type; // 'foundation' or 'branded'
  final String? brand;
  final int? nutrients;
  final double? servingSize;
  final String? servingSizeUnit;
  final String unit;

  factory GlobalFoodItem.fromJson(Map<String, dynamic> json) {
    return GlobalFoodItem(
      fdcId: json['fdcId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '기타',
      type: json['type'] as String? ?? 'foundation',
      brand: json['brand'] as String?,
      nutrients: json['nutrients'] as int?,
      servingSize: (json['servingSize'] as num?)?.toDouble(),
      servingSizeUnit: json['servingSizeUnit'] as String?,
      unit: json['unit'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fdcId': fdcId,
      'name': name,
      'category': category,
      'type': type,
      if (brand != null) 'brand': brand,
      if (nutrients != null) 'nutrients': nutrients,
      if (servingSize != null) 'servingSize': servingSize,
      if (servingSizeUnit != null) 'servingSizeUnit': servingSizeUnit,
      'unit': unit,
    };
  }
}

/// 글로벌 식료품 데이터 로더
class GlobalFoodDataUtils {
  GlobalFoodDataUtils._();

  static List<GlobalFoodItem>? _cachedItems;
  static List<String>? _cachedCategories;

  /// 전체 데이터 로드
  static Future<List<GlobalFoodItem>> loadItems() async {
    if (_cachedItems != null) return _cachedItems!;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/global_food_data.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      _cachedItems = jsonList
          .map((json) => GlobalFoodItem.fromJson(json as Map<String, dynamic>))
          .toList();

      return _cachedItems!;
    } catch (e) {
      _cachedItems = [];
      return _cachedItems!;
    }
  }

  /// 카테고리 목록
  static Future<List<String>> getCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;

    final items = await loadItems();
    final categorySet = <String>{};

    for (final item in items) {
      if (item.category.isNotEmpty) {
        categorySet.add(item.category);
      }
    }

    _cachedCategories = categorySet.toList()..sort();
    return _cachedCategories!;
  }

  /// 카테고리별 아이템
  static Future<List<GlobalFoodItem>> getItemsByCategory(
    String category,
  ) async {
    final items = await loadItems();
    return items.where((item) => item.category == category).toList();
  }

  /// 타입별 아이템 (foundation/branded)
  static Future<List<GlobalFoodItem>> getItemsByType(String type) async {
    final items = await loadItems();
    return items.where((item) => item.type == type).toList();
  }

  /// 브랜드별 아이템
  static Future<List<GlobalFoodItem>> getItemsByBrand(String brand) async {
    final items = await loadItems();
    return items
        .where(
          (item) =>
              item.brand != null &&
              item.brand!.toLowerCase().contains(brand.toLowerCase()),
        )
        .toList();
  }

  /// 검색
  static Future<List<GlobalFoodItem>> searchItems(String query) async {
    if (query.trim().isEmpty) return [];

    final items = await loadItems();
    final lowerQuery = query.toLowerCase().trim();
    final results = <GlobalFoodItem>[];

    for (final item in items) {
      final matchName = item.name.toLowerCase().contains(lowerQuery);
      final matchCategory = item.category.toLowerCase().contains(lowerQuery);
      final matchBrand =
          item.brand != null && item.brand!.toLowerCase().contains(lowerQuery);

      if (matchName || matchCategory || matchBrand) {
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
