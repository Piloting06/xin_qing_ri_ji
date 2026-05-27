import 'package:flutter/material.dart';

/// 手绘装饰元素库

/// 手绘波浪分隔线
class HandDrawnDividerPainter extends CustomPainter {
  final Color inkColor;
  final double amplitude;

  HandDrawnDividerPainter({required this.inkColor, this.amplitude = 3.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final mid = size.height / 2;
    path.moveTo(0, mid);
    path.cubicTo(
      size.width * 0.25,
      mid - amplitude,
      size.width * 0.5,
      mid + amplitude,
      size.width * 0.75,
      mid - amplitude * 0.6,
    );
    path.cubicTo(
      size.width * 0.9,
      mid + amplitude * 0.4,
      size.width,
      mid,
      size.width,
      mid,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 墨点选择指示器（有机形状）
class InkDotPainter extends CustomPainter {
  final Color inkColor;
  final double radius;

  InkDotPainter({required this.inkColor, this.radius = 4.0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..color = inkColor;
    canvas.drawCircle(Offset(cx, cy), radius, paint);
    canvas.drawCircle(
      Offset(cx + radius * 0.3, cy - radius * 0.2),
      radius * 0.7,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
