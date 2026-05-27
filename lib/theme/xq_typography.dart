import 'package:flutter/material.dart';

/// 心晴日记 — 字体系统
/// 标题/手写：LXGW WenKai（霞鹜文楷）
/// 正文：系统默认字体
class XqTypography {
  XqTypography._();

  // ── Display ──
  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 2.0,
  );
  static const displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
  );
  static const displaySmall = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
  );

  // ── Headline ──
  static const headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  static const headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  static const headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  // ── Body ──
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.8,
  );
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ── Label ──
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );
  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  // ── 专用样式 ──
  static const handwrittenBody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.9,
    letterSpacing: 0.3,
  );
  static const splashTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: 4.0,
  );
}
