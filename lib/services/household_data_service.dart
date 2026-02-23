import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/household_product.dart';

class HouseholdDataService {
  HouseholdDataService._internal();
  static final HouseholdDataService instance = HouseholdDataService._internal();

  List<HouseholdProduct>? _allProducts;
  final Map<String, List<HouseholdProduct>> _categoryMap = {};

  bool get isLoaded => _allProducts != null;

  Future<void> init() async {
    if (isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/household_products_3089.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _allProducts = jsonList.map((e) => HouseholdProduct.fromJson(e)).toList();

      // 카테고리별 그룹화 (Category1 기준)
      for (final p in _allProducts!) {
        _categoryMap.putIfAbsent(p.category1, () => []).add(p);
      }
    } catch (e) {
      _allProducts = [];
    }
  }

  List<String> getMainCategories() {
    return _categoryMap.keys.toList()..sort();
  }

  List<HouseholdProduct> getProductsByCategory(String category1) {
    return _categoryMap[category1] ?? [];
  }

  List<HouseholdProduct> search(String query) {
    if (query.isEmpty) return [];
    if (_allProducts == null) return [];

    final q = query.toLowerCase().trim();
    return _allProducts!.where((p) {
      return p.name.toLowerCase().contains(q) ||
             p.category1.toLowerCase().contains(q) ||
             p.category2.toLowerCase().contains(q) ||
             p.category3.toLowerCase().contains(q) ||
             p.category4.toLowerCase().contains(q);
    }).toList();
  }
}
