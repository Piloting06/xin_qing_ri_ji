import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stores/theme_state.dart';

class GlassWeatherSphere extends StatefulWidget {
  final List<Map<String, dynamic>> days;
  final ThemeState theme;
  final void Function(Map<String, dynamic> day)? onTap;

  const GlassWeatherSphere({
    super.key,
    required this.days,
    required this.theme,
    this.onTap,
  });

  @override
  State<GlassWeatherSphere> createState() => _GlassWeatherSphereState();
}

class _GlassWeatherSphereState extends State<GlassWeatherSphere>
    with SingleTickerProviderStateMixin {
  late AnimationController _inertiaCtrl;
  final double _sphereR = 130;

  // Current rotation angle in radians
  double _angle = 0;
  // Which day is "active" (closest to front)
  int _activeIndex = 0;

  // Gesture tracking
  double _lastPanX = 0;
  double _velocity = 0;
  bool _isDragging = false;

  static const _labels = ['今天', '明天', '后天'];

  @override
  void initState() {
    super.initState();
    _inertiaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _inertiaCtrl.addListener(() {
      setState(() => _angle = _inertiaCtrl.value);
    });
  }

  @override
  void dispose() {
    _inertiaCtrl.dispose();
    super.dispose();
  }

  double _angleForIndex(int i) {
    // Map index to angle: 0 at center, 1 at 2π/3, 2 at 4π/3
    return i * 2 * pi / 3;
  }

  int _nearestIndex(double angle) {
    var a = angle % (2 * pi);
    if (a < 0) a += 2 * pi;
    double best = double.infinity;
    int idx = 0;
    for (int i = 0; i < 3; i++) {
      var target = _angleForIndex(i);
      var diff = (a - target).abs();
      if (diff > pi) diff = 2 * pi - diff;
      if (diff < best) {
        best = diff;
        idx = i;
      }
    }
    return idx;
  }

  void _onPanStart(DragStartDetails d) {
    _inertiaCtrl.stop();
    _lastPanX = d.localPosition.dx;
    _isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final sensitivity = _sphereR * 1.6;
    final delta = (d.localPosition.dx - _lastPanX) / sensitivity;
    _angle -= delta;
    _velocity = -delta;
    _lastPanX = d.localPosition.dx;
    _activeIndex = _nearestIndex(_angle);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails d) {
    _isDragging = false;
    // Apply inertia
    final inertiaVel = d.velocity.pixelsPerSecond.dx / (_sphereR * 1.6) * 0.3;
    final totalVel = _velocity * 2 + inertiaVel;

    // Find target angle (nearest day's angle)
    final targetIdx = _nearestIndex(_angle + totalVel * 1.5);
    double targetAngle = _angleForIndex(targetIdx);

    // Ensure we rotate the shortest path
    var diff = targetAngle - _angle;
    // Normalize to [-π, π]
    while (diff > pi) diff -= 2 * pi;
    while (diff < -pi) diff += 2 * pi;
    targetAngle = _angle + diff;

    // Add slight inertia overshoot then settle
    final startAngle = _angle;

    _inertiaCtrl.value = startAngle;
    _inertiaCtrl.animateTo(targetAngle, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);

    HapticFeedback.selectionClick();
    _activeIndex = targetIdx;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _sphereR * 2 + 60,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Glass sphere background
            Positioned.fill(
              child: Center(
                child: CustomPaint(
                  size: Size(_sphereR * 2, _sphereR * 2),
                  painter: _GlassPainter(theme: widget.theme),
                ),
              ),
            ),
            // Weather nodes positioned on sphere surface
            ...List.generate(widget.days.length, (i) {
              final nodeAngle = _angleForIndex(i) - _angle;
              final cosA = cos(nodeAngle);
              final sinA = sin(nodeAngle);
              final visible = cosA > -0.15;

              if (!visible) return const SizedBox.shrink();

              final x = _sphereR * sinA;
              final scale = (cosA * 0.7 + 0.3).clamp(0.2, 1.0);
              final opacity = (cosA * 0.6 + 0.4).clamp(0.0, 1.0);
              final isActive = i == _activeIndex;

              return Positioned(
                top: 30,
                left: _sphereR - 35 + x,
                right: null,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: _SphereNode(
                      data: widget.days[i],
                      label: _labels[i],
                      isActive: isActive && !_isDragging,
                      theme: widget.theme,
                      onTap: widget.onTap != null
                          ? () => widget.onTap!(widget.days[i])
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Glass Sphere Painter ──
class _GlassPainter extends CustomPainter {
  final ThemeState theme;
  _GlassPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width / 2;

    // Sphere body — subtle gradient fill
    final spherePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withAlpha(30),
          Colors.white.withAlpha(8),
          Colors.white.withAlpha(3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, spherePaint);

    // Glass edge — thin, slightly brighter
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withAlpha(50),
    );

    // Inner rim — darker for depth
    canvas.drawCircle(
      Offset(cx, cy),
      r - 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withAlpha(25),
    );

    // Specular highlight — large, top-left
    final specPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withAlpha(70),
          Colors.white.withAlpha(20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx - r * 0.35, cy - r * 0.4),
        radius: r * 0.55,
      ));
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.4), r * 0.55, specPaint1);

    // Specular highlight — small, bottom-right
    final specPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withAlpha(40),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx + r * 0.3, cy + r * 0.35),
        radius: r * 0.3,
      ));
    canvas.drawCircle(Offset(cx + r * 0.3, cy + r * 0.35), r * 0.3, specPaint2);

    // Equator line
    canvas.drawLine(
      Offset(cx - r + 10, cy),
      Offset(cx + r - 10, cy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.white.withAlpha(18),
    );

    // Latitude arcs — subtle
    for (int i = -1; i <= 1; i++) {
      if (i == 0) continue;
      final latY = cy + i * r * 0.45;
      final latR = sqrt(max(0, r * r - (latY - cy) * (latY - cy)));
      if (latR > 10) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, latY), width: latR * 2, height: r * 0.3),
          pi * 0.15,
          pi * 1.7,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.4
            ..color = Colors.white.withAlpha(12),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GlassPainter old) => old.theme.themeMode != theme.themeMode;
}

// ── Weather Node (displayed on sphere surface) ──
class _SphereNode extends StatelessWidget {
  final Map<String, dynamic> data;
  final String label;
  final bool isActive;
  final ThemeState theme;
  final VoidCallback? onTap;

  const _SphereNode({
    required this.data,
    required this.label,
    required this.isActive,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final temp = data['temp_max']?.toString() ?? '--';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? t.accentColor : t.textSecondary)),
            const SizedBox(height: 4),
            _MiniWeatherIcon(data['weather_code'] ?? 0, isActive, t),
            const SizedBox(height: 2),
            Text('$temp°',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: t.textPrimary)),
            Text(data['weather'] ?? '',
                style: TextStyle(fontSize: 10, color: t.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Mini Weather Icon ──
class _MiniWeatherIcon extends StatelessWidget {
  final int code;
  final bool active;
  final ThemeState theme;
  const _MiniWeatherIcon(this.code, this.active, this.theme);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: _MiniIconPainter(code, active, theme),
      ),
    );
  }
}

class _MiniIconPainter extends CustomPainter {
  final int code;
  final bool active;
  final ThemeState theme;
  _MiniIconPainter(this.code, this.active, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final color = active ? theme.accentColor : theme.textSecondary;
    final r = size.width * 0.38;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (code <= 1) {
      // Sun
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()..color = color.withAlpha(200));
      for (int i = 0; i < 6; i++) {
        final angle = (i / 6) * pi * 2;
        canvas.drawLine(
          Offset(cx + cos(angle) * (r + 2), cy + sin(angle) * (r + 2)),
          Offset(cx + cos(angle) * (r + 6), cy + sin(angle) * (r + 6)),
          Paint()..color = color..strokeWidth = 1.2..style = PaintingStyle.stroke,
        );
      }
    } else if (code == 2 || code == 3) {
      // Cloud
      canvas.drawCircle(Offset(cx - 4, cy + 2), r * 0.7, paint..color = color.withAlpha(180));
      canvas.drawCircle(Offset(cx + 4, cy + 2), r * 0.7, paint..color = color.withAlpha(180));
      canvas.drawCircle(Offset(cx, cy - 2), r * 0.8, paint..color = color);
    } else if ((code >= 51 && code <= 55) || code == 80) {
      // Rain
      canvas.drawCircle(Offset(cx, cy - 6), r * 0.6, paint..color = color.withAlpha(180));
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.2;
      for (int i = 0; i < 3; i++) {
        final x = cx - 4 + i * 4.0;
        canvas.drawLine(Offset(x, cy + 2), Offset(x - 1, cy + 10), paint..color = color.withAlpha(140));
      }
    } else if (code >= 61 && code <= 65) {
      // Snow
      canvas.drawCircle(Offset(cx, cy - 6), r * 0.6, paint..color = color.withAlpha(180));
      paint.style = PaintingStyle.fill;
      for (int i = 0; i < 4; i++) {
        canvas.drawCircle(Offset(cx - 4 + i * 3.0, cy + 4 + (i % 2) * 3.0), 2, paint..color = color.withAlpha(160));
      }
    } else if (code == 95) {
      // Thunder
      canvas.drawCircle(Offset(cx, cy - 6), r * 0.6, paint..color = color.withAlpha(180));
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.5;
      paint.color = const Color(0xFFFFD54F);
      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(cx - 3, cy + 7)
        ..lineTo(cx + 2, cy + 7)
        ..lineTo(cx - 1, cy + 14);
      canvas.drawPath(path, paint);
    } else if (code == 45) {
      // Fog
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.2;
      for (int i = 0; i < 3; i++) {
        canvas.drawLine(Offset(cx - 8, cy - 2 + i * 5.0), Offset(cx + 8, cy - 2 + i * 5.0), paint..color = color.withAlpha(100));
      }
    } else {
      canvas.drawCircle(Offset(cx - 4, cy + 2), r * 0.7, paint..color = color.withAlpha(180));
      canvas.drawCircle(Offset(cx + 4, cy + 2), r * 0.7, paint..color = color.withAlpha(180));
      canvas.drawCircle(Offset(cx, cy - 2), r * 0.8, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_MiniIconPainter old) => old.code != code || old.active != active;
}
