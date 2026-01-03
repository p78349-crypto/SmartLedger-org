import 'package:flutter/foundation.dart';

@immutable
class FoodExpiryItem {
  final String id;
  final String name;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final DateTime createdAt;
  final String memo;
  final double quantity;
  final String unit;
  final String category;
  final String location;
  final double price;
  final String supplier;

  const FoodExpiryItem({
    required this.id,
    required this.name,
    required this.purchaseDate,
    required this.expiryDate,
    required this.createdAt,
    this.memo = '',
    this.quantity = 1.0,
    this.unit = '개',
    this.category = '기타',
    this.location = '냉장',
    this.price = 0.0,
    this.supplier = '',
  });

  int daysLeft(DateTime now) {
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return end.difference(start).inDays;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'purchaseDate': purchaseDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'memo': memo,
    'quantity': quantity,
    'unit': unit,
    'category': category,
    'location': location,
    'price': price,
    'supplier': supplier,
  };

  static FoodExpiryItem fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);
    return FoodExpiryItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      purchaseDate: json['purchaseDate'] is String
          ? DateTime.parse(json['purchaseDate'] as String)
          : createdAt,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      createdAt: createdAt,
      memo: (json['memo'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: (json['unit'] as String?) ?? '개',
      category: (json['category'] as String?) ?? '기타',
      location: (json['location'] as String?) ?? '냉장',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      supplier: (json['supplier'] as String?) ?? '',
    );
  }

  FoodExpiryItem copyWith({
    String? name,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? memo,
    double? quantity,
    String? unit,
    String? category,
    String? location,
    double? price,
    String? supplier,
  }) {
    return FoodExpiryItem(
      id: id,
      name: name ?? this.name,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt,
      memo: memo ?? this.memo,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      location: location ?? this.location,
      price: price ?? this.price,
      supplier: supplier ?? this.supplier,
    );
  }
}
