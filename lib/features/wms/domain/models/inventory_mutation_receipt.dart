/// Receipt for inventory mutation operations
library;

/// Represents a receipt for inventory stock changes
///
/// This is returned when stock quantity changes (increase or decrease).
/// The delta field represents the change amount (negative for decrease).
class InventoryMutationReceipt {
  /// The item ID that was modified
  final String itemId;

  /// The change in stock quantity (negative for decrease, positive for increase)
  final double delta;

  /// When the mutation occurred
  final DateTime occurredAt;

  /// Optional note about the mutation
  final String? note;

  const InventoryMutationReceipt({
    required this.itemId,
    required this.delta,
    required this.occurredAt,
    this.note,
  });

  /// Copy with method for creating modified copies
  InventoryMutationReceipt copyWith({
    String? itemId,
    double? delta,
    DateTime? occurredAt,
    String? note,
  }) {
    return InventoryMutationReceipt(
      itemId: itemId ?? this.itemId,
      delta: delta ?? this.delta,
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryMutationReceipt &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId &&
          delta == other.delta &&
          occurredAt == other.occurredAt &&
          note == other.note;

  @override
  int get hashCode => Object.hash(itemId, delta, occurredAt, note);

  @override
  String toString() =>
      'InventoryMutationReceipt(itemId: $itemId, delta: $delta, occurredAt: $occurredAt)';
}
