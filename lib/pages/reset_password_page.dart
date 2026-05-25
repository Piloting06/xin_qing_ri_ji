import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../stores/theme_state.dart';
import '../theme/xq_typography.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _loading = false;
  bool _sending = false;
  int _countdown = 0;
  String? _error;
  bool _obscure = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) return false;
    const validPrefixes = {
      '130','131','132','133','134','135','136','137','138','139',
      '145','146','147','148','149',
      '150','151','152','153','155','156','157','158','159',
      '162','165','166','167',
      '170','171','172','173','174','175','176','177','178',
      '180','181','182','183','184','185','186','187','188','189',
      '190','191','193','195','196','197','198','199',
    };
    return validPrefixes.contains(phone.substring(0, 3));
  }

  bool get _formValid =>
      _isValidPhone(_phoneCtrl.text.trim()) &&
      _codeCtrl.text.trim().length == 6 &&
      _pwCtrl.text.length >= 6 &&
      _pwCtrl.text == _pw2Ctrl.text;

  Future<void> _sendCode() async {
    if (_sending || _countdown > 0) return;
    final phone = _phoneCtrl.text.trim();
    if (!_isValidPhone(phone)) {
      setState(() => _error = '请输入正确的11位手机号');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await Api.sendSmsCode(phone);
      if (!mounted) return;
      setState(() => _countdown = 60);
      _startCountdown();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '发送失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        if (_countdown <= 1) {
          _countdown = 0;
          timer.cancel();
        } else {
          _countdown--;
        }
      });
    });
  }

  Future<void> _reset() async {
    if (_loading || !_formValid) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      await Api.resetPassword(
        _phoneCtrl.text.trim(),
        _codeCtrl.text.trim(),
        _pwCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已重置，请登录')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '重置失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              _AuthBackdrop(theme: theme),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        _AuthHero(theme: theme, title: '重置密码'),
                        const SizedBox(height: 22),
                        _AuthCard(
                          theme: theme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '忘记密码',
                                style: XqTypography.headlineMedium.copyWith(
                                  color: theme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '输入手机号获取验证码，设置新密码。',
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // SMS service tip
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.gold.withAlpha(theme.isDark ? 15 : 20),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.gold.withAlpha(40),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 16, color: theme.gold),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '短信服务正在申请中，暂时无法接收验证码。'
                                        '如有需要请先联系客服。',
                                        style: TextStyle(
                                          color: theme.gold,
                                          fontSize: 11,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
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
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _AuthInput(
                                      controller: _codeCtrl,
                                      label: '验证码',
                                      hint: '6位数字',
                                      icon: Icons.pin_outlined,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(6),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: SizedBox(
                                        height: 48,
                                        child: OutlinedButton(
                                          onPressed:
                                              (_countdown > 0 || _sending)
                                                  ? null
                                                  : _sendCode,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: theme.accentColor,
                                            side: BorderSide(
                                              color: theme.accentColor.withAlpha(100),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: Text(
                                            _countdown > 0
                                                ? '${_countdown}s'
                                                : _sending
                                                    ? '发送中'
                                                    : '获取验证码',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _AuthInput(
                                controller: _pwCtrl,
                                label: '新密码',
                                hint: '至少 6 位',
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
                              ),
                              const SizedBox(height: 14),
                              _AuthInput(
                                controller: _pw2Ctrl,
                                label: '确认新密码',
                                hint: '再次输入新密码',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscure2,
                                suffix: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure2 = !_obscure2),
                                  icon: Icon(
                                    _obscure2
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ),
                              if (_pwCtrl.text.isNotEmpty &&
                                  _pw2Ctrl.text.isNotEmpty &&
                                  _pwCtrl.text != _pw2Ctrl.text)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '两次密码不一致',
                                    style: TextStyle(
                                      color: theme.errorColor,
                                      fontSize: 12,
                                    ),
                                  ),
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
                                label: '重置密码',
                                loading: _loading,
                                active: _formValid,
                                onTap: _reset,
                              ),
                            ],
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

// Re-use the same Auth widgets from login_page
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
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.cardColor.withAlpha(220),
            borderRadius: BorderRadius.circular(24),
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
            Icons.lock_reset_outlined,
            color: theme.gold,
            size: 34,
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

  const _AuthInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.suffix,
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
          style: TextStyle(color: theme.textPrimary, fontSize: 15),
          cursorColor: theme.accentColor,
          decoration: InputDecoration(
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
