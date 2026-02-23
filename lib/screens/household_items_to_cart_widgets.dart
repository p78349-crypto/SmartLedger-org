import 'package:flutter/material.dart';

/// 생활용품 아이템 타일
class HouseholdItemTile extends StatelessWidget {
  const HouseholdItemTile({
    super.key,
    required this.name,
    required this.selected,
    required this.quantity,
    required this.onSelectedChanged,
    required this.onQuantityChanged,
  });

  final String name;
  final bool selected;
  final double quantity;
  final ValueChanged<bool?> onSelectedChanged;
  final ValueChanged<double> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: onSelectedChanged,
            ),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  decoration: selected ? null : TextDecoration.lineThrough,
                  color: selected ? null : Colors.grey,
                ),
              ),
            ),
            if (selected) ...[
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: quantity > 1
                    ? () => onQuantityChanged(quantity - 1)
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
                onPressed: () => onQuantityChanged(quantity + 1),
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// 장바구니 추가 버튼
class HouseholdCartBottomButton extends StatelessWidget {
  const HouseholdCartBottomButton({
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

/// 카테고리 선택 드롭다운
class HouseholdCategorySelectors extends StatelessWidget {
  const HouseholdCategorySelectors({
    super.key,
    required this.categories1,
    required this.categories2,
    required this.selectedCategory1,
    required this.selectedCategory2,
    required this.onCategory1Changed,
    required this.onCategory2Changed,
  });

  final List<String> categories1;
  final List<String> categories2;
  final String? selectedCategory1;
  final String? selectedCategory2;
  final ValueChanged<String?> onCategory1Changed;
  final ValueChanged<String?> onCategory2Changed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (categories1.isNotEmpty)
            _buildDropdown(
              '대분류',
              selectedCategory1,
              categories1,
              onCategory1Changed,
            ),
          if (categories2.isNotEmpty) const SizedBox(height: 8),
          if (categories2.isNotEmpty)
            _buildDropdown(
              '중분류',
              selectedCategory2,
              categories2,
              onCategory2Changed,
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? currentValue,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// 검색 바
class HouseholdSearchBar extends StatelessWidget {
  const HouseholdSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: '상품 검색',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onSearch,
      ),
    );
  }
}
