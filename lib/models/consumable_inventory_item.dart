import 'package:flutter/foundation.dart';

@immutable
class ConsumableInventoryItem {
  final String id;
  final String name;
  final double currentStock;
  final String unit;
  final double threshold; // Stock level at which to suggest adding to cart
  final double bundleSize; // Default bundle size (e.g., 30 for toilet paper)
  final String category;
  final String? detailCategory;
  final String location; // 보관 위치: 욕실, 주방, 거실, 창고 등
  final DateTime createdAt; // FIFO: 구매/등록일 기준 정렬용
  final DateTime lastUpdated;

  // 로케이션 옵션 목록
  static const List<String> locationOptions = [
    '욕실',
    '주방',
    '거실',
    '침실',
    '창고',
    '기타',
  ];

  const ConsumableInventoryItem({
    required this.id,
    required this.name,
    this.currentStock = 0.0,
    this.unit = '개',
    this.threshold = 1.0,
    this.bundleSize = 1.0,
    this.category = '생활용품',
    this.detailCategory,
    this.location = '기타',
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currentStock': currentStock,
        'unit': unit,
        'threshold': threshold,
        'bundleSize': bundleSize,
        'category': category,
        'detailCategory': detailCategory,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory ConsumableInventoryItem.fromJson(Map<String, dynamic> json) {
    final lastUpdated = DateTime.parse(json['lastUpdated'] as String);
    return ConsumableInventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      unit: (json['unit'] as String?) ?? '개',
      threshold: (json['threshold'] as num?)?.toDouble() ?? 1.0,
      bundleSize: (json['bundleSize'] as num?)?.toDouble() ?? 1.0,
      category: (json['category'] as String?) ?? '생활용품',
      detailCategory: json['detailCategory'] as String?,
      location: (json['location'] as String?) ?? '기타', // 기존 데이터 호환
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : lastUpdated, // 기존 데이터 호환: createdAt 없으면 lastUpdated 사용
      lastUpdated: lastUpdated,
    );
  }

  ConsumableInventoryItem copyWith({
    String? name,
    double? currentStock,
    String? unit,
    double? threshold,
    double? bundleSize,
    String? category,
    String? detailCategory,
    String? location,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return ConsumableInventoryItem(
      id: id,
      name: name ?? this.name,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      threshold: threshold ?? this.threshold,
      bundleSize: bundleSize ?? this.bundleSize,
      category: category ?? this.category,
      detailCategory: detailCategory ?? this.detailCategory,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
