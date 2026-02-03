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

/// 생활용품 재고 관리 통합 모델
/// 
/// - 생활용품 + 식료품 수량 추적
/// - 유통기한 관리 지원 (선택사항)
/// - 사용 기록 및 부족 알림 포함
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
  final List<String> healthTags; // 건강 주의 태그 (예: 탄수화물/당류/주류)
  final List<ConsumableUsageRecord> usageHistory;
  
  // 식료품 관리용 필드 (유통기한 추적)
  final DateTime? expiryDate;        // 유통기한
  final DateTime? purchaseDate;      // 구매일 (FoodExpiry와의 호환성)
  final double? price;               // 구매 가격
  final String? supplier;            // 구매처

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
    this.unit = '',
    this.threshold = 1.0,
    this.bundleSize = 1.0,
    this.category = '생활용품',
    this.detailCategory,
    this.location = '기타',
    required this.createdAt,
    required this.lastUpdated,
    this.healthTags = const <String>[],
    this.usageHistory = const <ConsumableUsageRecord>[],
    this.expiryDate,
    this.purchaseDate,
    this.price,
    this.supplier,
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
    'healthTags': healthTags,
    'usageHistory': usageHistory.map((e) => e.toJson()).toList(),
    'expiryDate': expiryDate?.toIso8601String(),
    'purchaseDate': purchaseDate?.toIso8601String(),
    'price': price,
    'supplier': supplier,
  };

  factory ConsumableInventoryItem.fromJson(Map<String, dynamic> json) {
    final lastUpdated = DateTime.parse(json['lastUpdated'] as String);

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
      unit: (json['unit'] as String?) ?? '',
      threshold: (json['threshold'] as num?)?.toDouble() ?? 1.0,
      bundleSize: (json['bundleSize'] as num?)?.toDouble() ?? 1.0,
      category: (json['category'] as String?) ?? '생활용품',
      detailCategory: json['detailCategory'] as String?,
      location: (json['location'] as String?) ?? '기타', // 기존 데이터 호환
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : lastUpdated, // 기존 데이터 호환: createdAt 없으면 lastUpdated 사용
      lastUpdated: lastUpdated,
      healthTags: tags,
      usageHistory: usageHistory,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      price: (json['price'] as num?)?.toDouble(),
      supplier: json['supplier'] as String?,
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
    List<String>? healthTags,
    List<ConsumableUsageRecord>? usageHistory,
    DateTime? expiryDate,
    DateTime? purchaseDate,
    double? price,
    String? supplier,
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
      healthTags: healthTags ?? this.healthTags,
      usageHistory: usageHistory ?? this.usageHistory,
      expiryDate: expiryDate ?? this.expiryDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      price: price ?? this.price,
      supplier: supplier ?? this.supplier,
    );
  }
  
  /// 유통기한 임박 여부 (기본 3일 이내)
  bool isExpiringWithin({int days = 3}) {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final diff = expiryDate!.difference(now).inDays;
    return diff >= 0 && diff <= days;
  }
  
  /// 유통기한 경과 여부
  bool isExpired() {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
}
