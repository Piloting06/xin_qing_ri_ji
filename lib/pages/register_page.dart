import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../stores/app_state.dart';
import '../widgets/main_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _obscure2 = true;
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;
  final _phoneFocus = FocusNode();
  final _pwFocus = FocusNode();

  // Security question
  String _questionType = 'choice';
  String _customQuestion = '';
  String _customAnswer = '';
  int _choiceAnswer = 0;
  DateTime? _dateAnswer;

  static const _choiceQuestions = [
    '你第一次养宠物是在几岁？',
    '你小时候最喜欢的玩具是什么？',
    '你的小学叫什么名字？',
    '你妈妈的生日是哪天？',
  ];
  static const _dateQuestions = [
    '你最重要的纪念日是？',
    '你第一次离开家乡是哪天？',
    '你最难忘的旅行是哪天？',
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _phoneCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    _phoneFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  bool get _formValid =>
      _phoneCtrl.text.trim().length >= 11 &&
      _pwCtrl.text.isNotEmpty &&
      _pwCtrl.text == _pw2Ctrl.text;

  Future<void> _register() async {
    if (!_formValid) {
      setState(() => _error = '请填写完整且密码一致');
      return;
    }
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      String question;
      switch (_questionType) {
        case 'date':
          question = _dateQuestions[0];
          break;
        case 'choice':
          question = _choiceQuestions[0];
          break;
        default:
          question = _customQuestion;
      }
      final data = await Api.register(
        _phoneCtrl.text.trim(),
        _pwCtrl.text,
        questionType: _questionType,
        question: question,
        answer: _questionType == 'choice'
            ? '$_choiceAnswer'
            : _questionType == 'date'
                ? (_dateAnswer?.toIso8601String() ?? '')
                : _customAnswer,
      );
      final dn = data['display_name']?.toString() ?? '';
      if (mounted) {
        context.read<AppState>().setDisplayName(dn);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainScaffold()));
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '网络连接失败，请检查网络');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                  AnimatedBuilder(
                    animation: _entryAnim,
                    builder: (_, __) => Opacity(
                      opacity: _entryAnim.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.8 + _entryAnim.value * 0.2,
                        child: Column(children: [
                          CustomPaint(
                              size: const Size(64, 64),
                              painter: _NeonLogoPainter(_entryAnim.value)),
                          const SizedBox(height: 12),
                          Text('创建账号',
                              style: TextStyle(
                                  fontSize: 22,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w300,
                                  color: const Color(0xFFC4A46C)
                                      .withAlpha(200))),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Phone
                  _NeonInput(
                      controller: _phoneCtrl,
                      focusNode: _phoneFocus,
                      hint: '手机号（也是你的账号）',
                      icon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                      entryProgress: _entryAnim.value),
                  const SizedBox(height: 14),
                  // Password
                  _NeonInput(
                      controller: _pwCtrl,
                      focusNode: _pwFocus,
                      hint: '设置密码',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      entryProgress: _entryAnim.value,
                      suffix: IconButton(
                        icon: Icon(
                            _obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: const Color(0xFF8C8C8C),
                            size: 20),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      )),
                  const SizedBox(height: 14),
                  _NeonInput(
                      controller: _pw2Ctrl,
                      hint: '确认密码',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure2,
                      entryProgress: _entryAnim.value,
                      suffix: IconButton(
                        icon: Icon(
                            _obscure2
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: const Color(0xFF8C8C8C),
                            size: 20),
                        onPressed: () =>
                            setState(() => _obscure2 = !_obscure2),
                      )),
                  const SizedBox(height: 16),
                  // Security question type selector
                  AnimatedOpacity(
                    opacity: _entryAnim.value.clamp(0.0, 1.0),
                    duration: const Duration(milliseconds: 400),
                    child: _buildSecurityQuestion(),
                  ),
                  // Error
                  AnimatedOpacity(
                    opacity: _error != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_error ?? '',
                          style: const TextStyle(
                              color: Color(0xFFD4837A), fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _NeonButton(
                    label: '注 册',
                    loading: _loading,
                    active: _formValid,
                    entryProgress: _entryAnim.value,
                    onTap: _register,
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _entryAnim,
                    builder: (_, __) => Opacity(
                      opacity: _entryAnim.value.clamp(0.0, 1.0),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44)),
                        child: const Text('已有账号？去登录',
                            style: TextStyle(
                                color: Color(0xFF8C8C8C), fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityQuestion() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC4A46C).withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('安全问题（找回密码用）',
              style: TextStyle(color: Color(0xFF8C8C8C), fontSize: 13)),
          const SizedBox(height: 10),
          Row(children: [
            _qTypeBtn('choice', '选择题'),
            const SizedBox(width: 8),
            _qTypeBtn('date', '日期题'),
            const SizedBox(width: 8),
            _qTypeBtn('custom', '自定义'),
          ]),
          const SizedBox(height: 10),
          if (_questionType == 'choice') ...[
            const Text('你第一次养宠物是在几岁？',
                style: TextStyle(color: Color(0xFFB0A898), fontSize: 14)),
            Slider(
                value: _choiceAnswer.toDouble(),
                min: 0,
                max: 30,
                divisions: 30,
                activeColor: const Color(0xFFC4A46C),
                label: '$_choiceAnswer 岁',
                onChanged: (v) =>
                    setState(() => _choiceAnswer = v.round())),
          ] else if (_questionType == 'date') ...[
            const Text('你最重要的纪念日是？',
                style: TextStyle(color: Color(0xFFB0A898), fontSize: 14)),
            TextButton(
              onPressed: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now());
                if (d != null)
                  setState(() => _dateAnswer = d);
              },
              child: Text(
                  _dateAnswer != null
                      ? '${_dateAnswer!.year}-${_dateAnswer!.month.toString().padLeft(2, '0')}-${_dateAnswer!.day.toString().padLeft(2, '0')}'
                      : '点击选择日期',
                  style:
                      const TextStyle(color: Color(0xFFC4A46C))),
            ),
          ] else ...[
            TextField(
              onChanged: (v) => _customQuestion = v,
              style: const TextStyle(color: Color(0xFFE8E4DC), fontSize: 14),
              decoration: const InputDecoration(
                  hintText: '输入你的问题...',
                  hintStyle: TextStyle(color: Color(0xFF6B6058)),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => _customAnswer = v,
              style: const TextStyle(color: Color(0xFFE8E4DC), fontSize: 14),
              decoration: const InputDecoration(
                  hintText: '输入答案...',
                  hintStyle: TextStyle(color: Color(0xFF6B6058)),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _qTypeBtn(String type, String label) {
    final active = _questionType == type;
    return GestureDetector(
      onTap: () => setState(() => _questionType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFC4A46C).withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? const Color(0xFFC4A46C)
                  : const Color(0xFF4A4440)),
        ),
        child: Text(label,
            style: TextStyle(
                color: active
                    ? const Color(0xFFC4A46C)
                    : const Color(0xFF8C8C8C),
                fontSize: 12)),
      ),
    );
  }
}

// ── Reuse neon input widget (simplified inline copy) ──
class _NeonInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final double entryProgress;
  final Widget? suffix;

  const _NeonInput({
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.icon,
    required this.entryProgress,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
  });

  @override
  State<_NeonInput> createState() => _NeonInputState();
}

class _NeonInputState extends State<_NeonInput> {
  final _defaultFocus = FocusNode();
  FocusNode get _fn => widget.focusNode ?? _defaultFocus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _fn.addListener(() {
      if (mounted) setState(() => _focused = _fn.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _defaultFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseAlpha = (180 + (_focused ? 75 : 0)).round().clamp(0, 255);

    return AnimatedOpacity(
      opacity: widget.entryProgress.clamp(0.0, 1.0),
      duration: const Duration(milliseconds: 300),
      child: Transform.translate(
        offset: Offset(0, (1 - widget.entryProgress) * 20),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFC4A46C).withAlpha(baseAlpha),
              width: _focused ? 1.5 : 1.0,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                        color: const Color(0xFFC4A46C).withAlpha(30),
                        blurRadius: 12,
                        spreadRadius: 1)
                  ]
                : null,
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            Icon(widget.icon,
                size: 20,
                color: const Color(0xFFC4A46C).withAlpha(baseAlpha)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _fn,
                obscureText: widget.obscure,
                keyboardType: widget.keyboardType,
                style:
                    const TextStyle(color: Color(0xFFE8E4DC), fontSize: 16),
                cursorColor: const Color(0xFFC4A46C),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle:
                      const TextStyle(color: Color(0xFF6B6058), fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 4),
                ),
              ),
            ),
            if (widget.suffix != null) widget.suffix!,
            const SizedBox(width: 4),
          ]),
        ),
      ),
    );
  }
}

// ── Neon Button ──
class _NeonButton extends StatefulWidget {
  final String label;
  final bool loading;
  final bool active;
  final double entryProgress;
  final VoidCallback onTap;

  const _NeonButton({
    required this.label,
    required this.loading,
    required this.active,
    required this.entryProgress,
    required this.onTap,
  });

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
  }

  @override
  void didUpdateWidget(_NeonButton old) {
    super.didUpdateWidget(old);
    if (widget.active && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.active && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alpha = widget.active ? 255 : 100;
    return AnimatedOpacity(
      opacity: widget.entryProgress.clamp(0.0, 1.0),
      duration: const Duration(milliseconds: 400),
      child: Transform.translate(
        offset: Offset(0, (1 - widget.entryProgress) * 30),
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final pulseAlpha =
                widget.active ? (30 + _pulseCtrl.value * 30).round() : 0;
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
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFC4A46C).withAlpha(pulseAlpha),
                        blurRadius: 20,
                        spreadRadius: 1)
                  ],
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
                              color: const Color(0xFFC4A46C)
                                  .withAlpha(alpha),
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 4)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NeonLogoPainter extends CustomPainter {
  final double progress;
  _NeonLogoPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width * 0.38;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    if (progress > 0.3) {
      final gp = (progress - 0.3) / 0.7;
      canvas.drawCircle(
          Offset(cx, cy),
          r + 6,
          Paint()
            ..color = const Color(0xFFC4A46C).withAlpha((25 * gp).round())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    paint.color = const Color(0xFFC4A46C).withAlpha(200);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * progress),
        -3.14159 / 2,
        2 * 3.14159 * progress,
        false,
        paint);

    if (progress > 0.5) {
      final rayProgress = (progress - 0.5) * 2;
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * 3.14159;
        final len = r * 0.3 * rayProgress;
        final dx = cx + cos(angle) * (r * progress + 2);
        final dy = cy + sin(angle) * (r * progress + 2);
        canvas.drawLine(
            Offset(dx, dy),
            Offset(dx + cos(angle) * len, dy + sin(angle) * len),
            paint..color = paint.color.withAlpha((140 * rayProgress).round()));
      }
    }
  }

  @override
  bool shouldRepaint(_NeonLogoPainter old) => old.progress != progress;
}
