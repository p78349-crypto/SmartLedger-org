// ignore_for_file: invalid_use_of_protected_member

part of 'icon_management_screen.dart';

/// Placed-icons horizontal list section.
extension IconManagementPlaced on _IconManagementScreenState {
  Widget _buildPlacedIconsSection(
    ThemeData theme,
    ColorScheme scheme,
    List<(int index, String id)> placedSlots,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '현재 배치 (${placedSlots.length}개)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: placedSlots.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final iconId = placedSlots[index].$2;
              return _buildPlacedIconDragItem(theme, scheme, iconId);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPlacedIconDragItem(
    ThemeData theme,
    ColorScheme scheme,
    String iconId,
  ) {
    final icon = _iconById[iconId];
    return SizedBox(
      width: 80,
      child: LongPressDraggable<String>(
        data: iconId,
        feedback: Opacity(
          opacity: 0.9,
          child: SizedBox(
            width: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: scheme.primaryContainer,
                    border: Border.all(color: scheme.primary),
                  ),
                  child: Center(
                    child: Icon(
                      icon?.icon ?? Icons.help,
                      size: 28,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  icon?.label ?? iconId,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: scheme.primaryContainer,
                  border: Border.all(color: scheme.primary),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: scheme.primaryContainer,
                border: Border.all(color: scheme.primary),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      icon?.icon ?? Icons.help,
                      size: 28,
                      color: scheme.primary,
                    ),
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              icon?.label ?? iconId,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
