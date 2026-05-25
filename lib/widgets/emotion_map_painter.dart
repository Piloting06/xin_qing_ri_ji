import 'dart:math';
import 'package:flutter/material.dart';
import '../stores/map_state.dart';
import '../stores/theme_state.dart';
import '../constants/china_boundary.dart';

class EmotionMapPainter extends CustomPainter {
  final List<CityData> cities;
  final ThemeState theme;
  final double breathValue;
  final CityData? myCity;
  final String? Function(String code) cityMood;
  final int Function(String code) cityCommentCount;

  EmotionMapPainter({
    required this.cities,
    required this.theme,
    required this.breathValue,
    this.myCity,
    required this.cityMood,
    required this.cityCommentCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawOutline(canvas, size);
    _drawCities(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0A1628),
          const Color(0xFF1A2A40),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawOutline(Canvas canvas, Size size) {
    final path = _chinaOutlinePath(size);

    // Fill — distinctly lighter than background so landmass is visible
    final fillPaint = Paint()
      ..color = const Color(0xFF1E3A5C)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Glow layer — thick semi-transparent halo
    final glowPaint = Paint()
      ..color = const Color(0xFF6BAFD4).withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // Bright stroke — soft cyan-blue, visible but aesthetic
    final strokePaint = Paint()
      ..color = const Color(0xFF88CCEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(path, strokePaint);

    // Nine-dash line (drawn directly, not part of fill path)
    _drawNineDashLine(canvas, size);

    // South China Sea inset
    _drawSouthChinaSeaInset(canvas, size);
  }

  void _drawCities(Canvas canvas, Size size) {
    for (var i = 0; i < cities.length; i++) {
      final city = cities[i];
      final point = _geoToScreen(city.lat, city.lng, size);
      if (point.dx < 0 || point.dx > size.width || point.dy < 0 || point.dy > size.height) continue;

      final mood = cityMood(city.code);
      final count = cityCommentCount(city.code);
      final isMe = myCity != null && myCity!.code == city.code;

      final phase = (breathValue + i * 0.07) % 1.0;
      final pulse = 0.85 + 0.15 * sin(phase * 2 * pi);
      final alpha = 0.45 + 0.35 * sin(phase * 2 * pi);

      final baseRadius = isMe ? 6.0 : 4.0;
      final countScale = count > 0 ? log(count + 1) / log(2) : 0;
      final radius = (baseRadius + countScale * 2.5) * pulse;

      final color = _moodColor(mood);
      final glowColor = color.withAlpha((180 * alpha).round());

      // Glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [glowColor, color.withAlpha(0)],
        ).createShader(Rect.fromCircle(center: point, radius: radius * 3));
      canvas.drawCircle(point, radius * 3, glowPaint);

      // Core
      final corePaint = Paint()..color = color.withAlpha((220 * alpha + 35).round().clamp(0, 255));
      canvas.drawCircle(point, radius, corePaint);

      // My city ring
      if (isMe) {
        final ringPaint = Paint()
          ..color = const Color(0xFFFF9F1C).withAlpha(180)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * pulse;
        canvas.drawCircle(point, radius + 4, ringPaint);
      }

      // City label
      if (count > 0) {
        final label = TextSpan(
          text: city.name,
          style: TextStyle(
            color: Colors.white.withAlpha(isMe ? 230 : 150),
            fontSize: isMe ? 12 : 10,
            fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
          ),
        );
        final tp = TextPainter(text: label, textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(point.dx - tp.width / 2, point.dy - radius - tp.height - 6));
      }
    }
  }

  Color _moodColor(String? mood) {
    return switch (mood) {
      'warm' => const Color(0xFFF5A623),
      'sad' => const Color(0xFF5B8FB9),
      'anxious' => const Color(0xFF9B72CF),
      'calm' => const Color(0xFF6ABF8A),
      'excited' => const Color(0xFFFF6B35),
      _ => const Color(0xFF3A4A5A),
    };
  }

  Offset _geoToScreen(double lat, double lng, Size size) {
    // Expanded projection for portrait mode: lng 73°~135°, lat 5°~56°
    const minLng = 73.0;
    const maxLng = 135.0;
    const minLat = 5.0;
    const maxLat = 56.0;

    final padding = 24.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;

    final x = padding + (lng - minLng) / (maxLng - minLng) * w;
    final y = padding + (maxLat - lat) / (maxLat - minLat) * h;
    return Offset(x, y);
  }

  Path _chinaOutlinePath(Size size) {
    // Real China boundary from DataV GeoJSON, simplified with Douglas-Peucker
    final path = Path();

    // Mainland
    if (chinaMainland.isNotEmpty) {
      final first = _geoToScreen(chinaMainland[0][0], chinaMainland[0][1], size);
      path.moveTo(first.dx, first.dy);
      for (var i = 1; i < chinaMainland.length; i++) {
        final p = _geoToScreen(chinaMainland[i][0], chinaMainland[i][1], size);
        path.lineTo(p.dx, p.dy);
      }
      path.close();
    }

    // Taiwan
    if (chinaTaiwan.isNotEmpty) {
      final twPath = Path();
      final twFirst = _geoToScreen(chinaTaiwan[0][0], chinaTaiwan[0][1], size);
      twPath.moveTo(twFirst.dx, twFirst.dy);
      for (var i = 1; i < chinaTaiwan.length; i++) {
        final p = _geoToScreen(chinaTaiwan[i][0], chinaTaiwan[i][1], size);
        twPath.lineTo(p.dx, p.dy);
      }
      twPath.close();
      path.addPath(twPath, Offset.zero);
    }

    // Hainan
    if (chinaHainan.isNotEmpty) {
      final hnPath = Path();
      final hnFirst = _geoToScreen(chinaHainan[0][0], chinaHainan[0][1], size);
      hnPath.moveTo(hnFirst.dx, hnFirst.dy);
      for (var i = 1; i < chinaHainan.length; i++) {
        final p = _geoToScreen(chinaHainan[i][0], chinaHainan[i][1], size);
        hnPath.lineTo(p.dx, p.dy);
      }
      hnPath.close();
      path.addPath(hnPath, Offset.zero);
    }

    return path;
  }

  void _drawNineDashLine(Canvas canvas, Size size) {
    // Approximate nine-dash line segments
    final dashes = [
      [[21.0, 108.0], [19.5, 108.5]],
      [[19.0, 109.0], [17.5, 109.5]],
      [[16.5, 110.0], [15.0, 111.0]],
      [[13.5, 112.0], [12.0, 113.0]],
      [[10.5, 114.0], [9.0, 115.0]],
      [[8.0, 115.5], [7.0, 116.0]],
      [[7.0, 116.5], [6.5, 117.0]],
      [[8.0, 117.5], [9.0, 118.0]],
      [[11.0, 118.5], [13.0, 119.0]],
    ];

    final paint = Paint()
      ..color = const Color(0xFF5A8AAA).withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final dash in dashes) {
      final start = _geoToScreen(dash[0][0], dash[0][1], size);
      final end = _geoToScreen(dash[1][0], dash[1][1], size);
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawSouthChinaSeaInset(Canvas canvas, Size size) {
    // Small inset box at bottom-right showing Nansha/Spratly Islands
    final insetX = size.width - 100;
    final insetY = size.height - 90;
    const insetW = 76.0;
    const insetH = 90.0;

    // Inset border
    final borderPaint = Paint()
      ..color = const Color(0xFF6BAFD4).withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRect(Rect.fromLTWH(insetX, insetY, insetW, insetH), borderPaint);

    // Simplified Nansha outline
    final nsPath = Path();
    final nsPoints = [
      [12.0, 113.0], [11.0, 114.0], [10.0, 115.0],
      [8.0, 115.0], [7.0, 114.0], [6.0, 113.0],
      [7.0, 112.0], [8.5, 112.0], [10.0, 113.0], [11.0, 113.5],
    ];
    // Map these to inset coordinates
    for (var i = 0; i < nsPoints.length; i++) {
      final ix = insetX + 8 + (nsPoints[i][1] - 112.0) / 4.0 * 60;
      final iy = insetY + 8 + (12.0 - nsPoints[i][0]) / 6.0 * 74;
      if (i == 0) {
        nsPath.moveTo(ix, iy);
      } else {
        nsPath.lineTo(ix, iy);
      }
    }
    nsPath.close();

    final insetPaint = Paint()
      ..color = const Color(0xFF6BAFD4).withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(nsPath, insetPaint);

    // 九段线 in inset
    final idPaint = Paint()
      ..color = const Color(0xFF6BAFD4).withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawLine(
      Offset(insetX + 8, insetY + 12),
      Offset(insetX + 12, insetY + 8),
      idPaint,
    );
  }

  @override
  bool shouldRepaint(covariant EmotionMapPainter oldDelegate) {
    return oldDelegate.breathValue != breathValue ||
        oldDelegate.cities != cities ||
        oldDelegate.myCity != myCity ||
        oldDelegate.theme != theme;
  }
}
