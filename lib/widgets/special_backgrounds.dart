import 'package:flutter/material.dart';

class MidnightGoldBackground extends StatelessWidget {
  final Color baseColor;
  const MidnightGoldBackground({super.key, required this.baseColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Stack(
      children: [
        // Base dark color
        Positioned.fill(child: ColoredBox(color: baseColor)),

        // Top accent glow (using theme primary color)
        Positioned(
          top: -150,
          left: -100,
          right: -100,
          height: 500,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.0,
                colors: [
                  primaryColor.withValues(alpha: 0.2),
                  primaryColor.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom subtle glow
        Positioned(
          bottom: -100,
          left: 50,
          right: 50,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 1.0,
                colors: [
                  primaryColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StarlightNavyBackground extends StatelessWidget {
  final Color baseColor;
  const StarlightNavyBackground({super.key, required this.baseColor});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: ColoredBox(color: baseColor));
  }
}
