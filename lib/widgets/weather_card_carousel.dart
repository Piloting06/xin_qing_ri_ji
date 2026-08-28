import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../theme/xq_paper_textures.dart';
import '../utils/weather_utils.dart';
import 'weather_illustration.dart';
import 'glow_wrap.dart';

/// 天气卡片轮播（垂直翻页）
/// 2 页：明天 / 后天
/// 简笔画手绘风插画 + 纸质卡片 + 温度对比 + 温度条
class WeatherCardCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> days;
  final String cityName;
  final VoidCallback? onTap;
  /// 今天的最高温，用于温度对比
  final int? todayHigh;

  const WeatherCardCarousel({
    super.key,
    required this.days,
    required this.cityName,
    this.onTap,
    this.todayHigh,
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
      height: 240,
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
                  todayHigh: widget.todayHigh,
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
  final int? todayHigh;

  const _WeatherCard({
    required this.day,
    required this.label,
    required this.cityName,
    required this.theme,
    this.onTap,
    this.todayHigh,
  });

  @override
  Widget build(BuildContext context) {
    final tempHigh = weatherInt(day['temp_max']);
    final tempLow = weatherInt(day['temp_min']);
    final temp = tempHigh?.toString() ?? '--';
    final weatherText = day['weather'] ?? '';
    final weatherCode = day['weather_code'] as int? ?? 0;
    final isDark = theme.isDark;

    // Temperature comparison
    String? tempDiff;
    if (tempHigh != null && todayHigh != null) {
      final diff = tempHigh - todayHigh!;
      if (diff > 0) {
        tempDiff = '比今天暖 $diff°';
      } else if (diff < 0) {
        tempDiff = '比今天冷 ${-diff}°';
      } else {
        tempDiff = '和今天差不多';
      }
    }

    return GlowWrap(
      accentColor: theme.accentColor,
      radius: 35,
      borderRadius: BorderRadius.circular(XqDecorations.radiusLarge),
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
                    // 标签 + 温度对比
                    Row(
                      children: [
                        if (label.isNotEmpty)
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTertiary,
                              letterSpacing: 1,
                            ),
                          ),
                        if (tempDiff != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.accentColor.withAlpha(18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tempDiff,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 简笔画插画区
                    Expanded(
                      child: Center(
                        child: AnimatedWeatherIllustration(
                          code: weatherCode,
                          inkColor: theme.ink,
                          accentColor: theme.gold,
                          size: const Size(140, 78),
                          isNight: _isNight(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 温度 + 天气 + 城市
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$temp°',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w300,
                            color: theme.textPrimary,
                            letterSpacing: 1,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (tempLow != null && tempHigh != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '$tempLow° / $tempHigh°',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textSecondary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Temperature bar
                    if (tempLow != null && tempHigh != null)
                      _tempBar(tempLow, tempHigh, theme),
                    const SizedBox(height: 4),
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

  /// Colored temperature range bar
  bool _isNight() {
    final hour = DateTime.now().hour;
    return hour < 6 || hour >= 19;
  }

  Widget _tempBar(int low, int high, ThemeState theme) {
    // Map temp to 0..1 within a -10..45 range
    const rangeMin = -10.0;
    const rangeMax = 45.0;
    final start = ((low - rangeMin) / (rangeMax - rangeMin)).clamp(0.0, 1.0);
    final end = ((high - rangeMin) / (rangeMax - rangeMin)).clamp(0.0, 1.0);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              children: [
                // Background track
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.borderColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Colored fill
                Positioned(
                  left: start * width,
                  right: (1 - end) * width,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          theme.accentColor.withAlpha(80),
                          theme.accentColor.withAlpha(180),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
