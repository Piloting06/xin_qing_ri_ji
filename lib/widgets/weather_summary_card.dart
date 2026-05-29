import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../utils/weather_utils.dart';
import 'weather_illustration.dart';

class WeatherSummaryCard extends StatelessWidget {
  final bool loading;
  final bool refreshing;
  final String? statusText;
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
    this.refreshing = false,
    this.statusText,
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
      child: loading && weather == null
          ? _buildLoading(theme)
          : error != null && weather == null
          ? _buildError(theme)
          : _buildWeather(theme),
    );
  }

  Widget _buildLoading(ThemeState theme) {
    return _shell(
      theme,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.accentColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(14),
                ),
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
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            color: theme.accentColor.withAlpha(80),
            backgroundColor: theme.accentColor.withAlpha(15),
            minHeight: 2,
            borderRadius: BorderRadius.circular(1),
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
    final prompt = weatherCardPrompt(weather);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(XqDecorations.radiusHero),
        onTap: onOpenDetail,
        child: _shell(
          theme,
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
                          cityName.isEmpty ? '城市待确认' : cityName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          locationStatus,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                      '详情',
                      style: TextStyle(
                        color: theme.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                                    fontSize: 42,
                                    height: 1,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                '${low == null ? '--' : '$low°'} / ${high == null ? '--' : '$high°'}',
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            if (feelsLike != null)
                              _metricPill(theme, '体感', '$feelsLike°'),
                            if (humidity != null)
                              _metricPill(theme, '湿度', '$humidity%'),
                            if (wind != null) _metricPill(theme, '风', '$wind'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 94,
                    height: 94,
                    padding: const EdgeInsets.all(8),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: theme.cardColor.withAlpha(
                        theme.isDark ? 150 : 180,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.borderColor.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedWeatherIllustration(
                                code: code,
                                inkColor: theme.ink,
                                accentColor: theme.gold,
                                size: const Size(72, 50),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              weatherIcon(code, weatherText),
                              color: theme.accentColor,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                weatherText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 10,
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: theme.gold.withAlpha(theme.isDark ? 10 : 14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.gold.withAlpha(theme.isDark ? 24 : 22),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 15,
                      color: theme.gold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '试试去心情页制作卡片吧',
                style: TextStyle(
                  color: theme.textTertiary,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: theme.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    weatherUpdatedText(updatedAt),
                    style: TextStyle(color: theme.textSecondary, fontSize: 11),
                  ),
                  if (statusText != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: refreshing
                            ? theme.accentColor.withAlpha(20)
                            : theme.textSecondary.withAlpha(18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (refreshing)
                            SizedBox(
                              width: 9,
                              height: 9,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.4,
                                color: theme.accentColor,
                              ),
                            ),
                          if (refreshing) const SizedBox(width: 4),
                          Text(
                            statusText!,
                            style: TextStyle(
                              color: refreshing
                                  ? theme.accentColor
                                  : theme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.accentColor.withAlpha(13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.accentColor.withAlpha(35)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _shell(ThemeState theme, {required Widget child}) {
    return Container(
      key: ValueKey('${loading}_${error}_$cityName'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: XqDecorations.heroCard(
        theme.isDark ? theme.cardColor : theme.cardElevated,
        theme.isDark ? theme.cardElevated : theme.cardColor,
        theme.borderColor,
        dark: theme.isDark,
        glow: theme.accentColor,
      ),
      child: child,
    );
  }
}
