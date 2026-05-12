import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../stores/app_state.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/handdrawn_bg.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _obscure2 = true;
  final _phoneFocus = FocusNode();
  final _pwFocus = FocusNode();

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
  void dispose() {
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
                      const SizedBox(height: 24),
                      const WarmLogo(size: 36),
                      const SizedBox(height: 12),
                      const Text('创建账号',
                          style: TextStyle(
                              fontSize: 22,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF8B7355))),
                      const SizedBox(height: 32),
                      _WarmInput(
                        controller: _phoneCtrl,
                        focusNode: _phoneFocus,
                        hint: '手机号（也是你的账号）',
                        icon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _WarmInput(
                        controller: _pwCtrl,
                        hint: '设置密码',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: const Color(0xFF8C7E6F),
                              size: 20),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _WarmInput(
                        controller: _pw2Ctrl,
                        hint: '确认密码',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure2,
                        suffix: IconButton(
                          icon: Icon(
                              _obscure2
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: const Color(0xFF8C7E6F),
                              size: 20),
                          onPressed: () =>
                              setState(() => _obscure2 = !_obscure2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSecurityQuestion(),
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
                      const SizedBox(height: 20),
                      _WarmButton(
                        label: '注 册',
                        loading: _loading,
                        active: _formValid,
                        onTap: _register,
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44)),
                        child: const Text('已有账号？去登录',
                            style: TextStyle(
                                color: Color(0xFF8C7E6F), fontSize: 14)),
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildSecurityQuestion() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(120),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4C8B8), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('安全问题（找回密码用）',
              style: TextStyle(color: Color(0xFF8C7E6F), fontSize: 13)),
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
                style: TextStyle(color: Color(0xFF5D5348), fontSize: 14)),
            Slider(
                value: _choiceAnswer.toDouble(),
                min: 0,
                max: 30,
                divisions: 30,
                activeColor: const Color(0xFFB8956A),
                inactiveColor: const Color(0xFFD4C8B8),
                label: '$_choiceAnswer 岁',
                onChanged: (v) =>
                    setState(() => _choiceAnswer = v.round())),
          ] else if (_questionType == 'date') ...[
            const Text('你最重要的纪念日是？',
                style: TextStyle(color: Color(0xFF5D5348), fontSize: 14)),
            TextButton(
              onPressed: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now());
                if (d != null) setState(() => _dateAnswer = d);
              },
              child: Text(
                  _dateAnswer != null
                      ? '${_dateAnswer!.year}-${_dateAnswer!.month.toString().padLeft(2, '0')}-${_dateAnswer!.day.toString().padLeft(2, '0')}'
                      : '点击选择日期',
                  style: const TextStyle(color: Color(0xFFB8956A))),
            ),
          ] else ...[
            TextField(
              onChanged: (v) => _customQuestion = v,
              style: const TextStyle(color: Color(0xFF3D3228), fontSize: 14),
              cursorColor: const Color(0xFFB8956A),
              decoration: const InputDecoration(
                  hintText: '输入你的问题...',
                  hintStyle: TextStyle(color: Color(0xFFB8A898)),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4C8B8))),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4C8B8))),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB8956A))),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => _customAnswer = v,
              style: const TextStyle(color: Color(0xFF3D3228), fontSize: 14),
              cursorColor: const Color(0xFFB8956A),
              decoration: const InputDecoration(
                  hintText: '输入答案...',
                  hintStyle: TextStyle(color: Color(0xFFB8A898)),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4C8B8))),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4C8B8))),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB8956A))),
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
              ? const Color(0xFFB8956A).withAlpha(25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? const Color(0xFFB8956A)
                  : const Color(0xFFD4C8B8)),
        ),
        child: Text(label,
            style: TextStyle(
                color: active
                    ? const Color(0xFF8B7355)
                    : const Color(0xFF8C7E6F),
                fontSize: 12)),
      ),
    );
  }
}

// ── Warm Input (register variant, no neonGlow) ──
class _WarmInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffix;

  const _WarmInput({
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
  });

  @override
  State<_WarmInput> createState() => _WarmInputState();
}

class _WarmInputState extends State<_WarmInput> {
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
            focusNode: _fn,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
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
