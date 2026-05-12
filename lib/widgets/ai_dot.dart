import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AiDot extends StatefulWidget {
  final VoidCallback? onWriteDiary;
  final VoidCallback? onWhiteNoise;
  final VoidCallback? onPoems;

  const AiDot({
    super.key,
    this.onWriteDiary,
    this.onWhiteNoise,
    this.onPoems,
  });

  @override
  State<AiDot> createState() => _AiDotState();
}

class _AiDotState extends State<AiDot>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
  }

  void _close() {
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dot
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: _toggle,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB8956A).withAlpha(140),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC4A46C).withAlpha((60 + _pulseCtrl.value * 40).round()),
                      blurRadius: 8 + _pulseCtrl.value * 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Expanded panel
        if (_expanded)
          Positioned(
            right: 28,
            top: -8,
            child: _AiPanel(
              onWriteDiary: () {
                _close();
                widget.onWriteDiary?.call();
              },
              onWhiteNoise: () {
                _close();
                widget.onWhiteNoise?.call();
              },
              onPoems: () {
                _close();
                widget.onPoems?.call();
              },
              onDismiss: _close,
            ),
          ),
      ],
    );
  }
}

class _AiPanel extends StatelessWidget {
  final VoidCallback onWriteDiary;
  final VoidCallback onWhiteNoise;
  final VoidCallback onPoems;
  final VoidCallback onDismiss;

  const _AiPanel({
    required this.onWriteDiary,
    required this.onWhiteNoise,
    required this.onPoems,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD4C8B8), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B7355).withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('需要什么？',
                style: TextStyle(
                    color: Color(0xFF8B7355),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _option('📝 写日记', onWriteDiary),
            _option('🎧 听白噪音', onWhiteNoise),
            _option('📜 看看古诗', onPoems),
          ],
        ),
      ),
    );
  }

  Widget _option(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(text,
            style: const TextStyle(color: Color(0xFF5D5348), fontSize: 13)),
      ),
    );
  }
}
