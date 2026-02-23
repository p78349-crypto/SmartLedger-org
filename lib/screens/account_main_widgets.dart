part of 'account_main_screen.dart';

class _PageQuickMenuButton extends StatelessWidget {
  final bool isEditMode;
  final VoidCallback onToggleEditMode;
  final VoidCallback? onResetMainPages;
  final ValueChanged<int>? onPageSelected;
  final String accountName;
  final int currentPageIndex;

  const _PageQuickMenuButton({
    required this.isEditMode,
    required this.onToggleEditMode,
    this.onResetMainPages,
    this.onPageSelected,
    required this.accountName,
    required this.currentPageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<_QuickMenuAction>(
      tooltip: '메뉴',
      icon: Icon(
        isEditMode ? Icons.check : Icons.more_vert,
        color: theme.colorScheme.onSurface,
      ),
      onSelected: (action) {
        switch (action) {
          case _QuickMenuAction.toggleEdit:
            onToggleEditMode();
            break;
          case _QuickMenuAction.pageIconManagement:
            _openPageIconManagement(context);
            break;
          case _QuickMenuAction.jumpPage1:
            onPageSelected?.call(0);
            break;
          case _QuickMenuAction.jumpPage2:
            onPageSelected?.call(1);
            break;
          case _QuickMenuAction.jumpPage3:
            onPageSelected?.call(2);
            break;
          case _QuickMenuAction.jumpPage4:
            onPageSelected?.call(3);
            break;
          case _QuickMenuAction.jumpPage5:
            onPageSelected?.call(4);
            break;
          case _QuickMenuAction.jumpPage6:
            onPageSelected?.call(5);
            break;
          case _QuickMenuAction.jumpPage7:
            onPageSelected?.call(6);
            break;
        }
      },
      itemBuilder: (context) {
        return <PopupMenuEntry<_QuickMenuAction>>[
          PopupMenuItem<_QuickMenuAction>(
            value: _QuickMenuAction.toggleEdit,
            child: Row(
              children: [
                Icon(
                  isEditMode ? Icons.check : Icons.edit,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(isEditMode ? '편집 종료' : '편집 모드'),
              ],
            ),
          ),
          PopupMenuItem<_QuickMenuAction>(
            value: _QuickMenuAction.pageIconManagement,
            child: Row(
              children: [
                const Icon(
                  Icons.apps,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text('${_getPageTitle(currentPageIndex)} 아이콘 관리'),
              ],
            ),
          ),
          if (onPageSelected != null) ...<PopupMenuEntry<_QuickMenuAction>>[
            const PopupMenuDivider(),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage1,
              child: Text('Index 0: 대시보드'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage2,
              child: Text('Index 1: 거래'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage3,
              child: Text('Index 2: 수입'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage4,
              child: Text('Index 3: 통계'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage5,
              child: Text('Index 4: 자산'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage6,
              child: Text('Index 5: ROOT'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage7,
              child: Text('Index 6: 설정'),
            ),
          ],
        ];
      },
    );
  }

  void _openPageIconManagement(BuildContext context) {
    final pageTitle = _getPageTitle(currentPageIndex);
    Navigator.of(context).pushNamed(
      AppRoutes.pageIconManagement,
      arguments: PageIconManagementArgs(
        accountName: accountName,
        pageIndex: currentPageIndex,
        pageTitle: pageTitle,
      ),
    );
  }

  String _getPageTitle(int pageIndex) {
    const pageNames = [
      '대시보드',
      '요리/쇼핑/지출',
      '수입',
      '통계',
      '자산',
      'ROOT',
      '설정',
    ];

    if (pageIndex >= 0 && pageIndex < pageNames.length) {
      return pageNames[pageIndex];
    }
    return '페이지 ${pageIndex + 1}';
  }
}

enum _QuickMenuAction {
  toggleEdit,
  pageIconManagement,
  jumpPage1,
  jumpPage2,
  jumpPage3,
  jumpPage4,
  jumpPage5,
  jumpPage6,
  jumpPage7,
}

class _EmptySlotTile extends StatelessWidget {
  final bool isEditMode;
  const _EmptySlotTile({required this.isEditMode});

  @override
  Widget build(BuildContext context) {
    // If pages are blocked, don't show the empty-slot UI.
    if (MainFeatureIconCatalog.pageCount == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isEditMode
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Icon(
                IconCatalog.add,
                color: isEditMode
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEditMode ? '추가' : '',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isEditMode;
  final int pageIndex;
  final int itemIndex;
  final String? badgeText; // 숫자 또는 텍스트 표시용
  final Widget? liveDataWidget;
  final VoidCallback? onTap;

  const _IconTile({
    required this.label,
    required this.icon,
    required this.isEditMode,
    required this.pageIndex,
    required this.itemIndex,
    this.badgeText,
    required this.liveDataWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final live = liveDataWidget;

    final featureColor = AppColors.getFeatureIconColor(pageIndex, itemIndex);

    final bgColor = !isEditMode
        ? scheme.primary.withValues(alpha: 0.12)
        : scheme.primaryContainer;
    final iconColor = !isEditMode ? featureColor : scheme.onPrimaryContainer;
    final labelStyle = theme.textTheme.labelMedium;
    final labelColor = !isEditMode
        ? (labelStyle?.color ?? scheme.onSurface)
        : scheme.onPrimaryContainer;

    return AnimatedRotation(
      turns: isEditMode ? -0.01 : 0,
      duration: const Duration(milliseconds: 140),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (!isEditMode)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: featureColor.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(18),
                      border: isEditMode
                          ? Border.all(color: scheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  if (badgeText != null && badgeText!.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.error,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          badgeText!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    labelStyle?.copyWith(
                      color: labelColor,
                      fontWeight:
                          isEditMode ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                      letterSpacing: -0.4,
                    ) ??
                    TextStyle(
                      color: labelColor,
                      fontWeight:
                          isEditMode ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                      letterSpacing: -0.4,
                    ),
              ),
              if (!isEditMode && live != null) ...[
                const SizedBox(height: 4),
                live,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
