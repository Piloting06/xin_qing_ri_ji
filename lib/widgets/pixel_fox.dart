import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/mood.dart';

class PixelFox extends StatefulWidget {
  final int streak;
  final int totalMoods;
  final int todayMood;
  final VoidCallback? onWriteDiary;
  final VoidCallback? onListenWhiteNoise;
  final VoidCallback? onViewPoems;

  const PixelFox({
    super.key,
    this.streak = 0,
    this.totalMoods = 0,
    this.todayMood = 0,
    this.onWriteDiary,
    this.onListenWhiteNoise,
    this.onViewPoems,
  });

  @override
  State<PixelFox> createState() => _PixelFoxState();
}

class _PixelFoxState extends State<PixelFox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _showBubble = false;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _stage {
    if (widget.totalMoods >= 30) return 5;
    if (widget.streak >= 7) return 4;
    if (widget.streak >= 3) return 3;
    if (widget.totalMoods >= 1) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showBubble = !_showBubble);
      },
      child: SizedBox(
        width: 72,
        height: 90,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Fox canvas
            Positioned(
              top: 0,
              left: 0,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CustomPaint(
                  size: const Size(72, 72),
                  painter: _FoxPainter(
                    stage: _stage,
                    mood: widget.todayMood,
                    breath: _ctrl.value,
                  ),
                ),
              ),
            ),
            // Speech bubble
            if (_showBubble)
              Positioned(
                top: -50,
                left: -20,
                child: _BubbleMenu(
                  stage: _stage,
                  mood: widget.todayMood,
                  onWriteDiary: () {
                    setState(() => _showBubble = false);
                    widget.onWriteDiary?.call();
                  },
                  onWhiteNoise: () {
                    setState(() => _showBubble = false);
                    widget.onListenWhiteNoise?.call();
                  },
                  onPoems: () {
                    setState(() => _showBubble = false);
                    widget.onViewPoems?.call();
                  },
                  onDismiss: () => setState(() => _showBubble = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FoxPainter extends CustomPainter {
  final int stage;
  final int mood;
  final double breath;

  _FoxPainter({
    required this.stage,
    required this.mood,
    required this.breath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2 + 4;
    final breathe = 1.0 + (breath - 0.5) * 0.08;

    if (stage == 1) {
      _drawOrb(canvas, cx, cy, breathe);
    } else if (stage == 2) {
      _drawStar(canvas, cx, cy, breathe);
    } else {
      _drawFox(canvas, cx, cy, breathe);
    }
  }

  void _drawOrb(Canvas canvas, double cx, double cy, double s) {
    canvas.drawCircle(Offset(cx, cy), 14 * s,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFD54F).withAlpha(200),
            const Color(0xFFFF8F00).withAlpha(50),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(
              center: Offset(cx, cy), radius: 18)));
    // Sparkles
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * pi * 2 + DateTime.now().millisecond * 0.003;
      final dist = 16 * s + sin(DateTime.now().millisecond * 0.005 + i) * 4;
      canvas.drawCircle(
          Offset(cx + cos(angle) * dist, cy + sin(angle) * dist),
          1.8,
          Paint()..color = const Color(0xFFFFFDE7).withAlpha(150));
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double s) {
    final bodyPaint = Paint()..color = const Color(0xFFFFD54F);
    // Round body
    canvas.drawCircle(Offset(cx, cy), 16 * s, bodyPaint);
    // Eyes
    canvas.drawCircle(Offset(cx - 5, cy - 3), 2.5,
        Paint()..color = const Color(0xFF3E2723));
    canvas.drawCircle(Offset(cx + 5, cy - 3), 2.5,
        Paint()..color = const Color(0xFF3E2723));
    // Smile
    final path = Path()
      ..moveTo(cx - 4, cy + 4)
      ..quadraticBezierTo(cx, cy + 8, cx + 4, cy + 4);
    canvas.drawPath(
        path, Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Star points
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * pi * 2 - pi / 2;
      final dist = 20 * s;
      canvas.drawLine(
          Offset(cx + cos(angle) * (14 * s), cy + sin(angle) * (14 * s)),
          Offset(cx + cos(angle) * dist, cy + sin(angle) * dist),
          Paint()..color = const Color(0xFFFFC107).withAlpha(100)..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    }
  }

  void _drawFox(Canvas canvas, double cx, double cy, double s) {
    // Tail
    final tailPath = Path()
      ..moveTo(cx - 22, cy + 14)
      ..quadraticBezierTo(cx - 34, cy - 2, cx - 28, cy - 14)
      ..quadraticBezierTo(cx - 20, cy - 24, cx - 14, cy - 18);
    canvas.drawPath(tailPath,
        Paint()..color = const Color(0xFFD4A85C));
    canvas.drawCircle(Offset(cx - 26, cy - 16), 4,
        Paint()..color = Colors.white.withAlpha(180));

    // Body
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + 8), width: 28 * s, height: 22 * s),
        Paint()..color = const Color(0xFFD4A85C));
    // Belly
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + 10),
            width: 16 * s,
            height: 14 * s),
        Paint()..color = const Color(0xFFFFF8E1));

    // Ears
    final earPaint = Paint()..color = const Color(0xFFD4A85C);
    final earInPaint = Paint()..color = const Color(0xFF8B6914);
    // Left ear
    canvas.drawPath(
        Path()
          ..moveTo(cx - 10, cy - 14)
          ..lineTo(cx - 16, cy - 30)
          ..lineTo(cx - 4, cy - 16),
        earPaint);
    canvas.drawPath(
        Path()
          ..moveTo(cx - 8, cy - 15)
          ..lineTo(cx - 13, cy - 26)
          ..lineTo(cx - 5, cy - 16),
        earInPaint);
    // Right ear
    canvas.drawPath(
        Path()
          ..moveTo(cx + 10, cy - 14)
          ..lineTo(cx + 16, cy - 30)
          ..lineTo(cx + 4, cy - 16),
        earPaint);
    canvas.drawPath(
        Path()
          ..moveTo(cx + 8, cy - 15)
          ..lineTo(cx + 13, cy - 26)
          ..lineTo(cx + 5, cy - 16),
        earInPaint);

    // Head
    canvas.drawCircle(Offset(cx, cy - 4), 14 * s,
        Paint()..color = const Color(0xFFD4A85C));
    // Cheeks
    canvas.drawCircle(Offset(cx - 8, cy), 5,
        Paint()..color = const Color(0xFFFFF8E1).withAlpha(150));
    canvas.drawCircle(Offset(cx + 8, cy), 5,
        Paint()..color = const Color(0xFFFFF8E1).withAlpha(150));

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(cx - 5, cy - 6), 3, eyePaint);
    canvas.drawCircle(Offset(cx + 5, cy - 6), 3, eyePaint);
    // Eye highlights
    canvas.drawCircle(Offset(cx - 4, cy - 7), 1,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 6, cy - 7), 1,
        Paint()..color = Colors.white);

    // Nose
    canvas.drawCircle(Offset(cx, cy - 1), 2,
        Paint()..color = const Color(0xFF3E2723));

    // Scarf (stage 4+)
    if (stage >= 4) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx, cy - 10),
                  width: 22,
                  height: 8),
              const Radius.circular(3)),
          Paint()..color = const Color(0xFFC44A4A));
      // Scarf tail
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + 12, cy - 4),
                  width: 6,
                  height: 14),
              const Radius.circular(3)),
          Paint()..color = const Color(0xFFC44A4A));
    }

    // Badge pendant (stage 5)
    if (stage >= 5) {
      canvas.drawCircle(Offset(cx + 14, cy - 8), 4,
          Paint()..color = const Color(0xFFFFD54F));
      canvas.drawCircle(Offset(cx + 14, cy - 8), 2,
          Paint()..color = const Color(0xFFFF8F00));
    }

    // Emotion expressions
    _drawExpression(canvas, cx, cy);
  }

  void _drawExpression(Canvas canvas, double cx, double cy) {
    final paint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case 1: // Happy
        final path = Path()
          ..moveTo(cx - 5, cy + 4)
          ..quadraticBezierTo(cx, cy + 10, cx + 5, cy + 4);
        canvas.drawPath(path, paint);
        break;
      case 3: // Sad
        final path = Path()
          ..moveTo(cx - 5, cy + 4)
          ..quadraticBezierTo(cx, cy, cx + 5, cy + 4);
        canvas.drawPath(path, paint);
        break;
      case 4: // Angry
        canvas.drawLine(Offset(cx - 6, cy - 11), Offset(cx - 2, cy - 9), paint);
        canvas.drawLine(Offset(cx + 6, cy - 11), Offset(cx + 2, cy - 9), paint);
        final path = Path()
          ..moveTo(cx - 4, cy + 4)
          ..lineTo(cx + 4, cy + 4);
        canvas.drawPath(path, paint);
        break;
      case 5: // Anxious
        final path = Path()
          ..moveTo(cx - 3, cy + 3)
          ..lineTo(cx, cy + 1)
          ..lineTo(cx + 3, cy + 3);
        canvas.drawPath(path, paint);
        break;
      default: // Neutral small smile
        final path = Path()
          ..moveTo(cx - 3, cy + 3)
          ..quadraticBezierTo(cx, cy + 6, cx + 3, cy + 3);
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FoxPainter old) =>
      old.stage != stage || old.mood != mood || old.breath != breath;
}

class _BubbleMenu extends StatelessWidget {
  final int stage;
  final int mood;
  final VoidCallback onWriteDiary;
  final VoidCallback onWhiteNoise;
  final VoidCallback onPoems;
  final VoidCallback onDismiss;

  const _BubbleMenu({
    required this.stage,
    required this.mood,
    required this.onWriteDiary,
    required this.onWhiteNoise,
    required this.onPoems,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final greeting = stage >= 4
        ? '今天的你需要什么？'
        : stage >= 2
            ? '我在陪着你哦～'
            : '...';

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFC4A46C).withAlpha(80)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 8)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(greeting,
                style: const TextStyle(
                    color: Color(0xFFE8E4DC), fontSize: 13)),
            const SizedBox(height: 6),
            _bubbleBtn('📝 写日记', onWriteDiary),
            _bubbleBtn('🎧 听白噪音', onWhiteNoise),
            _bubbleBtn('📜 看看古诗', onPoems),
          ],
        ),
      ),
    );
  }

  Widget _bubbleBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFFC4A46C), fontSize: 12)),
      ),
    );
  }
}
