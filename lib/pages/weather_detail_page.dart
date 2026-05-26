import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_card_carousel.dart';
import '../widgets/weather_feedback_bar.dart';

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
              '未来两天',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _dayCard(theme, '明天', tomorrow, onTap: () => _showDayDialog(context, theme, '明天', tomorrow)),
            const SizedBox(height: 10),
            _dayCard(theme, '后天', dayAfter, onTap: () => _showDayDialog(context, theme, '后天', dayAfter)),
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

  Widget _dayCard(ThemeState theme, String title, Map<String, dynamic> day, {VoidCallback? onTap}) {
    final weatherText = day['weather']?.toString() ?? '暂无数据';
    final high = weatherInt(day['temp_max']);
    final low = weatherInt(day['temp_min']);
    final rain = weatherInt(day['rain_prob']);
    final wind = weatherInt(day['wind']);
    final code = weatherInt(day['weather_code']) ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.cardElevated.withAlpha(theme.isDark ? 230 : 240),
                theme.cardColor.withAlpha(200),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.borderColor.withAlpha(100)),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: theme.accentColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(weatherIcon(code, weatherText), color: theme.accentColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('$weatherText · ${low == null ? '--' : '$low°'} / ${high == null ? '--' : '$high°'}',
                        style: TextStyle(color: theme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (rain != null) Text('降水 $rain%', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                  if (wind != null) Text('风 $wind km/h', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, size: 18, color: theme.textTertiary),
                ],
              ),
            ],
          ),
        ),
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

  void _showDayDialog(BuildContext context, ThemeState theme, String title, Map<String, dynamic> day) {
    final w = day['weather']?.toString() ?? '--';
    final code = weatherInt(day['weather_code']) ?? 0;
    final high = weatherInt(day['temp_max']);
    final low = weatherInt(day['temp_min']);
    final rain = weatherInt(day['rain_prob']);
    final wind = weatherInt(day['wind']);
    final feels = weatherInt(day['feels_like']);
    final prompt = weatherCardPrompt({title == '明天' ? 'tomorrow' : 'day_after': day, 'current': day});

    final barColors = _weatherBarColors(code);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: Container(
            width: MediaQuery.sizeOf(context).width - 48,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 24, offset: const Offset(0, 12)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color header
                Stack(
                  children: [
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: barColors,
                        ),
                      ),
                      child: Center(
                        child: Icon(weatherIcon(code, w), color: Colors.white, size: 32),
                      ),
                    ),
                    Positioned(
                      right: 4, top: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      // Weather icon
                      CustomPaint(
                        size: const Size(80, 60),
                        painter: WeatherIllustrationPainter(code: code, inkColor: theme.ink, accentColor: theme.gold),
                      ),
                      const SizedBox(height: 8),
                      Text('$low° / $high°',
                          style: TextStyle(color: theme.textPrimary, fontSize: 48, fontWeight: FontWeight.w300, height: 1)),
                      const SizedBox(height: 4),
                      Text(w, style: TextStyle(color: theme.textSecondary, fontSize: 16)),
                      const SizedBox(height: 18),
                      // Metric pills
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        if (feels != null) _metricPill(theme, '体感', '$feels°'),
                        if (rain != null) _metricPill(theme, '降水', '$rain%'),
                        if (wind != null) _metricPill(theme, '风速', '$wind km/h'),
                      ]),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity, height: 44,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: FilledButton.styleFrom(
                            backgroundColor: barColors[0],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('知道了'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Tip
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.accentColor.withAlpha(10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(prompt, style: TextStyle(color: theme.textSecondary, fontSize: 12, height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _weatherBarColors(int code) {
    if (code <= 1) return const [Color(0xFFF5A623), Color(0xFFD4891A)]; // sunny
    if (code <= 3) return const [Color(0xFF8899AA), Color(0xFF667788)]; // cloudy
    if (code <= 48) return const [Color(0xFF99AABB), Color(0xFF778899)]; // fog
    if (code <= 67 || (code >= 80 && code <= 82)) return const [Color(0xFF6B8FAA), Color(0xFF4A6D8A)]; // rain
    if (code >= 71 && code <= 86) return const [Color(0xFFAABBCC), Color(0xFF8899BB)]; // snow
    return const [Color(0xFF8899AA), Color(0xFF667788)];
  }

  Widget _metricPill(ThemeState theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.accentColor.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label $value',
          style: TextStyle(color: theme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
