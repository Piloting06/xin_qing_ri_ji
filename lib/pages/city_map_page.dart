import 'dart:async';
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
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // 城市列表：当前城市置顶，其余按评论数排序
    final cities = List<CityData>.from(MapState.allCityList);
    if (map.myCity != null) cities.remove(map.myCity);
    cities.sort((a, b) => map.cityCommentCount(b.code).compareTo(map.cityCommentCount(a.code)));
    if (map.myCity != null) cities.insert(0, map.myCity!);

    // 搜索过滤
    final filtered = _search.trim().isEmpty
        ? cities
        : cities.where((c) =>
            c.name.contains(_search.trim()) ||
            c.province.contains(_search.trim())).toList();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async { await _map.initialize(); },
          child: CustomScrollView(
            slivers: [
              // 搜索条
              SliverToBoxAdapter(child: _searchBar(theme)),
              // 卡片网格
              filtered.isEmpty
                  ? SliverFillRemaining(hasScrollBody: false, child: _emptySearch(theme))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _cityCard(filtered[i], map, theme),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
              // 底部提示
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    '64 座城市 · 更多城市陆续开放中',
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

  Widget _searchBar(ThemeState theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor.withAlpha(180),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.borderColor.withAlpha(120)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: TextStyle(color: theme.textPrimary, fontSize: 14),
            cursorColor: theme.accentColor,
            decoration: InputDecoration(
              hintText: '搜城市...',
              hintStyle: TextStyle(color: theme.textTertiary, fontSize: 14),
              prefixIcon:
                  Icon(Icons.search, color: theme.textSecondary, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: theme.textSecondary, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      })
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
            color: _moodBg(mood, theme),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isMe ? const Color(0xFFFF9F1C) : theme.borderColor.withAlpha(80),
              width: isMe ? 2 : 0.5,
            ),
            boxShadow: isMe
                ? [BoxShadow(color: const Color(0xFFFF9F1C).withAlpha(30), blurRadius: 12)]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 城市名
              Row(children: [
                if (isMe) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F1C).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('当前', style: TextStyle(color: Color(0xFFFF9F1C), fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ],
                Text(city.name, style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (count > 0)
                  Text('$count', style: TextStyle(color: theme.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 2),
              Text(city.province, style: TextStyle(color: theme.textTertiary, fontSize: 11)),
              const SizedBox(height: 8),
              // 情绪描述
              Expanded(
                child: Text(
                  _moodLine(mood, city.name, count),
                  style: TextStyle(color: theme.textSecondary, fontSize: 11, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 空状态
              if (count == 0)
                Text('还没有足迹', style: TextStyle(color: theme.textTertiary.withAlpha(120), fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptySearch(ThemeState theme) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Column(children: [
        Icon(Icons.search_off, size: 48, color: theme.textTertiary),
        const SizedBox(height: 12),
        Text('没找到这个城市', style: TextStyle(color: theme.textSecondary, fontSize: 14)),
      ]),
    );
  }

  Color _moodBg(String? mood, ThemeState theme) {
    final c = switch (mood) {
      'warm' => const Color(0xFFF0A830),
      'sad' => const Color(0xFF7B9BB8),
      'anxious' => const Color(0xFFB090C8),
      'calm' => const Color(0xFF78B090),
      'excited' => const Color(0xFFF08848),
      _ => theme.borderColor,
    };
    return c.withAlpha(theme.isDark ? 25 : 18);
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
