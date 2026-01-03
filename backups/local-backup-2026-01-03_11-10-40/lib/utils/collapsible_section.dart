import 'package:flutter/material.dart';

/// 접기/펼치기 가능한 섹션 헤더 위젯
///
/// 사용 예시:
/// ```dart
/// bool _isExpanded = true;
///
/// CollapsibleSectionHeader(
///   title: '계획 정보',
///   subtitle: '터치하여 숨기기/보기',
///   isExpanded: _isExpanded,
///   onToggle: () => setState(() => _isExpanded = !_isExpanded),
/// ),
/// if (_isExpanded) ...[
///   // 여기에 필드들 배치
/// ],
/// ```
class CollapsibleSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isExpanded;
  final VoidCallback onToggle;
  final TextStyle? textStyle;
  final TextStyle? subtitleStyle;
  final Color? iconColor;
  final double iconSize;

  const CollapsibleSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.isExpanded,
    required this.onToggle,
    this.textStyle,
    this.subtitleStyle,
    this.iconColor,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    );
    final defaultIconColor = theme.colorScheme.primary;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textStyle ?? defaultTextStyle),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style:
                          subtitleStyle ??
                          theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
              size: iconSize,
              color: iconColor ?? defaultIconColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// 접기/펼치기 가능한 섹션 (헤더 + 내용 통합)
///
/// 사용 예시:
/// ```dart
/// CollapsibleSection(
///   title: '계획 정보',
///   subtitle: '터치하여 숨기기/보기',
///   initiallyExpanded: true,
///   children: [
///     TextFormField(...),
///     SizedBox(height: 12),
///     TextFormField(...),
///   ],
/// )
/// ```
class CollapsibleSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsets? padding;

  const CollapsibleSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.initiallyExpanded = true,
    this.titleStyle,
    this.subtitleStyle,
    this.iconColor,
    this.iconSize = 16,
    this.padding,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CollapsibleSectionHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            isExpanded: _isExpanded,
            onToggle: () => setState(() => _isExpanded = !_isExpanded),
            textStyle: widget.titleStyle,
            subtitleStyle: widget.subtitleStyle,
            iconColor: widget.iconColor,
            iconSize: widget.iconSize,
          ),
          const SizedBox(height: 12),
          if (_isExpanded) ...widget.children,
        ],
      ),
    );
  }
}
