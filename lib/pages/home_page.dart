import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../theme/xq_hand_drawn.dart';
import '../theme/xq_paper_textures.dart';
import '../utils/weather_utils.dart';
import '../utils/geo_utils.dart';
import '../widgets/weather_summary_card.dart';
import '../widgets/main_scaffold.dart';
import 'capsule_page.dart';
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
        final data = Map<String, dynamic>.from(json.decode(dataStr) as Map);
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

    // 缓存新鲜（30分钟内）则不触发网络请求
    if (updatedAt != null && DateTime.now().difference(updatedAt).inMinutes < 30) {
      return;
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
    for (final resolver in [_cachedLocation, _systemLocation, _ipLocation]) {
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

    // Default fallback — Beijing
    if (!hasCache && _weather == null && mounted) {
      await _fetchWeatherFor(
        _WeatherLocation(
          lat: 39.9042,
          lon: 116.4074,
          city: '北京',
          status: '默认位置',
          cacheable: false,
        ),
      );
    }
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
    // 始终返回最近城市（不再有距离限制）
    final nearest = findNearestCity(lat, lon);
    if (nearest != null) return '${nearest.name}，${nearest.province}，中国';
    return fallback;
  }

  bool _isGenericCity(String city) {
    final text = city.trim();
    if (text.isEmpty) return true;
    const generics = {
      '当前位置',
      '上次位置',
      '定位城市',
      '手动城市',
      'GPS定位',
      'IP 定位',
      'IP 定位城市',
      '正在定位',
      '使用上次位置',
      '城市待确认',
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

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      // 重试一次，降低精度要求
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );
    }
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
    final updatedAt = DateTime.tryParse(
      prefs.getString(_weatherUpdatedAtKey) ?? '',
    );
    // 始终从坐标反查城市名（不用缓存的字符串，避免换城市后名称不更新）
    final city = await _resolveCity(lat, lon, fallback: '上次位置');
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

  /// 直接从客户端调用 ip-api.com，获取手机真实 IP 对应的城市
  Future<Map<String, dynamic>> _clientIpLocation() async {
    try {
      final res = await http
          .get(
            Uri.parse(
              'http://ip-api.com/json/?fields=status,lat,lon,city,regionName,country&lang=zh',
            ),
          )
          .timeout(const Duration(seconds: 5));
      final j = json.decode(res.body) as Map<String, dynamic>;
      if (j['status'] == 'success') return j;
    } catch (_) {}
    return {'status': 'fail'};
  }

  Future<_WeatherLocation?> _ipLocation() async {
    final loc = await _clientIpLocation();
    if (loc['status'] != 'success' ||
        loc['lat'] == null ||
        loc['lon'] == null) {
      throw Exception('IP 定位失败');
    }
    final ipLat = (loc['lat'] as num).toDouble();
    final ipLng = (loc['lon'] as num).toDouble();
    final ipCity = loc['city']?.toString() ?? '';
    final ipRegion = loc['regionName']?.toString() ?? '';
    String city;
    if (ipCity.isNotEmpty && ipCity != '未知') {
      city = ipRegion.isNotEmpty && ipRegion != '未知'
          ? '$ipCity，$ipRegion，中国'
          : '$ipCity，中国';
    } else {
      final nearest = findNearestCity(ipLat, ipLng);
      city = nearest != null
          ? '${nearest.name}，${nearest.province}，中国'
          : 'IP 定位城市';
    }
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
        _cityResults = results
            .map(
              (c) => {
                'name': c.name,
                'admin1': c.province,
                'country': '中国',
                'latitude': c.lat,
                'longitude': c.lng,
              },
            )
            .toList();
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

  void _openMood() {
    MainScaffold.switchToTab(context, 1);
  }

  void _openCityMap() {
    MainScaffold.switchToTab(context, 2);
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
              const SizedBox(height: 16),
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
              if (_weather != null && !_loading) const SizedBox(height: 12),
              if (_showCitySearch) ...[
                _buildCitySearch(theme),
                const SizedBox(height: 12),
              ],
              _buildMoodPaperHero(theme, appState),
              const SizedBox(height: 18),
              _buildTodayDashboard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodPaperHero(ThemeState theme, AppState appState) {
    final prompt = dashboardPrompt(_weather);
    final name = appState.displayName.isNotEmpty ? appState.displayName : '朋友';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(XqDecorations.radiusHero),
        onTap: _openMood,
        child: Container(
          decoration: XqDecorations.heroCard(
            theme.cardElevated,
            theme.cardColor,
            theme.borderColor,
            dark: theme.isDark,
            glow: theme.accentColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(XqDecorations.radiusHero),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: PaperTexturePainter(
                        dotColor: theme.accentColor.withAlpha(
                          theme.isDark ? 8 : 10,
                        ),
                        seed: DateTime.now().day,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.accentColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: theme.accentColor.withAlpha(38),
                              ),
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: theme.accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$name，今天想怎么被记住？',
                                  style: TextStyle(
                                    color: theme.textPrimary,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  prompt,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textSecondary,
                                    fontSize: 11.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: FilledButton.icon(
                                onPressed: _openMood,
                                icon: const Icon(
                                  Icons.edit_note_rounded,
                                  size: 16,
                                ),
                                label: const Text('记录此刻'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.accentColor,
                                  foregroundColor: theme.textOnAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CustomPaint(
                              painter: InkDotPainter(
                                inkColor: theme.accentColor.withAlpha(90),
                                radius: 4,
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
          ),
        ),
      ),
    );
  }

  Widget _buildTodayDashboard(ThemeState theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '值得一试',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(XqDecorations.radiusCard),
            border: Border.all(color: theme.borderColor.withAlpha(80)),
          ),
          child: Column(
            children: [
              _quickListTile(
                theme,
                icon: Icons.explore_outlined,
                iconColor: theme.accentColor,
                title: '城迹',
                subtitle: '看看城市情绪',
                onTap: _openCityMap,
              ),
              Divider(height: 1, color: theme.borderColor.withAlpha(60)),
              _quickListTile(
                theme,
                icon: Icons.hourglass_top_rounded,
                iconColor: theme.gold,
                title: '胶囊',
                subtitle: '写给未来的自己',
                onTap: _openCapsule,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickListTile(
    ThemeState theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(Icons.chevron_right, size: 18, color: theme.textTertiary),
            ],
          ),
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
