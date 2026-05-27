import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedWeatherIllustration extends StatefulWidget {
  final int code;
  final Color inkColor;
  final Color accentColor;
  final Size size;
  final bool animate;

  const AnimatedWeatherIllustration({
    super.key,
    required this.code,
    required this.inkColor,
    required this.accentColor,
    this.size = const Size(120, 82),
    this.animate = true,
  });

  @override
  State<AnimatedWeatherIllustration> createState() =>
      _AnimatedWeatherIllustrationState();
}

class _AnimatedWeatherIllustrationState
    extends State<AnimatedWeatherIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationForCode(widget.code),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedWeatherIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) {
      _controller.duration = _durationForCode(widget.code);
      if (widget.animate) _controller.repeat();
    }
    if (oldWidget.animate != widget.animate) {
      widget.animate ? _controller.repeat() : _controller.stop();
    }
  }

  Duration _durationForCode(int code) {
    if (_isRain(code)) return const Duration(milliseconds: 1700);
    if (_isSnow(code)) return const Duration(milliseconds: 3600);
    if (_isFog(code)) return const Duration(milliseconds: 4200);
    return const Duration(milliseconds: 4600);
  }

  bool _isRain(int code) =>
      (code >= 51 && code <= 67) || (code >= 80 && code <= 82);
  bool _isSnow(int code) =>
      code == 71 ||
      code == 73 ||
      code == 75 ||
      code == 77 ||
      code == 85 ||
      code == 86;
  bool _isFog(int code) => code == 45 || code == 48;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return CustomPaint(
        size: widget.size,
        painter: WeatherIllustrationPainter(
          code: widget.code,
          inkColor: widget.inkColor,
          accentColor: widget.accentColor,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: widget.size,
        painter: WeatherIllustrationPainter(
          code: widget.code,
          inkColor: widget.inkColor,
          accentColor: widget.accentColor,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class WeatherIllustrationPainter extends CustomPainter {
  final int code;
  final Color inkColor;
  final Color accentColor;
  final double progress;

  WeatherIllustrationPainter({
    required this.code,
    required this.inkColor,
    required this.accentColor,
    this.progress = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const baseSize = Size(120, 82);
    final scale = min(
      size.width / baseSize.width,
      size.height / baseSize.height,
    );
    final dx = (size.width - baseSize.width * scale) / 2;
    final dy = (size.height - baseSize.height * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    const cx = 60.0;
    const cy = 41.0;
    if (code <= 1) {
      _drawSun(canvas, cx, cy);
    } else if (code <= 3) {
      _drawCloudy(canvas, cx, cy);
    } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      _drawRain(canvas, cx, cy);
    } else if (code == 71 ||
        code == 73 ||
        code == 75 ||
        code == 77 ||
        code == 85 ||
        code == 86) {
      _drawSnow(canvas, cx, cy);
    } else if (code == 95 || code == 96 || code == 99) {
      _drawThunder(canvas, cx, cy);
    } else if (code == 45 || code == 48) {
      _drawFog(canvas, cx, cy);
    } else {
      _drawSun(canvas, cx, cy);
    }

    canvas.restore();
  }

  Paint _inkPaint([double width = 2.0, double alpha = 1.0]) => Paint()
    ..color = inkColor.withAlpha((255 * alpha).round().clamp(0, 255))
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  void _drawSun(Canvas canvas, double cx, double cy) {
    final breath = (sin(progress * pi * 2) + 1) / 2;
    final center = Offset(cx, cy + 1);
    canvas.drawCircle(
      center,
      26 + breath * 3,
      Paint()..color = accentColor.withAlpha((18 + breath * 18).round()),
    );
    canvas.drawCircle(center, 18, _inkPaint(2.0));
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * pi * 2;
      final inner = 24.0;
      final outer = 32.0 + (i.isEven ? 3.0 : 0.0) + breath * 1.5;
      canvas.drawLine(
        Offset(cx + cos(angle) * inner, center.dy + sin(angle) * inner),
        Offset(cx + cos(angle) * outer, center.dy + sin(angle) * outer),
        _inkPaint(1.5),
      );
    }
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 32, cy + 15), width: 16, height: 10),
      0,
      pi,
      false,
      _inkPaint(1.0, 0.5),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 35, cy + 20), width: 12, height: 8),
      0,
      pi,
      false,
      _inkPaint(1.0, 0.4),
    );
  }

  void _drawCloudy(Canvas canvas, double cx, double cy) {
    final drift = sin(progress * pi * 2) * 3;
    canvas.save();
    canvas.translate(drift, 0);
    _drawCloud(canvas, cx, cy - 8, 1.0);
    canvas.restore();
    if (code == 3) {
      for (int i = 0; i < 3; i++) {
        final y = cy + 20 + i * 8;
        final path = Path()..moveTo(cx - 35 + drift * 0.5, y);
        path.cubicTo(cx - 20, y - 4, cx - 5, y + 4, cx + 10, y);
        path.cubicTo(cx + 20, y - 3, cx + 30, y + 3, cx + 40 + drift * 0.5, y);
        canvas.drawPath(path, _inkPaint(1.2, 0.4));
      }
    }
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double alpha) {
    final paint = _inkPaint(1.8, alpha);
    final path = Path();
    path.moveTo(cx - 30, cy + 8);
    path.quadraticBezierTo(cx - 30, cy - 10, cx - 12, cy - 10);
    path.quadraticBezierTo(cx - 10, cy - 22, cx + 5, cy - 18);
    path.quadraticBezierTo(cx + 18, cy - 26, cx + 28, cy - 12);
    path.quadraticBezierTo(cx + 38, cy - 8, cx + 35, cy + 8);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawRain(Canvas canvas, double cx, double cy) {
    _drawCloud(canvas, cx, cy - 14, 0.8);
    final fall = progress * 14;
    for (int i = 0; i < 6; i++) {
      final x = cx - 25 + i * 10;
      final y = cy + 6 + (i % 2) * 5 + (fall + i * 2) % 12;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3, y + 14 + (i % 3) * 3),
        _inkPaint(1.3, 0.55),
      );
    }
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(cx - 15 + i * 15, cy + 32),
        1.5,
        Paint()..color = inkColor.withAlpha(60),
      );
    }
  }

  void _drawSnow(Canvas canvas, double cx, double cy) {
    _drawCloud(canvas, cx, cy - 14, 0.8);
    final rng = Random(code);
    for (int i = 0; i < 10; i++) {
      final x = cx - 30 + rng.nextDouble() * 60;
      final baseY = cy + 5 + rng.nextDouble() * 30;
      final y = cy + 5 + ((baseY - cy - 5 + progress * 18 + i * 3) % 32);
      final r = 1.5 + rng.nextDouble() * 2.5;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = inkColor.withAlpha(45),
      );
    }
    for (int i = 0; i < 3; i++) {
      final x = cx - 20 + i * 20;
      final y = cy + 8 + i * 6;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(x, y), width: 10, height: 6),
        0,
        pi,
        false,
        _inkPaint(1.0, 0.3),
      );
    }
  }

  void _drawThunder(Canvas canvas, double cx, double cy) {
    _drawCloud(canvas, cx, cy - 14, 0.9);
    final flash = (sin(progress * pi * 2) + 1) / 2;
    final lightning = Path()
      ..moveTo(cx - 2, cy + 2)
      ..lineTo(cx + 6, cy + 14)
      ..lineTo(cx, cy + 14)
      ..lineTo(cx + 8, cy + 28);
    canvas.drawPath(
      lightning,
      _inkPaint(2.0, 1.0)
        ..color = accentColor.withAlpha((180 + flash * 75).round()),
    );
    canvas.drawCircle(
      Offset(cx + 4, cy + 16),
      3,
      Paint()..color = accentColor.withAlpha((55 + flash * 60).round()),
    );
  }

  void _drawFog(Canvas canvas, double cx, double cy) {
    final drift = sin(progress * pi * 2) * 5;
    for (int i = 0; i < 4; i++) {
      final y = cy - 12 + i * 10;
      final alpha = [60, 80, 50, 40][i];
      final path = Path()..moveTo(cx - 40 + drift, y);
      path.cubicTo(cx - 25, y - 5, cx - 10, y + 5, cx + 5, y);
      path.cubicTo(cx + 18, y - 4, cx + 30, y + 4, cx + 45 + drift, y);
      canvas.drawPath(path, _inkPaint(1.5, alpha / 255));
    }
    final bldg = Path()
      ..moveTo(cx - 30, cy + 25)
      ..lineTo(cx - 30, cy + 10)
      ..lineTo(cx - 18, cy + 10)
      ..lineTo(cx - 18, cy + 18)
      ..lineTo(cx - 8, cy + 18)
      ..lineTo(cx - 8, cy + 5)
      ..lineTo(cx + 2, cy + 5)
      ..lineTo(cx + 2, cy + 25);
    canvas.drawPath(bldg, _inkPaint(1.0, 0.25));
  }

  @override
  bool shouldRepaint(WeatherIllustrationPainter old) =>
      old.code != code ||
      old.inkColor != inkColor ||
      old.accentColor != accentColor ||
      old.progress != progress;
}
