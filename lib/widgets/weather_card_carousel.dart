import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../theme/xq_paper_textures.dart';
import 'weather_illustration.dart';

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
    _pageCtrl = PageController(viewportFraction: 0.9);
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
      height: 216,
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
                    color: active ? theme.accentColor : theme.borderColor,
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标签
                    if (label.isNotEmpty)
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTertiary,
                          letterSpacing: 1,
                        ),
                      ),
                    const SizedBox(height: 6),
                    // 简笔画插画区
                    Expanded(
                      child: Center(
                        child: AnimatedWeatherIllustration(
                          code: weatherCode,
                          inkColor: theme.ink,
                          accentColor: theme.gold,
                          size: const Size(140, 78),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 温度 + 天气 + 城市
                    Text(
                      '$temp°',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w300,
                        color: theme.textPrimary,
                        fontFamily: 'LXGW WenKai',
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          weatherText,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          cityName,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTertiary,
                          ),
                        ),
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
