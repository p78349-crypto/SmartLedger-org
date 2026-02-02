/// WMS 재고 입력 임시저장 모델
///
/// 재고 입력 화면에서 입력 중 종료 시 자동 저장하고,
/// 다음 진입 시 이어서 입력할 수 있도록 지원합니다.
///
/// 사용 예시:
/// - 재고 입력 중 앱 종료 → 자동 저장
/// - 재고 입력 화면 재진입 → "이전 입력 이어하기?" 알림
/// - 장바구니 자동등록 체크한 항목 임시 저장
class WmsInventoryDraftEntry {
  const WmsInventoryDraftEntry({
    required this.id,
    required this.at,
    required this.name,
    this.currentStock,
    this.unit,
    this.category,
    this.detailCategory,
    this.location,
    this.threshold,
    this.bundleSize,
    this.expiryDate,
    this.source,
    this.memo,
  });

  /// 고유 ID (예: "wms_draft_1234567890")
  final String id;

  /// 임시저장 시각
  final DateTime at;

  /// 상품명 (필수)
  final String name;

  /// 현재 재고량 (옵션)
  final double? currentStock;

  /// 단위 (예: "개", "병", "묶음")
  final String? unit;

  /// 카테고리 ("생활용품" / "식료품")
  final String? category;

  /// 상세 카테고리
  final String? detailCategory;

  /// 보관 위치 (욕실, 주방, 거실, 침실, 창고, 기타)
  final String? location;

  /// 알림 임계값 (재고 부족 알림)
  final double? threshold;

  /// 묶음 크기 (구입 단위)
  final double? bundleSize;

  /// 유통기한 (옵션)
  final DateTime? expiryDate;

  /// 입력 경로 추적 (manual, quickUse, shoppingCart, voiceCommand 등)
  final String? source;

  /// 메모
  final String? memo;

  factory WmsInventoryDraftEntry.fromJson(Map<String, dynamic> json) {
    return WmsInventoryDraftEntry(
      id: (json['id'] ?? '').toString(),
      at: DateTime.tryParse((json['at'] ?? '').toString()) ?? DateTime.now(),
      name: (json['name'] ?? '').toString(),
      currentStock: json['currentStock'] is num
          ? (json['currentStock'] as num).toDouble()
          : double.tryParse((json['currentStock'] ?? '').toString()),
      unit: (json['unit'] as String?)?.trim(),
      category: (json['category'] as String?)?.trim(),
      detailCategory: (json['detailCategory'] as String?)?.trim(),
      location: (json['location'] as String?)?.trim(),
      threshold: json['threshold'] is num
          ? (json['threshold'] as num).toDouble()
          : double.tryParse((json['threshold'] ?? '').toString()),
      bundleSize: json['bundleSize'] is num
          ? (json['bundleSize'] as num).toDouble()
          : double.tryParse((json['bundleSize'] ?? '').toString()),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      source: (json['source'] as String?)?.trim(),
      memo: (json['memo'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'at': at.toIso8601String(),
      'name': name,
      if (currentStock != null) 'currentStock': currentStock,
      if (unit != null) 'unit': unit,
      if (category != null) 'category': category,
      if (detailCategory != null) 'detailCategory': detailCategory,
      if (location != null) 'location': location,
      if (threshold != null) 'threshold': threshold,
      if (bundleSize != null) 'bundleSize': bundleSize,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      if (source != null) 'source': source,
      if (memo != null) 'memo': memo,
    };
  }

  WmsInventoryDraftEntry copyWith({
    DateTime? at,
    String? name,
    double? currentStock,
    String? unit,
    String? category,
    String? detailCategory,
    String? location,
    double? threshold,
    double? bundleSize,
    DateTime? expiryDate,
    String? source,
    String? memo,
  }) {
    return WmsInventoryDraftEntry(
      id: id,
      at: at ?? this.at,
      name: name ?? this.name,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      detailCategory: detailCategory ?? this.detailCategory,
      location: location ?? this.location,
      threshold: threshold ?? this.threshold,
      bundleSize: bundleSize ?? this.bundleSize,
      expiryDate: expiryDate ?? this.expiryDate,
      source: source ?? this.source,
      memo: memo ?? this.memo,
    );
  }

  /// 간단한 재고 입력용 생성자 (최소 필드만)
  factory WmsInventoryDraftEntry.quick({
    required String id,
    required String name,
    String? source,
  }) {
    return WmsInventoryDraftEntry(
      id: id,
      at: DateTime.now(),
      name: name,
      source: source ?? 'manual',
    );
  }

  /// 장바구니 자동등록용 생성자
  factory WmsInventoryDraftEntry.fromShoppingCart({
    required String id,
    required String name,
    double? quantity,
    String? unit,
    String? category,
  }) {
    return WmsInventoryDraftEntry(
      id: id,
      at: DateTime.now(),
      name: name,
      currentStock: quantity,
      unit: unit,
      category: category,
      source: 'shoppingCart',
    );
  }

  @override
  String toString() {
    return 'WmsInventoryDraftEntry('
        'id: $id, '
        'name: $name, '
        'stock: $currentStock, '
        'unit: $unit, '
        'category: $category, '
        'location: $location, '
        'source: $source'
        ')';
  }
}
