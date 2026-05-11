import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';

const _wpKey = 'active_wallpaper';
const _unlockedKey = 'unlocked_wallpapers';

// ── Wallpaper registry (pure code, unlimited) ──
final wallpapers = [
  _WallpaperDef('none', '无', '关闭壁纸', _drawNone),
  _WallpaperDef('spring', '春樱', '签到7天解锁', _drawSpring),
  _WallpaperDef('summer', '夏夜', '签到14天解锁', _drawSummer),
  _WallpaperDef('autumn', '秋枫', '签到21天解锁', _drawAutumn),
  _WallpaperDef('winter', '冬雪', '签到30天解锁', _drawWinter),
  _WallpaperDef('midautumn', '中秋', '中秋节限定', _drawMidAutumn),
  _WallpaperDef('newyear', '新年', '春节限定', _drawNewYear),
  _WallpaperDef('fox', '小狐狸', '累计记录100天', _drawFoxPattern),
];

class _WallpaperDef {
  final String id, name, desc;
  final void Function(Canvas, Size, ThemeState) paint;
  const _WallpaperDef(this.id, this.name, this.desc, this.paint);
}

// ── Manager ──
class WallpaperManager extends ChangeNotifier {
  String _active = 'none';
  List<String> _unlocked = ['none'];

  String get active => _active;
  List<String> get unlocked => _unlocked;
  bool get enabled => _active != 'none';
  _WallpaperDef get current => wallpapers.firstWhere((w) => w.id == _active, orElse: () => wallpapers[0]);

  WallpaperManager() { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _active = p.getString(_wpKey) ?? 'none';
    _unlocked = (p.getStringList(_unlockedKey) ?? ['none']);
    notifyListeners();
  }

  Future<void> setWallpaper(String id) async {
    _active = id;
    final p = await SharedPreferences.getInstance();
    p.setString(_wpKey, id);
    notifyListeners();
  }

  Future<void> unlock(String id) async {
    if (_unlocked.contains(id)) return;
    _unlocked.add(id);
    final p = await SharedPreferences.getInstance();
    p.setStringList(_unlockedKey, _unlocked);
    notifyListeners();
  }
}

// ── Wallpaper Painter ──
class WallpaperPainter extends CustomPainter {
  final _WallpaperDef def;
  final ThemeState theme;
  const WallpaperPainter(this.def, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    def.paint(canvas, size, theme);
  }

  @override
  bool shouldRepaint(WallpaperPainter old) => old.def.id != def.id;
}

// ── Drawing functions ──

void _drawNone(Canvas c, Size s, ThemeState t) {
  // No wallpaper - plain background
}

void _drawSpring(Canvas c, Size s, ThemeState t) {
  // Pink gradient bg + cherry petals
  final bg = Paint()
    ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFF0F5).withAlpha(60), const Color(0xFFFFE4E1).withAlpha(30)]
    ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
  c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), bg);
  final rng = Random(12);
  for (int i = 0; i < 20; i++) {
    final x = rng.nextDouble() * s.width;
    final y = rng.nextDouble() * s.height;
    c.drawCircle(Offset(x, y), 3 + rng.nextDouble() * 5,
        Paint()..color = const Color(0xFFFFB7C5).withAlpha(30 + rng.nextInt(30)));
  }
}

void _drawSummer(Canvas c, Size s, ThemeState t) {
  final bg = Paint()
    ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFF1A237E).withAlpha(30), const Color(0xFF0D47A1).withAlpha(15)]
    ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
  c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), bg);
  // Firefly dots
  final rng = Random(6);
  for (int i = 0; i < 15; i++) {
    final x = rng.nextDouble() * s.width;
    final y = rng.nextDouble() * s.height * 0.7;
    c.drawCircle(Offset(x, y), 1.5, Paint()..color = const Color(0xFFFFF176).withAlpha(40));
  }
}

void _drawAutumn(Canvas c, Size s, ThemeState t) {
  final bg = Paint()
    ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFF3E0).withAlpha(60), const Color(0xFFFFE0B2).withAlpha(30)]
    ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
  c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), bg);
  final rng = Random(24);
  for (int i = 0; i < 12; i++) {
    final x = rng.nextDouble() * s.width;
    final y = rng.nextDouble() * s.height;
    c.drawCircle(Offset(x, y), 4 + rng.nextDouble() * 6,
        Paint()..color = const Color(0xFFE65100).withAlpha(15 + rng.nextInt(15)));
  }
}

void _drawWinter(Canvas c, Size s, ThemeState t) {
  final bg = Paint()
    ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFFE3F2FD).withAlpha(50), const Color(0xFFBBDEFB).withAlpha(25)]
    ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
  c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), bg);
  final rng = Random(36);
  for (int i = 0; i < 30; i++) {
    final x = rng.nextDouble() * s.width;
    final y = rng.nextDouble() * s.height;
    c.drawCircle(Offset(x, y), 2 + rng.nextDouble() * 3,
        Paint()..color = Colors.white.withAlpha(25 + rng.nextInt(25)));
  }
}

void _drawMidAutumn(Canvas c, Size s, ThemeState t) {
  final bg = Paint()
    ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFF1A237E).withAlpha(40), const Color(0xFF283593).withAlpha(20)]
    ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
  c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), bg);
  // Moon
  c.drawCircle(Offset(s.width * 0.78, s.height * 0.15), 45,
      Paint()..color = const Color(0xFFFFF9C4).withAlpha(50));
  c.drawCircle(Offset(s.width * 0.78, s.height * 0.15), 40,
      Paint()..color = const Color(0xFFFFFDE7).withAlpha(40));
}

void _drawNewYear(Canvas c, Size s, ThemeState t) {
  final bg = Paint()
    ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFFB71C1C).withAlpha(30), const Color(0xFF880E4F).withAlpha(15)]
    ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
  c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), bg);
  final rng = Random(88);
  for (int i = 0; i < 25; i++) {
    final x = rng.nextDouble() * s.width;
    final y = rng.nextDouble() * s.height;
    c.drawCircle(Offset(x, y), 1.5 + rng.nextDouble() * 3,
        Paint()..color = const Color(0xFFFFD54F).withAlpha(15 + rng.nextInt(20)));
  }
}

void _drawFoxPattern(Canvas c, Size s, ThemeState t) {
  final bg = Paint()
    ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFF8E1).withAlpha(40), const Color(0xFFFFECB3).withAlpha(20)]
    ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
  c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), bg);
  // Small fox paw prints
  final rng = Random(7);
  for (int i = 0; i < 10; i++) {
    final x = rng.nextDouble() * s.width;
    final y = rng.nextDouble() * s.height;
    c.drawCircle(Offset(x, y), 3, Paint()..color = const Color(0xFFD4A85C).withAlpha(20));
    c.drawCircle(Offset(x + 8, y), 2.5, Paint()..color = const Color(0xFFD4A85C).withAlpha(20));
    c.drawCircle(Offset(x + 16, y), 2, Paint()..color = const Color(0xFFD4A85C).withAlpha(20));
  }
}
