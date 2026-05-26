import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/map_state.dart';
import '../stores/theme_state.dart';
import '../widgets/city_comment_sheet.dart';

class CityMapPage extends StatefulWidget {
  const CityMapPage({super.key});
  @override
  State<CityMapPage> createState() => _CityMapPageState();
}

class _CityMapPageState extends State<CityMapPage>
    with AutomaticKeepAliveClientMixin {
  late MapState _map;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _map = context.read<MapState>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _map.initialize());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.watch<ThemeState>();
    final map = context.watch<MapState>();

    if (map.loading) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public, size: 48, color: theme.accentColor.withAlpha(80)),
              const SizedBox(height: 16),
              Text(
                '正在加载城市情绪…',
                style: TextStyle(color: theme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '首次加载可能需要几秒',
                style: TextStyle(color: theme.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final allCities = List<CityData>.from(MapState.allCityList);
    if (map.myCity != null) allCities.remove(map.myCity);
    allCities.sort(
        (a, b) => map.cityCommentCount(b.code).compareTo(map.cityCommentCount(a.code)));
    if (map.myCity != null) allCities.insert(0, map.myCity!);

    final filtered = _search.trim().isEmpty
        ? allCities
        : allCities
            .where((c) =>
                c.name.contains(_search.trim()) ||
                c.province.contains(_search.trim()))
            .toList();

    final activeCities =
        filtered.where((c) => map.cityCommentCount(c.code) > 0).toList();
    final quietCities =
        filtered.where((c) => map.cityCommentCount(c.code) == 0).toList();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _map.refresh();
          },
          child: CustomScrollView(
            slivers: [
              // Search bar
              SliverToBoxAdapter(child: _searchBar(theme)),

              // Stats header
              if (_search.trim().isEmpty)
                SliverToBoxAdapter(child: _statsHeader(map, theme)),

              // Active cities section
              if (activeCities.isNotEmpty && _search.trim().isEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 15, color: theme.accentColor),
                        const SizedBox(width: 6),
                        Text(
                          '正在说话的城市',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${activeCities.length}',
                          style: TextStyle(
                            color: theme.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _cityCard(activeCities[i], map, theme),
                      childCount: activeCities.length,
                    ),
                  ),
                ),

                // Quiet section
                if (quietCities.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Icon(Icons.explore_outlined, size: 15,
                              color: theme.textTertiary),
                          const SizedBox(width: 6),
                          Text(
                            '等待第一个说话的人',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${quietCities.length}',
                            style: TextStyle(
                              color: theme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _cityCard(quietCities[i], map, theme),
                        childCount: quietCities.length,
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // Search results: flat grid
                filtered.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _emptySearch(theme),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.72,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _cityCard(filtered[i], map, theme),
                            childCount: filtered.length,
                          ),
                        ),
                      ),
              ],

              // Footer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    '${MapState.allCityList.length} 座城市 · 更多城市陆续开放中',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textTertiary, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsHeader(MapState map, ThemeState theme) {
    final myCity = map.myCity;
    final totalActive = MapState.allCityList
        .where((c) => map.cityCommentCount(c.code) > 0)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: myCity != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.accentColor.withAlpha(18),
                    theme.accentColor.withAlpha(6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.accentColor.withAlpha(30)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.accentColor.withAlpha(22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.location_on,
                        color: theme.accentColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '你在 ${myCity.name}',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalActive 座城市正在分享情绪',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      map.selectCityCode(myCity.code);
                      CityCommentSheet.show(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.accentColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '写足迹',
                        style: TextStyle(
                          color: theme.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor.withAlpha(120),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.explore, size: 22, color: theme.textTertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalActive 座城市有人在说话',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '定位或搜索你的城市，留下足迹',
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
            ),
    );
  }

  Widget _searchBar(ThemeState theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor.withAlpha(180),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor.withAlpha(120)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: TextStyle(color: theme.textPrimary, fontSize: 14),
            cursorColor: theme.accentColor,
            decoration: InputDecoration(
              hintText: '搜城市…',
              hintStyle:
                  TextStyle(color: theme.textTertiary, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: theme.textSecondary, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear,
                          color: theme.textSecondary, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cityCard(CityData city, MapState map, ThemeState theme) {
    final isMe = map.myCity != null && map.myCity!.code == city.code;
    final count = map.cityCommentCount(city.code);
    final mood = map.cityMood(city.code);
    final hasActivity = count > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          map.selectCityCode(city.code);
          CityCommentSheet.show(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasActivity
                ? _moodBg(mood, theme).withAlpha(theme.isDark ? 55 : 40)
                : theme.cardColor.withAlpha(120),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isMe
                  ? const Color(0xFFFF9F1C)
                  : hasActivity
                      ? _moodColor(mood).withAlpha(80)
                      : theme.borderColor.withAlpha(60),
              width: isMe ? 2 : 0.5,
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF9F1C).withAlpha(30),
                      blurRadius: 12,
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // City name row
              Row(
                children: [
                  if (isMe) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9F1C).withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '当前',
                        style: TextStyle(
                          color: Color(0xFFFF9F1C),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      city.name,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasActivity) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _moodColor(mood).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: _moodColor(mood),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Province
              Text(
                city.province,
                style: TextStyle(color: theme.textTertiary, fontSize: 11),
              ),
              const SizedBox(height: 8),
              // Mood text
              Expanded(
                child: Text(
                  _moodLine(mood, city.name, count),
                  style: TextStyle(
                    color: hasActivity
                        ? theme.textSecondary
                        : theme.textTertiary,
                    fontSize: 11,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!hasActivity)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '还没有足迹',
                    style: TextStyle(
                      color: theme.textTertiary.withAlpha(100),
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptySearch(ThemeState theme) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: theme.textTertiary),
          const SizedBox(height: 12),
          Text(
            '没找到这个城市',
            style: TextStyle(color: theme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _moodColor(String? mood) {
    return switch (mood) {
      'warm' => const Color(0xFFF0A830),
      'sad' => const Color(0xFF7B9BB8),
      'anxious' => const Color(0xFFB090C8),
      'calm' => const Color(0xFF78B090),
      'excited' => const Color(0xFFF08848),
      _ => const Color(0xFF8899AA),
    };
  }

  Color _moodBg(String? mood, ThemeState theme) {
    return _moodColor(mood);
  }

  String _moodLine(String? mood, String name, int count) {
    if (count > 0 && mood == null) return '有人在$name留下了足迹';
    return switch (mood) {
      'warm' => '有人在这里被陌生人撑了伞',
      'sad' => '凌晨的$name，有人在想家',
      'anxious' => '这里的人说「干就完了」',
      'calm' => '有人坐在街边发了一下午呆',
      'excited' => '昨晚有人在这里庆祝到凌晨',
      _ => '$name还在等第一个说话的人',
    };
  }
}
