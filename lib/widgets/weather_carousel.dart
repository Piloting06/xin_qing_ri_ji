import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stores/theme_state.dart';

class WeatherCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> days;
  final ThemeState theme;
  final void Function(Map<String, dynamic> day)? onTap;

  const WeatherCarousel({
    super.key,
    required this.days,
    required this.theme,
    this.onTap,
  });

  @override
  State<WeatherCarousel> createState() => _WeatherCarouselState();
}

class _WeatherCarouselState extends State<WeatherCarousel> {
  late PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.72,
      initialPage: 0,
    );
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final page = _controller.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  static const _labels = ['今天', '明天', '后天'];

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.isDark;

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.days.length,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (context, index) {
          final isActive = index == _currentPage;
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final page = _controller.hasClients ? _controller.page! : 0.0;
              final diff = (page - index).abs().clamp(0.0, 1.0);

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(diff * 0.45 * (index < page ? 1 : -1))
                  ..scale(1.0 - diff * 0.12),
                child: Opacity(
                  opacity: 1.0 - diff * 0.5,
                  child: _WeatherCard(
                    data: widget.days[index],
                    label: _labels[index],
                    isActive: isActive,
                    theme: widget.theme,
                    onTap: widget.onTap != null
                        ? () => widget.onTap!(widget.days[index])
                        : null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String label;
  final bool isActive;
  final ThemeState theme;
  final VoidCallback? onTap;

  const _WeatherCard({
    required this.data,
    required this.label,
    required this.isActive,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.isDark;
    final t = theme; // shorthand

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A1A).withAlpha(isActive ? 220 : 160)
            : Colors.white.withAlpha(isActive ? 240 : 160),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? t.accentColor.withAlpha(120)
              : t.borderColor,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: t.accentColor.withAlpha(15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? t.accentColor : t.textSecondary,
              )),
          const SizedBox(height: 10),
          // Weather icon placeholder
          _WeatherIcon(data['weather_code'] ?? 0, isActive, theme),
          const SizedBox(height: 10),
          // Weather text
          Text(data['weather'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: t.textPrimary,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              )),
          const SizedBox(height: 10),
          // Temp range
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${data['temp_max'] ?? '--'}°',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: t.textPrimary,
                  )),
              const SizedBox(width: 6),
              Text('/ ${data['temp_min'] ?? '--'}°',
                  style: TextStyle(
                    fontSize: 16,
                    color: t.textSecondary,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          // Rain + Wind
          Text('💧${data['rain_prob'] ?? 0}%  💨${data['wind'] ?? 0}km/h',
              style: TextStyle(
                fontSize: 11,
                color: t.textSecondary,
              )),
        ],
      ),
      ),
    );
  }
}

class _WeatherIcon extends StatelessWidget {
  final int code;
  final bool active;
  final ThemeState theme;

  const _WeatherIcon(this.code, this.active, this.theme);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _WeatherIconPainter(code, active, theme),
      ),
    );
  }
}

class _WeatherIconPainter extends CustomPainter {
  final int code;
  final bool active;
  final ThemeState theme;

  _WeatherIconPainter(this.code, this.active, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final color = active ? theme.accentColor : theme.textSecondary;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    if (code == 0 || code == 1) {
      _drawSun(canvas, cx, cy, size.width * 0.35, color);
    } else if (code == 2 || code == 3) {
      _drawCloud(canvas, cx, cy + 4, size.width * 0.4, paint);
    } else if (code >= 51 && code <= 55 || code == 80) {
      _drawRain(canvas, cx, cy, size, paint);
    } else if (code >= 61 && code <= 65) {
      _drawSnow(canvas, cx, cy, size, paint);
    } else if (code == 95) {
      _drawThunder(canvas, cx, cy, size, paint);
    } else if (code == 45) {
      _drawFog(canvas, cx, cy, size, paint);
    } else {
      _drawCloud(canvas, cx, cy + 4, size.width * 0.4, paint);
    }
  }

  void _drawSun(Canvas canvas, double cx, double cy, double r, Color color) {
    // Outer glow
    canvas.drawCircle(Offset(cx, cy), r + 6,
        Paint()..color = color.withAlpha(30)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // Core
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..shader = RadialGradient(colors: [color.withAlpha(220), color.withAlpha(80)]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double r, Paint paint) {
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - r * 0.6, cy), r * 0.7, paint..color = paint.color.withAlpha(180));
    canvas.drawCircle(Offset(cx + r * 0.6, cy), r * 0.7, paint..color = paint.color.withAlpha(180));
    canvas.drawCircle(Offset(cx, cy - r * 0.4), r * 0.8, paint..color = paint.color.withAlpha(220));
  }

  void _drawRain(Canvas canvas, double cx, double cy, Size size, Paint paint) {
    _drawCloud(canvas, cx, cy - 8, size.width * 0.3, paint);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    paint.color = paint.color.withAlpha(160);
    final rng = Random(42);
    for (int i = 0; i < 5; i++) {
      final x = cx - 10 + i * 5.0;
      final len = 8.0 + rng.nextDouble() * 6;
      canvas.drawLine(Offset(x, cy + 4), Offset(x - 1, cy + 4 + len), paint);
    }
    paint.style = PaintingStyle.fill;
  }

  void _drawSnow(Canvas canvas, double cx, double cy, Size size, Paint paint) {
    _drawCloud(canvas, cx, cy - 8, size.width * 0.3, paint);
    final rng = Random(18);
    for (int i = 0; i < 5; i++) {
      final x = cx - 8 + i * 4.0;
      final y = cy + 6 + rng.nextDouble() * 8;
      canvas.drawCircle(Offset(x, y), 2.5, paint..color = paint.color.withAlpha(180));
    }
  }

  void _drawThunder(Canvas canvas, double cx, double cy, Size size, Paint paint) {
    _drawCloud(canvas, cx, cy - 8, size.width * 0.3, paint);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = const Color(0xFFFFD54F).withAlpha(200);
    final path = Path()
      ..moveTo(cx, cy + 2)
      ..lineTo(cx - 4, cy + 12)
      ..lineTo(cx + 2, cy + 12)
      ..lineTo(cx - 2, cy + 22);
    canvas.drawPath(path, paint);
    paint.style = PaintingStyle.fill;
  }

  void _drawFog(Canvas canvas, double cx, double cy, Size size, Paint paint) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = paint.color.withAlpha(100);
    for (int i = 0; i < 3; i++) {
      final y = cy - 4 + i * 8.0;
      canvas.drawLine(Offset(cx - 14, y), Offset(cx + 14, y), paint);
    }
    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(_WeatherIconPainter old) => old.code != code || old.active != active;
}
