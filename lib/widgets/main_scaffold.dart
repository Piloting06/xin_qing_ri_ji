import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../services/notification_service.dart';
import '../stores/theme_state.dart';
import '../stores/app_state.dart';
import '../pages/home_page.dart';
import '../pages/mood_page.dart';
import '../pages/city_map_page.dart';
import '../pages/profile_page.dart';
import '../pages/login_page.dart';
import 'onboarding_flow.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;

  const MainScaffold({super.key, this.initialIndex = 0});

  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainScaffoldState>();
    state?.goToTab(index);
  }

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;
  late final PageController _pageController;
  bool _onboardingChecked = false;
  bool _lockoutHandled = false;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_onboardingChecked && mounted) {
        _onboardingChecked = true;
        OnboardingFlow.checkAndShow(context);
      }
      _rescheduleCapsuleReminders();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _rescheduleCapsuleReminders() async {
    try {
      final data = await Api.getCapsuleList();
      final capsules = data['capsules'] as List? ?? [];
      for (final c in capsules) {
        if (c is! Map) continue;
        if (c['is_opened'] == 1) continue;
        final id = c['id'];
        final openDate = c['open_date']?.toString();
        final content = c['content']?.toString() ?? '';
        if (id == null || openDate == null) continue;
        await NotificationService.scheduleCapsuleReminder(
          capsuleId: id is int ? id : int.tryParse(id.toString()) ?? 0,
          openDate: openDate,
          preview: content.length > 36
              ? '${content.substring(0, 36)}...'
              : content,
        );
      }
    } catch (_) {}
  }

  void goToTab(int i) {
    if (_currentIndex == i) return;
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() => _currentIndex = i);
  }

  void _onTabTap(int i) {
    if (_currentIndex == i) return;
    goToTab(i);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final appState = context.watch<AppState>();

    final overlayStyle = SystemUiOverlayStyle(
      systemNavigationBarColor: theme.backgroundColor,
      systemNavigationBarDividerColor: theme.backgroundColor,
      systemNavigationBarIconBrightness: theme.isDark
          ? Brightness.light
          : Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark
          ? Brightness.light
          : Brightness.dark,
    );

    if (appState.isLockedOut && !_lockoutHandled) {
      _lockoutHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('登录已过期，请重新登录')),
        );
      });
    }

    final bottomInsets = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // 不在首页 tab → 切回首页
        if (_currentIndex != 0) {
          goToTab(0);
          return;
        }
        // 在首页 → 双击返回退出
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.exit_to_app_rounded, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    '再按一次退出',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              backgroundColor: theme.textPrimary.withAlpha(160),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.fromLTRB(
                80, 0, 80, 16 + MediaQuery.of(context).padding.bottom,
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(child: Container(color: theme.backgroundColor)),
            Padding(
              padding: EdgeInsets.only(bottom: 70 + bottomInsets),
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                children: const [
                  HomePage(),
                  MoodPage(),
                  CityMapPage(),
                  ProfilePage(),
                ],
              ),
            ),
            if (theme.transitioning)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 0.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Container(
                      color: theme.accentColor.withAlpha((value * 120).round()),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 6 + bottomInsets,
              left: 0,
              right: 0,
              child: Center(
                child: _FrostedCapsule(
                  currentIndex: _currentIndex,
                  theme: theme,
                  onTap: _onTabTap,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// 毛玻璃悬浮胶囊导航栏
class _FrostedCapsule extends StatefulWidget {
  final int currentIndex;
  final ThemeState theme;
  final Function(int) onTap;

  const _FrostedCapsule({
    required this.currentIndex,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_FrostedCapsule> createState() => _FrostedCapsuleState();
}

class _FrostedCapsuleState extends State<_FrostedCapsule>
    with SingleTickerProviderStateMixin {
  static const _icons = [
    _TabIcon(Icons.wb_sunny_outlined, Icons.wb_sunny),
    _TabIcon(Icons.favorite_border, Icons.favorite),
    _TabIcon(Icons.explore_outlined, Icons.explore),
    _TabIcon(Icons.person_outline, Icons.person),
  ];
  static const _labels = ['天气', '心情', '城迹', '我的'];

  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceTranslate;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));

    _bounceTranslate = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 0.3),
      TweenSequenceItem(tween: Tween(begin: -6, end: 2), weight: 0.5),
      TweenSequenceItem(tween: Tween(begin: 2, end: 0), weight: 0.2),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _onCapsuleTap() {
    if (_bounceCtrl.isAnimating) return;
    HapticFeedback.selectionClick();
    _bounceCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _bounceTranslate.value),
        child: child,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onCapsuleTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: t.isDark
                    ? const Color(0xFF0E1222).withAlpha(120)
                    : t.backgroundColor.withAlpha(140),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: t.borderColor.withAlpha(40),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_icons.length, (i) {
                  final active = widget.currentIndex == i;
                  return _CapsuleTabItem(
                    icon: _icons[i],
                    label: _labels[i],
                    active: active,
                    accentColor: t.accentColor,
                    inactiveColor: t.textSecondary,
                    onTap: () => widget.onTap(i),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIcon {
  final IconData outlined;
  final IconData filled;
  const _TabIcon(this.outlined, this.filled);
}

class _CapsuleTabItem extends StatelessWidget {
  final _TabIcon icon;
  final String label;
  final bool active;
  final Color accentColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _CapsuleTabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.accentColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? accentColor : inactiveColor;

    return Semantics(
      label: label,
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, active ? -2 : 0, 0),
          child: SizedBox(
            width: 64,
            height: 52,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: active ? 54 : 44,
                height: active ? 48 : 44,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? accentColor.withAlpha(24) : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: active ? accentColor.withAlpha(70) : Colors.transparent,
                    width: 0.8,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: accentColor.withAlpha(65),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
                      child: Icon(
                        active ? icon.filled : icon.outlined,
                        key: ValueKey('${label}_$active'),
                        size: 22,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: color,
                      ),
                      child: Text(label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
