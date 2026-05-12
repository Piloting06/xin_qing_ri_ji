import 'dart:math';
import 'dart:ui' as ui;
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

// ── Particle ──
class _Particle {
  double x, y, z;      // 3D position relative to sphere center
  double vx, vy, vz;   // velocity
  double size;
  double opacity;
  double life;          // 0..1, dies at 0
  double phase;         // for animation offset
  int type;             // 0=sparkle, 1=streak, 2=cloud, 3=dot

  _Particle(this.x, this.y, this.z, this.vx, this.vy, this.vz,
      this.size, this.opacity, this.life, this.phase, this.type);
}

class _GlassWeatherSphereState extends State<GlassWeatherSphere>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late AnimationController _inertiaCtrl;

  final double _sphereR = 125;
  final int _maxParticles = 200;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  double _angle = 0;
  double _targetAngle = 0;
  int _activeIndex = 0;
  double _dragVelocity = 0;
  bool _isDragging = false;
  double _lastPointerX = 0;

  // Weather-dependent particle params
  int _weatherCode = 0;

  static const _labels = ['今天', '明天', '后天'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
    _inertiaCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _inertiaCtrl.addListener(() => setState(() => _angle = _inertiaCtrl.value));
    _activeIndex = 0;
    _loadWeatherCode();
    _spawnParticles();
    _animCtrl.addListener(_updateParticles);
  }

  void _loadWeatherCode() {
    if (widget.days.isNotEmpty && widget.days[0].isNotEmpty) {
      _weatherCode = widget.days[0]['weather_code'] ?? 0;
    }
  }

  @override
  void didUpdateWidget(GlassWeatherSphere old) {
    super.didUpdateWidget(old);
    final newCode = widget.days.isNotEmpty ? (widget.days[0]['weather_code'] ?? 0) : 0;
    if (newCode != _weatherCode) {
      _weatherCode = newCode;
      _spawnParticles();
    }
  }

  void _spawnParticles() {
    _particles.clear();
    final nowCode = _weatherCode;

    if (nowCode <= 1) _spawnSparkles();        // sunny
    else if (nowCode == 2 || nowCode == 3) _spawnClouds(); // cloudy/overcast
    else if (nowCode >= 51 && nowCode <= 55 || nowCode == 80) _spawnRain(); // rain
    else if (nowCode >= 61 && nowCode <= 65) _spawnSnow();  // snow
    else if (nowCode == 95) _spawnThunder();   // thunder
    else if (nowCode == 45) _spawnFog();        // fog
    else _spawnSparkles();
  }

  void _spawnSparkles() {
    for (int i = 0; i < _maxParticles; i++) {
      // Random position on sphere surface
      final theta = _rng.nextDouble() * pi * 2;
      final phi = _rng.nextDouble() * pi;
      final r = _sphereR * (0.85 + _rng.nextDouble() * 0.3);
      final x = r * sin(phi) * cos(theta);
      final y = r * sin(phi) * sin(theta);
      final z = r * cos(phi);
      _particles.add(_Particle(x, y, z,
          (_rng.nextDouble() - 0.5) * 0.4, (_rng.nextDouble() - 0.5) * 0.4, 0,
          1.5 + _rng.nextDouble() * 3.5,
          0.4 + _rng.nextDouble() * 0.6,
          0.3 + _rng.nextDouble() * 0.7,
          _rng.nextDouble() * pi * 2,
          0));
    }
  }

  void _spawnClouds() {
    for (int i = 0; i < _maxParticles; i++) {
      final theta = _rng.nextDouble() * pi * 2;
      final phi = pi * 0.3 + _rng.nextDouble() * pi * 0.4;
      final r = _sphereR * (0.7 + _rng.nextDouble() * 0.4);
      _particles.add(_Particle(
          r * sin(phi) * cos(theta), r * sin(phi) * sin(theta), r * cos(phi),
          (_rng.nextDouble() - 0.5) * 0.15, (_rng.nextDouble() - 0.5) * 0.1, 0,
          4 + _rng.nextDouble() * 10,
          0.08 + _rng.nextDouble() * 0.18,
          0.5 + _rng.nextDouble() * 0.5,
          _rng.nextDouble() * pi * 2,
          2));
    }
  }

  void _spawnRain() {
    for (int i = 0; i < _maxParticles; i++) {
      final theta = _rng.nextDouble() * pi * 2;
      final y = -_sphereR + _rng.nextDouble() * _sphereR * 2.5;
      final x = cos(theta) * _sphereR * (0.3 + _rng.nextDouble() * 1.2);
      _particles.add(_Particle(x, y, _sphereR * (_rng.nextDouble() - 0.5),
          (_rng.nextDouble() - 0.5) * 0.3, 2 + _rng.nextDouble() * 4, 0,
          0.8 + _rng.nextDouble() * 1.5,
          0.15 + _rng.nextDouble() * 0.5,
          _rng.nextDouble(),
          _rng.nextDouble() * pi * 2,
          1));
    }
  }

  void _spawnSnow() {
    for (int i = 0; i < _maxParticles; i++) {
      final theta = _rng.nextDouble() * pi * 2;
      final y = -_sphereR + _rng.nextDouble() * _sphereR * 2.5;
      final wobble = (_rng.nextDouble() - 0.5) * _sphereR * 0.3;
      _particles.add(_Particle(cos(theta) * _sphereR * 1.2 + wobble, y, _sphereR * (_rng.nextDouble() - 0.5),
          (_rng.nextDouble() - 0.5) * 0.5, 0.4 + _rng.nextDouble() * 1.2, 0,
          2.5 + _rng.nextDouble() * 5,
          0.3 + _rng.nextDouble() * 0.7,
          _rng.nextDouble(),
          _rng.nextDouble() * pi * 2,
          3));
    }
  }

  void _spawnThunder() {
    _spawnClouds();
    for (int i = 0; i < 30; i++) {
      final theta = _rng.nextDouble() * pi * 2;
      final phi = _rng.nextDouble() * pi * 0.5;
      _particles.add(_Particle(
          _sphereR * 0.8 * sin(phi) * cos(theta),
          _sphereR * 0.8 * sin(phi) * sin(theta),
          _sphereR * 0.8 * cos(phi),
          0, 0, 0,
          1 + _rng.nextDouble() * 2,
          0.9,
          0.05 + _rng.nextDouble() * 0.1,
          _rng.nextDouble() * pi * 2,
          0));
    }
  }

  void _spawnFog() {
    for (int i = 0; i < _maxParticles; i++) {
      final theta = _rng.nextDouble() * pi * 2;
      final y = _sphereR * (_rng.nextDouble() - 0.5);
      final r = _sphereR * (0.6 + _rng.nextDouble() * 0.6);
      _particles.add(_Particle(cos(theta) * r, y, _sphereR * (_rng.nextDouble() - 0.5),
          (_rng.nextDouble() - 0.5) * 0.1, (_rng.nextDouble() - 0.5) * 0.05, 0,
          10 + _rng.nextDouble() * 18,
          0.02 + _rng.nextDouble() * 0.06,
          0.4 + _rng.nextDouble() * 0.6,
          _rng.nextDouble() * pi * 2,
          2));
    }
  }

  void _updateParticles() {
    final nowCode = _weatherCode;
    for (final p in _particles) {
      p.phase += 0.02;
      if (nowCode <= 1) {
        // Sparkles orbit
        p.x += p.vx + cos(p.phase) * 0.3;
        p.y += p.vy + sin(p.phase) * 0.3;
        p.opacity = 0.3 + 0.7 * (0.5 + 0.5 * sin(p.phase * 3));
        p.size = 1.5 + 2.5 * (0.5 + 0.5 * sin(p.phase * 2.7 + 1));
        p.life -= 0.001;
        if (p.life <= 0) {
          p.life = 0.3 + _rng.nextDouble() * 0.7;
          final theta = _rng.nextDouble() * pi * 2;
          final phi = _rng.nextDouble() * pi;
          final r = _sphereR * (0.85 + _rng.nextDouble() * 0.3);
          p.x = r * sin(phi) * cos(theta);
          p.y = r * sin(phi) * sin(theta);
          p.z = r * cos(phi);
        }
      } else if (nowCode >= 51 && nowCode <= 55 || nowCode == 80) {
        // Rain falls
        p.y += p.vy;
        p.x += p.vx;
        if (p.y > _sphereR * 1.5) {
          p.y = -_sphereR * 1.3;
          p.x = cos(_rng.nextDouble() * pi * 2) * _sphereR * (0.3 + _rng.nextDouble() * 1.2);
        }
      } else if (nowCode >= 61 && nowCode <= 65) {
        // Snow drifts
        p.y += p.vy;
        p.x += sin(p.phase * 0.5) * 1.5;
        if (p.y > _sphereR * 1.5) {
          p.y = -_sphereR * 1.3;
          p.x = cos(_rng.nextDouble() * pi * 2) * _sphereR * 1.2;
        }
      } else if (nowCode >= 2 && nowCode <= 3 || nowCode == 45) {
        // Clouds/fog drift
        p.x += p.vx + sin(p.phase) * 0.2;
        p.y += p.vy + cos(p.phase * 0.7) * 0.15;
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.removeListener(_updateParticles);
    _animCtrl.dispose();
    _inertiaCtrl.dispose();
    super.dispose();
  }

  double _angleForIndex(int i) => i * 2 * pi / 3;

  int _nearestIndex(double angle) {
    var a = angle % (2 * pi);
    if (a < 0) a += 2 * pi;
    double best = double.infinity;
    int idx = 0;
    for (int i = 0; i < 3; i++) {
      var target = _angleForIndex(i);
      var diff = (a - target).abs();
      if (diff > pi) diff = 2 * pi - diff;
      if (diff < best) { best = diff; idx = i; }
    }
    return idx;
  }

  void _onPointerDown(PointerDownEvent e) {
    _inertiaCtrl.stop();
    _lastPointerX = e.position.dx;
    _isDragging = true;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_isDragging) return;
    final delta = (e.position.dx - _lastPointerX) / (_sphereR * 1.6);
    _angle -= delta;
    _dragVelocity = -delta;
    _lastPointerX = e.position.dx;
    _activeIndex = _nearestIndex(_angle);
    setState(() {});
  }

  void _onPointerUp(PointerUpEvent e) {
    _isDragging = false;
    final targetIdx = _nearestIndex(_angle + _dragVelocity * 2);
    double targetAngle = _angleForIndex(targetIdx);
    var diff = targetAngle - _angle;
    while (diff > pi) diff -= 2 * pi;
    while (diff < -pi) diff += 2 * pi;
    targetAngle = _angle + diff;

    _inertiaCtrl.value = _angle;
    _inertiaCtrl.animateTo(targetAngle, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    HapticFeedback.selectionClick();
    _activeIndex = targetIdx;
  }

  void _onPointerCancel(PointerCancelEvent e) => _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _sphereR * 2 + 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Particle canvas
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _ParticleSpherePainter(
                    sphereR: _sphereR,
                    particles: _particles,
                    weatherCode: _weatherCode,
                    angle: _angle,
                    theme: widget.theme,
                    time: _animCtrl.value,
                  ),
                ),
              ),
            ),
          ),
          // Weather info overlay
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildWeatherInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    final day = widget.days.isNotEmpty && widget.days[0].isNotEmpty ? widget.days[0] : null;
    if (day == null) return const SizedBox.shrink();
    final temp = day['temp_max']?.toString() ?? '--';
    final weatherText = day['weather'] ?? '';
    final t = widget.theme;

    return GestureDetector(
      onTap: widget.onTap != null ? () => widget.onTap!(day) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$temp°',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w200, color: t.textPrimary, height: 1)),
          Text(weatherText,
              style: TextStyle(fontSize: 16, color: t.textSecondary, height: 1.2)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_labels.length, (i) {
              final active = i == _activeIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 8 : 6,
                height: active ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? t.accentColor : t.borderColor,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Particle Sphere Painter ──
class _ParticleSpherePainter extends CustomPainter {
  final double sphereR;
  final List<_Particle> particles;
  final int weatherCode;
  final double angle;
  final ThemeState theme;
  final double time;

  _ParticleSpherePainter({
    required this.sphereR,
    required this.particles,
    required this.weatherCode,
    required this.angle,
    required this.theme,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 30;
    final r = sphereR;
    final isDark = theme.isDark;

    // ── Glass sphere ──
    // Main body
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..shader = RadialGradient(colors: [
          isDark ? Colors.white.withAlpha(25) : Colors.white.withAlpha(40),
          Colors.white.withAlpha(5),
          Colors.transparent,
        ], stops: const [0.0, 0.4, 1.0]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // Edge
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = Colors.white.withAlpha(isDark ? 40 : 55));
    canvas.drawCircle(Offset(cx, cy), r - 3,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6..color = Colors.white.withAlpha(isDark ? 20 : 30));

    // Specular highlights
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.35), r * 0.5,
        Paint()..shader = RadialGradient(colors: [
          Colors.white.withAlpha(isDark ? 60 : 80),
          Colors.white.withAlpha(15),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(cx - r * 0.3, cy - r * 0.35), radius: r * 0.5)));
    canvas.drawCircle(Offset(cx + r * 0.25, cy + r * 0.3), r * 0.25,
        Paint()..shader = RadialGradient(colors: [
          Colors.white.withAlpha(isDark ? 35 : 45),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(cx + r * 0.25, cy + r * 0.3), radius: r * 0.25)));

    // Equator
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r - 8), pi * 0.05, pi * 1.9, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 0.4..color = Colors.white.withAlpha(isDark ? 12 : 20));
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy - r * 0.35), width: r * 1.5, height: r * 0.5), pi * 0.1, pi * 1.8, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 0.3..color = Colors.white.withAlpha(isDark ? 8 : 14));

    // ── Particles with 3D projection ──
    for (final p in particles) {
      // Apply sphere rotation to x,z
      final cosA = cos(angle);
      final sinA = sin(angle);
      final rx = p.x * cosA - p.z * sinA;
      final rz = p.x * sinA + p.z * cosA;

      // Simple perspective: z affects scale and opacity
      final zFactor = (rz / sphereR + 1.0) / 2.0; // 0=back, 1=front
      final scale = (0.3 + zFactor * 0.7).clamp(0.1, 1.0);
      final opacity = (p.opacity * zFactor).clamp(0.0, 1.0);
      if (opacity < 0.02) continue;

      final px = cx + rx;
      final py = cy + p.y;

      final paint = Paint();
      final color = _particleColor(theme.accentColor, isDark);

      if (p.type == 1) {
        // Rain streak
        paint.color = const Color(0xFF90B8E0).withAlpha((opacity * 200).round());
        paint.strokeWidth = p.size * scale;
        paint.strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(px, py), Offset(px + p.vx * 4, py + 10 * scale), paint);
      } else if (p.type == 2) {
        // Cloud — soft ellipse
        paint.color = Colors.white.withAlpha((opacity * 50).round());
        paint.style = PaintingStyle.fill;
        canvas.drawOval(Rect.fromCenter(center: Offset(px, py), width: p.size * scale * 2, height: p.size * scale), paint);
        // Cloud highlight
        paint.color = Colors.white.withAlpha((opacity * 30).round());
        canvas.drawOval(Rect.fromCenter(center: Offset(px - p.size * 0.2, py - p.size * 0.15), width: p.size * scale, height: p.size * scale * 0.6), paint);
      } else if (p.type == 3) {
        // Snow — soft dot with glow
        final glowPaint = Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withAlpha((opacity * 220).round()),
            Colors.white.withAlpha(0),
          ]).createShader(Rect.fromCircle(center: Offset(px, py), radius: p.size * scale * 2.5));
        canvas.drawCircle(Offset(px, py), p.size * scale * 2.5, glowPaint);
        paint.color = Colors.white.withAlpha((opacity * 200).round());
        canvas.drawCircle(Offset(px, py), p.size * scale * 0.8, paint);
      } else {
        // Sparkle — glow dot
        final glowR = p.size * scale * 3;
        final glowPaint = Paint()
          ..shader = RadialGradient(colors: [
            color.withAlpha((opacity * 200).round()),
            color.withAlpha((opacity * 80).round()),
            color.withAlpha(0),
          ]).createShader(Rect.fromCircle(center: Offset(px, py), radius: glowR));
        canvas.drawCircle(Offset(px, py), glowR, glowPaint);
        paint.color = Colors.white.withAlpha((opacity * 220).round());
        canvas.drawCircle(Offset(px, py), p.size * scale * 0.6, paint);
      }
    }
  }

  Color _particleColor(Color accent, bool isDark) {
    if (weatherCode <= 1) return const Color(0xFFFFD54F);      // sunny gold
    if (weatherCode == 2 || weatherCode == 3) return const Color(0xFFE8E4DC); // cloud white
    if (weatherCode >= 51 && weatherCode <= 55 || weatherCode == 80) return const Color(0xFF90B8E0); // rain blue
    if (weatherCode >= 61 && weatherCode <= 65) return const Color(0xFFF0F4FF); // snow white
    if (weatherCode == 95) return const Color(0xFFFFF9C4);     // thunder yellow
    if (weatherCode == 45) return const Color(0xFFD8DEE4);     // fog gray
    return accent;
  }

  @override
  bool shouldRepaint(_ParticleSpherePainter old) => true;
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
      width: 36, height: 36,
      child: CustomPaint(painter: _MiniIconPainter(code, active, theme)),
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
    final paint = Paint()..color = color..style = PaintingStyle.fill;

    if (code <= 1) {
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color.withAlpha(200));
      for (int i = 0; i < 6; i++) {
        final a = (i / 6) * pi * 2;
        canvas.drawLine(Offset(cx + cos(a) * (r + 2), cy + sin(a) * (r + 2)),
            Offset(cx + cos(a) * (r + 6), cy + sin(a) * (r + 6)),
            Paint()..color = color..strokeWidth = 1.2..style = PaintingStyle.stroke);
      }
    } else if (code == 2 || code == 3) {
      canvas.drawCircle(Offset(cx - 4, cy + 2), r * 0.7, paint..color = color.withAlpha(180));
      canvas.drawCircle(Offset(cx + 4, cy + 2), r * 0.7, paint..color = color.withAlpha(180));
      canvas.drawCircle(Offset(cx, cy - 2), r * 0.8, paint);
    } else if ((code >= 51 && code <= 55) || code == 80) {
      canvas.drawCircle(Offset(cx, cy - 6), r * 0.6, paint..color = color.withAlpha(180));
      paint.style = PaintingStyle.stroke; paint.strokeWidth = 1.2;
      for (int i = 0; i < 3; i++) {
        canvas.drawLine(Offset(cx - 4 + i * 4.0, cy + 2), Offset(cx - 1 + i * 4.0, cy + 10), paint..color = color.withAlpha(140));
      }
    } else if (code >= 61 && code <= 65) {
      canvas.drawCircle(Offset(cx, cy - 6), r * 0.6, paint..color = color.withAlpha(180));
      paint.style = PaintingStyle.fill;
      for (int i = 0; i < 4; i++) {
        canvas.drawCircle(Offset(cx - 4 + i * 3.0, cy + 4 + (i % 2) * 3.0), 2, paint..color = color.withAlpha(160));
      }
    } else if (code == 95) {
      canvas.drawCircle(Offset(cx, cy - 6), r * 0.6, paint..color = color.withAlpha(180));
      paint.style = PaintingStyle.stroke; paint.strokeWidth = 1.5; paint.color = const Color(0xFFFFD54F);
      canvas.drawPath(Path()..moveTo(cx, cy)..lineTo(cx - 3, cy + 7)..lineTo(cx + 2, cy + 7)..lineTo(cx - 1, cy + 14), paint);
    } else if (code == 45) {
      paint.style = PaintingStyle.stroke; paint.strokeWidth = 1.2;
      for (int i = 0; i < 3; i++) {
        canvas.drawLine(Offset(cx - 8, cy - 2 + i * 5.0), Offset(cx + 8, cy - 2 + i * 5.0), paint..color = color.withAlpha(100));
      }
    } else {
      canvas.drawCircle(Offset(cx - 4, cy + 2), r * 0.7, paint..color = color.withAlpha(180));
      canvas.drawCircle(Offset(cx + 4, cy + 2), r * 0.7, paint..color = color.withAlpha(180));
      canvas.drawCircle(Offset(cx, cy - 2), r * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(_MiniIconPainter old) => old.code != code || old.active != active;
}
