part of shopping_list_screen;

extension ShoppingListScreenCategoryMap on _ShoppingListScreenState {
  Color _getCategoryColor(PrepCategory category) {
    switch (category) {
      case PrepCategory.safety:
        return Colors.red;
      case PrepCategory.freshFood:
        return Colors.green;
      case PrepCategory.storableFood:
        return Colors.brown;
      case PrepCategory.medicine:
        return Colors.purple;
      case PrepCategory.energy:
        return Colors.orange;
      case PrepCategory.water:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(PrepCategory category) {
    switch (category) {
      case PrepCategory.safety:
        return Icons.security;
      case PrepCategory.freshFood:
        return Icons.restaurant;
      case PrepCategory.storableFood:
        return Icons.inventory_2;
      case PrepCategory.medicine:
        return Icons.medical_services;
      case PrepCategory.energy:
        return Icons.bolt;
      case PrepCategory.water:
        return Icons.water_drop;
    }
  }
}
