import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/keys.dart';

class ThemeState extends ChangeNotifier {
  String _themeMode = 'light';
  bool _transitioning = false;

  bool get transitioning => _transitioning;

  static const Map<String, String> themeNames = {
    'light': '暖白基础',
    'green': '护眼柔绿',
    'dark': '深夜暗金',
  };

  static const Map<String, List<Color>> themeColors = {
    'light': [Color(0xFFC4A46C), Color(0xFFF0EDE6), Color(0xFFFAF8F4)],
    'green': [Color(0xFF6B8F71), Color(0xFFF5F9F3), Color(0xFFE8F0E5)],
    'dark': [Color(0xFFA08050), Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
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
  bool get isGreen => _themeMode == 'green';
  bool get isLight => _themeMode == 'light';

  Color get backgroundColor {
    switch (_themeMode) {
      case 'dark': return const Color(0xFF0A0A0A);
      case 'green': return const Color(0xFFF5F9F3);
      default: return const Color(0xFFFAF8F4);
    }
  }

  Color get cardColor {
    switch (_themeMode) {
      case 'dark': return const Color(0xFF1A1A1A);
      case 'green': return const Color(0xFFE8F0E5);
      default: return Colors.white;
    }
  }

  Color get accentColor {
    switch (_themeMode) {
      case 'dark': return const Color(0xFFA08050);
      case 'green': return const Color(0xFF6B8F71);
      default: return const Color(0xFFC4A46C);
    }
  }

  Color get textPrimary {
    switch (_themeMode) {
      case 'dark': return const Color(0xFFD0CDC6);
      case 'green': return const Color(0xFF1C2E1C);
      default: return const Color(0xFF2A2218);
    }
  }

  Color get textSecondary {
    switch (_themeMode) {
      case 'dark': return const Color(0xFFA09888);
      case 'green': return const Color(0xFF6B8F71);
      default: return const Color(0xFF8C7E6F);
    }
  }

  Color get borderColor {
    switch (_themeMode) {
      case 'dark': return Colors.white.withAlpha(20);
      case 'green': return Colors.black.withAlpha(15);
      default: return Colors.black.withAlpha(15);
    }
  }

  Color get surfaceAlpha {
    switch (_themeMode) {
      case 'dark': return Colors.white.withAlpha(10);
      case 'green': return Colors.black.withAlpha(8);
      default: return Colors.black.withAlpha(5);
    }
  }
}
