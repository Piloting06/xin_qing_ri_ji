import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../stores/app_state.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/handdrawn_bg.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  final _phoneFocus = FocusNode();
  final _pwFocus = FocusNode();

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
      final data = await Api.login(_phoneCtrl.text.trim(), _pwCtrl.text);
      final dn = data['display_name']?.toString() ?? '';
      if (mounted) {
        context.read<AppState>().setDisplayName(dn);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainScaffold()));
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '网络错误: ${e.toString().substring(0, e.toString().length.clamp(0, 60))}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              const HandDrawnBackground(),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 32),
                      const WarmLogo(size: 40),
                      const SizedBox(height: 14),
                      const Text('心晴日记',
                          style: TextStyle(
                              fontSize: 26,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF8B7355))),
                      const SizedBox(height: 48),
                      _WarmInput(
                        controller: _phoneCtrl,
                        focusNode: _phoneFocus,
                        hint: '手机号',
                        icon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      _WarmInput(
                        controller: _pwCtrl,
                        focusNode: _pwFocus,
                        hint: '密码',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFF8C7E6F),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
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
                      const SizedBox(height: 28),
                      _WarmButton(
                        label: '登 录',
                        loading: _loading,
                        active: _formValid,
                        onTap: _login,
                      ),
                      const SizedBox(height: 18),
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
                                color: Color(0xFF8C7E6F), fontSize: 14)),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Warm Input ──
class _WarmInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffix;
  final void Function(String)? onSubmitted;

  const _WarmInput({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.onSubmitted,
  });

  @override
  State<_WarmInput> createState() => _WarmInputState();
}

class _WarmInputState extends State<_WarmInput> {
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
    final borderColor = _focused
        ? const Color(0xFFB8956A)
        : const Color(0xFFD4C8B8);
    final borderWidth = _focused ? 1.5 : 0.5;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: _focused
            ? [BoxShadow(color: const Color(0xFFC4A46C).withAlpha(20), blurRadius: 8)]
            : null,
      ),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(widget.icon, size: 20, color: borderColor),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
            onSubmitted: widget.onSubmitted,
            style: const TextStyle(color: Color(0xFF3D3228), fontSize: 15),
            cursorColor: const Color(0xFFB8956A),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Color(0xFFB8A898), fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(bottom: 2),
            ),
          ),
        ),
        if (widget.suffix != null) widget.suffix!,
        const SizedBox(width: 4),
      ]),
    );
  }
}

// ── Warm Button (solid fill) ──
class _WarmButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool active;
  final VoidCallback onTap;

  const _WarmButton({
    required this.label,
    required this.loading,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = active
        ? const Color(0xFFB8956A)
        : const Color(0xFFD4C8B8);
    return GestureDetector(
      onTap: active && !loading ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(label,
                  style: TextStyle(
                      color: active ? Colors.white : const Color(0xFFC8BFAE),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 4)),
        ),
      ),
    );
  }
}
