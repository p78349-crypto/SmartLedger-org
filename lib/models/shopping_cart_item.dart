class ShoppingCartItem {
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;

  /// Optional note per item.
  /// Used to highlight items needing attention.
  final String memo;

  /// True when user pre-wrote the item before going shopping.
  /// Displayed as a leading dot (●).
  final bool isPlanned;

  /// Toggle with the left checkbox.
  /// Used for: in-cart / selected-to-buy / returned-before-payment (unchecked).
  final bool isChecked;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingCartItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.unitPrice = 0,
    this.memo = '',
    this.isPlanned = true,
    this.isChecked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  ShoppingCartItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? unitPrice,
    String? memo,
    bool? isPlanned,
    bool? isChecked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingCartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      memo: memo ?? this.memo,
      isPlanned: isPlanned ?? this.isPlanned,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ShoppingCartItem.fromJson(Map<String, dynamic> json) {
    return ShoppingCartItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      memo: (json['memo'] as String?) ?? '',
      isPlanned: (json['isPlanned'] as bool?) ?? true,
      isChecked: (json['isChecked'] as bool?) ?? false,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'memo': memo,
      'isPlanned': isPlanned,
      'isChecked': isChecked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

