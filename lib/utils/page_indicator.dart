import 'package:flutter/material.dart';

/// Page indicator widget (dots showing current page position)
class PageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final ValueChanged<int>? onPageTap;
  final Color? activeColor;
  final Color? inactiveColor;
  final double dotSize;
  final double spacing;

  const PageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.onPageTap,
    this.activeColor,
    this.inactiveColor,
    this.dotSize = 5.0,
    this.spacing = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveActiveColor = activeColor ?? scheme.primary;
    final effectiveInactiveColor =
        inactiveColor ?? scheme.onSurfaceVariant.withValues(alpha: 0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return GestureDetector(
          onTap: onPageTap != null ? () => onPageTap!(index) : null,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isActive ? dotSize * 2.5 : dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: isActive ? effectiveActiveColor : effectiveInactiveColor,
                borderRadius: BorderRadius.circular(dotSize / 2),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: effectiveActiveColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ] : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
