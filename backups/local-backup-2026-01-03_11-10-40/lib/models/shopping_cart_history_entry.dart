enum ShoppingCartHistoryAction { returnedBeforePayment, addToLedger }

class ShoppingCartHistoryEntry {
  final String id;
  final ShoppingCartHistoryAction action;
  final String itemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final bool isPlanned;
  final DateTime at;

  const ShoppingCartHistoryEntry({
    required this.id,
    required this.action,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.isPlanned,
    required this.at,
  });

  factory ShoppingCartHistoryEntry.fromJson(Map<String, dynamic> json) {
    final actionRaw = (json['action'] as String?) ?? '';
    final action = ShoppingCartHistoryAction.values.firstWhere(
      (a) => a.name == actionRaw,
      orElse: () => ShoppingCartHistoryAction.addToLedger,
    );

    return ShoppingCartHistoryEntry(
      id: (json['id'] as String?) ?? '',
      action: action,
      itemId: (json['itemId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      isPlanned: (json['isPlanned'] as bool?) ?? true,
      at: DateTime.tryParse((json['at'] as String?) ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action.name,
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'isPlanned': isPlanned,
      'at': at.toIso8601String(),
    };
  }
}
