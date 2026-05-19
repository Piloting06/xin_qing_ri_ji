import 'dart:math';
import 'package:flutter/material.dart';

/// 手绘装饰元素库
/// 贝塞尔曲线装饰线、墨点、和纸胶带、墨渍

/// 页面背景装饰波浪线
class HandDrawnCurvesPainter extends CustomPainter {
  final Color inkColor;
  final int seed;

  HandDrawnCurvesPainter({required this.inkColor, this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    // 6 条贝塞尔装饰线
    for (int i = 0; i < 6; i++) {
      final path = Path();
      final startX = rng.nextDouble() * size.width;
      final startY = rng.nextDouble() * size.height;
      path.moveTo(startX, startY);
      path.cubicTo(
        startX + rng.nextDouble() * 200 - 100,
        startY + rng.nextDouble() * 150 - 75,
        startX + rng.nextDouble() * 300 - 150,
        startY + rng.nextDouble() * 200 - 100,
        startX + rng.nextDouble() * 400 - 200,
        startY + rng.nextDouble() * 250 - 125,
      );
      canvas.drawPath(path, paint..color = inkColor.withAlpha(30 + rng.nextInt(30)));
    }

    // 3 个墨点
    for (int i = 0; i < 3; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 3 + 1;
      canvas.drawCircle(Offset(cx, cy), r, paint..color = inkColor.withAlpha(20 + rng.nextInt(20)));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
      size.width * 0.25, mid - amplitude,
      size.width * 0.5, mid + amplitude,
      size.width * 0.75, mid - amplitude * 0.6,
    );
    path.cubicTo(
      size.width * 0.9, mid + amplitude * 0.4,
      size.width, mid,
      size.width, mid,
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
    // 两个微偏移重叠圆模拟有机墨点
    canvas.drawCircle(Offset(cx, cy), radius, paint);
    canvas.drawCircle(Offset(cx + radius * 0.3, cy - radius * 0.2),
        radius * 0.7, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 和纸胶带装饰条
class WashiTapePainter extends CustomPainter {
  final Color tapeColor;

  WashiTapePainter({required this.tapeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = tapeColor;
    // 主体矩形
    canvas.drawRect(
      Rect.fromLTWH(0, 2, size.width, size.height - 4),
      paint,
    );
    // 锯齿撕边效果（顶部）
    final edgePaint = Paint()
      ..color = tapeColor.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..moveTo(0, 2);
    for (double x = 0; x < size.width; x += 6) {
      path.lineTo(x + 3, 0);
      path.lineTo(x + 6, 2);
    }
    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 墨渍装饰
class InkStainPainter extends CustomPainter {
  final Color inkColor;
  final int seed;

  InkStainPainter({required this.inkColor, this.seed = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..color = inkColor.withAlpha(40);

    final path = Path();
    final points = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * pi * 2;
      final r = size.width * 0.3 + rng.nextDouble() * size.width * 0.15;
      points.add(Offset(cx + cos(angle) * r, cy + sin(angle) * r));
    }
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length; i++) {
      final next = points[(i + 1) % points.length];
      final cp = Offset(
        (points[i].dx + next.dx) / 2 + rng.nextDouble() * 10 - 5,
        (points[i].dy + next.dy) / 2 + rng.nextDouble() * 10 - 5,
      );
      path.quadraticBezierTo(cp.dx, cp.dy, next.dx, next.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
