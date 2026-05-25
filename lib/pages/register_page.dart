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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  final _customQuestionCtrl = TextEditingController();
  final _customAnswerCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _obscure2 = true;

  String _questionType = 'choice';
  int _choiceAnswer = 0;
  DateTime? _dateAnswer;

  static const _choiceQuestions = [
    '你第一次养宠物是在几岁？',
    '你小时候最喜欢的玩具是什么？',
    '你的小学叫什么名字？',
    '你妈妈的生日是哪天？',
  ];
  static const _dateQuestions = ['你最重要的纪念日是？', '你第一次离开家乡是哪天？', '你最难忘的旅行是哪天？'];

  @override
  void initState() {
    super.initState();
    for (final ctrl in [
      _phoneCtrl,
      _pwCtrl,
      _pw2Ctrl,
      _customQuestionCtrl,
      _customAnswerCtrl,
    ]) {
      ctrl.addListener(_onInputChanged);
    }
  }

  @override
  void dispose() {
    for (final ctrl in [
      _phoneCtrl,
      _pwCtrl,
      _pw2Ctrl,
      _customQuestionCtrl,
      _customAnswerCtrl,
    ]) {
      ctrl.removeListener(_onInputChanged);
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted || _error == null) return;
    setState(() => _error = null);
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

  bool get _formValid {
    final phoneOk = _isValidPhone(_phoneCtrl.text.trim());
    final passwordOk =
        _pwCtrl.text.length >= 6 && _pwCtrl.text == _pw2Ctrl.text;
    final questionOk = _questionType == 'custom'
        ? _customQuestionCtrl.text.trim().isNotEmpty &&
              _customAnswerCtrl.text.trim().isNotEmpty
        : _questionType == 'date'
        ? _dateAnswer != null
        : true;
    return phoneOk && passwordOk && questionOk;
  }

  Future<void> _register() async {
    if (_loading) return;
    if (!_formValid) {
      setState(() => _error = '请确认手机号、密码和安全问题都填写正确');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      final question = switch (_questionType) {
        'date' => _dateQuestions[0],
        'choice' => _choiceQuestions[0],
        _ => _customQuestionCtrl.text.trim(),
      };
      final answer = switch (_questionType) {
        'choice' => '$_choiceAnswer',
        'date' => _dateAnswer?.toIso8601String() ?? '',
        _ => _customAnswerCtrl.text.trim(),
      };
      final data = await Api.register(
        _phoneCtrl.text.trim(),
        _pwCtrl.text,
        questionType: _questionType,
        question: question,
        answer: answer,
      );
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateAnswer = picked;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          _RegisterBackdrop(theme: theme),
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        _RegisterHero(theme: theme),
                        const SizedBox(height: 20),
                        _RegisterCard(
                          theme: theme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '创建账号',
                                style: XqTypography.headlineMedium.copyWith(
                                  color: theme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '用一个手机号保存你的心情、天气和友人关系。',
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _RegisterInput(
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
                              _RegisterInput(
                                controller: _pwCtrl,
                                label: '密码',
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
                              _RegisterInput(
                                controller: _pw2Ctrl,
                                label: '确认密码',
                                hint: '再次输入密码',
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
                              const SizedBox(height: 16),
                              _securityQuestion(theme),
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
                              _RegisterButton(
                                label: '创建账号',
                                loading: _loading,
                                active: _formValid,
                                onTap: _register,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                          ),
                          child: Text(
                            '已有账号？去登录',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityQuestion(ThemeState theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceAlpha,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '安全问题',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '用于以后找回账号，请选择一个自己记得住的答案。',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _qTypeBtn('choice', '选择题', theme),
              _qTypeBtn('date', '日期题', theme),
              _qTypeBtn('custom', '自定义', theme),
            ],
          ),
          const SizedBox(height: 12),
          if (_questionType == 'choice') ...[
            Text(
              _choiceQuestions[0],
              style: TextStyle(color: theme.textPrimary, fontSize: 14),
            ),
            Slider(
              value: _choiceAnswer.toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              activeColor: theme.accentColor,
              inactiveColor: theme.borderColor,
              label: '$_choiceAnswer 岁',
              onChanged: (v) => setState(() => _choiceAnswer = v.round()),
            ),
          ] else if (_questionType == 'date') ...[
            Text(
              _dateQuestions[0],
              style: TextStyle(color: theme.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Text(
                _dateAnswer == null
                    ? '选择日期'
                    : '${_dateAnswer!.year}-${_dateAnswer!.month.toString().padLeft(2, '0')}-${_dateAnswer!.day.toString().padLeft(2, '0')}',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.accentColor,
                side: BorderSide(color: theme.accentColor.withAlpha(90)),
                minimumSize: const Size(44, 42),
              ),
            ),
          ] else ...[
            _RegisterInput(
              controller: _customQuestionCtrl,
              label: '自定义问题',
              hint: '输入你的问题',
              icon: Icons.help_outline_rounded,
            ),
            const SizedBox(height: 10),
            _RegisterInput(
              controller: _customAnswerCtrl,
              label: '答案',
              hint: '输入答案',
              icon: Icons.edit_note_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _qTypeBtn(String type, String label, ThemeState theme) {
    final active = _questionType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() {
        _questionType = type;
        _error = null;
      }),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: active ? theme.accentColor.withAlpha(24) : theme.cardColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? theme.accentColor : theme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? theme.accentColor : theme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RegisterBackdrop extends StatelessWidget {
  final ThemeState theme;

  const _RegisterBackdrop({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -70,
          child: _RegisterGlow(
            size: 220,
            color: theme.accentColor.withAlpha(theme.isDark ? 42 : 30),
          ),
        ),
        Positioned(
          left: -80,
          bottom: 80,
          child: _RegisterGlow(
            size: 180,
            color: theme.gold.withAlpha(theme.isDark ? 30 : 24),
          ),
        ),
      ],
    );
  }
}

class _RegisterGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _RegisterGlow({required this.size, required this.color});

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

class _RegisterHero extends StatelessWidget {
  final ThemeState theme;

  const _RegisterHero({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: theme.cardColor.withAlpha(220),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(theme.isDark ? 38 : 12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.auto_stories_outlined, color: theme.gold, size: 29),
        ),
        const SizedBox(height: 12),
        Text(
          '欢迎来到心晴日记',
          style: XqTypography.headlineMedium.copyWith(color: theme.textPrimary),
        ),
      ],
    );
  }
}

class _RegisterCard extends StatelessWidget {
  final ThemeState theme;
  final Widget child;

  const _RegisterCard({required this.theme, required this.child});

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

class _RegisterInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;

  const _RegisterInput({
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
          maxLength: keyboardType == TextInputType.phone ? 11 : null,
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

class _RegisterButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool active;
  final VoidCallback onTap;

  const _RegisterButton({
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
