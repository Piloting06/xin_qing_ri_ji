import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/keys.dart';
import '../theme/xq_colors.dart';

class ThemeState extends ChangeNotifier {
  String _themeMode = 'warm';
  bool _transitioning = false;

  bool get transitioning => _transitioning;
  String get themeMode => _themeMode;
  bool get isDark => _themeMode == 'dark';

  static const Map<String, String> themeNames = {
    'warm': '晴日暖白',
    'dark': '静夜深蓝',
    'mint': '雾感薄荷',
    'blush': '豆沙柔粉',
  };

  static const Map<String, List<Color>> themeColors = {
    'warm': [XqColors.lightAccent, XqColors.lightCard, XqColors.lightBackground],
    'dark': [XqColors.darkAccent, XqColors.darkCard, XqColors.darkBackground],
    'mint': [XqColors.mintAccent, XqColors.mintCard, XqColors.mintBackground],
    'blush': [XqColors.blushAccent, XqColors.blushCard, XqColors.blushBackground],
  };

  ThemeState() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(StorageKeys.themeMode) ?? 'warm';
    // Migrate old 'light' → 'warm'
    final normalized = stored == 'light' ? 'warm' : stored;
    _themeMode = themeNames.containsKey(normalized) ? normalized : 'warm';
    if (_themeMode != stored) {
      await prefs.setString(StorageKeys.themeMode, _themeMode);
    }
    notifyListeners();
  }

  Future<void> setTheme(String mode) async {
    final next = themeNames.containsKey(mode) ? mode : 'warm';
    if (_themeMode == next) return;
    _transitioning = true;
    _themeMode = next;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(StorageKeys.themeMode, next);
    });
    await Future.delayed(const Duration(milliseconds: 280));
    _transitioning = false;
    notifyListeners();
  }

  // ── Color getters indexed by theme ──

  Color get backgroundColor => switch (_themeMode) {
    'dark' => XqColors.darkBackground,
    'mint' => XqColors.mintBackground,
    'blush' => XqColors.blushBackground,
    _ => XqColors.lightBackground,
  };

  Color get cardColor => switch (_themeMode) {
    'dark' => XqColors.darkCard,
    'mint' => XqColors.mintCard,
    'blush' => XqColors.blushCard,
    _ => XqColors.lightCard,
  };

  Color get cardElevated => switch (_themeMode) {
    'dark' => XqColors.darkCardElevated,
    'mint' => XqColors.mintCardElevated,
    'blush' => XqColors.blushCardElevated,
    _ => XqColors.lightCardElevated,
  };

  Color get accentColor => switch (_themeMode) {
    'dark' => XqColors.darkAccent,
    'mint' => XqColors.mintAccent,
    'blush' => XqColors.blushAccent,
    _ => XqColors.lightAccent,
  };

  Color get accentLight => switch (_themeMode) {
    'dark' => XqColors.darkAccentLight,
    'mint' => XqColors.mintAccentLight,
    'blush' => XqColors.blushAccentLight,
    _ => XqColors.lightAccentLight,
  };

  Color get accentMuted => switch (_themeMode) {
    'dark' => XqColors.darkAccentMuted,
    'mint' => XqColors.mintAccentMuted,
    'blush' => XqColors.blushAccentMuted,
    _ => XqColors.lightAccentMuted,
  };

  Color get textPrimary => switch (_themeMode) {
    'dark' => XqColors.darkTextPrimary,
    'mint' => XqColors.mintTextPrimary,
    'blush' => XqColors.blushTextPrimary,
    _ => XqColors.lightTextPrimary,
  };

  Color get textSecondary => switch (_themeMode) {
    'dark' => XqColors.darkTextSecondary,
    'mint' => XqColors.mintTextSecondary,
    'blush' => XqColors.blushTextSecondary,
    _ => XqColors.lightTextSecondary,
  };

  Color get textTertiary => switch (_themeMode) {
    'dark' => XqColors.darkTextTertiary,
    'mint' => XqColors.mintTextTertiary,
    'blush' => XqColors.blushTextTertiary,
    _ => XqColors.lightTextTertiary,
  };

  Color get textOnAccent => switch (_themeMode) {
    'dark' => XqColors.darkTextOnAccent,
    _ => XqColors.lightTextOnAccent, // all light themes use white text on accent
  };

  Color get borderColor => switch (_themeMode) {
    'dark' => XqColors.darkBorder,
    'mint' => XqColors.mintBorder,
    'blush' => XqColors.blushBorder,
    _ => XqColors.lightBorder,
  };

  Color get borderFocus => switch (_themeMode) {
    'dark' => XqColors.darkBorderFocus,
    'mint' => XqColors.mintBorderFocus,
    'blush' => XqColors.blushBorderFocus,
    _ => XqColors.lightBorderFocus,
  };

  Color get errorColor => switch (_themeMode) {
    'dark' => XqColors.darkError,
    _ => XqColors.lightError,
  };

  Color get successColor => switch (_themeMode) {
    'dark' => XqColors.darkSuccess,
    _ => XqColors.lightSuccess,
  };

  Color get warningColor => switch (_themeMode) {
    'dark' => XqColors.darkWarning,
    _ => XqColors.lightWarning,
  };

  Color get ink => switch (_themeMode) {
    'dark' => XqColors.darkInk,
    'mint' => XqColors.mintInk,
    'blush' => XqColors.blushInk,
    _ => XqColors.lightInk,
  };

  Color get inkLight => switch (_themeMode) {
    'dark' => XqColors.darkInkLight,
    'mint' => XqColors.mintInkLight,
    'blush' => XqColors.blushInkLight,
    _ => XqColors.lightInkLight,
  };

  Color get gold => switch (_themeMode) {
    'dark' => XqColors.darkGold,
    'mint' => XqColors.mintGold,
    'blush' => XqColors.blushGold,
    _ => XqColors.lightGold,
  };

  Color get paperLine => switch (_themeMode) {
    'dark' => XqColors.darkPaperLine,
    'mint' => XqColors.mintPaperLine,
    'blush' => XqColors.blushPaperLine,
    _ => XqColors.lightPaperLine,
  };

  Color get surfaceAlpha => switch (_themeMode) {
    'dark' => Colors.white.withAlpha(12),
    'mint' => XqColors.mintAccent.withAlpha(20),
    'blush' => XqColors.blushAccent.withAlpha(20),
    _ => XqColors.lightAccent.withAlpha(20),
  };

  List<Color> get washiColors => switch (_themeMode) {
    'dark' => [XqColors.darkWashi1, XqColors.darkWashi2, XqColors.darkWashi3, XqColors.darkWashi4],
    'mint' => [XqColors.mintWashi1, XqColors.mintWashi2, XqColors.mintWashi3, XqColors.mintWashi4],
    'blush' => [XqColors.blushWashi1, XqColors.blushWashi2, XqColors.blushWashi3, XqColors.blushWashi4],
    _ => [XqColors.lightWashi1, XqColors.lightWashi2, XqColors.lightWashi3, XqColors.lightWashi4],
  };
}
