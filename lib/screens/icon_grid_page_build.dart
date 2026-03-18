part of 'account_main_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension IconGridPageBuild on _IconGridPageState {
  int _slotIndexForDisplayPosition({
    required int displayIndex,
    required int crossAxisCount,
    required int totalSlots,
  }) {
    final rows = (totalSlots + crossAxisCount - 1) ~/ crossAxisCount;
    if (rows <= 1) return displayIndex;

    final displayRow = displayIndex ~/ crossAxisCount;
    final column = displayIndex % crossAxisCount;
    final mappedRow = _mappedRowForThumbReach(displayRow, rows);
    return (mappedRow * crossAxisCount) + column;
  }

  int _mappedRowForThumbReach(int displayRow, int rows) {
    if (rows <= 1) return 0;

    final orderedRows = <int>[];
    final secondFromBottom = rows - 2;

    for (int row = secondFromBottom; row >= 0; row--) {
      orderedRows.add(row);
    }
    orderedRows.add(rows - 1);

    if (displayRow < 0 || displayRow >= orderedRows.length) {
      return displayRow;
    }
    return orderedRows[displayRow];
  }

  Widget _buildGridPage(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final content = Container(
      color: scheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 70),
          child: Column(
            children: [
              if (widget.pageIndex == 5 &&
                  widget.accountName.toLowerCase() == 'root')
                _buildCeoDashboardCard(theme, scheme),
              Expanded(child: _buildGrid(scheme)),
              _buildBottomBar(scheme),
            ],
          ),
        ),
      ),
    );

    // ROOT 페이지(인덱스 5)는 별도의 RootAuthGate로 보호
    if (widget.pageIndex == 5) {
      return RootAuthGate(child: content);
    }

    return content;
  }

  Widget _buildCeoDashboardCard(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(IconCatalog.insightsOutlined, color: scheme.primary),
          ),
          title: Text(
            'CEO 비서 대시보드',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text('전략 지표 및 복구 계획 보기'),
          trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.ceoAssistant),
        ),
      ),
    );
  }

  Widget _buildGrid(ColorScheme scheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 4;
        const rows = (_defaultSlotCount + crossAxisCount - 1) ~/ crossAxisCount;
        const mainAxisSpacing = 12.0;
        const horizontalPadding = 16.0 * 2;
        const verticalPadding = 16.0 * 2;
        const totalVerticalSpacing = mainAxisSpacing * (rows - 1);
        final usableWidth =
            constraints.maxWidth -
            horizontalPadding -
            (12.0 * (crossAxisCount - 1));
        final itemWidth = usableWidth / crossAxisCount;
        const childAspectRatio = 0.75;
        final itemHeight = itemWidth / childAspectRatio;
        final gridHeight =
            (rows * itemHeight) + totalVerticalSpacing + verticalPadding;

        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: gridHeight,
            width: double.infinity,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(rows, (displayRow) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: displayRow == rows - 1 ? 0 : mainAxisSpacing,
                      ),
                      child: SizedBox(
                        height: itemHeight,
                        child: Row(
                          children: List.generate(crossAxisCount, (column) {
                            final displayIndex =
                                (displayRow * crossAxisCount) + column;
                            final slotIndex = _slotIndexForDisplayPosition(
                              displayIndex: displayIndex,
                              crossAxisCount: crossAxisCount,
                              totalSlots: _defaultSlotCount,
                            );
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: column == crossAxisCount - 1 ? 0 : 12,
                                ),
                                child: _buildSlotItem(slotIndex, scheme),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotItem(int index, ColorScheme scheme) {
    final slotKey = ValueKey<String>(
      'main_icon_slot_${widget.pageIndex}_$index',
    );
    final id = _slots[index];
    final isEmpty = id.isEmpty;
    final icon = isEmpty ? null : _iconById(id);

    if (!_isEditMode && _hideEmptySlots && (isEmpty || icon == null)) {
      return KeyedSubtree(key: slotKey, child: const SizedBox.expand());
    }

    final tile = icon != null
        ? _IconTile(
            label: icon.labelFor(context),
            icon: icon.icon,
            isEditMode: _isEditMode,
            pageIndex: widget.pageIndex,
            itemIndex: index,
            badgeText: _getBadgeText(id),
            liveDataWidget: null,
            onTap: InteractionBlockers.gate(() {
              if (_isEditMode) return;
              _navigateToIcon(icon);
            }),
          )
        : _EmptySlotTile(isEditMode: _isEditMode);

    if (!_isEditMode) {
      return SizedBox(
        child: KeyedSubtree(key: slotKey, child: tile),
      );
    }

    return SizedBox(
      child: KeyedSubtree(
        key: slotKey,
        child: LongPressDraggable<String>(
          data: id,
          feedback: Opacity(
            opacity: 0.9,
            child: SizedBox(width: 80, child: tile),
          ),
          childWhenDragging: Opacity(
            opacity: id.isEmpty ? 1.0 : 0.3,
            child: tile,
          ),
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              final draggedId = details.data;
              if (draggedId.isEmpty) return;
              _assignOrSwap(draggedId, index);
            },
            builder: (context, candidateData, rejectedData) {
              final highlight = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                transform: Matrix4.diagonal3Values(
                  highlight ? 1.03 : 1.0,
                  highlight ? 1.03 : 1.0,
                  1.0,
                ),
                child: tile,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PageIndicator(
            pageCount: widget.pageCount,
            currentPage: widget.currentPage,
            onPageTap: (index) {
              widget.pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          _PageQuickMenuButton(
            isEditMode: _isEditMode,
            onToggleEditMode: _toggleEditMode,
            onResetMainPages: widget.onRequestResetMainPages,
            accountName: widget.accountName,
            currentPageIndex: widget.pageIndex,
            onPageSelected: (pageIndex) {
              if (pageIndex < 0 || pageIndex >= widget.pageCount) return;
              widget.pageController.animateToPage(
                pageIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
        ],
      ),
    );
  }
}
