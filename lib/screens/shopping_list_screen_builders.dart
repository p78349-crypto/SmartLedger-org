// ignore_for_file: invalid_use_of_protected_member
part of shopping_list_screen;

extension ShoppingListScreenBuilders on _ShoppingListScreenState {
  Widget _buildUrgentBanner(WeatherForecast forecast) {
    final urgency = forecast.urgency;
    if (urgency < 3) return const SizedBox.shrink();

    final color = urgency >= 4 ? Colors.red : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.warning, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shoppingList.urgentMessage,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  forecast.preparationTiming,
                  style: TextStyle(fontSize: 13, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final result = widget.shoppingList;
    final checkedCount = _checkedItems.length;
    final totalCount = result.items.length;
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '진행률: $checkedCount/$totalCount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: progress == 1.0 ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '예상 비용',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    Text(
                      '${ShoppingListGenerator.formatPrice(result.totalCost)}원',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (result.potentialSavings > 0) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '예상 절약',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        '${ShoppingListGenerator.formatPrice(
                          result.potentialSavings,
                        )}원',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingItem(ShoppingListItem item, int index) {
    final isChecked = _checkedItems.contains(index);
    final categoryColor = _getCategoryColor(item.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _checkedItems.add(index);
            } else {
              _checkedItems.remove(index);
            }
          });
        },
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getCategoryIcon(item.category),
                color: categoryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: isChecked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (item.isUrgent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '긴급',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.quantity}${item.unit}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration:
                          isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ShoppingListGenerator.formatPrice(item.totalCost)}원',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 44, top: 4),
          child: Text(
            item.reason,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final checkedCount = _checkedItems.length;
    final totalCount = widget.shoppingList.items.length;

    if (checkedCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$checkedCount개 선택됨',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: checkedCount == totalCount
                  ? _completeAllShopping
                  : null,
              icon: const Icon(Icons.check),
              label: const Text('장보기 완료'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
