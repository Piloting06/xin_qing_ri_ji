import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../stores/theme_state.dart';
import '../pages/home_page.dart';
import 'wallpaper_manager.dart';
import '../pages/mood_page.dart';
import '../pages/treehole_page.dart';
import '../pages/friends_page.dart';
import '../pages/profile_page.dart';
import 'onboarding_flow.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _onboardingChecked = false;
  String _activeWallpaper = 'none';
  List<String> _unlocked = ['none'];

  @override
  void initState() {
    super.initState();
    _loadWallpaper();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_onboardingChecked && mounted) {
        _onboardingChecked = true;
        OnboardingFlow.checkAndShow(context);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadWallpaper() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() {
      _activeWallpaper = p.getString('active_wallpaper') ?? 'none';
      _unlocked = p.getStringList('unlocked_wallpapers') ?? ['none'];
    });
  }


  static const _tabs = [
    _TabData('天气', Icons.wb_sunny_outlined, Icons.wb_sunny),
    _TabData('心情', Icons.favorite_border, Icons.favorite),
    _TabData('树洞', Icons.forest_outlined, Icons.forest),
    _TabData('友人', Icons.people_outline, Icons.people),
    _TabData('我的', Icons.person_outline, Icons.person),
  ];

  final _pages = const [
    HomePage(),
    MoodPage(),
    TreeholePage(),
    FriendsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final isDark = theme.isDark;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          // Wallpaper layer
          if (_activeWallpaper != 'none')
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: WallpaperPainter(
                    wallpapers.firstWhere((w) => w.id == _activeWallpaper),
                    theme,
                  ),
                ),
              ),
            ),
          // Content with swipeable pages
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: _pages,
          ),
          // Dissolve transition overlay
          if (theme.transitioning)
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 0.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (_, v, __) => Opacity(
                  opacity: v,
                  child: Container(color: theme.accentColor.withAlpha((v * 120).round())),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0A0A0A).withAlpha(240)
              : const Color(0xFFFAF8F4).withAlpha(240),
          border: Border(
              top: BorderSide(
                  color: isDark
                      ? Colors.white.withAlpha(12)
                      : Colors.black.withAlpha(10))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final active = _currentIndex == i;
                return _TabItem(
                  tab: _tabs[i],
                  active: active,
                  theme: theme,
                  onTap: () {
                    if (_currentIndex != i) {
                      HapticFeedback.lightImpact();
                      _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      setState(() => _currentIndex = i);
                    }
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabData {
  final String label;
  final IconData iconOutlined;
  final IconData iconFilled;

  const _TabData(this.label, this.iconOutlined, this.iconFilled);
}

class _TabItem extends StatelessWidget {
  final _TabData tab;
  final bool active;
  final ThemeState theme;
  final VoidCallback onTap;

  const _TabItem({
    required this.tab,
    required this.active,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? theme.accentColor : theme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim, child: child),
              child: Icon(
                active ? tab.iconFilled : tab.iconOutlined,
                key: ValueKey(active),
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            TweenAnimationBuilder<double>(
              tween:
                  Tween(begin: active ? 0.8 : 1.0, end: active ? 1.0 : 0.8),
              duration: const Duration(milliseconds: 200),
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: Text(tab.label,
                    style: TextStyle(fontSize: 10, color: color)),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
