/// 자산 이동/전환 기록 모델
enum AssetMoveType {
  purchase('구매'), // 현금 → 주식/채권/부동산 등
  sale('판매'), // 주식/채권/부동산 → 현금
  transfer('이동'), // 자산 간 직접 이동
  exchange('교환'), // 자산을 다른 자산으로 교환
  deposit('예금'); // 현금 → 예금/적금

  final String label;
  const AssetMoveType(this.label);
}

class AssetMove {
  final String id;
  final String accountName;
  final String fromAssetId;
  final String? toAssetId; // 기존 자산으로 이동 시
  final String? toCategoryName; // 새 자산 생성 시 카테고리명
  final double amount;
  final AssetMoveType type;
  final String memo;
  final DateTime date;
  final DateTime createdAt;

  AssetMove({
    required this.id,
    required this.accountName,
    required this.fromAssetId,
    this.toAssetId,
    this.toCategoryName,
    required this.amount,
    this.type = AssetMoveType.transfer,
    this.memo = '',
    DateTime? date,
    DateTime? createdAt,
  }) : date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  factory AssetMove.fromJson(Map<String, dynamic> json) {
    return AssetMove(
      id: json['id'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '',
      fromAssetId: json['fromAssetId'] as String? ?? '',
      toAssetId: json['toAssetId'] as String?,
      toCategoryName: json['toCategoryName'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: _parseType(json['type'] as String?),
      memo: json['memo'] as String? ?? '',
      date: _parseDate(json['date']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountName': accountName,
      'fromAssetId': fromAssetId,
      'toAssetId': toAssetId,
      'toCategoryName': toCategoryName,
      'amount': amount,
      'type': type.name,
      'memo': memo,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static AssetMoveType _parseType(String? typeStr) {
    try {
      return AssetMoveType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => AssetMoveType.transfer,
      );
    } catch (e) {
      return AssetMoveType.transfer;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

