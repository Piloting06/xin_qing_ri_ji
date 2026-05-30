import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../api/api_client.dart';
import '../constants/keys.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../theme/xq_typography.dart';
import '../services/notification_service.dart';
import '../widgets/xq_toast.dart';
import 'capsule_page.dart';
import 'friends_page.dart';
import 'legal_page.dart';
import 'login_page.dart';
import 'about_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _avatarFileKey = 'avatar_file';
  static const _legacyAvatarPathKey = 'avatar_path';

  String _avatarFileName() {
    final phone = _phone.isNotEmpty ? _phone.replaceAll(RegExp(r'[^0-9]'), '') : 'default';
    return 'avatar_$phone.jpg';
  }

  final _nameCtrl = TextEditingController();
  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  bool _saving = false;
  bool _checkingIn = false;
  bool _checkedIn = false;
  bool _capsuleNotify = true;
  int _consecutive = 0;
  String? _avatarPath;
  String _phone = '';
  String _boundEmail = '';

  @override
  void initState() {
    super.initState();
    _loadProfileInfo();
    _loadCheckin();
    _loadAvatar();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _oldPwCtrl.dispose();
    _newPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfileInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _phone = prefs.getString(StorageKeys.phone) ?? '';
        _boundEmail = prefs.getString(StorageKeys.email) ?? '';
        _capsuleNotify = prefs.getBool(StorageKeys.capsuleNotify) ?? true;
      });
    }
    // Fetch from server to stay in sync
    try {
      final profile = await Api.getProfile();
      if (mounted) {
        final email = profile['email'] as String? ?? '';
        setState(() => _boundEmail = email);
        final prefs = await SharedPreferences.getInstance();
        if (email.isNotEmpty) {
          await prefs.setString(StorageKeys.email, email);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadCheckin() async {
    try {
      final s = await Api.getCheckinStatus();
      if (mounted) {
        setState(() {
          _checkedIn = s['checked_in'] == true || s['checked_in'] == 1;
          _consecutive = s['consecutive_days'] ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final dir = await getApplicationDocumentsDirectory();
    final fileName = _avatarFileName();
    final storedFile = prefs.getString(_avatarFileKey);
    if (storedFile != null && storedFile.isNotEmpty) {
      final file = File(p.join(dir.path, storedFile));
      if (file.existsSync()) {
        if (mounted) setState(() => _avatarPath = file.path);
        return;
      }
      await prefs.remove(_avatarFileKey);
    }

    // Try loading user-specific avatar
    final userFile = File(p.join(dir.path, fileName));
    if (userFile.existsSync()) {
      await prefs.setString(_avatarFileKey, fileName);
      if (mounted) setState(() => _avatarPath = userFile.path);
      return;
    }

    // Legacy migration
    final legacyPath = prefs.getString(_legacyAvatarPathKey);
    if (legacyPath != null && legacyPath.isNotEmpty) {
      final legacyFile = File(legacyPath);
      if (legacyFile.existsSync()) {
        final dest = File(p.join(dir.path, fileName));
        if (p.normalize(legacyFile.path) != p.normalize(dest.path)) {
          await legacyFile.copy(dest.path);
        }
        await prefs.setString(_avatarFileKey, fileName);
        await prefs.remove(_legacyAvatarPathKey);
        if (mounted) setState(() => _avatarPath = dest.path);
        return;
      }
      await prefs.remove(_legacyAvatarPathKey);
    }

    if (mounted) setState(() => _avatarPath = null);
  }

  Future<void> _pickAvatar() async {
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        imageQuality: 80,
      );
      if (img == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final fileName = _avatarFileName();
      final dest = File(p.join(dir.path, fileName));
      await File(img.path).copy(dest.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarFileKey, _avatarFileName());
      await prefs.remove(_legacyAvatarPathKey);
      if (!mounted) return;
      setState(() => _avatarPath = dest.path);
      XqToast.success(context, '头像已保存');
    } catch (_) {
      if (mounted) XqToast.error(context, '头像保存失败，请重试');
    }
  }

  Future<void> _doCheckin() async {
    if (_checkedIn || _checkingIn) return;
    HapticFeedback.lightImpact();
    setState(() => _checkingIn = true);
    try {
      final r = await Api.checkin();
      if (mounted) {
        setState(() {
          _checkedIn = true;
          _consecutive = r['consecutive_days'] ?? _consecutive;
        });
        XqToast.success(context, '今日已记录');
      }
    } catch (_) {
      if (mounted) XqToast.error(context, '签到失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  Future<void> _updateName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await Api.updateDisplayName(name);
      if (mounted) {
        context.read<AppState>().setDisplayName(name);
        _nameCtrl.clear();
        XqToast.success(context, '名字已更新');
      }
    } catch (_) {
      if (mounted) XqToast.error(context, '名字保存失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setCapsuleNotify(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.capsuleNotify, value);
    if (!mounted) return;
    setState(() => _capsuleNotify = value);
  }

  Future<void> _changePassword() async {
    if (_oldPwCtrl.text.isEmpty || _newPwCtrl.text.length < 6 || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await Api.changePassword(_oldPwCtrl.text, _newPwCtrl.text);
      if (mounted) {
        _oldPwCtrl.clear();
        _newPwCtrl.clear();
        XqToast.success(context, '密码已更改');
      }
    } catch (_) {
      if (mounted) XqToast.error(context, '修改失败，请检查当前密码');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final theme = context.read<ThemeState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.cardColor,
        title: Text(
          '注销账号',
          style: TextStyle(
            color: theme.errorColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text('注销后会退出当前账号，并释放手机号。重新注册会创建一个全新账号。'),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.errorColor,
            ),
            child: const Text('确定注销'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteAccount();
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      context.read<AppState>().clearUser();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (_) {
      if (mounted) XqToast.error(context, '注销失败，请稍后重试');
    }
  }

  Future<void> _logout() async {
    final theme = context.read<ThemeState>();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.cardColor,
        title: const Text(
          '退出登录',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: const Text('确定要退出当前账号吗？'),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'logout'),
            style: TextButton.styleFrom(foregroundColor: theme.accentColor),
            child: const Text('退出'),
          ),
          // 注销入口藏在弹窗底部
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx, 'delete'),
              child: Text(
                '彻底注销账号',
                style: TextStyle(
                  color: theme.textTertiary,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.textTertiary.withAlpha(120),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (result == 'logout') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.token);
      await prefs.remove(StorageKeys.phone);
      await prefs.remove(StorageKeys.username);
      await prefs.remove(StorageKeys.displayName);
      await prefs.remove(StorageKeys.email);
      if (!mounted) return;
      context.read<AppState>().clearUser();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } else if (result == 'delete') {
      _deleteAccount();
    }
  }

  void _showEmailSheet(ThemeState theme) {
    final emailCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    var sending = false;
    var countdown = 0;
    var binding = false;

    void startCountdown() {
      Future.delayed(const Duration(seconds: 1), () {
        if (countdown <= 0) return;
        countdown--;
        if (mounted) setState(() {});
        startCountdown();
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _boundEmail.isEmpty ? '绑定邮箱' : '更换邮箱',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_boundEmail.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '当前: $_boundEmail',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setSheetState(() {}),
                      style: TextStyle(color: theme.textPrimary, fontSize: 14),
                      cursorColor: theme.accentColor,
                      decoration: InputDecoration(
                        labelText: '邮箱地址',
                        labelStyle: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: theme.accentColor,
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 14,
                            ),
                            cursorColor: theme.accentColor,
                            decoration: InputDecoration(
                              labelText: '验证码',
                              labelStyle: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.pin_outlined,
                                color: theme.accentColor,
                                size: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.borderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.accentColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 120,
                          height: 44,
                          child: OutlinedButton(
                            onPressed:
                                (sending ||
                                    countdown > 0 ||
                                    !emailCtrl.text.contains('@') ||
                                    !emailCtrl.text.contains('.'))
                                ? null
                                : () async {
                                    sending = true;
                                    setSheetState(() {});
                                    try {
                                      await Api.sendEmailCode(
                                        emailCtrl.text.trim(),
                                      );
                                      countdown = 60;
                                      sending = false;
                                      if (mounted) setState(() {});
                                      startCountdown();
                                    } catch (_) {
                                      sending = false;
                                      if (mounted) setState(() {});
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.accentColor,
                              disabledForegroundColor: theme.accentColor
                                  .withAlpha(100),
                              side: BorderSide(
                                color: theme.accentColor.withAlpha(140),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: countdown > 0
                                ? Text(
                                    '${countdown}s',
                                    style: const TextStyle(fontSize: 13),
                                  )
                                : sending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '发送验证码',
                                    style: TextStyle(fontSize: 12),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: binding
                            ? null
                            : () async {
                                if (emailCtrl.text.trim().isEmpty ||
                                    codeCtrl.text.isEmpty) {
                                  return;
                                }
                                binding = true;
                                setSheetState(() {});
                                try {
                                  await Api.bindEmail(
                                    emailCtrl.text.trim(),
                                    codeCtrl.text,
                                  );
                                  final email = emailCtrl.text.trim();
                                  setState(() => _boundEmail = email);
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString(StorageKeys.email, email);
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (mounted) {
                                    XqToast.success(context, '邮箱绑定成功');
                                  }
                                } on ApiException catch (e) {
                                  binding = false;
                                  setSheetState(() {});
                                  if (mounted) {
                                    XqToast.error(context, e.message);
                                  }
                                } catch (_) {
                                  binding = false;
                                  setSheetState(() {});
                                  if (mounted) {
                                    XqToast.error(context, '绑定失败，请稍后重试');
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.accentColor,
                          foregroundColor: theme.textOnAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: binding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('确认绑定'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            _profileHeader(theme, appState),
            const SizedBox(height: 18),

            _sectionTitle('记录概览', theme, subtitle: '这些小事正在慢慢攒起来'),
            const SizedBox(height: 10),
            _recordsGroup(theme),
            const SizedBox(height: 22),

            _sectionTitle('个人资料', theme),
            const SizedBox(height: 10),
            _profileSettingsGroup(theme, appState),
            const SizedBox(height: 22),

            _sectionTitle('外观与偏好', theme),
            const SizedBox(height: 10),
            _appearanceGroup(theme),
            const SizedBox(height: 22),

            _sectionTitle('账号与安全', theme),
            const SizedBox(height: 10),
            _securityGroup(theme),
            const SizedBox(height: 22),

            _sectionTitle('关于与帮助', theme),
            const SizedBox(height: 10),
            _aboutGroup(theme),
            const SizedBox(height: 22),

            // 退出登录（低调 footer 样式）
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _logout,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '退出登录',
                    style: TextStyle(
                      color: theme.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            Text(
              '拾晴日记 2.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTertiary, fontSize: 11),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse('https://beian.miit.gov.cn/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                '赣ICP备2026009414号-3A',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTertiary.withAlpha(150),
                  fontSize: 10,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.textTertiary.withAlpha(80),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(ThemeState theme, AppState appState) {
    final name = appState.displayName.isNotEmpty ? appState.displayName : '用户';
    final accountText = _phone.isEmpty ? '账号信息已同步' : _phone;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: XqDecorations.heroCard(
        theme.cardColor.withAlpha(theme.isDark ? 238 : 248),
        theme.cardElevated.withAlpha(theme.isDark ? 210 : 236),
        theme.borderColor,
        dark: theme.isDark,
        glow: theme.accentColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.accentColor.withAlpha(46),
                            theme.gold.withAlpha(theme.isDark ? 34 : 46),
                          ],
                        ),
                        border: Border.all(
                          color: theme.accentColor.withAlpha(100),
                          width: 1.4,
                        ),
                        boxShadow: XqDecorations.shadowSubtle(
                          dark: theme.isDark,
                        ),
                      ),
                      child: _avatarPath != null
                          ? ClipOval(
                              child: Image.file(
                                File(_avatarPath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person_outline_rounded,
                              size: 34,
                              color: theme.accentColor,
                            ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.cardColor, width: 2),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: theme.textOnAccent,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: XqTypography.headlineMedium.copyWith(
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      accountText,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _profilePill(
                          theme,
                          Icons.local_fire_department_outlined,
                          '连续 $_consecutive 天',
                        ),
                        _profilePill(
                          theme,
                          _checkedIn
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                          _checkedIn ? '今日已记' : '今日未记',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profilePill(ThemeState theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.accentColor.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.accentColor.withAlpha(55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.accentColor, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: theme.accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordsGroup(ThemeState theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('记录概览', theme),
        const SizedBox(height: 8),
        _listTile(
          theme,
          icon: _checkedIn
              ? Icons.check_circle_outline_rounded
              : Icons.local_fire_department_outlined,
          iconColor: _checkedIn ? theme.successColor : theme.accentColor,
          title: _checkedIn ? '今日已记录' : '今天还没记',
          subtitle: _checkedIn
              ? '连续 $_consecutive 天'
              : (_checkingIn ? '正在记录' : '轻点签到'),
          onTap: (_checkedIn || _checkingIn) ? null : _doCheckin,
        ),
        Divider(height: 1, color: theme.borderColor.withAlpha(80)),
        _listTile(
          theme,
          icon: Icons.hourglass_empty_rounded,
          iconColor: theme.accentColor,
          title: '时光胶囊',
          subtitle: _capsuleNotify ? '提醒已开启' : '提醒未开启',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CapsulePage()),
          ),
        ),
        Divider(height: 1, color: theme.borderColor.withAlpha(80)),
        _listTile(
          theme,
          icon: Icons.people_outline_rounded,
          iconColor: theme.accentColor,
          title: '好友心情',
          subtitle: '看看朋友近况',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FriendsPage()),
          ),
        ),
      ],
    );
  }

  Widget _listTile(
    ThemeState theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileSettingsGroup(ThemeState theme, AppState appState) {
    return _card(
      theme,
      child: Column(
        children: [
          _infoRow(
            theme,
            icon: Icons.badge_outlined,
            title: '昵称',
            subtitle: appState.displayName.isNotEmpty
                ? appState.displayName
                : '点击设置你的日记署名',
            trailing: '修改',
            onTap: () => _showNicknameDialog(theme, appState),
          ),
          _divider(theme),
          _infoRow(
            theme,
            icon: Icons.email_outlined,
            title: _boundEmail.isEmpty ? '绑定邮箱' : '邮箱',
            subtitle: _boundEmail.isEmpty ? '绑定后可用邮箱登录' : _boundEmail,
            trailing: _boundEmail.isEmpty ? '绑定' : '更换',
            onTap: () => _showEmailSheet(theme),
          ),
        ],
      ),
    );
  }

  Widget _appearanceGroup(ThemeState theme) {
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _themeSelectorGrid(theme),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 14,
                color: theme.textTertiary.withAlpha(160),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '点击已选中的主题，可以查看它的创作故事',
                  style: TextStyle(
                    color: theme.textTertiary.withAlpha(170),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: theme.borderColor.withAlpha(60), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 18,
                color: theme.gold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '胶囊提醒',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '到期时通过通知提醒我',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _capsuleNotify,
                onChanged: (v) async {
                  if (v) {
                    // 直接请求系统通知权限（类似定位权限弹窗）
                    final granted = await NotificationService.requestPermissionIfNeeded();
                    if (!mounted) return;
                    if (!granted) {
                      // 系统弹窗被拒绝，保持关闭状态
                      return;
                    }
                  }
                  _setCapsuleNotify(v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeSelectorGrid(ThemeState theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ThemeState.themeNames.entries.map((entry) {
            final active = theme.themeMode == entry.key;
            final colors = ThemeState.themeColors[entry.key]!;
            final desc = _themeSceneDesc(entry.key);
            return SizedBox(
              width: width,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(XqDecorations.radiusCard),
                  onTap: () {
                    if (active) {
                      _showThemeDetail(entry.key, entry.value, colors, desc);
                    } else {
                      theme.setTheme(entry.key);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    height: 78,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(XqDecorations.radiusCard),
                      color: colors[2],
                      border: Border.all(
                        color: active
                            ? colors[0]
                            : theme.borderColor.withAlpha(100),
                        width: active ? 1.6 : 0.7,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: colors[0].withAlpha(32),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ...colors
                                .take(3)
                                .map(
                                  (c) => Container(
                                    width: 13,
                                    height: 13,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c,
                                      border: Border.all(
                                        color: Colors.white.withAlpha(140),
                                        width: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                            const Spacer(),
                            if (active)
                              Icon(
                                Icons.check_circle_rounded,
                                color: colors[0],
                                size: 17,
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          entry.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active
                                ? colors[0]
                                : _readableTextOn(colors[2]),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _readableTextOn(colors[2]).withAlpha(165),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _securityGroup(ThemeState theme) {
    return _card(
      theme,
      child: _infoRow(
        theme,
        icon: Icons.lock_outline_rounded,
        title: '修改密码',
        subtitle: '更改当前登录密码',
        trailing: '修改',
        onTap: () => _showPasswordSheet(theme),
      ),
    );
  }

  Widget _aboutGroup(ThemeState theme) {
    return _card(
      theme,
      child: Column(
        children: [
          _infoRow(
            theme,
            icon: Icons.info_outline_rounded,
            title: '关于拾晴日记',
            subtitle: '版本、合规、开源许可',
            trailing: '查看',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          _divider(theme),
          _infoRow(
            theme,
            icon: Icons.description_outlined,
            title: '隐私政策',
            subtitle: '查看数据和隐私说明',
            trailing: '查看',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalPage(isPrivacy: true),
              ),
            ),
          ),
          _divider(theme),
          _infoRow(
            theme,
            icon: Icons.article_outlined,
            title: '用户协议',
            subtitle: '查看使用约定',
            trailing: '查看',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalPage(isPrivacy: false),
              ),
            ),
          ),
          _divider(theme),
          _infoRow(
            theme,
            icon: Icons.chat_bubble_outline_rounded,
            title: '加入交流群',
            subtitle: '和更多用户一起聊聊',
            trailing: '加入',
            onTap: _openQqGroup,
          ),
        ],
      ),
    );
  }

  Future<void> _openQqGroup() async {
    final url = Uri.parse('https://qm.qq.com/q/EKUVPDQV8Y');
    try {
      final can = await canLaunchUrl(url);
      if (!mounted) return;
      if (can) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请先安装 QQ')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('跳转失败，请稍后重试')));
    }
  }

  void _showNicknameDialog(ThemeState theme, AppState appState) {
    final ctrl = TextEditingController(
      text: appState.displayName.isNotEmpty ? appState.displayName : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          '修改昵称',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: theme.textPrimary),
          cursorColor: theme.accentColor,
          decoration: InputDecoration(
            hintText: '输入新的昵称',
            hintStyle: TextStyle(color: theme.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: theme.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              _nameCtrl.text = name;
              _updateName();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.accentColor,
              foregroundColor: theme.textOnAccent,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showPasswordSheet(ThemeState theme) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var obscureOld = true;
    var obscureNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '修改密码',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: oldCtrl,
                    obscureText: obscureOld,
                    style: TextStyle(color: theme.textPrimary, fontSize: 14),
                    cursorColor: theme.accentColor,
                    decoration: InputDecoration(
                      labelText: '当前密码',
                      labelStyle: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: theme.accentColor,
                        size: 18,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureOld ? Icons.visibility_off : Icons.visibility,
                          color: theme.textSecondary,
                          size: 18,
                        ),
                        onPressed: () =>
                            setSheetState(() => obscureOld = !obscureOld),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newCtrl,
                    obscureText: obscureNew,
                    style: TextStyle(color: theme.textPrimary, fontSize: 14),
                    cursorColor: theme.accentColor,
                    decoration: InputDecoration(
                      labelText: '新密码',
                      labelStyle: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_reset,
                        color: theme.accentColor,
                        size: 18,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                          color: theme.textSecondary,
                          size: 18,
                        ),
                        onPressed: () =>
                            setSheetState(() => obscureNew = !obscureNew),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    style: TextStyle(color: theme.textPrimary, fontSize: 14),
                    cursorColor: theme.accentColor,
                    decoration: InputDecoration(
                      labelText: '确认新密码',
                      labelStyle: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_reset,
                        color: theme.accentColor,
                        size: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        if (oldCtrl.text.isEmpty ||
                            newCtrl.text.length < 6 ||
                            newCtrl.text != confirmCtrl.text) {
                          return;
                        }
                        _oldPwCtrl.text = oldCtrl.text;
                        _newPwCtrl.text = newCtrl.text;
                        _changePassword();
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        foregroundColor: theme.textOnAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('确认修改'),
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

  // ── Helpers ──

  String _themeSceneDesc(String mode) {
    return switch (mode) {
      'dark' => '深夜被窝里',
      'mint' => '雨后清晨',
      'blush' => '咖啡店角落',
      _ => '午后窗边',
    };
  }

  Color _readableTextOn(Color bg) {
    return (bg.computeLuminance() > 0.5)
        ? const Color(0xFF333333)
        : const Color(0xFFEEEEEE);
  }

  void _showThemeDetail(
    String mode,
    String name,
    List<Color> colors,
    String scene,
  ) {
    final d = _themeDetail(mode);
    final repaintKey = GlobalKey();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: RepaintBoundary(
          key: repaintKey,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colors[2],
              border: Border.all(color: colors[0].withAlpha(60), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withAlpha(40),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color header strip
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors[0], colors[1]],
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: colors
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c,
                                    border: Border.all(
                                      color: Colors.white.withAlpha(180),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(30),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: _readableTextOn(colors[2]),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$scene，”${d['nickname']}”',
                          style: TextStyle(
                            color: _readableTextOn(colors[2]).withAlpha(180),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors[0].withAlpha(18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors[0].withAlpha(30)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: colors[0],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  d['creator']!,
                                  style: TextStyle(
                                    color: _readableTextOn(
                                      colors[2],
                                    ).withAlpha(210),
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          d['title']!,
                          style: TextStyle(
                            color: _readableTextOn(colors[2]),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d['detail']!,
                          style: TextStyle(
                            color: _readableTextOn(colors[2]).withAlpha(200),
                            fontSize: 12,
                            height: 1.65,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Buttons row
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: () => _saveCard(repaintKey, name),
                                  icon: const Icon(Icons.download, size: 17),
                                  label: const Text(
                                    '保存',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors[0],
                                    side: BorderSide(
                                      color: colors[0].withAlpha(100),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: FilledButton.icon(
                                  onPressed: () => _shareCard(repaintKey, name),
                                  icon: const Icon(Icons.share, size: 17),
                                  label: const Text(
                                    '分享',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors[0],
                                    foregroundColor:
                                        colors[0].computeLuminance() > 0.5
                                        ? const Color(0xFF222222)
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Future<void> _saveCard(GlobalKey key, String name) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'theme_$name.png'));
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Gal.putImage(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name 已保存到相册'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存失败，请检查相册权限')));
    }
  }

  Future<void> _shareCard(GlobalKey key, String name) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'theme_$name.png'));
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '拾晴日记 · $name主题\n$name — 记录天气，也记录你',
        ),
      );
    } catch (e) {
      // share_plus handles its own errors
    }
  }

  Map<String, String> _themeDetail(String mode) {
    return switch (mode) {
      'warm' => {
        'nickname': '晴日暖白',
        'creator':
            '我喜欢被阳光包裹的感觉。窗边那张桌子，一本摊开的日记本，笔尖在纸上沙沙地走，'
            '旁边一杯热茶冒着气。这种温暖不是燥热，是让人忍不住想跟自己说几句话的那种安宁。'
            '这是我给拾晴日记选的第一套颜色。',
        'title': '不只是一种颜色',
        'detail':
            '暖白色不是白色加了黄，是一种被时间浸润后的纸张色。'
            '它的温和不刺眼，适合长时间书写。棕色强调色像一杯手冲，'
            '不过分甜，不刻意苦，刚好能托住情绪的起伏。'
            '这大概是所有日记应用都想成为的样子：一个让你愿意坐下来、慢慢写的地方。',
      },
      'dark' => {
        'nickname': '静夜深蓝',
        'creator':
            '有时候就是半夜才有话想说。白天的话是社交用的，夜里的话才是自己的。'
            '关掉灯，只剩屏幕的光，指尖在暗色界面上敲字很安静，不会吵醒心里那些还没理清的念头。'
            '我需要一个不怕黑的主题。',
        'title': '黑夜是伴侣，不是敌人',
        'detail':
            '深蓝底色带一点紫调，避免了纯黑的压抑感，像是在月光下写字而不是在黑洞里。'
            '薰衣草蓝的强调色保留了夜间的温柔，不会刺眼，不会让深夜的情绪觉得被冒犯。'
            '这是一个为独处时刻准备的空间：不用假装开心，不用强撑白天的样子。',
      },
      'mint' => {
        'nickname': '雾感薄荷',
        'creator':
            '有些早晨推开窗，空气里还有昨晚下雨的味道，凉凉的、带着植物的清新。'
            '那种感觉应该被记录下来。我觉得写东西不一定要很沉重，'
            '有时候就是随手记一个念头、一张喜欢的外卖单、一句路过听到的话。清爽就好。',
        'title': '轻，但不轻薄',
        'detail':
            '低饱和的青碧绿像薄荷叶在杯底慢慢舒展，不是鲜艳夺目的荧光绿，'
            '而是被水雾蒙了一层的那种温柔绿意。它让写日记这件事变得轻快起来，'
            '像是在雨后林间散步，深呼吸一口，所有烦恼都能先放一放。',
      },
      _ => {
        'nickname': '豆沙柔粉',
        'creator':
            '这个颜色是我心里的隐藏款。有人说粉色太甜，那是没找到对的灰调。'
            '豆沙粉像是冬天大衣口袋里的一颗糖果，或者咖啡馆角落里铺着的那种旧丝绒沙发。'
            '它不张扬，但每次看到都会心里一动。我把它收在四个主题里，像是给懂的人留的小暗号。',
        'title': '被低估的温柔力量',
        'detail':
            '灰调豆沙粉在哑光质感下呈现出一种成熟的浪漫：不是少女梦里的粉红泡泡，'
            '而是成年后还愿意相信美好的那种笃定。暖棕色的强调色让整个界面有了温度，'
            '像一封手写信的封蜡，或一杯温水，不惊艳，但能安抚你一天的疲惫。'
            '这是一款值得细细品味的颜色，也是四款中最特别的存在。',
      },
    };
  }

  // ── Reusable components ──

  Widget _sectionTitle(String text, ThemeState theme, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(color: theme.textTertiary, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _card(ThemeState theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: XqDecorations.actionCard(
        theme.cardColor.withAlpha(theme.isDark ? 224 : 245),
        theme.borderColor,
        dark: theme.isDark,
        accent: theme.accentColor,
      ),
      child: child,
    );
  }

  Widget _divider(ThemeState theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: theme.borderColor, height: 1),
    );
  }

  Widget _infoRow(
    ThemeState theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.accentColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                trailing,
                style: TextStyle(
                  color: onTap == null ? theme.textTertiary : theme.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.accentColor.withAlpha(150),
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
