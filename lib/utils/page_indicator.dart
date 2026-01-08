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
    this.dotSize = 8.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Display as page number (e.g., "1", "2", "3", ... "pageCount")
    return GestureDetector(
      onTap: onPageTap != null ? () => onPageTap!(currentPage) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          '${currentPage + 1}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}
