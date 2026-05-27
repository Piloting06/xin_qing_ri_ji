import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'xq_colors.dart';
import 'xq_typography.dart';

/// 拾晴日记 — ThemeData 构建器
/// 按主题模式动态生成 ThemeData，确保输入框/按钮/AppBar 等 M3 组件跟随主题变色
class XqTheme {
  XqTheme._();

  /// 根据模式返回对应 ThemeData
  static ThemeData forMode(String mode) {
    if (mode == 'dark') return _dark();
    final bg = _bg(mode);
    final card = _card(mode);
    final accent = _accent(mode);
    final border = _border(mode);
    final focus = _focus(mode);
    final text1 = _textPrimary(mode);
    final text2 = _textSecondary(mode);
    final text3 = _textTertiary(mode);
    final onAccent = _textOnAccent(mode);
    final error = _error(mode);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: _accentLight(mode),
        surface: card,
        error: error,
        onPrimary: onAccent,
        onSecondary: text1,
        onSurface: text1,
      ),
      fontFamily: '',
      textTheme: const TextTheme(
        displayLarge: XqTypography.displayLarge,
        displayMedium: XqTypography.displayMedium,
        displaySmall: XqTypography.displaySmall,
        headlineLarge: XqTypography.headlineLarge,
        headlineMedium: XqTypography.headlineMedium,
        headlineSmall: XqTypography.headlineSmall,
        bodyLarge: XqTypography.bodyLarge,
        bodyMedium: XqTypography.bodyMedium,
        bodySmall: XqTypography.bodySmall,
        labelLarge: XqTypography.labelLarge,
        labelMedium: XqTypography.labelMedium,
        labelSmall: XqTypography.labelSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: focus, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: card,
        hintStyle: XqTypography.bodyMedium.copyWith(color: text3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: XqTypography.labelLarge,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: XqTypography.headlineMedium.copyWith(color: text1),
        iconTheme: IconThemeData(color: text1),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 0.5,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: XqTypography.bodyMedium.copyWith(color: text1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: XqTypography.headlineMedium.copyWith(color: text1),
        contentTextStyle: XqTypography.bodyMedium.copyWith(color: text2),
      ),
    );
  }

  // ── Legacy compat (used by existing code that calls XqTheme.light() / XqTheme.dark()) ──

  static ThemeData light() => forMode('warm');
  static ThemeData dark() => _dark();

  static ThemeData _dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: XqColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: XqColors.darkAccent,
        secondary: XqColors.darkAccentLight,
        surface: XqColors.darkCard,
        error: XqColors.darkError,
        onPrimary: XqColors.darkTextOnAccent,
        onSecondary: XqColors.darkTextPrimary,
        onSurface: XqColors.darkTextPrimary,
      ),
      fontFamily: '',
      textTheme: TextTheme(
        displayLarge: XqTypography.displayLarge.copyWith(color: XqColors.darkTextPrimary),
        displayMedium: XqTypography.displayMedium.copyWith(color: XqColors.darkTextPrimary),
        displaySmall: XqTypography.displaySmall.copyWith(color: XqColors.darkTextPrimary),
        headlineLarge: XqTypography.headlineLarge.copyWith(color: XqColors.darkTextPrimary),
        headlineMedium: XqTypography.headlineMedium.copyWith(color: XqColors.darkTextPrimary),
        headlineSmall: XqTypography.headlineSmall.copyWith(color: XqColors.darkTextPrimary),
        bodyLarge: XqTypography.bodyLarge.copyWith(color: XqColors.darkTextPrimary),
        bodyMedium: XqTypography.bodyMedium.copyWith(color: XqColors.darkTextPrimary),
        bodySmall: XqTypography.bodySmall.copyWith(color: XqColors.darkTextSecondary),
        labelLarge: XqTypography.labelLarge.copyWith(color: XqColors.darkTextPrimary),
        labelMedium: XqTypography.labelMedium.copyWith(color: XqColors.darkTextSecondary),
        labelSmall: XqTypography.labelSmall.copyWith(color: XqColors.darkTextTertiary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: XqColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: XqColors.darkBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: XqColors.darkBorderFocus, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: XqColors.darkCard,
        hintStyle: XqTypography.bodyMedium.copyWith(color: XqColors.darkTextTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: XqColors.darkAccent,
          foregroundColor: XqColors.darkTextOnAccent,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: XqTypography.labelLarge,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: XqTypography.headlineMedium.copyWith(color: XqColors.darkTextPrimary),
        iconTheme: const IconThemeData(color: XqColors.darkTextPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: XqColors.darkBorder,
        thickness: 0.5,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: XqColors.darkCard,
        contentTextStyle: XqTypography.bodyMedium.copyWith(color: XqColors.darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: XqColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: XqTypography.headlineMedium.copyWith(color: XqColors.darkTextPrimary),
        contentTextStyle: XqTypography.bodyMedium.copyWith(color: XqColors.darkTextSecondary),
      ),
    );
  }

  // ── Color resolvers ──

  static Color _bg(String m) => switch (m) {
    'mint' => XqColors.mintBackground,
    'blush' => XqColors.blushBackground,
    _ => XqColors.lightBackground,
  };
  static Color _card(String m) => switch (m) {
    'mint' => XqColors.mintCard,
    'blush' => XqColors.blushCard,
    _ => XqColors.lightCard,
  };
  static Color _accent(String m) => switch (m) {
    'mint' => XqColors.mintAccent,
    'blush' => XqColors.blushAccent,
    _ => XqColors.lightAccent,
  };
  static Color _accentLight(String m) => switch (m) {
    'mint' => XqColors.mintAccentLight,
    'blush' => XqColors.blushAccentLight,
    _ => XqColors.lightAccentLight,
  };
  static Color _border(String m) => switch (m) {
    'mint' => XqColors.mintBorder,
    'blush' => XqColors.blushBorder,
    _ => XqColors.lightBorder,
  };
  static Color _focus(String m) => switch (m) {
    'mint' => XqColors.mintBorderFocus,
    'blush' => XqColors.blushBorderFocus,
    _ => XqColors.lightBorderFocus,
  };
  static Color _textPrimary(String m) => switch (m) {
    'mint' => XqColors.mintTextPrimary,
    'blush' => XqColors.blushTextPrimary,
    _ => XqColors.lightTextPrimary,
  };
  static Color _textSecondary(String m) => switch (m) {
    'mint' => XqColors.mintTextSecondary,
    'blush' => XqColors.blushTextSecondary,
    _ => XqColors.lightTextSecondary,
  };
  static Color _textTertiary(String m) => switch (m) {
    'mint' => XqColors.mintTextTertiary,
    'blush' => XqColors.blushTextTertiary,
    _ => XqColors.lightTextTertiary,
  };
  static Color _textOnAccent(String m) => const Color(0xFFFFFFFF);
  static Color _error(String _) => XqColors.lightError;
}
