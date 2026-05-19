import 'package:flutter/material.dart';

/// 墨迹书写加载动画
/// 笔尖（3px 圆）沿贝塞尔路径画一条短线 → 线淡出 → 重复
/// 替代 CircularProgressIndicator
class InkWritingLoader extends StatefulWidget {
  final Color inkColor;
  final double size;

  const InkWritingLoader({super.key, required this.inkColor, this.size = 40});

  @override
  State<InkWritingLoader> createState() => _InkWritingLoaderState();
}

class _InkWritingLoaderState extends State<InkWritingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _InkWritingPainter(
          progress: _ctrl.value,
          inkColor: widget.inkColor,
        ),
      ),
    );
  }
}

class _InkWritingPainter extends CustomPainter {
  final double progress;
  final Color inkColor;

  _InkWritingPainter({required this.progress, required this.inkColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 贝塞尔路径：从左到右画一条弯曲的线
    final path = Path()
      ..moveTo(cx - 16, cy + 4)
      ..cubicTo(cx - 8, cy - 6, cx + 4, cy + 10, cx + 16, cy - 2);

    // 画笔描边（带淡入淡出）
    final drawProgress = (progress * 1.5).clamp(0.0, 1.0);
    final fadeOut = progress > 0.7 ? ((progress - 0.7) / 0.3) : 0.0;
    final alpha = ((1 - fadeOut) * 200).round().clamp(0, 255);

    final pathPaint = Paint()
      ..color = inkColor.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // 裁剪路径到当前进度
    final metrics = path.computeMetrics().first;
    final extract = metrics.extractPath(0, metrics.length * drawProgress);
    canvas.drawPath(extract, pathPaint);

    // 笔尖圆点
    if (drawProgress > 0 && drawProgress < 1) {
      final tangent = metrics.getTangentForOffset(
        metrics.length * drawProgress,
      );
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          2.5,
          Paint()..color = inkColor.withAlpha(alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_InkWritingPainter old) =>
      old.progress != progress || old.inkColor != inkColor;
}
