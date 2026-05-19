import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_card_carousel.dart';

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
    final code = weatherInt(current['weather_code']) ??
        weatherInt(today['weather_code']) ??
        0;
    final currentTemp = weatherInt(current['temp_current']) ??
        weatherInt(today['temp_current']);
    final high = weatherInt(today['temp_max']);
    final low = weatherInt(today['temp_min']);
    final humidity = weatherInt(current['humidity']) ?? weatherInt(today['humidity']);
    final feelsLike = weatherInt(current['feels_like']);
    final wind = weatherInt(current['wind_current']) ?? weatherInt(today['wind']);
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.isDark
                      ? [theme.cardColor, theme.cardElevated]
                      : [theme.cardElevated, theme.cardColor],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: theme.borderColor),
                boxShadow: XqDecorations.shadowMedium(dark: theme.isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cityName.isEmpty ? '当前位置' : cityName,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$locationStatus · ${weatherUpdatedText(updatedAt)}',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // 天气插画 — 全宽
                  SizedBox(
                    height: 120,
                    child: CustomPaint(
                      size: const Size(double.infinity, 100),
                      painter: WeatherIllustrationPainter(
                        code: code,
                        inkColor: theme.ink,
                        accentColor: theme.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 温度信息 — 下方独立区域
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weatherText,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currentTemp == null ? '--°' : '$currentTemp°',
                                style: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 54,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '今日 ${low == null ? '--' : '$low°'} / ${high == null ? '--' : '$high°'}',
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 14,
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
                          if (feelsLike != null) _badge(theme, '体感 $feelsLike°'),
                          if (humidity != null) _badge(theme, '湿度 $humidity%'),
                          if (wind != null) _badge(theme, '风速 $wind km/h'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(
                            context,
                            WeatherDetailAction.relocate,
                          ),
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text('重新定位'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.accentColor,
                            side: BorderSide(
                              color: theme.accentColor.withAlpha(90),
                            ),
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
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('手动城市'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.gold,
                            side: BorderSide(color: theme.gold.withAlpha(90)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            const SizedBox(height: 18),
            Text(
              '未来三天',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _dayCard(theme, '今天', today),
            const SizedBox(height: 10),
            _dayCard(theme, '明天', tomorrow),
            const SizedBox(height: 10),
            _dayCard(theme, '后天', dayAfter),
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

  Widget _dayCard(ThemeState theme, String title, Map<String, dynamic> day) {
    final weatherText = day['weather']?.toString() ?? '暂无数据';
    final high = weatherInt(day['temp_max']);
    final low = weatherInt(day['temp_min']);
    final rain = weatherInt(day['rain_prob']);
    final wind = weatherInt(day['wind']);
    final code = weatherInt(day['weather_code']) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.accentColor.withAlpha(18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              weatherIcon(code, weatherText),
              color: theme.accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$weatherText · ${low == null ? '--' : '$low°'} / ${high == null ? '--' : '$high°'}',
                  style: TextStyle(color: theme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (rain != null)
                Text(
                  '降水 $rain%',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
              if (wind != null)
                Text(
                  '风 $wind km/h',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
            ],
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
