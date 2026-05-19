import 'dart:math';
import 'package:flutter/material.dart';

/// 纸张纹理和横线纸 CustomPainter
class PaperTexturePainter extends CustomPainter {
  final Color dotColor;
  final int seed;

  PaperTexturePainter({required this.dotColor, this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint()..color = dotColor;
    for (int i = 0; i < 300; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.2 + 0.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 横线纸（笔记本格线）
class LinedPaperPainter extends CustomPainter {
  final Color lineColor;
  final double lineSpacing;
  final double marginLeft;
  final bool showMarginLine;

  LinedPaperPainter({
    required this.lineColor,
    this.lineSpacing = 28,
    this.marginLeft = 48,
    this.showMarginLine = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    double y = lineSpacing;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineSpacing;
    }

    if (showMarginLine) {
      paint.color = lineColor.withAlpha(80);
      paint.strokeWidth = 1.0;
      canvas.drawLine(
        Offset(marginLeft, 0),
        Offset(marginLeft, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
