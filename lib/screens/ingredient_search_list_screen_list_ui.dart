// ignore_for_file: invalid_use_of_protected_member

part of 'ingredient_search_list_screen.dart';

/// 리스트 UI 빌더 메서드
extension IngredientSearchListUi on _IngredientSearchListScreenState {
  /// 검색 결과 없음 화면
  Scaffold _buildSearchNotFoundView(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '검색 결과',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '"${widget.searchQuery}" 데이터 없음',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 빈 목록 화면
  Scaffold _buildEmptyListView(ThemeData theme, bool isCustomMode) {
    final title =
        isCustomMode ? '식재료 목록' : _mainIngredient!.primaryName;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCustomMode
                  ? '표시할 식재료가 없습니다.'
                  : '$title 요리에 필요한\n재료 정보가 아직 없습니다.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 재료 목록 SliverList 빌더
  SliverList _buildSliverList(
    ThemeData theme,
    List<PairingIngredient> list,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final pairing = list[index];
        final statusColor = _getStatusColor(theme, pairing.status);
        final statusIcon = _getStatusIcon(pairing.status);
        final isSelected = _selectedNames.contains(pairing.name);

        return GestureDetector(
          onTap: _isSelectionMode
              ? () => _toggleItemSelection(pairing.name)
              : null,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: isSelected
                ? statusColor.withValues(alpha: 0.15)
                : statusColor.withValues(alpha: 0.08),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: _isSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (_) =>
                          _toggleItemSelection(pairing.name),
                    )
                  : null,
              title: Text(
                pairing.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      pairing.reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pairing.requiredText} | ${pairing.inventoryText}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pairing.expiryText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: !_isSelectionMode
                  ? IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        if (widget.onSelect != null) {
                          widget.onSelect?.call(pairing.name);
                          Navigator.pop(context, pairing.name);
                        } else {
                          _addSingleToCart(pairing.name);
                        }
                      },
                    )
                  : null,
              onTap: !_isSelectionMode
                  ? () {
                      if (widget.onSelect != null) {
                        widget.onSelect?.call(pairing.name);
                        Navigator.pop(context, pairing.name);
                      } else {
                        _addSingleToCart(pairing.name);
                      }
                    }
                  : null,
            ),
          ),
        );
      }, childCount: list.length),
    );
  }

  /// 재고 상태에 따른 색상 반환
  Color _getStatusColor(ThemeData theme, InventoryStatus status) {
    switch (status) {
      case InventoryStatus.sufficient:
        return Colors.green; // 🟢
      case InventoryStatus.lowStock:
        return Colors.orange; // 🟡
      case InventoryStatus.noStock:
        return Colors.red; // 🔴
    }
  }

  /// 재고 상태에 따른 아이콘 반환
  IconData _getStatusIcon(InventoryStatus status) {
    switch (status) {
      case InventoryStatus.sufficient:
        return Icons.check_circle;
      case InventoryStatus.lowStock:
        return Icons.warning;
      case InventoryStatus.noStock:
        return Icons.cancel;
    }
  }
}
