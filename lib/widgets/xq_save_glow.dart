import 'package:flutter/material.dart';

class XqSaveGlow extends StatefulWidget {
  const XqSaveGlow({super.key});

  @override
  State<XqSaveGlow> createState() => XqSaveGlowState();
}

class XqSaveGlowState extends State<XqSaveGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Color _color = const Color(0xFFD4A76A);
  int _maxAlpha = 60;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void pulse(Color color, int alpha, Duration totalDuration) {
    _color = color;
    _maxAlpha = alpha;
    _ctrl.duration = totalDuration;
    _ctrl.forward(from: 0);
  }

  double _computeOpacity() {
    final t = _ctrl.value;
    // fadeIn: 0→0.2, hold: 0.2→0.55, fadeOut: 0.55→1.0
    if (t < 0.2) {
      return Curves.easeOut.transform(t / 0.2);
    } else if (t < 0.55) {
      return 1.0;
    } else {
      return Curves.easeIn.transform(1.0 - (t - 0.55) / 0.45);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ctrl.value == 0) return const SizedBox.shrink();

    final opacity = _computeOpacity();
    final glowColor = _color.withAlpha((_maxAlpha * opacity).round());

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Stack(
          children: [
            // Top edge
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [glowColor, glowColor.withAlpha(0)],
                  ),
                ),
              ),
            ),
            // Bottom edge
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [glowColor, glowColor.withAlpha(0)],
                  ),
                ),
              ),
            ),
            // Left edge
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [glowColor, glowColor.withAlpha(0)],
                  ),
                ),
              ),
            ),
            // Right edge
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [glowColor, glowColor.withAlpha(0)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
