// ignore_for_file: invalid_use_of_protected_member

part of 'icon_management_screen.dart';

/// Drop-zone grid and [_buildCurrentSlots] composer.
extension IconManagementDropzone on _IconManagementScreenState {
  Widget _buildCurrentSlots(ThemeData theme) {
    final scheme = theme.colorScheme;
    final placedSlots = <(int index, String id)>[];
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i].trim().isNotEmpty) placedSlots.add((i, _slots[i]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (placedSlots.isNotEmpty)
          _buildPlacedIconsSection(theme, scheme, placedSlots),
        _buildDropZoneSection(theme, scheme),
      ],
    );
  }

  Widget _buildDropZoneSection(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '빈 슬롯 (드롭존 4개)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: _fillCurrentPageSlotsFull,
              child: const Text('FULL'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final dropSlots = _dropZoneSlotIndices();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: 4,
              itemBuilder: (context, index) =>
                  _buildDropZoneTile(theme, scheme, index, dropSlots),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDropZoneTile(
    ThemeData theme,
    ColorScheme scheme,
    int index,
    List<int> dropSlots,
  ) {
    final slotIndex = index < dropSlots.length ? dropSlots[index] : -1;
    final isValidSlot = slotIndex >= 0 && slotIndex < _slots.length;
    final slotId = isValidSlot ? _slots[slotIndex] : '';
    final isEmpty = slotId.trim().isEmpty;
    final icon =
        (!isEmpty && isValidSlot) ? _iconById[slotId] : null;

    Widget tileContent;
    if (isEmpty) {
      tileContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 24, color: scheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            '추가',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    } else {
      tileContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon?.icon ?? Icons.help,
            size: 24,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            icon?.label ?? slotId,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    Widget baseTile({required bool highlight}) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.diagonal3Values(
          highlight ? 1.05 : 1.0,
          highlight ? 1.05 : 1.0,
          1.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? scheme.primary : scheme.outlineVariant,
            width: highlight ? 2 : 1,
          ),
          color: highlight
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
        ),
        child: Center(child: tileContent),
      );
    }

    DragTarget<String> target() {
      return DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          final draggedId = details.data;
          if (draggedId.trim().isEmpty) return false;
          if (_isBlockedForCurrentPage(draggedId)) return false;
          return true;
        },
        onAcceptWithDetails: (details) {
          _handleDropAccept(details.data, slotIndex, isValidSlot);
        },
        builder: (context, candidateData, rejectedData) {
          return baseTile(highlight: candidateData.isNotEmpty);
        },
      );
    }

    if (isEmpty || !isValidSlot) return target();

    return LongPressDraggable<String>(
      data: slotId,
      feedback: Opacity(
        opacity: 0.9,
        child: SizedBox(width: 80, child: baseTile(highlight: true)),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: baseTile(highlight: false),
      ),
      child: target(),
    );
  }

  void _handleDropAccept(String draggedId, int slotIndex, bool isValid) {
    if (_isBlockedForCurrentPage(draggedId)) {
      final msg = _settingsIconIds.contains(draggedId)
          ? '설정 아이콘은 Index 6에서만 노출할 수 있습니다'
          : (_rootIconIds.contains(draggedId)
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
    if (!isValid) return;
    if (draggedId.trim().isEmpty) return;

    if (!_isEditableSlotIndex(slotIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 슬롯에는 배치할 수 없습니다')),
      );
      return;
    }

    setState(() {
      _assignOrSwap(draggedId, slotIndex);
      _slots = _normalizeSlotsForCurrentPage(_slots);
    });
    _saveSlotsDebounced();
  }
}
