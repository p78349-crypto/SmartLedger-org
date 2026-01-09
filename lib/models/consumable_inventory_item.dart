import 'package:flutter/foundation.dart';

@immutable
class ConsumableUsageRecord {
  final DateTime timestamp;
  final double amount;

  const ConsumableUsageRecord({required this.timestamp, required this.amount});

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'amount': amount,
  };

  factory ConsumableUsageRecord.fromJson(Map<String, dynamic> json) {
    return ConsumableUsageRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

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
  final DateTime? expiryDate; // (옵션) 유통기한
  final List<String> healthTags; // 건강 주의 태그 (예: 탄수화물/당류/주류)
  final List<ConsumableUsageRecord> usageHistory;

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
    this.expiryDate,
    this.healthTags = const <String>[],
    this.usageHistory = const <ConsumableUsageRecord>[],
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
    'expiryDate': expiryDate?.toIso8601String(),
    'healthTags': healthTags,
    'usageHistory': usageHistory.map((e) => e.toJson()).toList(),
  };

  factory ConsumableInventoryItem.fromJson(Map<String, dynamic> json) {
    final lastUpdated = DateTime.parse(json['lastUpdated'] as String);
    DateTime? expiryDate;
    final expiryRaw = json['expiryDate'];
    if (expiryRaw is String && expiryRaw.trim().isNotEmpty) {
      expiryDate = DateTime.tryParse(expiryRaw);
    }

    final usageRaw = json['usageHistory'];
    final usageHistory = <ConsumableUsageRecord>[];
    if (usageRaw is List) {
      for (final entry in usageRaw) {
        if (entry is Map<String, dynamic>) {
          try {
            usageHistory.add(ConsumableUsageRecord.fromJson(entry));
          } catch (_) {
            // ignore invalid entries for backward compatibility
          }
        }
      }
    }

    final tagsRaw = json['healthTags'];
    final tags = <String>[];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        if (t is String) {
          final s = t.trim();
          if (s.isNotEmpty) tags.add(s);
        }
      }
    }

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
      expiryDate: expiryDate,
      healthTags: tags,
      usageHistory: usageHistory,
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
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    List<String>? healthTags,
    List<ConsumableUsageRecord>? usageHistory,
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
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      healthTags: healthTags ?? this.healthTags,
      usageHistory: usageHistory ?? this.usageHistory,
    );
  }
}
