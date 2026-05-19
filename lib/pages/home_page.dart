import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_summary_card.dart';
import 'capsule_page.dart';
import 'diary_page.dart';
import 'mood_page.dart';
import 'profile_page.dart';
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

  Map<String, dynamic>? _weather;
  String? _weatherError;
  String _currentCity = '';
  String _locationStatus = '正在定位';
  DateTime? _weatherUpdatedAt;
  bool _showCitySearch = false;
  final _citySearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _cityResults = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
    if (mounted) {
      setState(() {
        _loading = true;
        _weatherError = null;
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
      _loading = false;
      _weather = null;
      _currentCity = '';
      _locationStatus = '定位失败';
      _weatherUpdatedAt = null;
      _weatherError = failures.isEmpty ? '定位失败，请手动选择城市' : failures.last;
    });
  }

  Future<void> _fetchWeatherFor(_WeatherLocation location) async {
    final data = await Api.getWeather(location.lat, location.lon);
    final updatedAt = DateTime.now();
    if (location.cacheable) {
      await _cacheLocation(location, updatedAt);
    }
    if (!mounted) return;
    setState(() {
      _weather = Map<String, dynamic>.from(data);
      _weatherError = null;
      _currentCity = location.city;
      _locationStatus = location.status;
      _weatherUpdatedAt = updatedAt;
      _loading = false;
    });
  }

  Future<String> _resolveCity(
    double lat,
    double lon, {
    required String fallback,
  }) async {
    try {
      final loc = await Api.reverseWeatherLocation(lat, lon);
      final label = _locationLabel(loc);
      if (label.isNotEmpty) return label;
    } catch (_) {}

    try {
      final loc = await Api.getLocation();
      final label = _locationLabel(loc);
      if (loc['error'] != true && label.isNotEmpty) return label;
    } catch (_) {}

    return fallback;
  }

  String _locationLabel(Map<String, dynamic> loc) {
    final parts = <String>[];
    for (final value in [loc['city'], loc['region'], loc['country']]) {
      if (value is! String) continue;
      final text = value.trim();
      if (text.isEmpty || parts.contains(text)) continue;
      parts.add(text);
    }
    return parts.join('，');
  }

  bool _isGenericCity(String city) {
    final text = city.trim();
    return text.isEmpty || text == '当前位置' || text == '上次位置' || text == '定位城市';
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
    final city = _locationLabel(loc);
    return _WeatherLocation(
      lat: (loc['lat'] as num).toDouble(),
      lon: (loc['lon'] as num).toDouble(),
      city: city.isEmpty ? 'IP 定位城市' : city,
      status: 'IP 定位',
      cacheable: true,
    );
  }

  Future<void> _cacheLocation(
    _WeatherLocation location,
    DateTime updatedAt,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_weatherLatKey, location.lat);
    await prefs.setDouble(_weatherLonKey, location.lon);
    if (_isGenericCity(location.city)) {
      await prefs.remove(_weatherCityKey);
    } else {
      await prefs.setString(_weatherCityKey, location.city);
    }
    await prefs.setString(_weatherUpdatedAtKey, updatedAt.toIso8601String());
  }

  void _onCitySearch(String q) async {
    if (q.trim().isEmpty) {
      if (mounted) setState(() => _cityResults = []);
      return;
    }
    try {
      final data = await Api.searchWeather(q);
      final cities = data['cities'];
      if (mounted) {
        setState(() {
          _cityResults = cities is List
              ? List<Map<String, dynamic>>.from(cities)
              : [];
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cityResults = []);
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

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
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
                weather: _weather,
                cityName: _currentCity,
                locationStatus: _locationStatus,
                updatedAt: _weatherUpdatedAt,
                error: _weatherError,
                onRetry: _loadWeather,
                onChooseCity: _openCitySearch,
                onOpenDetail: _openWeatherDetail,
              ),
              if (_showCitySearch) _buildCitySearch(theme),
              const SizedBox(height: 18),
              _buildTodayDashboard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayDashboard(ThemeState theme) {
    final prompt = dashboardPrompt(_weather);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今天可以继续做什么',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_outlined, color: theme.gold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prompt,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                theme,
                icon: Icons.favorite_outline,
                title: '记录心情',
                subtitle: '看看今天的自己',
                onTap: () => _openMood(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionCard(
                theme,
                icon: Icons.edit_note_outlined,
                title: '继续写日记',
                subtitle: '把今天留住一点',
                onTap: _openDiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                theme,
                icon: Icons.forest_outlined,
                title: '写一句树洞',
                subtitle: '轻一点放下',
                onTap: () => _openTreehole(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionCard(
                theme,
                icon: Icons.local_fire_department_outlined,
                title: '今日签到',
                subtitle: '去留下一次记录',
                onTap: () => _openProfile(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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

  Widget _actionCard(
    ThemeState theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.accentColor.withAlpha(16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: theme.accentColor, size: 20),
            ),
            const SizedBox(height: 14),
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
              subtitle,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                height: 1.45,
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
