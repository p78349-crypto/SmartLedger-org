part of 'account_main_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension IconGridPageBuild on _IconGridPageState {
  Widget _buildGridPage(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      color: scheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 70),
          child: Column(
            children: [
              if (widget.pageIndex == 4 &&
                  widget.accountName.toLowerCase() == 'root')
                _buildCeoDashboardCard(theme, scheme),
              Expanded(child: _buildGrid(scheme)),
              _buildBottomBar(scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCeoDashboardCard(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.primary.withValues(alpha: 0.1),
          ),
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
            child: Icon(
              IconCatalog.insightsOutlined,
              color: scheme.primary,
            ),
          ),
          title: Text(
            'CEO 비서 대시보드',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text('전략 지표 및 복구 계획 보기'),
          trailing: Icon(
            Icons.chevron_right,
            color: scheme.onSurfaceVariant,
          ),
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.ceoAssistant),
        ),
      ),
    );
  }

  Widget _buildGrid(ColorScheme scheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 4;
        const rows =
            (_defaultSlotCount + crossAxisCount - 1) ~/ crossAxisCount;
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
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
              children: List.generate(_defaultSlotCount, (index) {
                return _buildSlotItem(index, scheme);
              }),
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

    if (!_isEditMode && _hideEmptySlots && isEmpty) {
      return SizedBox.expand(key: slotKey);
    }

    final tile = icon != null
        ? _IconTile(
            label: icon.labelFor(context),
            icon: icon.icon,
            isEditMode: _isEditMode,
            pageIndex: widget.pageIndex,
            itemIndex: index,
            liveDataWidget: null,
            onTap: InteractionBlockers.gate(() {
              if (_isEditMode) return;
              _navigateToIcon(icon);
            }),
          )
        : _EmptySlotTile(isEditMode: _isEditMode);

    if (!_isEditMode) return SizedBox(key: slotKey, child: tile);

    return SizedBox(
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
