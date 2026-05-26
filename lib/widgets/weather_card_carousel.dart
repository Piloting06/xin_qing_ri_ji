import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../theme/xq_paper_textures.dart';

/// 天气卡片轮播（垂直翻页）
/// 3 页：今天 / 明天 / 后天
/// 简笔画手绘风插画 + 纸质卡片
class WeatherCardCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> days;
  final String cityName;
  final VoidCallback? onTap;

  const WeatherCardCarousel({
    super.key,
    required this.days,
    required this.cityName,
    this.onTap,
  });

  @override
  State<WeatherCardCarousel> createState() => _WeatherCardCarouselState();
}

class _WeatherCardCarouselState extends State<WeatherCardCarousel> {
  late PageController _pageCtrl;
  int _currentPage = 0;

  static const _labels = ['明天', '后天'];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final days = widget.days;

    if (days.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 280,
      child: Row(
        children: [
          // 卡片区域
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              scrollDirection: Axis.vertical,
              itemCount: days.length,
              onPageChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _currentPage = i);
              },
              itemBuilder: (ctx, i) {
                final day = days[i];
                return _WeatherCard(
                  day: day,
                  label: i < _labels.length ? _labels[i] : '',
                  cityName: widget.cityName,
                  theme: theme,
                  onTap: widget.onTap,
                );
              },
            ),
          ),
          // 页码指示点（竖排）
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(days.length, (i) {
                final active = i == _currentPage;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: active ? 8 : 6,
                  height: active ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? theme.accentColor
                        : theme.borderColor,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final Map<String, dynamic> day;
  final String label;
  final String cityName;
  final ThemeState theme;
  final VoidCallback? onTap;

  const _WeatherCard({
    required this.day,
    required this.label,
    required this.cityName,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final temp = day['temp_max']?.toString() ?? '--';
    final weatherText = day['weather'] ?? '';
    final weatherCode = day['weather_code'] as int? ?? 0;
    final isDark = theme.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: XqDecorations.elevatedCard(
          theme.cardElevated,
          theme.accentColor,
          dark: isDark,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(XqDecorations.radiusLarge),
          child: Stack(
            children: [
              // 纸张纹理背景
              Positioned.fill(
                child: CustomPaint(
                  painter: PaperTexturePainter(
                    dotColor: theme.borderFocus.withAlpha(15),
                    seed: weatherCode,
                  ),
                ),
              ),
              // 内容
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标签
                    if (label.isNotEmpty)
                      Text(label,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTertiary,
                            letterSpacing: 1,
                          )),
                    const SizedBox(height: 8),
                    // 简笔画插画区
                    Expanded(
                      child: Center(
                        child: CustomPaint(
                          size: const Size(160, 100),
                          painter: WeatherIllustrationPainter(
                            code: weatherCode,
                            inkColor: theme.ink,
                            accentColor: theme.gold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 温度 + 天气 + 城市
                    Text('$temp°',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          color: theme.textPrimary,
                          fontFamily: 'LXGW WenKai',
                          letterSpacing: 1,
                        )),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(weatherText,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textSecondary,
                            )),
                        const Spacer(),
                        Text(cityName,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTertiary,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 天气简笔画插画 — CustomPainter
/// 所有描边使用 ink 色，StrokeCap.round
class WeatherIllustrationPainter extends CustomPainter {
  final int code;
  final Color inkColor;
  final Color accentColor;

  WeatherIllustrationPainter({
    required this.code,
    required this.inkColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    if (code <= 1) {
      _drawSun(canvas, cx, cy);
    } else if (code <= 3) {
      _drawCloudy(canvas, cx, cy);
    } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      _drawRain(canvas, cx, cy);
    } else if (code == 71 || code == 73 || code == 75 || code == 77 || code == 85 || code == 86) {
      _drawSnow(canvas, cx, cy);
    } else if (code == 95 || code == 96 || code == 99) {
      _drawThunder(canvas, cx, cy);
    } else if (code == 45 || code == 48) {
      _drawFog(canvas, cx, cy);
    } else {
      _drawSun(canvas, cx, cy);
    }
  }

  Paint _inkPaint([double width = 2.0, double alpha = 1.0]) => Paint()
    ..color = inkColor.withAlpha((255 * alpha).round().clamp(0, 255))
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  void _drawSun(Canvas canvas, double cx, double cy) {
    final paint = _inkPaint(2.0);
    // 圆圈
    canvas.drawCircle(Offset(cx, cy - 5), 20, paint);
    // 8 条放射短线
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * pi * 2;
      final inner = 26.0;
      final outer = 34.0 + (i.isEven ? 4.0 : 0.0);
      canvas.drawLine(
        Offset(cx + cos(angle) * inner, cy - 5 + sin(angle) * inner),
        Offset(cx + cos(angle) * outer, cy - 5 + sin(angle) * outer),
        _inkPaint(1.5),
      );
    }
    // 装饰小弧线
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 32, cy + 15), width: 16, height: 10),
      0, pi, false, _inkPaint(1.0, 0.5),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 35, cy + 20), width: 12, height: 8),
      0, pi, false, _inkPaint(1.0, 0.4),
    );
  }

  void _drawCloudy(Canvas canvas, double cx, double cy) {
    // 3 段重叠弧线画云朵
    _drawCloud(canvas, cx, cy - 8, 1.0);
    // 阴天加水平波浪线
    if (code == 3) {
      for (int i = 0; i < 3; i++) {
        final y = cy + 20 + i * 8;
        final path = Path()..moveTo(cx - 35, y);
        path.cubicTo(cx - 20, y - 4, cx - 5, y + 4, cx + 10, y);
        path.cubicTo(cx + 20, y - 3, cx + 30, y + 3, cx + 40, y);
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
    // 斜线雨滴
    for (int i = 0; i < 6; i++) {
      final x = cx - 25 + i * 10;
      final y = cy + 6 + (i % 2) * 5;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3, y + 15 + (i % 3) * 4),
        _inkPaint(1.3, 0.6),
      );
    }
    // 底部溅点
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
    // 散布雪花点
    final rng = Random(code);
    for (int i = 0; i < 10; i++) {
      final x = cx - 30 + rng.nextDouble() * 60;
      final y = cy + 5 + rng.nextDouble() * 30;
      final r = 1.5 + rng.nextDouble() * 2.5;
      canvas.drawCircle(Offset(x, y), r, Paint()..color = inkColor.withAlpha(50));
    }
    // 小弧线表示飘雪
    for (int i = 0; i < 3; i++) {
      final x = cx - 20 + i * 20;
      final y = cy + 8 + i * 6;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(x, y), width: 10, height: 6),
        0, pi, false, _inkPaint(1.0, 0.3),
      );
    }
  }

  void _drawThunder(Canvas canvas, double cx, double cy) {
    // 加粗云朵
    _drawCloud(canvas, cx, cy - 14, 0.9);
    // 闪电（锯齿路径）
    final lightning = Path()
      ..moveTo(cx - 2, cy + 2)
      ..lineTo(cx + 6, cy + 14)
      ..lineTo(cx, cy + 14)
      ..lineTo(cx + 8, cy + 28);
    canvas.drawPath(lightning, _inkPaint(2.0, 1.0)..color = accentColor);
    // 闪光点
    canvas.drawCircle(Offset(cx + 4, cy + 16), 3,
        Paint()..color = accentColor.withAlpha(80));
  }

  void _drawFog(Canvas canvas, double cx, double cy) {
    // 4 条水平波浪线
    for (int i = 0; i < 4; i++) {
      final y = cy - 12 + i * 10;
      final alpha = [60, 80, 50, 40][i];
      final path = Path()..moveTo(cx - 40, y);
      path.cubicTo(cx - 25, y - 5, cx - 10, y + 5, cx + 5, y);
      path.cubicTo(cx + 18, y - 4, cx + 30, y + 4, cx + 45, y);
      canvas.drawPath(path, _inkPaint(1.5, alpha / 255));
    }
    // 可选建筑剪影
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
      old.code != code || old.inkColor != inkColor;
}
