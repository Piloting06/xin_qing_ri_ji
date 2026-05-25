import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../stores/theme_state.dart';

/// Wraps a card widget with theme-specific texture effects
/// - mint (雾感薄荷): BackdropFilter blur for misty glass effect
/// - blush (豆沙柔粉): noise grain overlay for matte velvet feel
class ThemeCardWrapper extends StatelessWidget {
  final Widget child;
  final ThemeState theme;
  final double borderRadius;

  const ThemeCardWrapper({
    super.key,
    required this.child,
    required this.theme,
    this.borderRadius = 22,
  });

  @override
  Widget build(BuildContext context) {
    if (theme.themeMode == 'mint') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: child,
        ),
      );
    }
    if (theme.themeMode == 'blush') {
      return Stack(
        children: [
          child,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: CustomPaint(
                painter: _NoisePainter(
                  color: theme.accentColor.withAlpha(3),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return child;
  }
}

class _NoisePainter extends CustomPainter {
  final Color color;
  _NoisePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rng = Random(42);
    for (var i = 0; i < size.width * size.height * 0.08; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      if (rng.nextDouble() > 0.5) {
        canvas.drawCircle(Offset(x, y), rng.nextDouble() * 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) => false;
}
