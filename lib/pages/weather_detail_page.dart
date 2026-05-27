import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_card_carousel.dart';
import '../widgets/weather_feedback_bar.dart';
import '../widgets/weather_illustration.dart';

enum WeatherDetailAction { relocate, chooseCity }

class WeatherDetailPage extends StatelessWidget {
  final Map<String, dynamic> weather;
  final String cityName;
  final String locationStatus;
  final DateTime? updatedAt;

  const WeatherDetailPage({
    super.key,
    required this.weather,
    required this.cityName,
    required this.locationStatus,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final current = weatherCurrent(weather);
    final today = weatherDay(weather);
    final tomorrow = weatherDay(weather, key: 'tomorrow', index: 1);
    final dayAfter = weatherDay(weather, key: 'day_after', index: 2);
    final weatherText = (current['weather'] ?? today['weather'] ?? '未知天气')
        .toString();
    final code =
        weatherInt(current['weather_code']) ??
        weatherInt(today['weather_code']) ??
        0;
    final currentTemp =
        weatherInt(current['temp_current']) ??
        weatherInt(today['temp_current']);
    final high = weatherInt(today['temp_max']);
    final low = weatherInt(today['temp_min']);
    final humidity =
        weatherInt(current['humidity']) ?? weatherInt(today['humidity']);
    final feelsLike = weatherInt(current['feels_like']);
    final wind =
        weatherInt(current['wind_current']) ?? weatherInt(today['wind']);
    final rain = weatherInt(today['rain_prob']);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: theme.textPrimary,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Text(
                    '今天天气',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: XqDecorations.heroCard(
                theme.isDark ? theme.cardColor : theme.cardElevated,
                theme.isDark ? theme.cardElevated : theme.cardColor,
                theme.borderColor,
                dark: theme.isDark,
                glow: theme.accentColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cityName.isEmpty ? '当前位置' : cityName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$locationStatus · ${weatherUpdatedText(updatedAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.textTertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weatherText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      currentTemp == null
                                          ? '--°'
                                          : '$currentTemp°',
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontSize: 52,
                                        height: 1,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Text(
                                    '${low == null ? '--' : '$low°'} / ${high == null ? '--' : '$high°'}',
                                    style: TextStyle(
                                      color: theme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (feelsLike != null)
                                  _badge(theme, '体感 $feelsLike°'),
                                if (humidity != null)
                                  _badge(theme, '湿度 $humidity%'),
                                if (wind != null) _badge(theme, '风速 $wind'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 118,
                        height: 112,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withAlpha(
                            theme.isDark ? 145 : 175,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: theme.borderColor.withAlpha(80),
                          ),
                        ),
                        child: Center(
                          child: AnimatedWeatherIllustration(
                            code: code,
                            inkColor: theme.ink,
                            accentColor: theme.gold,
                            size: const Size(102, 74),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(
                            context,
                            WeatherDetailAction.relocate,
                          ),
                          icon: const Icon(Icons.my_location, size: 17),
                          label: const Text('重新定位'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.accentColor,
                            side: BorderSide(
                              color: theme.accentColor.withAlpha(90),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(
                            context,
                            WeatherDetailAction.chooseCity,
                          ),
                          icon: const Icon(Icons.search, size: 17),
                          label: const Text('手动城市'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.gold,
                            side: BorderSide(color: theme.gold.withAlpha(90)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 3-day forecast carousel
            if (tomorrow.isNotEmpty || dayAfter.isNotEmpty)
              WeatherCardCarousel(
                days: [
                  if (tomorrow.isNotEmpty) tomorrow,
                  if (dayAfter.isNotEmpty) dayAfter,
                ],
                cityName: cityName,
              ),
            const SizedBox(height: 18),
            Text(
              '现在感受',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    theme,
                    Icons.device_thermostat_outlined,
                    '体感温度',
                    feelsLike == null ? '暂无' : '$feelsLike°',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    theme,
                    Icons.water_drop_outlined,
                    '空气湿度',
                    humidity == null ? '暂无' : '$humidity%',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    theme,
                    Icons.air,
                    '今日风速',
                    wind == null ? '暂无' : '$wind km/h',
                  ),
                ),
              ],
            ),
            if (rain != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.grain_outlined,
                      color: theme.accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '今天降水概率约 $rain%，出门前可以看一眼天空。',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            WeatherFeedbackBar(
              weatherText: weatherText,
              currentTemp: currentTemp,
              high: high,
              low: low,
              cityName: cityName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
    ThemeState theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.accentColor, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(ThemeState theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.accentColor.withAlpha(14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
