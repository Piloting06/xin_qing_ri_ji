import 'package:flutter/material.dart';

/// 心晴日记 — 动画时间常量和曲线
class XqAnimations {
  XqAnimations._();

  // ── 时长 ──
  static const durationFast = Duration(milliseconds: 150);
  static const durationNormal = Duration(milliseconds: 300);
  static const durationSlow = Duration(milliseconds: 500);
  static const durationSplash = Duration(milliseconds: 3500);

  // ── 曲线 ──
  static const curveDefault = Curves.easeOut;
  static const curveBouncy = Curves.easeOutBack;
  static const curveSmooth = Curves.easeInOutCubic;
  static const curveSpring = Curves.elasticOut;
}
