import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/keys.dart';

class ThemeState extends ChangeNotifier {
  String _themeMode = 'light';
  bool _transitioning = false;

  bool get transitioning => _transitioning;

  static const Map<String, String> themeNames = {
    'light': '亚麻暖白',
    'green': '抹茶淡绿',
    'dark': '暮色暖灰',
  };

  // [accent, card, background]
  static const Map<String, List<Color>> themeColors = {
    'light': [Color(0xFF8B7355), Color(0xFFFAF7F2), Color(0xFFF5F0E8)],
    'green': [Color(0xFF7B8D6E), Color(0xFFF6F8F3), Color(0xFFF0F3EB)],
    'dark': [Color(0xFFB8956A), Color(0xFF363430), Color(0xFF2A2824)],
  };

  String get themeMode => _themeMode;

  ThemeState() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getString(StorageKeys.themeMode) ?? 'light';
    notifyListeners();
  }

  Future<void> setTheme(String mode) async {
    if (_themeMode == mode) return;
    _transitioning = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(StorageKeys.themeMode, mode);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _transitioning = false;
    notifyListeners();
  }

  bool get isDark => _themeMode == 'dark';

  // ── 亚麻暖白 (linen light) ──
  // ── 抹茶淡绿 (matcha green) ──
  // ── 暮色暖灰 (dusk dark) ──

  Color get backgroundColor {
    switch (_themeMode) {
      case 'dark': return const Color(0xFF2A2824);
      case 'green': return const Color(0xFFF0F3EB);
      default: return const Color(0xFFF5F0E8);
    }
  }

  Color get cardColor {
    switch (_themeMode) {
      case 'dark': return const Color(0xFF363430);
      case 'green': return const Color(0xFFF6F8F3);
      default: return const Color(0xFFFAF7F2);
    }
  }

  Color get accentColor {
    switch (_themeMode) {
      case 'dark': return const Color(0xFFB8956A);
      case 'green': return const Color(0xFF7B8D6E);
      default: return const Color(0xFF8B7355);
    }
  }

  Color get textPrimary {
    switch (_themeMode) {
      case 'dark': return const Color(0xFFE5DDD3);
      case 'green': return const Color(0xFF2C3328);
      default: return const Color(0xFF3D3228);
    }
  }

  Color get textSecondary {
    switch (_themeMode) {
      case 'dark': return const Color(0xFF9B8E80);
      case 'green': return const Color(0xFF7B8D6E);
      default: return const Color(0xFF8C7E6F);
    }
  }

  Color get borderColor {
    switch (_themeMode) {
      case 'dark': return Colors.white.withAlpha(25);
      case 'green': return const Color(0xFF8B9B80).withAlpha(50);
      default: return const Color(0xFF8B7355).withAlpha(40);
    }
  }

  Color get surfaceAlpha {
    switch (_themeMode) {
      case 'dark': return Colors.white.withAlpha(10);
      case 'green': return const Color(0xFF7B8D6E).withAlpha(12);
      default: return const Color(0xFF8B7355).withAlpha(8);
    }
  }
}
