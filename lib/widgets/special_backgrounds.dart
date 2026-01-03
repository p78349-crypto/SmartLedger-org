import 'dart:math';
import 'package:flutter/material.dart';

class MidnightGoldBackground extends StatelessWidget {
  final Color baseColor;
  const MidnightGoldBackground({super.key, required this.baseColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark color
        Positioned.fill(child: ColoredBox(color: baseColor)),
        
        // Top golden glow
        Positioned(
          top: -100,
          left: -50,
          right: -50,
          height: 400,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [
                  const Color(0xFFFFB300).withValues(alpha: 0.15),
                  const Color(0xFFFFB300).withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Stars
        Positioned.fill(
          child: CustomPaint(
            painter: StarPainter(),
          ),
        ),
      ],
    );
  }
}

class StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    final random = Random(42); // Fixed seed for consistent stars
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.2;
      
      // Some stars are brighter
      if (random.nextDouble() > 0.9) {
        paint.color = Colors.white.withValues(alpha: 0.7);
      } else {
        paint.color = Colors.white.withValues(alpha: 0.3);
      }
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
