// 실방문 가격 입력 모델
//
// 영수증 스캔, 전단지 OCR, 음성 입력 등 사용자 참여 데이터를
// 구조화해 가격 보정 엔진이 재사용할 수 있도록 정의합니다.

import 'package:uuid/uuid.dart';

/// 가격 데이터 출처 우선순위
/// [userReceipt] > [crowdContribution] > [officialBaseline]
enum VisitPriceSource {
  userReceipt,
  crowdContribution,
  officialBaseline,
}

/// 할인 맥락 정보 (1+1, 반값, 마감 세일 등)
class DiscountContext {
  final DiscountType type;
  final double multiplier; // 0~1, 적용 후 가격 비율
  final String label;
  final DateTime? expiresAt;

  const DiscountContext({
    required this.type,
    required this.multiplier,
    required this.label,
    this.expiresAt,
  });

  factory DiscountContext.none() => const DiscountContext(
        type: DiscountType.none,
        multiplier: 1.0,
        label: '정상가',
      );

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// 할인 유형
enum DiscountType {
  none,
  onePlusOne,
  clearance,
  timeSale,
  coupon,
  custom,
}

/// 실방문 가격 엔트리 (단가 기준)
class VisitPriceEntry {
  final String id;
  final String skuId;
  final String storeId;
  final String regionCode;
  final double unitPrice;
  final String currency;
  final int quantity;
  final VisitPriceSource source;
  final DiscountContext discount;
  final String? note;
  final String? evidenceUri; // 영수증/전단 사진/음성 텍스트 저장 위치
  final DateTime capturedAt;

  const VisitPriceEntry({
    required this.id,
    required this.skuId,
    required this.storeId,
    required this.regionCode,
    required this.unitPrice,
    required this.currency,
    required this.quantity,
    required this.source,
    required this.discount,
    this.note,
    this.evidenceUri,
    required this.capturedAt,
  });

  factory VisitPriceEntry.create({
    required String skuId,
    required String storeId,
    required String regionCode,
    required double unitPrice,
    required String currency,
    int quantity = 1,
    VisitPriceSource source = VisitPriceSource.userReceipt,
    DiscountContext discount = const DiscountContext(
      type: DiscountType.none,
      multiplier: 1.0,
      label: '정상가',
    ),
    String? note,
    String? evidenceUri,
    DateTime? capturedAt,
  }) {
    return VisitPriceEntry(
      id: const Uuid().v4(),
      skuId: skuId,
      storeId: storeId,
      regionCode: regionCode,
      unitPrice: unitPrice,
      currency: currency,
      quantity: quantity,
      source: source,
      discount: discount,
      note: note,
      evidenceUri: evidenceUri,
      capturedAt: capturedAt ?? DateTime.now(),
    );
  }

  /// 할인 적용 후 실질 단가
  double get effectiveUnitPrice => unitPrice * discount.multiplier;

  /// 데이터 최신성 비교
  bool isNewerThan(VisitPriceEntry other) => capturedAt.isAfter(other.capturedAt);

  VisitPriceEntry copyWith({
    double? unitPrice,
    int? quantity,
    VisitPriceSource? source,
    DiscountContext? discount,
    String? note,
    String? evidenceUri,
    DateTime? capturedAt,
  }) {
    return VisitPriceEntry(
      id: id,
      skuId: skuId,
      storeId: storeId,
      regionCode: regionCode,
      unitPrice: unitPrice ?? this.unitPrice,
      currency: currency,
      quantity: quantity ?? this.quantity,
      source: source ?? this.source,
      discount: discount ?? this.discount,
      note: note ?? this.note,
      evidenceUri: evidenceUri ?? this.evidenceUri,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}
