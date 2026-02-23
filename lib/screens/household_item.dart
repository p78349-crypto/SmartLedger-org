import 'package:flutter/material.dart';

/// 생활용품 항목 데이터 모델
class HouseholdItem {
  HouseholdItem({
    required this.id,
    required this.name,
    this.unit = '',
    this.quantity = 1,
  });

  factory HouseholdItem.fromJson(Map<String, dynamic> j) => HouseholdItem(
    id: j['id'] as String,
    name: j['name'] as String,
    unit: (j['unit'] ?? '') as String,
    quantity: ((j['quantity'] ?? 1) as num).toDouble(),
  );

  final String id;
  String name;
  String unit;
  double quantity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'quantity': quantity,
  };
}

/// 생활용품 항목 카드 위젯
class HouseholdItemCard extends StatelessWidget {
  const HouseholdItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onSelectedChanged,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  final HouseholdItem item;
  final bool isSelected;
  final ValueChanged<bool?> onSelectedChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Checkbox(value: isSelected, onChanged: onSelectedChanged),
        title: Text(item.name),
        subtitle: Text(item.unit),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: onDecrement,
              ),
              Text(item.quantity.toInt().toString()),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: onIncrement,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
