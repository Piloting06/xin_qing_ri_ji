import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../stores/app_state.dart';
import '../widgets/main_scaffold.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  final _phoneFocus = FocusNode();
  final _pwFocus = FocusNode();
  double _neonGlow = 0.0;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onFocusChange);
    _pwFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _neonGlow = (_phoneFocus.hasFocus || _pwFocus.hasFocus) ? 1.0 : 0.0;
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pwCtrl.dispose();
    _phoneFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  bool get _formValid =>
      _phoneCtrl.text.trim().length >= 11 && _pwCtrl.text.isNotEmpty;

  Future<void> _login() async {
    if (!_formValid) return;
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      final data = await Api.login(
          _phoneCtrl.text.trim(), _pwCtrl.text);
      final dn = data['display_name']?.toString() ?? '';
      if (mounted) {
        context.read<AppState>().setDisplayName(dn);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainScaffold()));
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      _shake();
    } catch (e) {
      setState(() => _error = '网络错误: ${e.toString().substring(0, e.toString().length.clamp(0, 60))}');
      _shake();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _shake() {
    HapticFeedback.lightImpact();
    // Brief shake via a key rebuild — handled by the error text visibility
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hasFocus = _neonGlow > 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              height: size.height - MediaQuery.of(context).padding.top - 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Column(children: [
                    CustomPaint(
                      size: const Size(72, 72),
                      painter: _NeonLogoPainter(1.0, hasFocus),
                    ),
                    const SizedBox(height: 16),
                    Text('心晴日记',
                        style: TextStyle(
                            fontSize: 28,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFFC4A46C)
                                .withAlpha(200))),
                  ]),
                  const SizedBox(height: 48),
                  // Phone field
                  _NeonInput(
                    controller: _phoneCtrl,
                    focusNode: _phoneFocus,
                    hint: '手机号',
                    icon: Icons.phone_iphone_rounded,
                    keyboardType: TextInputType.phone,
                    neonGlow: _neonGlow,
                  ),
                  const SizedBox(height: 16),
                  // Password field
                  _NeonInput(
                    controller: _pwCtrl,
                    focusNode: _pwFocus,
                    hint: '密码',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscure,
                    neonGlow: _neonGlow,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: const Color(0xFF8C8C8C),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  // Error
                  AnimatedOpacity(
                    opacity: _error != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error ?? '',
                          style: const TextStyle(
                              color: Color(0xFFD4837A), fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login button
                  _NeonButton(
                    label: '登 录',
                    loading: _loading,
                    active: _formValid,
                    onTap: _login,
                  ),
                  const SizedBox(height: 20),
                  // Register link
                  TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterPage())),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                        ),
                        child: const Text('还没有账号？立即注册',
                            style: TextStyle(
                                color: Color(0xFF8C8C8C), fontSize: 14)),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Neon Input Widget ──
class _NeonInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final double neonGlow;
  final Widget? suffix;
  final void Function(String)? onSubmitted;

  const _NeonInput({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    required this.neonGlow,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.onSubmitted,
  });

  @override
  State<_NeonInput> createState() => _NeonInputState();
}

class _NeonInputState extends State<_NeonInput> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final glow = _focused ? 1.0 : widget.neonGlow;
    final baseAlpha = (180 + (glow * 75)).round().clamp(0, 255);
    final children = <Widget>[
      const SizedBox(width: 14),
      Icon(widget.icon, size: 20, color: const Color(0xFFC4A46C).withAlpha(baseAlpha)),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          onSubmitted: widget.onSubmitted,
          style: const TextStyle(color: Color(0xFFE8E4DC), fontSize: 16),
          cursorColor: const Color(0xFFC4A46C),
          decoration: const InputDecoration(
            hintText: '',
            hintStyle: TextStyle(color: Color(0xFF6B6058), fontSize: 16),
            border: InputBorder.none,
            contentPadding: EdgeInsets.only(bottom: 4),
          ),
        ),
      ),
      const SizedBox(width: 4),
    ];

    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFC4A46C).withAlpha(baseAlpha),
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: const Color(0xFFC4A46C).withAlpha(30), blurRadius: 12, spreadRadius: 1)]
            : null,
      ),
      child: Row(children: children),
    );
  }
}

// ── Neon Button ──
class _NeonButton extends StatefulWidget {
  final String label;
  final bool loading;
  final bool active;
  final VoidCallback onTap;

  const _NeonButton({
    required this.label,
    required this.loading,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton> {

  @override
  Widget build(BuildContext context) {
    final alpha = widget.active ? 255 : 100;
    return GestureDetector(
      onTap: widget.active && !widget.loading ? widget.onTap : null,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFC4A46C).withAlpha(alpha),
            width: 1.5,
          ),
        ),
        child: Center(
          child: widget.loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFC4A46C)))
              : Text(widget.label,
                  style: TextStyle(
                      color: const Color(0xFFC4A46C).withAlpha(alpha),
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 4)),
        ),
      ),
    );
  }
}

// ── Neon Logo Painter ──
class _NeonLogoPainter extends CustomPainter {
  final double progress;
  final bool focused;
  _NeonLogoPainter(this.progress, this.focused);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width * 0.38;
    final glowAlpha = focused ? 80 : 30;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Outer glow
    if (progress > 0.3) {
      final gp = (progress - 0.3) / 0.7;
      canvas.drawCircle(Offset(cx, cy), r + 8,
          Paint()..color = const Color(0xFFC4A46C).withAlpha((glowAlpha * gp).round())..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }

    // Circle
    paint.color = const Color(0xFFC4A46C).withAlpha(200);
    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * progress),
        -3.14159 / 2,
        sweepAngle,
        false,
        paint);

    // Rays
    if (progress > 0.5) {
      final rayProgress = (progress - 0.5) * 2;
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * 3.14159;
        final len = r * 0.35 * rayProgress;
        final dx = cx + cos(angle) * (r * progress + 2);
        final dy = cy + sin(angle) * (r * progress + 2);
        canvas.drawLine(
            Offset(dx, dy),
            Offset(dx + cos(angle) * len, dy + sin(angle) * len),
            paint..color = paint.color.withAlpha((160 * rayProgress).round()));
      }
    }
  }

  @override
  bool shouldRepaint(_NeonLogoPainter old) =>
      old.progress != progress || old.focused != focused;
}
