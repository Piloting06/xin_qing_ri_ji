import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WeatherAnimation extends StatefulWidget {
  final int weatherCode;
  final String weatherText;
  final Map<String, dynamic> data;
  final VoidCallback onClose;

  const WeatherAnimation({
    super.key,
    required this.weatherCode,
    required this.weatherText,
    required this.data,
    required this.onClose,
  });

  @override
  State<WeatherAnimation> createState() => _WeatherAnimationState();
}

class _WeatherAnimationState extends State<WeatherAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 30))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isSunny => widget.weatherCode <= 1;
  bool get _isCloudy => widget.weatherCode == 2;
  bool get _isOvercast => widget.weatherCode == 3;
  bool get _isRain => widget.weatherCode >= 51 && widget.weatherCode <= 55 || widget.weatherCode == 80;
  bool get _isHeavyRain => widget.weatherCode >= 55 || widget.weatherCode == 80;
  bool get _isSnow => widget.weatherCode >= 61 && widget.weatherCode <= 65;
  bool get _isThunder => widget.weatherCode == 95;
  bool get _isFog => widget.weatherCode == 45;

  Color get _bg1 {
    if (_isSunny) return const Color(0xFF1565C0);
    if (_isRain || _isThunder) return const Color(0xFF0E0E24);
    if (_isSnow) return const Color(0xFF3A5068);
    if (_isFog) return const Color(0xFFBDC3C7);
    if (_isCloudy || _isOvercast) return const Color(0xFF3A4A5C);
    return const Color(0xFF1A1A2E);
  }

  Color get _bg2 {
    if (_isSunny) return const Color(0xFFFF8F00);
    if (_isRain || _isThunder) return const Color(0xFF181838);
    if (_isSnow) return const Color(0xFF9AAFC0);
    if (_isFog) return const Color(0xFFECF0F1);
    if (_isCloudy || _isOvercast) return const Color(0xFF7B8FA0);
    return const Color(0xFF2D2D44);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bg1,
      body: Stack(
        children: [
          // Sky gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_bg1, _bg2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Animated particles
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _WeatherPainter(
                weatherCode: widget.weatherCode,
                time: _ctrl.value * 30,
                width: size.width,
                height: size.height,
              ),
            ),
          ),
          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onClose();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('← 返回',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          // Weather info
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(children: [
              Text(widget.weatherText,
                  style: const TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                  '${widget.data['temp_max'] ?? '--'}° / ${widget.data['temp_min'] ?? '--'}°',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _WeatherPainter extends CustomPainter {
  final int weatherCode;
  final double time;
  final double width;
  final double height;

  _WeatherPainter({
    required this.weatherCode,
    required this.time,
    required this.width,
    required this.height,
  });

  bool get isSunny => weatherCode <= 1;
  bool get isRain => weatherCode >= 51 && weatherCode <= 55 || weatherCode == 80;
  bool get isHeavy => weatherCode >= 55 || weatherCode == 80;
  bool get isSnow => weatherCode >= 61 && weatherCode <= 65;
  bool get isThunder => weatherCode == 95;
  bool get isFog => weatherCode == 45;
  bool get isCloud => weatherCode == 2 || weatherCode == 3;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);

    // ── Sun ──
    if (isSunny) {
      final sx = width * 0.72, sy = height * 0.22;
      // Corona glow
      canvas.drawRect(
          Rect.fromLTWH(0, 0, width, height * 0.55),
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFFFFC832).withAlpha(180),
              const Color(0xFFFF9620).withAlpha(50),
              Colors.transparent,
            ]).createShader(Rect.fromCircle(
                center: Offset(sx, sy), radius: 200)));
      // Sun core
      canvas.drawCircle(
          Offset(sx, sy),
          48,
          Paint()
            ..shader = RadialGradient(colors: [
              Colors.white,
              const Color(0xFFFFD54F),
              const Color(0xFFFF8F00).withAlpha(150),
            ]).createShader(
                Rect.fromCircle(center: Offset(sx, sy), radius: 48)));
      // Rays
      final rayPaint = Paint()
        ..color = const Color(0xFFFFEB3B).withAlpha(100)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 12; i++) {
        final angle = (i / 12) * pi * 2 + sin(time * 0.4) * 0.05;
        final len = 55 + sin(time * 2 + i) * 18;
        canvas.drawLine(
            Offset(sx + cos(angle) * 50, sy + sin(angle) * 50),
            Offset(sx + cos(angle) * len, sy + sin(angle) * len),
            rayPaint);
      }
      // Lens flare
      for (int i = 0; i < 2; i++) {
        final fx = sx + (rng.nextDouble() - 0.5) * 120;
        final fy = sy + (rng.nextDouble() - 0.5) * 80;
        canvas.drawCircle(
            Offset(fx, fy),
            3 + rng.nextDouble() * 4,
            Paint()
              ..color = Colors.white.withAlpha((20 + rng.nextDouble() * 30).round()));
      }
      // Cloud wisps
      for (int i = 0; i < 3; i++) {
        final cx = (rng.nextDouble() * width + time * 2) % (width + 60) - 30;
        final cy = height * 0.15 + i * 40;
        canvas.drawCircle(Offset(cx, cy), 18 + rng.nextDouble() * 14,
            Paint()..color = Colors.white.withAlpha(8));
      }
    }

    // ── Rain ──
    if (isRain) {
      final count = isHeavy ? 250 : 140;
      for (int i = 0; i < count; i++) {
        final depth = rng.nextDouble();
        final x = (rng.nextDouble() * (width + 40) - 20);
        final y = ((rng.nextDouble() * height + time * (18 + depth * 25)) %
                (height + 60)) -
            30;
        final windDrift = -2.5 + depth * 4;
        final alpha = (60 + depth * 120).round();
        final thick = 0.6 + depth * 2.0;
        canvas.drawLine(
            Offset(x, y),
            Offset(x + windDrift, y + 10 + depth * 14),
            Paint()
              ..color = const Color(0xFFB0C8E6).withAlpha(alpha)
              ..strokeWidth = thick
              ..strokeCap = StrokeCap.round);
        // Splash
        if (y > height - 60 && rng.nextDouble() < 0.2) {
          for (int s = 0; s < 2; s++) {
            final sx = x + (rng.nextDouble() - 0.5) * 6;
            final sy = height - 8 - rng.nextDouble() * 6;
            canvas.drawCircle(
                Offset(sx, sy),
                1.5 + rng.nextDouble(),
                Paint()
                  ..color = const Color(0xFFB0C8E6)
                      .withAlpha((30 + rng.nextDouble() * 40).round()));
          }
        }
      }
      // Distant rain veil
      canvas.drawRect(
          Rect.fromLTWH(0, height * 0.2, width, height * 0.5),
          Paint()
            ..color = const Color(0xFF8899BB).withAlpha(12));
    }

    // ── Snow ──
    if (isSnow) {
      // Ground accumulation
      canvas.drawRect(
          Rect.fromLTWH(0, height - 25, width, 25),
          Paint()
            ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withAlpha(40),
                  Colors.white.withAlpha(80),
                ]).createShader(Rect.fromLTWH(0, height - 25, width, 25)));
      for (int i = 0; i < 90; i++) {
        final depth = rng.nextDouble();
        final r = 1.5 + depth * 4.5;
        final x = (rng.nextDouble() * (width + 20) - 10 +
                sin(rng.nextDouble() * pi * 2 + time * 0.8) * 1.5) %
            (width + 20);
        final y = (rng.nextDouble() * height + time * (0.3 + depth * 1.0)) %
                (height + 20) -
            10;
        canvas.drawCircle(
            Offset(x, y),
            r,
            Paint()
              ..color =
                  Colors.white.withAlpha((80 + depth * 140).round()));
        // Bounce on ground
        if (y > height - 30 && rng.nextDouble() < 0.15) {
          canvas.drawCircle(
              Offset(x + (rng.nextDouble() - 0.5) * 3, height - 28),
              1.5,
              Paint()..color = Colors.white.withAlpha(40));
        }
      }
    }

    // ── Thunder ──
    if (isThunder && rng.nextDouble() < 0.015) {
      final flashAlpha = 0.3 + rng.nextDouble() * 0.5;
      canvas.drawRect(
          Rect.fromLTWH(0, 0, width, height),
          Paint()
            ..color = Colors.white.withAlpha((flashAlpha * 80).round()));
      // Lightning bolt
      final startX = width * (0.35 + rng.nextDouble() * 0.3);
      final path = Path()..moveTo(startX, 0);
      double curX = startX, curY = 0;
      while (curY < height * 0.7) {
        curX += (rng.nextDouble() - 0.5) * 50;
        curY += 20 + rng.nextDouble() * 50;
        path.lineTo(curX, curY);
        if (rng.nextDouble() < 0.3) {
          final bx = curX + (rng.nextDouble() - 0.5) * 35;
          final by = curY + rng.nextDouble() * 30;
          path.moveTo(curX, curY);
          path.lineTo(bx, by);
          path.moveTo(curX, curY);
        }
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFFDE7).withAlpha(200)
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    // ── Clouds ──
    if (isCloud) {
      for (int i = 0; i < 12; i++) {
        final depth = rng.nextDouble();
        final cx = (rng.nextDouble() * width * 2 - width * 0.5 +
                time * (0.15 + depth * 0.3)) %
            (width + 120);
        final cy = height * 0.15 + depth * height * 0.45;
        final alpha = isCloud && weatherCode <= 2
            ? (40 + depth * 60).round()
            : (60 + depth * 80).round();
        canvas.drawCircle(
            Offset(cx - 18, cy + 6),
            16 + depth * 12,
            Paint()..color = Colors.white.withAlpha(alpha));
        canvas.drawCircle(Offset(cx + 9, cy - 4), 20 + depth * 14,
            Paint()..color = Colors.white.withAlpha(alpha));
        canvas.drawCircle(Offset(cx + 22, cy + 2), 14 + depth * 10,
            Paint()..color = Colors.white.withAlpha(alpha));
      }
      // Cloud edge highlights for overcast
      if (isCloud && weatherCode >= 3) {
        for (int i = 0; i < 6; i++) {
          final cx = width * 0.1 + i * width * 0.16;
          final cy = height * 0.3 + sin(time * 0.3 + i) * 15;
          canvas.drawCircle(
              Offset(cx, cy),
              35,
              Paint()
                ..color = const Color(0xFFDDDDDD).withAlpha(25));
        }
      }
    }

    // ── Fog ──
    if (isFog) {
      // City silhouette
      final skylinePaint = Paint()
        ..color = const Color(0xFF9EAAB0).withAlpha(60);
      for (int i = 0; i < 8; i++) {
        final bx = i * width / 7 - 20;
        final bh = 40 + rng.nextDouble() * 80;
        canvas.drawRect(
            Rect.fromLTWH(bx, height * 0.5 - bh, width / 6, bh + height * 0.5),
            skylinePaint);
      }
      // Fog banks
      for (int i = 0; i < 25; i++) {
        final r = 18 + rng.nextDouble() * 55;
        final x = (rng.nextDouble() * (width + 120) - 60 +
                time * (0.03 + rng.nextDouble() * 0.1)) %
            (width + 120);
        final y = height * 0.2 + rng.nextDouble() * height * 0.6;
        canvas.drawCircle(
            Offset(x, y),
            r,
            Paint()
              ..color = const Color(0xFFD8DEE4)
                  .withAlpha((8 + rng.nextDouble() * 25).round()));
      }
      // Depth opacity overlay
      canvas.drawRect(
          Rect.fromLTWH(0, height * 0.35, width, height * 0.3),
          Paint()
            ..color = const Color(0xFFECF0F1).withAlpha(15));
    }
  }

  @override
  bool shouldRepaint(_WeatherPainter old) => old.time != time;
}
