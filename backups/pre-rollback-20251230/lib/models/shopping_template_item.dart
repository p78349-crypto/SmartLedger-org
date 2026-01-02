class ShoppingTemplateItem {
  final String name;
  final int quantity;
  final double unitPrice;

  const ShoppingTemplateItem({
    required this.name,
    this.quantity = 1,
    this.unitPrice = 0.0,
  });

  factory ShoppingTemplateItem.fromJson(Map<String, dynamic> json) {
    return ShoppingTemplateItem(
      name: (json['name'] as String? ?? '').trim(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'quantity': quantity, 'unitPrice': unitPrice};
  }
}

