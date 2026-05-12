import 'dart:math';
import 'package:flutter/material.dart';

class HandDrawnBackground extends StatelessWidget {
  const HandDrawnBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        size: Size.infinite,
        painter: _WarmLinesPainter(),
      ),
    );
  }
}

class _WarmLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final startX = size.width * (0.05 + rng.nextDouble() * 0.9);
      final startY = size.height * (0.05 + rng.nextDouble() * 0.9);
      final cp1x = startX + (rng.nextDouble() - 0.5) * 160;
      final cp1y = startY + (rng.nextDouble() - 0.5) * 100;
      final cp2x = cp1x + (rng.nextDouble() - 0.5) * 140;
      final cp2y = cp1y + (rng.nextDouble() - 0.5) * 80;
      final endX = cp2x + (rng.nextDouble() - 0.5) * 100;
      final endY = cp2y + (rng.nextDouble() - 0.5) * 80;

      paint.strokeWidth = 0.5 + rng.nextDouble() * 1.8;
      paint.color = const Color(0xFFE0D5C5).withAlpha(40 + rng.nextInt(100));

      final path = Path()
        ..moveTo(startX, startY)
        ..cubicTo(cp1x, cp1y, cp2x, cp2y, endX, endY);
      canvas.drawPath(path, paint);
    }

    // A couple small decorative dots/dashes
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.1 + rng.nextDouble() * 0.8);
      final y = size.height * (0.1 + rng.nextDouble() * 0.8);
      paint.strokeWidth = 1.0;
      paint.color = const Color(0xFFE0D5C5).withAlpha(60);
      canvas.drawCircle(Offset(x, y), 1.5 + rng.nextDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class WarmLogo extends StatelessWidget {
  final double size;
  const WarmLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WarmLogoPainter(),
    );
  }
}

class _WarmLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width * 0.42;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB8956A);

    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Small rays
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * 3.14159;
      final inner = r + 2;
      final outer = inner + r * 0.3;
      canvas.drawLine(
        Offset(cx + cos(angle) * inner, cy + sin(angle) * inner),
        Offset(cx + cos(angle) * outer, cy + sin(angle) * outer),
        paint..strokeWidth = 1.0,
      );
    }

    // Tiny center dot
    canvas.drawCircle(Offset(cx, cy), 2.5,
      Paint()..style = PaintingStyle.fill..color = const Color(0xFFB8956A));
  }

  @override
  bool shouldRepaint(_) => false;
}
