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

  const FoodExpiryItem({
    required this.id,
    required this.name,
    required this.purchaseDate,
    required this.expiryDate,
    required this.createdAt,
    this.memo = '',
    this.quantity = 1.0,
    this.unit = '개',
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
    );
  }
}
