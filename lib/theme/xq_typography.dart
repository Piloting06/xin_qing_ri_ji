import 'package:flutter/material.dart';

/// 拾晴日记 — 字体系统
/// 全局字体：LXGW WenKai（霞鹜文楷）
/// 已在 pubspec.yaml 注册，此处所有 TextStyle 统一声明 fontFamily
class XqTypography {
  XqTypography._();

  static const _ff = 'LXGW WenKai';

  // ── Display ──
  static const displayLarge = TextStyle(
    fontFamily: _ff,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 2.0,
  );
  static const displayMedium = TextStyle(
    fontFamily: _ff,
    fontSize: 26,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
  );
  static const displaySmall = TextStyle(
    fontFamily: _ff,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
  );

  // ── Headline ──
  static const headlineLarge = TextStyle(
    fontFamily: _ff,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
  static const headlineMedium = TextStyle(
    fontFamily: _ff,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  static const headlineSmall = TextStyle(
    fontFamily: _ff,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // ── Body ──
  static const bodyLarge = TextStyle(
    fontFamily: _ff,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _ff,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
  static const bodySmall = TextStyle(
    fontFamily: _ff,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ── Label ──
  static const labelLarge = TextStyle(
    fontFamily: _ff,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
  static const labelMedium = TextStyle(
    fontFamily: _ff,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );
  static const labelSmall = TextStyle(
    fontFamily: _ff,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  // ── Button ──
  static const button = TextStyle(
    fontFamily: _ff,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  // ── 专用样式 ──
  static const handwrittenBody = TextStyle(
    fontFamily: _ff,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.9,
    letterSpacing: 0.3,
  );
  static const splashTitle = TextStyle(
    fontFamily: _ff,
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: 4.0,
  );
}
