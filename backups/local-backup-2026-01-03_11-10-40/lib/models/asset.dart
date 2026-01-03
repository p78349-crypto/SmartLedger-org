enum AssetInputType { simple, detail }

enum AssetCategory {
  stock('주식', '📈', 0xFF4CAF50),
  bond('채권', '📊', 0xFF2196F3),
  realEstate('부동산', '🏠', 0xFFFF9800),
  deposit('예금/적금', '🏦', 0xFF673AB7),
  crypto('암호화폐', '₿', 0xFFFFA726),
  cash('현금', '💵', 0xFF4CAF50),
  other('기타', '📌', 0xFF757575);

  final String label;
  final String emoji;
  final int color;
  const AssetCategory(this.label, this.emoji, this.color);
}

class Asset {
  final String id;
  final String name;
  final double amount;
  final AssetInputType inputType;
  final String memo;
  final DateTime date;
  final AssetCategory category;

  /// Optional expected annual return rate (percentage).
  ///
  /// When set, projection screens may prioritize this value over
  /// global defaults.
  final double? expectedAnnualRatePct;
  final double? targetRatio;
  final double? targetAmount; // 목표액 (투자 자산의 경우)
  final bool isInvestment; // 투자 중인 자산인지 (트레이딩)
  final DateTime? conversionDate; // 자산으로 전환된 날짜
  final double? costBasis; // 원가 (손익 계산용)

  Asset({
    required this.id,
    required this.name,
    required this.amount,
    this.inputType = AssetInputType.simple,
    this.memo = '',
    this.category = AssetCategory.other,
    this.expectedAnnualRatePct,
    this.targetRatio,
    this.targetAmount,
    this.isInvestment = false,
    this.conversionDate,
    this.costBasis, // 원가: 구매 시점의 투입 금액
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Asset copyWith({
    String? name,
    double? amount,
    AssetInputType? inputType,
    String? memo,
    DateTime? date,
    AssetCategory? category,
    double? expectedAnnualRatePct,
    double? targetRatio,
    double? targetAmount,
    bool? isInvestment,
    DateTime? conversionDate,
    double? costBasis,
  }) {
    return Asset(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      inputType: inputType ?? this.inputType,
      memo: memo ?? this.memo,
      date: date ?? this.date,
      category: category ?? this.category,
      expectedAnnualRatePct:
          expectedAnnualRatePct ?? this.expectedAnnualRatePct,
      targetRatio: targetRatio ?? this.targetRatio,
      targetAmount: targetAmount ?? this.targetAmount,
      isInvestment: isInvestment ?? this.isInvestment,
      conversionDate: conversionDate ?? this.conversionDate,
      costBasis: costBasis ?? this.costBasis,
    );
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    final id = (rawId != null && rawId.isNotEmpty)
        ? rawId
        : DateTime.now().microsecondsSinceEpoch.toString();
    final inputTypeStr = json['inputType'] as String?;
    final inputType = inputTypeStr == 'detail'
        ? AssetInputType.detail
        : AssetInputType.simple;
    final dateStr = json['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final categoryStr = json['category'] as String? ?? 'other';
    AssetCategory category;
    try {
      category = AssetCategory.values.firstWhere(
        (e) => e.name == categoryStr,
        orElse: () => AssetCategory.other,
      );
    } catch (e) {
      category = AssetCategory.other;
    }
    return Asset(
      id: id,
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      inputType: inputType,
      memo: json['memo'] as String? ?? '',
      date: date,
      category: category,
      expectedAnnualRatePct: (json['expectedAnnualRatePct'] as num?)
          ?.toDouble(),
      targetRatio: (json['targetRatio'] as num?)?.toDouble(),
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      isInvestment: json['isInvestment'] as bool? ?? false,
      conversionDate: json['conversionDate'] != null
          ? DateTime.tryParse(json['conversionDate'] as String)
          : null,
      costBasis: (json['costBasis'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'inputType': inputType == AssetInputType.detail ? 'detail' : 'simple',
      'memo': memo,
      'date': date.toIso8601String(),
      'category': category.name,
      'expectedAnnualRatePct': expectedAnnualRatePct,
      'targetRatio': targetRatio,
      'targetAmount': targetAmount,
      'isInvestment': isInvestment,
      'conversionDate': conversionDate?.toIso8601String(),
      'costBasis': costBasis,
    };
  }
}
