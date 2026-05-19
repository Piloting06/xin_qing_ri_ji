import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';
import '../theme/xq_typography.dart';
import '../widgets/main_scaffold.dart';
import '../services/notification_service.dart';
import '../main.dart';
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
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_onInputChanged);
    _pwCtrl.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_onInputChanged);
    _pwCtrl.removeListener(_onInputChanged);
    _phoneCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted || _error == null) return;
    setState(() => _error = null);
  }

  bool get _formValid {
    return RegExp(r'^1\d{10}$').hasMatch(_phoneCtrl.text.trim()) &&
        _pwCtrl.text.isNotEmpty;
  }

  Future<void> _login() async {
    if (_loading) return;
    if (!_formValid) {
      setState(() => _error = '请输入完整手机号和密码');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      final data = await Api.login(_phoneCtrl.text.trim(), _pwCtrl.text);
      final dn = data['display_name']?.toString() ?? '';
      if (!mounted) return;
      context.read<AppState>().setDisplayName(dn);
      Navigator.pushReplacement(
        context,
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainScaffold(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: child,
              ),
        ),
      );
      NotificationService.openPendingCapsuleIfAny(appNavigatorKey);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '网络连接失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              _AuthBackdrop(theme: theme),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AuthHero(theme: theme, title: '心晴日记'),
                        const SizedBox(height: 22),
                        _AuthCard(
                          theme: theme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '欢迎回来',
                                style: XqTypography.headlineMedium.copyWith(
                                  color: theme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '记录今天的天气，也记录今天的你。',
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _AuthInput(
                                controller: _phoneCtrl,
                                label: '手机号',
                                hint: '请输入 11 位手机号',
                                icon: Icons.phone_iphone_rounded,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              const SizedBox(height: 14),
                              _AuthInput(
                                controller: _pwCtrl,
                                label: '密码',
                                hint: '请输入密码',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscure,
                                suffix: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: theme.textSecondary,
                                  ),
                                ),
                                onSubmitted: (_) => _login(),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: _error == null
                                    ? const SizedBox(height: 18)
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          _error!,
                                          key: ValueKey(_error),
                                          style: TextStyle(
                                            color: theme.errorColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 10),
                              _AuthButton(
                                label: '登录',
                                loading: _loading,
                                active: _formValid,
                                onTap: _login,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                ),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                          ),
                          child: Text(
                            '还没有账号？创建一个',
                            style: TextStyle(
                              color: theme.accentColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _AuthBackdrop extends StatelessWidget {
  final ThemeState theme;

  const _AuthBackdrop({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -70,
          child: _Glow(
            size: 220,
            color: theme.accentColor.withAlpha(theme.isDark ? 42 : 30),
          ),
        ),
        Positioned(
          left: -80,
          bottom: 80,
          child: _Glow(
            size: 180,
            color: theme.gold.withAlpha(theme.isDark ? 30 : 24),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  final ThemeState theme;
  final String title;

  const _AuthHero({required this.theme, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: theme.cardColor.withAlpha(220),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(theme.isDark ? 40 : 12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            theme.isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
            color: theme.gold,
            size: 31,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          title,
          style: XqTypography.headlineLarge.copyWith(
            color: theme.textPrimary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  final ThemeState theme;
  final Widget child;

  const _AuthCard({required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor.withAlpha(theme.isDark ? 238 : 245),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(theme.isDark ? 48 : 14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AuthInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final void Function(String)? onSubmitted;

  const _AuthInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: keyboardType == TextInputType.phone ? 11 : null,
          onSubmitted: onSubmitted,
          style: TextStyle(color: theme.textPrimary, fontSize: 15),
          cursorColor: theme.accentColor,
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: Icon(icon, color: theme.accentColor, size: 20),
            suffixIcon: suffix,
            hintText: hint,
          ),
        ),
      ],
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool active;
  final VoidCallback onTap;

  const _AuthButton({
    required this.label,
    required this.loading,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: active && !loading ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: theme.accentColor,
          foregroundColor: theme.textOnAccent,
          disabledBackgroundColor: theme.borderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.textOnAccent,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
