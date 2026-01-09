import 'weather_snapshot.dart';
import '../utils/benefit_memo_utils.dart';

enum TransactionType { expense, income, savings, refund }

enum SavingsAllocation { assetIncrease, expense }

TransactionType _parseTransactionType(String? raw) {
  if (raw == null || raw.isEmpty) {
    return TransactionType.expense;
  }
  final normalized = raw.toLowerCase();
  for (final type in TransactionType.values) {
    if (type.name == normalized) {
      return type;
    }
  }
  if (normalized.contains('income')) {
    return TransactionType.income;
  }
  if (normalized.contains('saving') || normalized.contains('예금')) {
    return TransactionType.savings;
  }
  if (normalized.contains('refund') || normalized.contains('반품')) {
    return TransactionType.refund;
  }
  return TransactionType.expense;
}

SavingsAllocation? _parseSavingsAllocation(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final normalized = raw.toLowerCase();
  switch (normalized) {
    case 'assetincrease':
    case 'asset_increase':
    case 'asset':
    case 'assetincreaseoption':
      return SavingsAllocation.assetIncrease;
    case 'expense':
      return SavingsAllocation.expense;
  }
  return null;
}

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.expense:
        return '지출';
      case TransactionType.income:
        return '수입';
      case TransactionType.savings:
        return '예금';
      case TransactionType.refund:
        return '반품';
    }
  }

  String get longLabel {
    switch (this) {
      case TransactionType.expense:
        return '지출';
      case TransactionType.income:
        return '수입';
      case TransactionType.savings:
        return '예금(저금통)';
      case TransactionType.refund:
        return '반품';
    }
  }

  bool get isInflow =>
      this == TransactionType.income || this == TransactionType.refund;

  bool get isOutflow => !isInflow;

  String get sign {
    switch (this) {
      case TransactionType.expense:
        return '-';
      case TransactionType.income:
        return '+';
      case TransactionType.savings:
        return '-';
      case TransactionType.refund:
        return '+';
    }
  }
}

extension TransactionX on Transaction {
  /// 거래의 부호 (예금의 경우 savingsAllocation에 따라 +/- 결정)
  String get sign {
    if (type == TransactionType.savings) {
      return savingsAllocation == SavingsAllocation.assetIncrease ? '+' : '-';
    }
    return type.sign;
  }
}

extension SavingsAllocationX on SavingsAllocation {
  String get label {
    switch (this) {
      case SavingsAllocation.assetIncrease:
        return '자산 증가';
      case SavingsAllocation.expense:
        return '지출';
    }
  }

  String get helperText {
    switch (this) {
      case SavingsAllocation.assetIncrease:
        return '정해진 날짜에 자동 반영됩니다.';
      case SavingsAllocation.expense:
        return '해당 금액이 지출 통계에 포함됩니다.';
    }
  }

  String get snackBarDetail {
    switch (this) {
      case SavingsAllocation.assetIncrease:
        return '자산 증가로 반영';
      case SavingsAllocation.expense:
        return '지출로 반영';
    }
  }
}

class Transaction {
  final String id;
  final TransactionType type;
  final String description;
  final double amount;
  final double? cardChargedAmount;
  final DateTime date;
  final int quantity;
  final String? unit;
  final double unitPrice;
  final WeatherSnapshot? weather;
  final String paymentMethod; // '현금', '카드'
  final String memo;

  /// Optional store key extracted from memo or other input.
  ///
  /// This is used for stable grouping and stats (store-based classification)
  /// without depending on memo parsing every time.
  final String? store;

  /// Structured benefits JSON (B). Nullable for backward compatibility.
  ///
  /// Format: {"카드":1200,"배송":3000}
  final String? benefitJson;
  final SavingsAllocation? savingsAllocation;
  final bool isRefund; // 반품/환불 여부
  final String? originalTransactionId; // 원본 거래 ID (반품인 경우)
  final String mainCategory;
  final String? subCategory;
  final String? detailCategory;
  final String? location;
  final String? supplier;
  final DateTime? expiryDate;

  static const String defaultMainCategory = '미분류';

  Transaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    this.cardChargedAmount,
    required this.date,
    this.quantity = 1,
    this.unit,
    this.unitPrice = 0,
    this.weather,
    this.paymentMethod = '현금',
    this.memo = '',
    this.store,
    this.benefitJson,
    this.savingsAllocation,
    this.isRefund = false,
    this.originalTransactionId,
    String? mainCategory,
    this.subCategory,
    this.detailCategory,
    this.location,
    this.supplier,
    this.expiryDate,
  }) : mainCategory = (mainCategory == null || mainCategory.trim().isEmpty)
           ? defaultMainCategory
           : mainCategory;

  Map<String, double> get benefitByType =>
      BenefitMemoUtils.decodeBenefitJson(benefitJson);

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final typeValue = (json['type'] as String?) ?? 'expense';
    final parsedType = _parseTransactionType(typeValue);
    final allocationValue = json['savingsAllocation'] as String?;
    final parsedAllocation =
        _parseSavingsAllocation(allocationValue) ??
        (parsedType == TransactionType.savings
            ? SavingsAllocation.assetIncrease
            : null);
    WeatherSnapshot? parsedWeather;
    final rawWeather = json['weather'];
    if (rawWeather is Map) {
      parsedWeather = WeatherSnapshot.fromJson(
        Map<String, dynamic>.from(rawWeather),
      );
      if (parsedWeather.condition.trim().isEmpty) {
        parsedWeather = null;
      }
    }
    return Transaction(
      id: json['id'] as String,
      type: parsedType,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      cardChargedAmount: (json['cardChargedAmount'] as num?)?.toDouble(),
      date: DateTime.parse(json['date'] as String),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      weather: parsedWeather,
      paymentMethod: json['paymentMethod'] as String? ?? '현금',
      memo: json['memo'] as String? ?? '',
      store: _parseStore(json['store']),
      benefitJson: json['benefitJson'] as String?,
      savingsAllocation: parsedAllocation,
      isRefund: json['isRefund'] as bool? ?? false,
      originalTransactionId: json['originalTransactionId'] as String?,
      mainCategory: json['mainCategory'] as String? ?? defaultMainCategory,
      subCategory: json['subCategory'] as String?,
      detailCategory: json['detailCategory'] as String?,
      location: json['location'] as String?,
      supplier: json['supplier'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
    );
  }

  static String? _parseStore(dynamic raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'amount': amount,
      if (cardChargedAmount != null) 'cardChargedAmount': cardChargedAmount,
      'date': date.toIso8601String(),
      'quantity': quantity,
      if (unit != null) 'unit': unit,
      'unitPrice': unitPrice,
      if (weather != null) 'weather': weather!.toJson(),
      'paymentMethod': paymentMethod,
      'memo': memo,
      if (store != null && store!.trim().isNotEmpty) 'store': store!.trim(),
      if (benefitJson != null && benefitJson!.trim().isNotEmpty)
        'benefitJson': benefitJson!.trim(),
      if (savingsAllocation != null)
        'savingsAllocation': savingsAllocation!.name,
      'isRefund': isRefund,
      if (originalTransactionId != null)
        'originalTransactionId': originalTransactionId,
      'mainCategory': mainCategory,
      if (subCategory != null) 'subCategory': subCategory,
      if (detailCategory != null) 'detailCategory': detailCategory,
      if (location != null) 'location': location,
      if (supplier != null) 'supplier': supplier,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    TransactionType? type,
    String? description,
    double? amount,
    double? cardChargedAmount,
    DateTime? date,
    int? quantity,
    double? unitPrice,
    WeatherSnapshot? weather,
    String? paymentMethod,
    String? memo,
    String? store,
    String? benefitJson,
    SavingsAllocation? savingsAllocation,
    bool? isRefund,
    String? originalTransactionId,
    String? mainCategory,
    String? subCategory,
    String? detailCategory,
    String? location,
    String? supplier,
    DateTime? expiryDate,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      cardChargedAmount: cardChargedAmount ?? this.cardChargedAmount,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      weather: weather ?? this.weather,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      memo: memo ?? this.memo,
      store: store ?? this.store,
      benefitJson: benefitJson ?? this.benefitJson,
      savingsAllocation: savingsAllocation ?? this.savingsAllocation,
      isRefund: isRefund ?? this.isRefund,
      originalTransactionId:
          originalTransactionId ?? this.originalTransactionId,
      mainCategory: mainCategory ?? this.mainCategory,
      subCategory: subCategory ?? this.subCategory,
      detailCategory: detailCategory ?? this.detailCategory,
      location: location ?? this.location,
      supplier: supplier ?? this.supplier,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  /// 반품 거래 생성 (지출을 환불받는 경우 마이너스 지출로 기록)
  Transaction createRefund({
    required String refundId,
    required DateTime refundDate,
    double? refundAmount,
    int? refundQuantity,
    String? refundMemo,
  }) {
    final memoText = refundMemo?.trim();
    final qty = (refundQuantity != null && refundQuantity > 0)
        ? refundQuantity
        : quantity;
    final computedAmount = unitPrice > 0
        ? unitPrice * qty
        : (quantity > 0 ? (amount.abs() / quantity) * qty : amount.abs());
    return Transaction(
      id: refundId,
      type: TransactionType.expense, // 환불은 마이너스 지출로 처리
      description: '$description (반품환불)',
      amount: -(refundAmount ?? computedAmount), // 음수로 저장
      date: refundDate,
      quantity: qty,
      unitPrice: unitPrice,
      weather: weather,
      paymentMethod: paymentMethod,
      memo: (memoText != null && memoText.isNotEmpty)
          ? memoText
          : (memo.isEmpty ? '반품환불' : '$memo (반품환불)'),
      isRefund: true,
      store: store,
      originalTransactionId: id,
      mainCategory: mainCategory,
      subCategory: subCategory,
    );
  }
}
