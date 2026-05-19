import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../pages/home_page.dart';
import '../pages/mood_page.dart';
import '../pages/treehole_page.dart';
import '../pages/friends_page.dart';
import '../pages/profile_page.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _pageController = PageController(initialPage: _currentIndex);
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
    goToTab(i);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          // Content pages — 底部 padding 防止胶囊遮挡
          Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              children: const [
                HomePage(),
                MoodPage(),
                TreeholePage(),
                FriendsPage(),
                ProfilePage(),
              ],
            ),
          ),
          // Dissolve transition overlay
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
          // 毛玻璃悬浮胶囊
          Positioned(
            bottom: 6,
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
    );
  }
}

/// 毛玻璃悬浮胶囊导航栏
class _FrostedCapsule extends StatelessWidget {
  final int currentIndex;
  final ThemeState theme;
  final Function(int) onTap;

  const _FrostedCapsule({
    required this.currentIndex,
    required this.theme,
    required this.onTap,
  });

  static const _icons = [
    _TabIcon(Icons.wb_sunny_outlined, Icons.wb_sunny),
    _TabIcon(Icons.favorite_border, Icons.favorite),
    _TabIcon(Icons.forest_outlined, Icons.forest),
    _TabIcon(Icons.people_outline, Icons.people),
    _TabIcon(Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor.withAlpha(200),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.borderColor, width: 0.5),
            boxShadow: XqDecorations.shadowMedium(dark: theme.isDark),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_icons.length, (i) {
              final active = currentIndex == i;
              return _CapsuleTabItem(
                icon: _icons[i],
                active: active,
                accentColor: theme.accentColor,
                inactiveColor: theme.textSecondary,
                onTap: () => onTap(i),
              );
            }),
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
  final bool active;
  final Color accentColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _CapsuleTabItem({
    required this.icon,
    required this.active,
    required this.accentColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? accentColor : inactiveColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Icon(
                  active ? icon.filled : icon.outlined,
                  key: ValueKey(active),
                  size: 22,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // 墨点指示器
            AnimatedOpacity(
              opacity: active ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
