import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/xq_decorations.dart';
import '../../theme/xq_typography.dart';
import 'mood_card_data.dart';

/// 晴收集：卡片随当天真实天气自动换肤（晴/云/阴雾/雨/雪）
class SunnyCardTemplate {
  SunnyCardTemplate._();

  static ({Color bg, Color accent, Color text}) paletteFor(String? weather) {
    final w = weather ?? '';
    if (w.contains('雪')) {
      return (bg: const Color(0xFFEAF2F8), accent: const Color(0xFF6E9EC4), text: const Color(0xFF24384A));
    }
    if (w.contains('雨') || w.contains('雷') || w.contains('阵雨')) {
      return (bg: const Color(0xFFE2EAF1), accent: const Color(0xFF4F7396), text: const Color(0xFF1F3244));
    }
    if (w.contains('阴') || w.contains('雾') || w.contains('霾')) {
      return (bg: const Color(0xFFEAECEF), accent: const Color(0xFF7E8C96), text: const Color(0xFF2C343A));
    }
    if (w.contains('云')) {
      return (bg: const Color(0xFFF0F3EE), accent: const Color(0xFF6E8F5E), text: const Color(0xFF2C3A26));
    }
    return (bg: const Color(0xFFFFF6DF), accent: const Color(0xFFDE9A26), text: const Color(0xFF4A3312));
  }

  static bool _isRain(String? w) => (w ?? '').contains('雨') || (w ?? '').contains('雷');
  static bool _isSnow(String? w) => (w ?? '').contains('雪');

  static Widget build(MoodCardData data) {
    final p = paletteFor(data.weatherText);
    final br = data.square ? 0.0 : 20.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(br),
        border: Border.all(color: p.accent.withAlpha(30), width: 0.5),
        boxShadow: XqDecorations.shadowStrong(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(br),
        child: Stack(
          children: [
            SizedBox(
              height: 216,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          data.dateText,
                          style: TextStyle(
                            color: p.text.withAlpha(140),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: p.accent.withAlpha(18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${data.weatherText ?? ''} · 晴收集',
                            style: TextStyle(
                              color: p.accent.withAlpha(190),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          data.moodEmoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.moodLabel,
                                style: XqTypography.handwrittenBody.copyWith(
                                  color: p.text,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data.moodEn,
                                style: TextStyle(
                                  color: p.accent.withAlpha(150),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (data.temperature != null)
                          Text(
                            data.temperature!,
                            style: TextStyle(
                              color: p.accent.withAlpha(140),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          data.bodyText.isNotEmpty ? data.bodyText : '写点什么吧',
                          style: XqTypography.handwrittenBody.copyWith(
                            color: data.bodyText.isNotEmpty
                                ? p.text
                                : p.text.withAlpha(60),
                            fontSize: data.bodyText.isNotEmpty ? 14.5 : 14,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (data.tags.isNotEmpty)
                          Expanded(
                            child: Text(
                              data.tags.take(3).join(' · '),
                              style: TextStyle(
                                color: p.accent.withAlpha(120),
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (data.tags.isEmpty) const Spacer(),
                        Text(
                          watermarkTextFor(data.watermark),
                          style: TextStyle(
                            color: p.accent.withAlpha(110),
                            fontSize: 8.2,
                            fontWeight: FontWeight.w700,
                            letterSpacing: data.watermark == 'sqrj' ? 1.5 : 1.15,
                          ),
                        ),
                        if (data.username.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            data.username,
                            style: TextStyle(
                              color: p.accent.withAlpha(90),
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: switch (data.weatherText ?? '') {
                    final w when _isRain(w) => _RainStreakPainter(accent: p.accent),
                    final w when _isSnow(w) => _SnowDotPainter(accent: p.accent),
                    final w when w.contains('云') => _CloudPainter(accent: p.accent),
                    final w when w.contains('阴') || w.contains('雾') => _HazePainter(accent: p.accent),
                    _ => _SunRaysPainter(accent: p.accent),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SunRaysPainter extends CustomPainter {
  final Color accent;
  _SunRaysPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - 36, 36);
    final glow = Paint()
      ..color = accent.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 24.0 + i * 10),
        math.pi * 0.55,
        math.pi * 0.85,
        false,
        glow,
      );
    }
    final rays = Paint()
      ..color = accent.withAlpha(34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + 0.3;
      final from = center + Offset(math.cos(angle) * 16, math.sin(angle) * 16);
      final to = center + Offset(math.cos(angle) * 22, math.sin(angle) * 22);
      canvas.drawLine(from, to, rays);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CloudPainter extends CustomPainter {
  final Color accent;
  _CloudPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = accent.withAlpha(22);
    void cloud(Offset c, double s) {
      canvas.drawCircle(c, 10 * s, paint);
      canvas.drawCircle(c + Offset(12 * s, 3 * s), 8 * s, paint);
      canvas.drawCircle(c + Offset(-11 * s, 4 * s), 7 * s, paint);
      canvas.drawCircle(c + Offset(2 * s, 6 * s), 9 * s, paint);
    }

    cloud(Offset(size.width - 42, 36), 1.2);
    cloud(Offset(size.width - 96, 22), 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HazePainter extends CustomPainter {
  final Color accent;
  _HazePainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withAlpha(18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final y = 26.0 + i * 12;
      canvas.drawLine(Offset(size.width - 66, y), Offset(size.width - 18, y + 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RainStreakPainter extends CustomPainter {
  final Color accent;
  _RainStreakPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final paint = Paint()
      ..color = accent.withAlpha(44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 26; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final len = rng.nextDouble() * 8 + 5;
      canvas.drawLine(Offset(x, y), Offset(x - 2, y + len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SnowDotPainter extends CustomPainter {
  final Color accent;
  _SnowDotPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(9);
    final paint = Paint()..color = accent.withAlpha(60);
    for (int i = 0; i < 34; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rng.nextDouble() * 1.6 + 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
