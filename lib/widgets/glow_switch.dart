import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';

/// 自定义光效开关 — 打开时有一圈小光晕从滑块扩散
class GlowSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlowSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<GlowSwitch> createState() => _GlowSwitchState();
}

class _GlowSwitchState extends State<GlowSwitch>
    with SingleTickerProviderStateMixin {
  static const double _width = 50;
  static const double _height = 28;
  static const double _thumbSize = 22;
  static const double _padding = 3;

  late final AnimationController _ctrl;
  late final Animation<double> _thumbAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.value ? 1.0 : 0.0,
    );
    _thumbAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(GlowSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _thumbAnim.value;
          final thumbLeft = _padding + t * (_width - _thumbSize - _padding * 2);
          final thumbCenter = Offset(
            thumbLeft + _thumbSize / 2,
            _height / 2,
          );

          final bgColor = Color.lerp(
            const Color(0xFFD0D0D0),
            theme.accentColor,
            t,
          )!;

          return Container(
            width: _width,
            height: _height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_height / 2),
              color: bgColor,
            ),
            child: Stack(
              children: [
                // 光晕层 — 只在打开动画过程中出现
                if (_glowAnim.value > 0.01)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_height / 2),
                      child: CustomPaint(
                        painter: _SwitchGlowPainter(
                          center: thumbCenter,
                          alpha: (_glowAnim.value * 80).round(),
                          radius: 18 + _glowAnim.value * 12,
                          color: theme.accentColor,
                        ),
                      ),
                    ),
                  ),
                // 滑块
                Positioned(
                  left: thumbLeft,
                  top: _padding,
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SwitchGlowPainter extends CustomPainter {
  final Offset center;
  final int alpha;
  final double radius;
  final Color color;

  _SwitchGlowPainter({
    required this.center,
    required this.alpha,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withAlpha(math.min(alpha, 200)),
            color.withAlpha((alpha * 0.3).round()),
            color.withAlpha(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SwitchGlowPainter old) =>
      old.center != center ||
      old.alpha != alpha ||
      old.radius != radius ||
      old.color != color;
}
