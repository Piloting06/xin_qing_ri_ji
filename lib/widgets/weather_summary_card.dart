import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../utils/weather_utils.dart';
import 'weather_card_carousel.dart';

class WeatherSummaryCard extends StatelessWidget {
  final bool loading;
  final Map<String, dynamic>? weather;
  final String cityName;
  final String locationStatus;
  final DateTime? updatedAt;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onChooseCity;
  final VoidCallback onOpenDetail;

  const WeatherSummaryCard({
    super.key,
    required this.loading,
    required this.weather,
    required this.cityName,
    required this.locationStatus,
    required this.updatedAt,
    required this.error,
    required this.onRetry,
    required this.onChooseCity,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: loading
          ? _buildLoading(theme)
          : error != null || weather == null
          ? _buildError(theme)
          : _buildWeather(theme),
    );
  }

  Widget _buildLoading(ThemeState theme) {
    return _shell(
      theme,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.3,
              color: theme.accentColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '正在准备今天的天气',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '会优先使用系统定位，失败后自动尝试缓存和 IP 定位。',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeState theme) {
    return _shell(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_off_outlined, color: theme.errorColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error ?? '天气加载失败',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '可以重新定位，或手动选择城市。',
            style: TextStyle(color: theme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('重新定位'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.accentColor,
                    side: BorderSide(color: theme.accentColor.withAlpha(90)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChooseCity,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('手动选城市'),
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
    );
  }

  Widget _buildWeather(ThemeState theme) {
    final current = weatherCurrent(weather);
    final today = weatherDay(weather);
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
    final prompt = weatherCardPrompt(weather);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpenDetail,
        child: _shell(
          theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cityName.isEmpty ? '城市待确认' : cityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withAlpha(18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '查看详情',
                      style: TextStyle(
                        color: theme.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                locationStatus,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
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
                        const SizedBox(height: 6),
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
                                    fontSize: 44,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '今日 ${low == null ? '--' : '$low°'} / ${high == null ? '--' : '$high°'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (feelsLike != null)
                              _metricPill(theme, '体感', '$feelsLike°'),
                            if (humidity != null)
                              _metricPill(theme, '湿度', '$humidity%'),
                            if (wind != null)
                              _metricPill(theme, '风速', '$wind km/h'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 118,
                    height: 128,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.cardElevated.withAlpha(theme.isDark ? 210 : 240),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomPaint(
                            size: const Size(92, 70),
                            painter: WeatherIllustrationPainter(
                              code: code,
                              inkColor: theme.ink,
                              accentColor: theme.gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              weatherIcon(code, weatherText),
                              color: theme.accentColor,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                weatherText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.surfaceAlpha,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.borderColor.withAlpha(120)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 18,
                      color: theme.gold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prompt,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 15, color: theme.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    weatherUpdatedText(updatedAt),
                    style: TextStyle(color: theme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricPill(ThemeState theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.accentColor.withAlpha(14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.accentColor.withAlpha(40)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _shell(ThemeState theme, {required Widget child}) {
    return Container(
      key: ValueKey('${loading}_${error}_$cityName'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.isDark
              ? [theme.cardColor, theme.cardElevated]
              : [theme.cardElevated, theme.cardColor],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderColor),
        boxShadow: XqDecorations.shadowMedium(dark: theme.isDark),
      ),
      child: child,
    );
  }
}
