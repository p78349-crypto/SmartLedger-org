import 'package:flutter/material.dart';
import '../utils/global_food_data_utils.dart';

/// 글로벌 식료품 아이템 리스트 뷰
class GlobalFoodItemListView extends StatelessWidget {
  const GlobalFoodItemListView({
    super.key,
    required this.displayItems,
    required this.selectedItems,
    required this.quantities,
    required this.onItemSelected,
    required this.onQuantityChanged,
  });

  final List<GlobalFoodItem> displayItems;
  final Map<String, bool> selectedItems;
  final Map<String, double> quantities;
  final void Function(String itemKey, bool selected) onItemSelected;
  final void Function(String itemKey, double quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    if (displayItems.isEmpty) {
      return const Center(child: Text('항목이 없습니다'));
    }

    return ListView.builder(
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final itemKey = '${item.fdcId}_${item.name}';
        final selected = selectedItems[itemKey] ?? false;
        final quantity = quantities[itemKey] ?? 1.0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) {
                    onItemSelected(itemKey, value ?? false);
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          decoration: selected
                              ? null
                              : TextDecoration.lineThrough,
                          color: selected ? null : Colors.grey,
                        ),
                      ),
                      Text(
                        '${item.type} • ${item.category}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (item.brand != null)
                        Text(
                          item.brand!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected) ...[
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: quantity > 1
                        ? () {
                            onQuantityChanged(itemKey, quantity - 1);
                          }
                        : null,
                  ),
                  Text(
                    '${quantity.toInt()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      onQuantityChanged(itemKey, quantity + 1);
                    },
                  ),
                ],
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 장바구니 하단 추가 버튼
class GlobalFoodCartBottomButton extends StatelessWidget {
  const GlobalFoodCartBottomButton({
    super.key,
    required this.sending,
    required this.selectedCount,
    required this.onPressed,
  });

  final bool sending;
  final int selectedCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: sending || selectedCount == 0 ? null : onPressed,
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.shopping_cart),
            label: Text(
              selectedCount == 0
                  ? '항목을 선택해주세요'
                  : '$selectedCount개 항목 장바구니에 추가',
            ),
          ),
        ),
      ),
    );
  }
}
