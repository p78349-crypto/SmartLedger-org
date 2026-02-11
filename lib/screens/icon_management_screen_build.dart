// ignore_for_file: invalid_use_of_protected_member

part of 'icon_management_screen.dart';

/// Catalog icon tile, apply button, and main build.
extension IconManagementBuild on _IconManagementScreenState {
  Widget _buildCatalogIconTile(ThemeData theme, MainFeatureIcon icon) {
    final scheme = theme.colorScheme;
    final isSelected = _pendingIds.contains(icon.id);
    final blocked = _isBlockedForCurrentPage(icon.id);
    final isAllowed = !blocked;
    final isPlaced = _isPlacedOnPage(icon.id);

    final bgColor = isSelected
        ? scheme.primaryContainer
        : (isPlaced ? scheme.tertiaryContainer : scheme.surface);
    final borderColor = isSelected
        ? scheme.primary
        : (isPlaced ? scheme.tertiary : scheme.outlineVariant);

    return Opacity(
      opacity: isAllowed ? 1.0 : 0.45,
      child: InkWell(
        key: ValueKey<String>('icon_mgmt_catalog_${icon.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onCatalogTileTap(icon, blocked, isSelected),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            color: bgColor,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon.icon, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      _effectiveLabelFor(icon.id),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: isSelected ? scheme.primary : scheme.outline,
                ),
              ),
              if (isPlaced)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.tertiary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '배치',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onTertiary,
                      ),
                    ),
                  ),
                ),
              if (!isAllowed)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      '하단불가',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCatalogTileTap(
    MainFeatureIcon icon,
    bool blocked,
    bool isSelected,
  ) {
    if (blocked) {
      final msg = _settingsIconIds.contains(icon.id)
          ? '설정 아이콘은 Index 6에서만 노출할 수 있습니다'
          : (_rootIconIds.contains(icon.id)
              ? 'ROOT 아이콘은 Index 5에서만 노출할 수 있습니다'
              : (_isStatsReservedPage(_pageIndex)
                  ? 'Index 3은 통계 아이콘 전용입니다'
                  : (_isAssetReservedPage(_pageIndex)
                      ? 'Index 4는 자산 아이콘 전용입니다'
                      : '현재 페이지 정책상 배치할 수 없습니다')));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    setState(() {
      if (isSelected) {
        _pendingIds.remove(icon.id);
      } else {
        _pendingIds.add(icon.id);
      }
    });
  }

  Widget _buildApplyEnterKeyButton(ThemeData theme) {
    final scheme = theme.colorScheme;
    final isEnabled = _pendingIds.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: ElevatedButton(
          onPressed: isEnabled ? _applyPending : null,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            backgroundColor: WidgetStatePropertyAll(scheme.primary),
            foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
          ),
          child: const Text(
            'ENT',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMain(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.titleOverride ?? '아이콘 관리';
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.showCurrentPageIndicator
                    ? 'Index $_pageIndex · 선택: ${_pendingIds.length}'
                    : '선택: ${_pendingIds.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Tooltip(
            message: '적용',
            child: _buildApplyEnterKeyButton(theme),
          ),
          if (widget.showClearSelectionAction)
            IconButton(
              tooltip: '선택해제',
              onPressed: _pendingIds.isEmpty ? null : _clearSelection,
              icon: const Icon(Icons.clear),
            ),
          if (!widget.showClearSelectionAction &&
              widget.reserveClearSelectionActionSpace)
            const SizedBox(width: 48),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '2) 현재 배치',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildCurrentSlots(theme),
                const SizedBox(height: 12),
                const Text(
                  '3) 아이콘 선택',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '여러 개 선택 후 상단(ENT)를 누르면 적용됩니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '배치됨: 현재 페이지에 배치됨 · 체크: 선택됨',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildIconCatalogPicker(theme),
              ],
            ),
    );
  }
}
