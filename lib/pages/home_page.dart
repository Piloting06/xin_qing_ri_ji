import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';
import '../utils/weather_utils.dart';
import '../utils/geo_utils.dart';
import '../widgets/weather_summary_card.dart';
import 'capsule_page.dart';
import 'diary_page.dart';
import 'mood_page.dart';
import 'treehole_page.dart';
import 'weather_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _weatherLatKey = 'weather_lat';
  static const _weatherLonKey = 'weather_lon';
  static const _weatherCityKey = 'weather_city';
  static const _weatherUpdatedAtKey = 'weather_updated_at';
  static const _weatherDataKey = 'weather_data';

  Map<String, dynamic>? _weather;
  String? _weatherError;
  String _currentCity = '';
  String _locationStatus = '正在定位';
  String? _statusText; // 顶部状态小字，如"正在更新..."
  DateTime? _weatherUpdatedAt;
  bool _showCitySearch = false;
  final _citySearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _cityResults = [];
  bool _loading = true;
  bool _refreshing = false; // 后台刷新中，不影响前台展示

  @override
  void initState() {
    super.initState();
    _loadCachedFirst();
  }

  Future<void> _loadCachedFirst() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_weatherLatKey);
    final lon = prefs.getDouble(_weatherLonKey);
    final city = prefs.getString(_weatherCityKey);
    final dataStr = prefs.getString(_weatherDataKey);
    final updatedAt = DateTime.tryParse(
      prefs.getString(_weatherUpdatedAtKey) ?? '',
    );

    if (lat != null && lon != null && city != null && dataStr != null) {
      try {
        final data = Map<String, dynamic>.from(
          json.decode(dataStr) as Map,
        );
        if (mounted) {
          setState(() {
            _weather = data;
            _currentCity = city;
            _weatherUpdatedAt = updatedAt;
            _weatherError = null;
            _statusText = null;
            _loading = false;
            _refreshing = true;
          });
        }
      } catch (_) {}
    }

    _loadWeather();
  }

  @override
  void dispose() {
    _citySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWeather({
    double? lat,
    double? lon,
    String? name,
    String? source,
  }) async {
    final hasCache = _weather != null;
    if (mounted) {
      setState(() {
        if (hasCache) {
          _refreshing = true;
          _statusText = '正在更新...';
        } else {
          _loading = true;
          _weatherError = null;
        }
        _locationStatus = source ?? '正在定位';
      });
    }

    if (lat != null && lon != null) {
      await _fetchWeatherFor(
        _WeatherLocation(
          lat: lat,
          lon: lon,
          city: name?.trim().isNotEmpty == true ? name!.trim() : '手动城市',
          status: source ?? '手动城市',
          cacheable: true,
        ),
      );
      return;
    }

    final failures = <String>[];
    for (final resolver in [_systemLocation, _cachedLocation, _ipLocation]) {
      try {
        final location = await resolver();
        if (location == null) continue;
        await _fetchWeatherFor(location);
        return;
      } on ApiException catch (e) {
        if (e.statusCode == 401) return;
        failures.add(e.message);
      } catch (e) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.trim().isNotEmpty) failures.add(msg);
      }
    }

    if (!mounted) return;
    setState(() {
      if (hasCache) {
        _refreshing = false;
        _statusText = '数据可能稍旧';
      } else {
        _loading = false;
        _weather = null;
        _currentCity = '';
        _locationStatus = '定位失败';
        _weatherUpdatedAt = null;
      }
      _weatherError = failures.isEmpty ? '定位失败，请手动选择城市' : failures.last;
    });
  }

  Future<void> _fetchWeatherFor(_WeatherLocation location) async {
    final data = await Api.getWeather(location.lat, location.lon);
    final updatedAt = DateTime.now();
    if (location.cacheable) {
      await _cacheLocation(location, updatedAt, data);
    }
    if (!mounted) return;
    setState(() {
      _weather = Map<String, dynamic>.from(data);
      _weatherError = null;
      _currentCity = location.city;
      _locationStatus = location.status;
      _weatherUpdatedAt = updatedAt;
      _loading = false;
      _refreshing = false;
      _statusText = null;
    });
  }

  Future<String> _resolveCity(
    double lat,
    double lon, {
    required String fallback,
  }) async {
    final nearest = findNearestCity(lat, lon, maxKm: 100);
    if (nearest != null) return '${nearest.name}，${nearest.province}，中国';

    // ip-api 只取坐标，重新走内置列表匹配，不直接用英文文本
    try {
      final loc = await Api.getLocation();
      if (loc['lat'] != null && loc['lon'] != null) {
        final ipNearest = findNearestCity(
          (loc['lat'] as num).toDouble(),
          (loc['lon'] as num).toDouble(),
          maxKm: 200,
        );
        if (ipNearest != null) {
          return '${ipNearest.name}，${ipNearest.province}，中国';
        }
      }
    } catch (_) {}

    return fallback;
  }

  bool _isGenericCity(String city) {
    final text = city.trim();
    if (text.isEmpty) return true;
    const generics = {
      '当前位置', '上次位置', '定位城市', '手动城市',
      'GPS定位', 'IP 定位', 'IP 定位城市', '正在定位',
      '使用上次位置', '城市待确认',
    };
    if (generics.contains(text)) return true;
    if (!RegExp(r'[一-鿿]').hasMatch(text)) return true;
    return false;
  }

  Future<_WeatherLocation?> _systemLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('系统定位未开启');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!mounted) return null;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('允许定位天气'),
          content: const Text('用于显示你所在城市天气，不会用于好友或公开展示。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('暂不允许'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('继续'),
            ),
          ],
        ),
      );
      if (!mounted || ok != true) throw Exception('未开启定位权限');
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) throw Exception('未开启定位权限');
    if (permission == LocationPermission.deniedForever) {
      throw Exception('定位权限已被系统拒绝，请在设置中开启或手动选择城市');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 8),
      ),
    );
    final city = await _resolveCity(
      position.latitude,
      position.longitude,
      fallback: '定位城市',
    );
    return _WeatherLocation(
      lat: position.latitude,
      lon: position.longitude,
      city: city,
      status: _isGenericCity(city) ? 'GPS定位 · 城市待确认' : 'GPS定位',
      cacheable: true,
    );
  }

  Future<_WeatherLocation?> _cachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_weatherLatKey);
    final lon = prefs.getDouble(_weatherLonKey);
    if (lat == null || lon == null) return null;
    var city = prefs.getString(_weatherCityKey) ?? '';
    final updatedAt = DateTime.tryParse(
      prefs.getString(_weatherUpdatedAtKey) ?? '',
    );
    if (_isGenericCity(city)) {
      city = await _resolveCity(lat, lon, fallback: '上次位置');
    }
    if (mounted) {
      setState(() => _weatherUpdatedAt = updatedAt);
    }
    return _WeatherLocation(
      lat: lat,
      lon: lon,
      city: city,
      status: _isGenericCity(city) ? '使用上次位置 · 城市待确认' : '使用上次位置',
      cacheable: false,
    );
  }

  Future<_WeatherLocation?> _ipLocation() async {
    final loc = await Api.getLocation();
    if (loc['error'] == true || loc['lat'] == null || loc['lon'] == null) {
      throw Exception(loc['message']?.toString() ?? 'IP 定位失败');
    }
    final ipLat = (loc['lat'] as num).toDouble();
    final ipLng = (loc['lon'] as num).toDouble();
    final nearest = findNearestCity(ipLat, ipLng, maxKm: 200);
    final city = nearest != null
        ? '${nearest.name}，${nearest.province}，中国'
        : 'IP 定位城市';
    return _WeatherLocation(
      lat: ipLat,
      lon: ipLng,
      city: city,
      status: 'IP 定位',
      cacheable: true,
    );
  }

  Future<void> _cacheLocation(
    _WeatherLocation location,
    DateTime updatedAt,
    Map<String, dynamic> weatherData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_weatherLatKey, location.lat);
    await prefs.setDouble(_weatherLonKey, location.lon);
    await prefs.setDouble('cityLat', location.lat);
    await prefs.setDouble('cityLon', location.lon);
    if (_isGenericCity(location.city)) {
      await prefs.remove(_weatherCityKey);
    } else {
      await prefs.setString(_weatherCityKey, location.city);
    }
    await prefs.setString(_weatherUpdatedAtKey, updatedAt.toIso8601String());
    await prefs.setString(_weatherDataKey, json.encode(weatherData));
  }

  void _onCitySearch(String q) async {
    if (q.trim().isEmpty) {
      if (mounted) setState(() => _cityResults = []);
      return;
    }
    final results = searchCityLocally(q);
    if (mounted) {
      setState(() {
        _cityResults = results.map((c) => {
          'name': c.name,
          'admin1': c.province,
          'country': '中国',
          'latitude': c.lat,
          'longitude': c.lng,
        }).toList();
      });
    }
  }

  void _pickCity(Map<String, dynamic> c) {
    final label = [
      c['name'],
      c['admin1'],
      c['country'],
    ].whereType<String>().where((s) => s.isNotEmpty).join('，');
    setState(() {
      _showCitySearch = false;
      _citySearchCtrl.clear();
      _cityResults = [];
    });
    _loadWeather(
      lat: (c['latitude'] as num).toDouble(),
      lon: (c['longitude'] as num).toDouble(),
      name: label,
      source: '手动城市',
    );
  }

  void _openCitySearch() {
    setState(() => _showCitySearch = true);
  }

  Future<void> _openWeatherDetail() async {
    if (_weather == null) return;
    final action = await Navigator.push<WeatherDetailAction>(
      context,
      MaterialPageRoute(
        builder: (_) => WeatherDetailPage(
          weather: _weather!,
          cityName: _currentCity,
          locationStatus: _locationStatus,
          updatedAt: _weatherUpdatedAt,
        ),
      ),
    );
    if (!mounted) return;
    if (action == WeatherDetailAction.relocate) {
      _loadWeather();
    } else if (action == WeatherDetailAction.chooseCity) {
      _openCitySearch();
    }
  }

  void _openDiary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiaryPage()),
    );
  }

  void _openMood() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MoodPage()),
    );
  }

  void _openTreehole() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TreeholePage()),
    );
  }

  void _openCapsule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CapsulePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final appState = context.watch<AppState>();
    final weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWeather,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.displayName.isNotEmpty
                              ? appState.displayName
                              : '朋友',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${now.year}年${now.month}月${now.day}日 ${weekdays[now.weekday == 7 ? 0 : now.weekday]}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              WeatherSummaryCard(
                loading: _loading,
                refreshing: _refreshing,
                statusText: _statusText,
                weather: _weather,
                cityName: _currentCity,
                locationStatus: _locationStatus,
                updatedAt: _weatherUpdatedAt,
                error: _weatherError,
                onRetry: _loadWeather,
                onChooseCity: _openCitySearch,
                onOpenDetail: _openWeatherDetail,
              ),
              if (_weather != null && !_loading) ...[
                const SizedBox(height: 12),
                _buildMiniForecast(theme),
              ],
              if (_showCitySearch) _buildCitySearch(theme),
              const SizedBox(height: 18),
              _buildTodayDashboard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniForecast(ThemeState theme) {
    final tomorrow = weatherDay(_weather, key: 'tomorrow', index: 1);
    final dayAfter = weatherDay(_weather, key: 'day_after', index: 2);
    if (tomorrow.isEmpty && dayAfter.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        if (tomorrow.isNotEmpty)
          Expanded(child: _miniDayCard(theme, '明天', tomorrow)),
        if (tomorrow.isNotEmpty && dayAfter.isNotEmpty)
          const SizedBox(width: 10),
        if (dayAfter.isNotEmpty)
          Expanded(child: _miniDayCard(theme, '后天', dayAfter)),
      ],
    );
  }

  Widget _miniDayCard(ThemeState theme, String label, Map<String, dynamic> day) {
    final w = day['weather']?.toString() ?? '--';
    final code = weatherInt(day['weather_code']) ?? 0;
    final high = weatherInt(day['temp_max']);
    final low = weatherInt(day['temp_min']);
    final rain = weatherInt(day['rain_prob']);

    return GestureDetector(
      onTap: _openWeatherDetail,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor.withAlpha(180),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.borderColor.withAlpha(80)),
        ),
        child: Row(
          children: [
            Icon(weatherIcon(code, w), color: theme.accentColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(w, style: TextStyle(color: theme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  high != null && low != null ? '$low° / $high°' : '--',
                  style: TextStyle(color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (rain != null && rain > 0)
                  Text('降水 $rain%', style: TextStyle(color: theme.accentColor.withAlpha(180), fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayDashboard(ThemeState theme) {
    final prompt = dashboardPrompt(_weather);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        // Prompt bar - lighter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.accentColor.withAlpha(theme.isDark ? 8 : 14),
                theme.accentColor.withAlpha(theme.isDark ? 2 : 5),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.accentColor.withAlpha(theme.isDark ? 25 : 30),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: theme.gold.withAlpha(28),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.auto_awesome_outlined, color: theme.gold, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  prompt,
                  style: TextStyle(
                    color: theme.textPrimary.withAlpha(220),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Primary: mood recording - full width, more visual weight
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _openMood,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.accentColor.withAlpha(22),
                  theme.cardColor,
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.accentColor.withAlpha(50)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.accentColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.favorite_rounded, color: theme.accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '记录心情',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '看看今天的自己',
                        style: TextStyle(color: theme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.accentColor, size: 22),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary row - diary and treehole side by side
        Row(
          children: [
            Expanded(
              child: _secondaryAction(
                theme,
                icon: Icons.edit_note_rounded,
                title: '写日记',
                onTap: _openDiary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _secondaryAction(
                theme,
                icon: Icons.auto_awesome_outlined,
                title: '留一句树洞',
                onTap: _openTreehole,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Capsule - kept as before
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _openCapsule,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.cardElevated,
                  theme.cardColor,
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.gold.withAlpha(22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    color: theme.gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '时光胶囊',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '写给几天后的自己，到了那天会回来提醒你。',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _secondaryAction(
    ThemeState theme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.borderColor.withAlpha(100)),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.accentColor, size: 18),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitySearch(ThemeState theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _citySearchCtrl,
                  autofocus: true,
                  onChanged: _onCitySearch,
                  style: TextStyle(color: theme.textPrimary),
                  decoration: InputDecoration(
                    hintText: '搜索城市...',
                    hintStyle: TextStyle(
                      color: theme.textSecondary.withAlpha(150),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: theme.accentColor,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showCitySearch = false),
                icon: Icon(Icons.close, color: theme.textSecondary),
              ),
            ],
          ),
          if (_citySearchCtrl.text.isNotEmpty && _cityResults.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '暂无结果，换个城市名试试',
                style: TextStyle(color: theme.textSecondary, fontSize: 13),
              ),
            ),
          ..._cityResults.map(
            (c) => ListTile(
              title: Text(
                c['name'] ?? '',
                style: TextStyle(color: theme.textPrimary),
              ),
              subtitle: Text(
                '${c['admin1'] ?? ''} ${c['country'] ?? ''}',
                style: TextStyle(color: theme.textSecondary, fontSize: 12),
              ),
              trailing: Text(
                '切换',
                style: TextStyle(color: theme.gold, fontSize: 13),
              ),
              onTap: () => _pickCity(c),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherLocation {
  final double lat;
  final double lon;
  final String city;
  final String status;
  final bool cacheable;

  const _WeatherLocation({
    required this.lat,
    required this.lon,
    required this.city,
    required this.status,
    required this.cacheable,
  });
}
