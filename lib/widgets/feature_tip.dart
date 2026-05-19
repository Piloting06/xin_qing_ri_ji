import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../stores/theme_state.dart';

class FeatureTip extends StatefulWidget {
  final String tipKey;
  final String text;
  final Widget child;
  final Offset? offset;

  const FeatureTip({
    super.key,
    required this.tipKey,
    required this.text,
    required this.child,
    this.offset,
  });

  static Future<bool> shouldShow(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tip_$key') ?? true;
  }

  static Future<void> markShown(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('tip_$key', false);
  }

  @override
  State<FeatureTip> createState() => _FeatureTipState();
}

class _FeatureTipState extends State<FeatureTip>
    with SingleTickerProviderStateMixin {
  bool _showTip = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _check();
  }

  Future<void> _check() async {
    final should = await FeatureTip.shouldShow(widget.tipKey);
    if (should && mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() => _showTip = true);
        _ctrl.forward();
      }
    }
  }

  void _dismiss() {
    FeatureTip.markShown(widget.tipKey);
    _ctrl.reverse().then((_) {
      if (mounted) setState(() => _showTip = false);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final isDark = theme.isDark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Semi-transparent overlay to catch taps outside
        if (_showTip)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _dismiss,
              child: Container(color: Colors.transparent),
            ),
          ),
        GestureDetector(
          onTap: _showTip ? _dismiss : null,
          child: widget.child,
        ),
        if (_showTip)
          Positioned(
            top: widget.offset?.dy ?? -48,
            left: widget.offset?.dx ?? 0,
            child: GestureDetector(
              onTap: _dismiss,
              child: FadeTransition(
                opacity: _anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_anim),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2824)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.accentColor.withAlpha(80)),
                      boxShadow: [
                        BoxShadow(
                            color: isDark
                                ? Colors.black.withAlpha(80)
                                : theme.accentColor.withAlpha(15),
                            blurRadius: 10,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_rounded,
                            size: 16, color: theme.accentColor),
                        const SizedBox(width: 8),
                        Text(widget.text,
                            style: TextStyle(
                                color: theme.textPrimary, fontSize: 13)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _dismiss,
                          child: Icon(Icons.close, size: 14,
                              color: theme.textSecondary.withAlpha(100)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
