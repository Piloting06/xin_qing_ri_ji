import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/app_state.dart';

/// 可复用光效包装组件 — 为任何可点击元素添加 3 层光效
///
/// 使用方式：
/// ```dart
/// GlowWrap(
///   accentColor: theme.accentColor,
///   radius: 40,
///   onTap: () => ...,
///   child: MyChip(),
/// )
/// ```
class GlowWrap extends StatefulWidget {
  final Widget child;
  final Color accentColor;
  final double radius;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  /// 触摸时最大 alpha（默认 140）
  final double touchAlphaMax;

  /// 点击波纹最大 alpha（默认 100）
  final double rippleAlphaMax;

  const GlowWrap({
    super.key,
    required this.child,
    required this.accentColor,
    this.radius = 40,
    this.borderRadius,
    this.onTap,
    this.touchAlphaMax = 140,
    this.rippleAlphaMax = 100,
  });

  @override
  State<GlowWrap> createState() => _GlowWrapState();
}

class _GlowWrapState extends State<GlowWrap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleCtrl;
  late final Animation<double> _rippleRadiusAnim;
  late final Animation<double> _rippleAlphaAnim;

  double _glowX = 0;
  double _glowY = 0;
  double _touchAlpha = 0;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _rippleRadiusAnim = Tween<double>(begin: 5, end: 80).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOutCubic),
    );
    _rippleAlphaAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    HapticFeedback.lightImpact();
    setState(() {
      _glowX = event.localPosition.dx;
      _glowY = event.localPosition.dy;
      _touchAlpha = widget.touchAlphaMax;
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      _glowX = event.localPosition.dx;
      _glowY = event.localPosition.dy;
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _touchAlpha = 0;
    });
    _rippleCtrl.forward(from: 0);
  }

  void _onTap() {
    HapticFeedback.mediumImpact();
    _rippleCtrl.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final animActive = context.watch<AppState>().animActive;

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.translucent,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: Stack(
            children: [
              // 光效层
              if (animActive)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _rippleCtrl,
                    builder: (context, _) => CustomPaint(
                      painter: _GlowPainter(
                        glowX: _glowX,
                        glowY: _glowY,
                        touchAlpha: _touchAlpha,
                        accentColor: widget.accentColor,
                        radius: widget.radius,
                        rippleRadius: _rippleRadiusAnim.value,
                        rippleAlpha:
                            _rippleAlphaAnim.value * widget.rippleAlphaMax,
                      ),
                    ),
                  ),
                ),
              // 内容层
              RepaintBoundary(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double glowX;
  final double glowY;
  final double touchAlpha;
  final Color accentColor;
  final double radius;
  final double rippleRadius;
  final double rippleAlpha;

  _GlowPainter({
    required this.glowX,
    required this.glowY,
    required this.touchAlpha,
    required this.accentColor,
    required this.radius,
    this.rippleRadius = 0,
    this.rippleAlpha = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Layer 1: 触摸追踪光
    if (touchAlpha > 1) {
      canvas.drawCircle(
        Offset(glowX, glowY),
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              accentColor.withAlpha(touchAlpha.round().clamp(0, 255)),
              accentColor.withAlpha((touchAlpha * 0.4).round().clamp(0, 255)),
              accentColor.withAlpha(0),
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(Rect.fromCircle(
            center: Offset(glowX, glowY),
            radius: radius,
          )),
      );
    }

    // Layer 2: 点击扩散波纹
    if (rippleAlpha > 1 && rippleRadius > 0) {
      final clamped = math.min(rippleRadius, math.max(size.width, size.height));
      final ringWidth = 15.0;
      final inner = (clamped - ringWidth).clamp(0.0, clamped);
      canvas.drawCircle(
        Offset(glowX, glowY),
        clamped,
        Paint()
          ..shader = RadialGradient(
            colors: [
              accentColor.withAlpha(0),
              if (inner > 0)
                accentColor.withAlpha(0)
              else
                accentColor.withAlpha(rippleAlpha.round().clamp(0, 255)),
              accentColor.withAlpha(rippleAlpha.round().clamp(0, 255)),
              accentColor.withAlpha(0),
            ],
            stops: inner > 0
                ? [0.0, inner / clamped, 0.85, 1.0]
                : const [0.0, 0.0, 0.7, 1.0],
          ).createShader(Rect.fromCircle(
            center: Offset(glowX, glowY),
            radius: clamped,
          )),
      );
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.glowX != glowX ||
      old.glowY != glowY ||
      old.touchAlpha != touchAlpha ||
      old.accentColor != accentColor ||
      old.radius != radius ||
      old.rippleRadius != rippleRadius ||
      old.rippleAlpha != rippleAlpha;
}
