part of 'shopping_guide_screen.dart';

extension _ShoppingGuideGroups on _ShoppingGuideScreenState {
  Widget _buildLocationGroupList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _sortedLocations.length,
      itemBuilder: (context, index) {
        final location = _sortedLocations[index];
        final items = _groupedItems[location] ?? [];
        final isCurrent = index == _currentLocationIndex;

        return _buildLocationGroup(
          theme: theme,
          location: location,
          items: items,
          isCurrent: isCurrent,
          index: index,
        );
      },
    );
  }

  Widget _buildLocationGroup({
    required ThemeData theme,
    required String location,
    required List<ShoppingCartItem> items,
    required bool isCurrent,
    required int index,
  }) {
    final colors = theme.colorScheme;
    final completedCount = items.where((i) => i.isChecked).length;
    final totalCount = items.length;
    final allCompleted = completedCount == totalCount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isCurrent ? 4 : 1,
      color: isCurrent
          ? colors.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: ExpansionTile(
        initiallyExpanded: isCurrent,
        leading: CircleAvatar(
          backgroundColor: allCompleted
              ? Colors.green.shade600
              : (isCurrent ? colors.primary : Colors.grey.shade400),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                location,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight:
                      isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? colors.primary : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: allCompleted
                    ? Colors.green.shade100
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$completedCount/$totalCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: allCompleted ? Colors.green.shade700 : null,
                ),
              ),
            ),
          ],
        ),
        children: items
            .map((item) => _buildItemTile(theme, item))
            .toList(),
      ),
    );
  }

  Widget _buildItemTile(ThemeData theme, ShoppingCartItem item) {
    final colors = theme.colorScheme;
    final total = item.unitPrice * item.quantity;

    return ListTile(
      dense: true,
      leading: Checkbox(
        value: item.isChecked,
        onChanged: (_) => _toggleItemCheck(item),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.isChecked ? TextDecoration.lineThrough : null,
          color: item.isChecked ? colors.onSurfaceVariant : null,
        ),
      ),
      subtitle: item.quantity > 1
          ? Text(
              '${item.quantity}개 × '
              '${CurrencyFormatter.format(item.unitPrice)}',
            )
          : null,
      trailing: Text(
        CurrencyFormatter.format(total),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: item.isChecked ? colors.onSurfaceVariant : colors.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '장바구니가 비어있습니다',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '상품에 위치를 설정하면\n최적 경로로 안내해드립니다',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildNavigationFAB(ThemeData theme) {
    if (_sortedLocations.isEmpty) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_currentLocationIndex > 0)
          FloatingActionButton.small(
            heroTag: 'prev',
            onPressed: _moveToPreviousLocation,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: const Icon(Icons.arrow_upward),
          ),
        const SizedBox(height: 8),
        if (_currentLocationIndex < _sortedLocations.length - 1)
          FloatingActionButton.extended(
            heroTag: 'next',
            onPressed: _moveToNextLocation,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('다음 위치'),
          ),
      ],
    );
  }
}
