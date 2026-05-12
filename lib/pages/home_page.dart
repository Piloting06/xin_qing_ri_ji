import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../constants/keys.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';
import '../widgets/feature_tip.dart';
import '../widgets/weather_carousel.dart';
import '../widgets/weather_animation.dart';
import '../widgets/pixel_fox.dart';
import 'diary_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _weather;
  String? _weatherError;
  String _currentCity = '';
  bool _showCitySearch = false;
  final _citySearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _cityResults = [];
  bool _loading = true;
  bool _showAnim = false;
  Map<String, dynamic> _animData = {};
  int _animCode = 0;
  String _animText = '';
  bool _checkedIn = false;
  int _consecutive = 0;
  bool _showCard = false;
  Map<String, dynamic>? _todayCard;

  Future<void> _loadCheckin() async {
    try {
      final s = await Api.getCheckinStatus();
      if (mounted) setState(() {
        _checkedIn = s['checked_in'] == true || s['checked_in'] == 1;
        _consecutive = s['consecutive_days'] ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _checkDailyCard() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final last = prefs.getString('last_card_date') ?? '';
    if (last != today) {
      try {
        final card = await Api.getTodayCard();
        if (mounted && card.isNotEmpty) {
          setState(() { _todayCard = card; _showCard = true; });
          prefs.setString('last_card_date', today);
        }
      } catch (_) {}
    }
  }

  void _openAnim(Map<String, dynamic> day) {
    if (day.isEmpty) return;
    setState(() {
      _animData = day;
      _animCode = day['weather_code'] ?? 0;
      _animText = day['weather'] ?? '';
      _showAnim = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadCheckin();
    _checkDailyCard();
  }

  @override
  void dispose() {
    _citySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await _loadWeather();
  }

  Future<void> _loadWeather({double? lat, double? lon, String? name}) async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      lat ??= double.tryParse(prefs.getString(StorageKeys.cityLat) ?? '');
      lon ??= double.tryParse(prefs.getString(StorageKeys.cityLon) ?? '');

      if (lat == null || lon == null) {
        try {
          final loc = await Api.getLocation();
          lat = (loc['lat'] as num).toDouble();
          lon = (loc['lon'] as num).toDouble();
          name ??= [loc['city'], loc['region'], loc['country']]
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .join('，');
          if (name!.isEmpty) name = '自动定位';
          prefs.setString(StorageKeys.cityLat, lat.toString());
          prefs.setString(StorageKeys.cityLon, lon.toString());
          prefs.setString(StorageKeys.cityName, name!);
        } catch (_) {}
      }

      lat ??= 39.9042;
      lon ??= 116.4074;
      name ??= prefs.getString(StorageKeys.cityName);

      if (name == '自动定位' || name == null || name!.isEmpty) {
        name = null;
        try {
          final loc = await Api.getLocation();
          if (loc != null && loc['lat'] != null) {
            lat = (loc['lat'] as num).toDouble();
            lon = (loc['lon'] as num).toDouble();
            name = [loc['city'], loc['region'], loc['country']]
                .whereType<String>()
                .where((s) => s.isNotEmpty)
                .join('，');
            if (name!.isEmpty) name = '自动定位';
            prefs.setString(StorageKeys.cityLat, lat.toString());
            prefs.setString(StorageKeys.cityLon, lon.toString());
            prefs.setString(StorageKeys.cityName, name!);
          }
        } catch (_) {
          name = '自动定位';
        }
      }

      final data = await Api.getWeather(lat!, lon!);
      if (mounted) {
        setState(() {
          _weather = Map<String, dynamic>.from(data);
          _weatherError = null;
          _currentCity = name ?? '自动定位';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherError = '获取天气失败';
          _loading = false;
        });
      }
    }
  }

  void _onCitySearch(String q) async {
    if (q.trim().isEmpty) {
      if (mounted) setState(() => _cityResults = []);
      return;
    }
    try {
      final data = await Api.searchWeather(q);
      final cities = data['cities'];
      if (mounted)
        setState(() => _cityResults = cities is List
            ? List<Map<String, dynamic>>.from(cities)
            : []);
    } catch (_) {
      if (mounted) setState(() => _cityResults = []);
    }
  }

  void _pickCity(Map<String, dynamic> c) {
    final label = [c['name'], c['admin1'], c['country']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join('，');
    setState(() {
      _showCitySearch = false;
      _citySearchCtrl.clear();
      _cityResults = [];
    });
    _loadWeather(
        lat: (c['latitude'] as num).toDouble(),
        lon: (c['longitude'] as num).toDouble(),
        name: label);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final appState = context.watch<AppState>();
    final weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];

    if (_showAnim) {
      return WeatherAnimation(
        weatherCode: _animCode,
        weatherText: _animText,
        data: _animData,
        onClose: () => setState(() => _showAnim = false),
      );
    }

    // Show daily weather card on first open
    if (_showCard && _todayCard != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showCard) {
          _showWeatherCard(context, theme);
          setState(() => _showCard = false);
        }
      });
    }

    final isDark = theme.isDark;
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Greeting
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            appState.displayName.isNotEmpty
                                ? appState.displayName
                                : '朋友',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.textPrimary)),
                        Text(
                            '${now.year}年${now.month}月${now.day}日 ${weekdays[now.weekday == 7 ? 0 : now.weekday]}',
                            style: TextStyle(
                                fontSize: 13, color: theme.textSecondary)),
                      ]),
                ),
              ]),
              const SizedBox(height: 20),
              // Weather section
              if (_loading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFC4A46C)),
                ))
              else if (_weatherError != null)
                Center(
                    child: Text(_weatherError!,
                        style: const TextStyle(color: Color(0xFFD4837A))))
              else if (_weather != null) ...[
                if (_currentCity.isNotEmpty)
                  FeatureTip(
                    tipKey: 'city_search',
                    text: '点这里可以搜索切换城市～',
                    offset: const Offset(60, -44),
                    child: GestureDetector(
                      onTap: () => setState(() => _showCitySearch = true),
                      child: Center(
                          child: Text('$_currentCity ▾',
                              style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 14))),
                    ),
                  ),
                const SizedBox(height: 4),
                // AI Pixel Fox
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PixelFox(
                      streak: _consecutive,
                      totalMoods: 1, // updated after mood loads
                      todayMood: 0,
                      onWriteDiary: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const DiaryPage()));
                      },
                      onViewPoems: () {},
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 3D弧形天气轮播
                WeatherCarousel(
                  days: [
                    _weather!['today'] is Map ? Map<String, dynamic>.from(_weather!['today']) : {},
                    _weather!['tomorrow'] is Map ? Map<String, dynamic>.from(_weather!['tomorrow']) : {},
                    _weather!['day_after'] is Map ? Map<String, dynamic>.from(_weather!['day_after']) : {},
                  ],
                  theme: theme,
                  onTap: _openAnim,
                ),
              ],
              // City search
              if (_showCitySearch) _buildCitySearch(theme),
              // 日记快捷入口
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DiaryPage()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: const Color(0xFFC4A46C).withAlpha(20),
                      border: Border.all(color: const Color(0xFFC4A46C).withAlpha(80)),
                    ),
                    child: const Text('📔 写日记',
                        style: TextStyle(color: Color(0xFF8B7355), fontSize: 16, letterSpacing: 2)),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeatherCard(BuildContext context, ThemeState theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final t = theme;
        final card = _todayCard ?? {};
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.55,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: t.isDark
                  ? [const Color(0xFF1A1A1A), const Color(0xFF2A2218)]
                  : [Colors.white, const Color(0xFFFFF8EC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFC4A46C).withAlpha(80)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFC4A46C).withAlpha(20),
                  blurRadius: 30,
                  spreadRadius: 2)
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Date
              Text(
                  DateTime.now()
                      .toIso8601String()
                      .substring(0, 10),
                  style: TextStyle(
                      color: t.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              // Weather info
              Text(_weather?['today']?['weather'] ?? '',
                  style: TextStyle(
                      color: t.accentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(
                  '${_weather?['today']?['temp_max'] ?? '--'}° / ${_weather?['today']?['temp_min'] ?? '--'}°',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.w200)),
              const SizedBox(height: 20),
              // Quote
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                    card['quote'] ?? '今天也要好好照顾自己 🌤️',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.textSecondary,
                        fontSize: 15,
                        height: 1.6,
                        fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 32),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 18,
                        color: Color(0xFFA09888)),
                    label: const Text('关闭',
                        style: TextStyle(
                            color: Color(0xFFA09888))),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                              content: Text('已保存到相册',
                                  textAlign:
                                      TextAlign.center),
                              duration: Duration(seconds: 1)));
                    },
                    icon: const Icon(Icons.save_alt, size: 18),
                    label: const Text('保存'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFC4A46C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCitySearch(ThemeState theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _citySearchCtrl,
              autofocus: true,
              onChanged: _onCitySearch,
              style: TextStyle(color: theme.textPrimary),
              decoration: InputDecoration(
                hintText: '搜索城市...',
                hintStyle:
                    TextStyle(color: theme.textSecondary.withAlpha(150)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.search, size: 20, color: theme.accentColor),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                setState(() => _showCitySearch = false),
            icon: Icon(Icons.close, color: theme.textSecondary),
          ),
        ]),
        ..._cityResults.map((c) => ListTile(
              title: Text(c['name'] ?? '',
                  style: TextStyle(color: theme.textPrimary)),
              subtitle: Text('${c['admin1'] ?? ''} ${c['country'] ?? ''}',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12)),
              trailing: const Text('切换 →',
                  style: TextStyle(color: Color(0xFFC4A46C), fontSize: 13)),
              onTap: () => _pickCity(c),
            )),
      ]),
    );
  }
}
