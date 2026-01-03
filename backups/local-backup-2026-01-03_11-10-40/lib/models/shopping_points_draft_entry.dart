class ShoppingPointsDraftEntry {
  const ShoppingPointsDraftEntry({
    required this.id,
    required this.at,
    required this.receiptTotal,
    this.store,
    this.card,
    this.memo,
  });

  final String id;

  /// When the shopping happened / draft created.
  final DateTime at;

  /// Receipt / checkout total (구입 총액).
  final double receiptTotal;

  /// Optional store name (구매처).
  final String? store;

  /// Optional card name (사용 카드).
  final String? card;

  /// Optional memo.
  final String? memo;

  factory ShoppingPointsDraftEntry.fromJson(Map<String, dynamic> json) {
    return ShoppingPointsDraftEntry(
      id: (json['id'] ?? '').toString(),
      at: DateTime.tryParse((json['at'] ?? '').toString()) ?? DateTime.now(),
      receiptTotal: (json['receiptTotal'] is num)
          ? (json['receiptTotal'] as num).toDouble()
          : double.tryParse((json['receiptTotal'] ?? '0').toString()) ?? 0.0,
      store: (json['store'] as String?)?.trim(),
      card: (json['card'] as String?)?.trim(),
      memo: (json['memo'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'at': at.toIso8601String(),
      'receiptTotal': receiptTotal,
      'store': store,
      'card': card,
      'memo': memo,
    };
  }

  ShoppingPointsDraftEntry copyWith({
    DateTime? at,
    double? receiptTotal,
    String? store,
    String? card,
    String? memo,
  }) {
    return ShoppingPointsDraftEntry(
      id: id,
      at: at ?? this.at,
      receiptTotal: receiptTotal ?? this.receiptTotal,
      store: store ?? this.store,
      card: card ?? this.card,
      memo: memo ?? this.memo,
    );
  }
}
