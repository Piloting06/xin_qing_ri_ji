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
import '../theme/xq_colors.dart';
import '../theme/xq_typography.dart';
import '../services/notification_service.dart';
import 'capsule_page.dart';
import 'friends_page.dart';
import 'legal_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _avatarFileKey = 'avatar_file';
  static const _legacyAvatarPathKey = 'avatar_path';
  static const _avatarFileName = 'avatar.jpg';

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
        _capsuleNotify = prefs.getBool(StorageKeys.capsuleNotify) ?? true;
      });
    }
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
    final storedFile = prefs.getString(_avatarFileKey);
    if (storedFile != null && storedFile.isNotEmpty) {
      final file = File(p.join(dir.path, storedFile));
      if (file.existsSync()) {
        if (mounted) setState(() => _avatarPath = file.path);
        return;
      }
      await prefs.remove(_avatarFileKey);
    }

    final legacyPath = prefs.getString(_legacyAvatarPathKey);
    if (legacyPath != null && legacyPath.isNotEmpty) {
      final legacyFile = File(legacyPath);
      if (legacyFile.existsSync()) {
        final dest = File(p.join(dir.path, _avatarFileName));
        if (p.normalize(legacyFile.path) != p.normalize(dest.path)) {
          await legacyFile.copy(dest.path);
        }
        await prefs.setString(_avatarFileKey, _avatarFileName);
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
      final dest = File(p.join(dir.path, _avatarFileName));
      await File(img.path).copy(dest.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarFileKey, _avatarFileName);
      await prefs.remove(_legacyAvatarPathKey);
      if (!mounted) return;
      setState(() => _avatarPath = dest.path);
      ScaffoldMessenger.of(context).showSnackBar(_snack('头像已保存', true));
    } catch (_) {
      if (mounted) _showErr('头像保存失败，请重试');
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
        ScaffoldMessenger.of(context).showSnackBar(_snack('今日已记录', true));
      }
    } catch (_) {
      if (mounted) _showErr('签到失败，请稍后重试');
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
        ScaffoldMessenger.of(context).showSnackBar(_snack('名字已更新', true));
      }
    } catch (_) {
      if (mounted) _showErr('名字保存失败，请稍后重试');
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
        ScaffoldMessenger.of(context).showSnackBar(_snack('密码已更改', true));
      }
    } catch (_) {
      if (mounted) _showErr('修改失败，请检查当前密码');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final theme = context.read<ThemeState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('注销账号', style: TextStyle(color: theme.errorColor)),
        content: const Text('注销后会退出当前账号，并释放手机号。重新注册会创建一个全新账号。确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: theme.errorColor),
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
      if (mounted) _showErr('注销失败，请稍后重试');
    }
  }

  Future<void> _logout() async {
    final theme = context.read<ThemeState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: theme.errorColor),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.token);
    await prefs.remove(StorageKeys.phone);
    await prefs.remove(StorageKeys.username);
    await prefs.remove(StorageKeys.displayName);
    if (!mounted) return;
    context.read<AppState>().clearUser();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  SnackBar _snack(String msg, bool ok) {
    final theme = context.read<ThemeState>();
    return SnackBar(
      content: Text(msg),
      backgroundColor: ok ? theme.successColor : null,
      duration: const Duration(seconds: 2),
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
            // ── Profile header ──
            _profileHeader(theme, appState),
            const SizedBox(height: 28),

            // ── 我的记录 ──
            _sectionTitle('我的记录', theme),
            const SizedBox(height: 10),
            _recordsGroup(theme),
            const SizedBox(height: 24),

            // ── 设置 ──
            _sectionTitle('设置', theme),
            const SizedBox(height: 10),
            _settingsGroup(theme, appState),
            const SizedBox(height: 24),

            // ── 账号 ──
            _sectionTitle('账号', theme),
            const SizedBox(height: 10),
            _accountGroup(theme),

            const SizedBox(height: 32),
            Text(
              '心晴日记 2.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile header: big avatar, name, phone ──
  Widget _profileHeader(ThemeState theme, AppState appState) {
    final name =
        appState.displayName.isNotEmpty ? appState.displayName : '用户';

    return Column(
      children: [
        GestureDetector(
          onTap: _pickAvatar,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.accentColor.withAlpha(50),
                  theme.accentColor.withAlpha(18),
                ],
              ),
              border: Border.all(
                color: theme.accentColor.withAlpha(100),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.accentColor.withAlpha(30),
                  blurRadius: 20,
                ),
              ],
            ),
            child: _avatarPath != null
                ? ClipOval(
                    child: Image.file(File(_avatarPath!), fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 30, color: theme.accentColor),
                      const SizedBox(height: 2),
                      Text(
                        '设置头像',
                        style: TextStyle(
                          color: theme.accentColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: XqTypography.headlineMedium.copyWith(
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _phone.isEmpty ? '账号信息已同步' : _phone,
          style: TextStyle(color: theme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  // ── 我的记录 ──
  Widget _recordsGroup(ThemeState theme) {
    return _card(
      theme,
      child: Column(
        children: [
          _infoRow(
            theme,
            icon: Icons.local_fire_department_outlined,
            title: _checkedIn ? '已连续记录 $_consecutive 天' : '今天还没记录',
            subtitle: _checkedIn
                ? '保持住这份小小的连续感'
                : _checkingIn
                    ? '正在帮你留住今天这一笔'
                    : '轻点一下，给今天留个印记',
            trailing: _checkedIn ? '已完成' : (_checkingIn ? '记录中' : '签到'),
            onTap: (_checkedIn || _checkingIn) ? null : _doCheckin,
          ),
          _divider(theme),
          // Time capsule + notification toggle
          _infoRow(
            theme,
            icon: Icons.hourglass_empty,
            title: '时光胶囊',
            subtitle: '写给未来某一天的自己',
            trailing: '打开',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CapsulePage()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '胶囊提醒  到期时通知我',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: _capsuleNotify,
                  onChanged: (v) async {
                    if (v) {
                      await NotificationService.requestPermissionIfNeeded();
                    }
                    _setCapsuleNotify(v);
                  },
                ),
              ],
            ),
          ),
          _divider(theme),
          _infoRow(
            theme,
            icon: Icons.people_outline,
            title: '好友',
            subtitle: '管理好友，查看朋友心情',
            trailing: '查看',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendsPage()),
            ),
          ),
        ],
      ),
    );
  }

  // ── 设置 ──
  Widget _settingsGroup(ThemeState theme, AppState appState) {
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nickname - tap to edit
          _infoRow(
            theme,
            icon: Icons.edit_outlined,
            title: '昵称',
            subtitle: appState.displayName.isNotEmpty
                ? appState.displayName
                : '点击设置',
            trailing: '修改',
            onTap: () => _showNicknameDialog(theme, appState),
          ),
          _divider(theme),

          // Theme - inline selector
          Text(
            '主题',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ThemeState.themeNames.entries.map((entry) {
              final active = theme.themeMode == entry.key;
              final colors = ThemeState.themeColors[entry.key]!;
              final desc = _themeSceneDesc(entry.key);
              return Expanded(
                child: GestureDetector(
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
                    height: 64,
                    margin: EdgeInsets.only(
                        right: entry.key != ThemeState.themeNames.keys.last
                            ? 6
                            : 0),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: colors[2],
                      border: Border.all(
                        color: active
                            ? colors[0]
                            : theme.borderColor.withAlpha(100),
                        width: active ? 2 : 0.5,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: colors[0].withAlpha(30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 3 color dots
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: colors.map((c) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c,
                                border: Border.all(
                                  color: Colors.white.withAlpha(120), width: 0.5),
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.value,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active  ? colors[0] : _readableTextOn(colors[2]),
                            fontSize: active ? 11 : 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        if (active)
                          Text(
                            desc,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _readableTextOn(colors[2]).withAlpha(160),
                              fontSize: 8,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 2),
            child: Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 13,
                    color: theme.textTertiary.withAlpha(150)),
                const SizedBox(width: 5),
                Text(
                  '点击已选中的主题，可以查看它的创作故事',
                  style: TextStyle(
                    color: theme.textTertiary.withAlpha(150),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _divider(theme),
          _infoRow(
            theme,
            icon: Icons.lock_outline,
            title: '修改密码',
            subtitle: '更改登录密码',
            trailing: '修改',
            onTap: () => _showPasswordSheet(theme),
          ),
        ],
      ),
    );
  }

  // ── 账号 ──
  Widget _accountGroup(ThemeState theme) {
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Privacy & Terms
          _infoRow(
            theme,
            icon: Icons.description_outlined,
            title: '隐私政策',
            subtitle: '查看数据和隐私说明',
            trailing: '查看',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalPage(isPrivacy: true),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          _infoRow(
            theme,
            icon: Icons.article_outlined,
            title: '用户协议',
            subtitle: '查看使用约定',
            trailing: '查看',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalPage(isPrivacy: false),
                ),
              );
            },
          ),

          _divider(theme),

          // QQ group
          _infoRow(
            theme,
            icon: Icons.chat_bubble_outline,
            title: '加入交流群',
            subtitle: '和更多用户一起聊聊',
            trailing: '加入',
            onTap: () async {
              final url = Uri.parse('https://qm.qq.com/q/EKUVPDQV8Y');
              try {
                final can = await canLaunchUrl(url);
                if (can) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请先安装 QQ')),
                    );
                  }
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('跳转失败，请稍后重试')),
                  );
                }
              }
            },
          ),

          _divider(theme),

          // Danger zone
          _dangerButton(theme, '退出登录', Icons.logout, _logout, filled: false),
          const SizedBox(height: 8),
          _dangerButton(
              theme, '注销账号', Icons.delete_outline, _deleteAccount, filled: true),
        ],
      ),
    );
  }

  void _showNicknameDialog(ThemeState theme, AppState appState) {
    final ctrl = TextEditingController(
        text: appState.displayName.isNotEmpty ? appState.displayName : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('修改昵称',
            style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w700)),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: theme.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('修改密码',
                      style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: oldCtrl,
                    obscureText: obscureOld,
                    style: TextStyle(color: theme.textPrimary, fontSize: 14),
                    cursorColor: theme.accentColor,
                    decoration: InputDecoration(
                      labelText: '当前密码',
                      labelStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
                      prefixIcon: Icon(Icons.lock_outline, color: theme.accentColor, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility,
                            color: theme.textSecondary, size: 18),
                        onPressed: () => setSheetState(() => obscureOld = !obscureOld),
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
                      labelStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
                      prefixIcon: Icon(Icons.lock_reset, color: theme.accentColor, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility,
                            color: theme.textSecondary, size: 18),
                        onPressed: () => setSheetState(() => obscureNew = !obscureNew),
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
                      labelStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
                      prefixIcon: Icon(Icons.lock_reset, color: theme.accentColor, size: 18),
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
                        if (oldCtrl.text.isEmpty || newCtrl.text.length < 6 ||
                            newCtrl.text != confirmCtrl.text) return;
                        _oldPwCtrl.text = oldCtrl.text;
                        _newPwCtrl.text = newCtrl.text;
                        _changePassword();
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        foregroundColor: theme.textOnAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
    return (bg.computeLuminance() > 0.5) ? const Color(0xFF333333) : const Color(0xFFEEEEEE);
  }

  void _showThemeDetail(String mode, String name, List<Color> colors, String scene) {
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
              borderRadius: BorderRadius.circular(24),
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors[0], colors[1]],
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: colors.map((c) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c,
                              border: Border.all(color: Colors.white.withAlpha(180), width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 6),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                              color: _readableTextOn(colors[2]),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 4),
                        Text('$scene，”${d['nickname']}”',
                            style: TextStyle(
                              color: _readableTextOn(colors[2]).withAlpha(180),
                              fontSize: 13,
                              height: 1.4,
                            )),
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
                              Icon(Icons.auto_awesome, size: 16, color: colors[0]),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(d['creator']!,
                                    style: TextStyle(
                                      color: _readableTextOn(colors[2]).withAlpha(210),
                                      fontSize: 13,
                                      height: 1.6,
                                    )),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(d['title']!,
                            style: TextStyle(
                              color: _readableTextOn(colors[2]),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(height: 8),
                        Text(d['detail']!,
                            style: TextStyle(
                              color: _readableTextOn(colors[2]).withAlpha(200),
                              fontSize: 12,
                              height: 1.65,
                            )),
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
                                  label: const Text('保存', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors[0],
                                    side: BorderSide(color: colors[0].withAlpha(100)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
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
                                  label: const Text('分享', style: TextStyle(fontSize: 12)),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors[0],
                                    foregroundColor: colors[0].computeLuminance() > 0.5
                                        ? const Color(0xFF222222)
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
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
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'theme_$name.png'));
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Gal.putImage(file.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name 已保存到相册'),
              duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请检查相册权限')),
        );
      }
    }
  }

  Future<void> _shareCard(GlobalKey key, String name) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
          text: '心晴日记 · $name主题\n$name — 记录天气，也记录你',
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
        'creator': '我喜欢被阳光包裹的感觉。窗边那张桌子，一本摊开的日记本，笔尖在纸上沙沙地走，'
            '旁边一杯热茶冒着气。这种温暖不是燥热，是让人忍不住想跟自己说几句话的那种安宁。'
            '这是我给心晴日记选的第一套颜色。',
        'title': '不只是一种颜色',
        'detail': '暖白色不是白色加了黄，是一种被时间浸润后的纸张色。'
            '它的温和不刺眼，适合长时间书写。棕色强调色像一杯手冲，'
            '不过分甜，不刻意苦，刚好能托住情绪的起伏。'
            '这大概是所有日记应用都想成为的样子：一个让你愿意坐下来、慢慢写的地方。',
      },
      'dark' => {
        'nickname': '静夜深蓝',
        'creator': '有时候就是半夜才有话想说。白天的话是社交用的，夜里的话才是自己的。'
            '关掉灯，只剩屏幕的光，指尖在暗色界面上敲字很安静，不会吵醒心里那些还没理清的念头。'
            '我需要一个不怕黑的主题。',
        'title': '黑夜是伴侣，不是敌人',
        'detail': '深蓝底色带一点紫调，避免了纯黑的压抑感，像是在月光下写字而不是在黑洞里。'
            '薰衣草蓝的强调色保留了夜间的温柔，不会刺眼，不会让深夜的情绪觉得被冒犯。'
            '这是一个为独处时刻准备的空间：不用假装开心，不用强撑白天的样子。',
      },
      'mint' => {
        'nickname': '雾感薄荷',
        'creator': '有些早晨推开窗，空气里还有昨晚下雨的味道，凉凉的、带着植物的清新。'
            '那种感觉应该被记录下来。我觉得写东西不一定要很沉重，'
            '有时候就是随手记一个念头、一张喜欢的外卖单、一句路过听到的话。清爽就好。',
        'title': '轻，但不轻薄',
        'detail': '低饱和的青碧绿像薄荷叶在杯底慢慢舒展，不是鲜艳夺目的荧光绿，'
            '而是被水雾蒙了一层的那种温柔绿意。它让写日记这件事变得轻快起来，'
            '像是在雨后林间散步，深呼吸一口，所有烦恼都能先放一放。',
      },
      _ => {
        'nickname': '豆沙柔粉',
        'creator': '这个颜色是我心里的隐藏款。有人说粉色太甜，那是没找到对的灰调。'
            '豆沙粉像是冬天大衣口袋里的一颗糖果，或者咖啡馆角落里铺着的那种旧丝绒沙发。'
            '它不张扬，但每次看到都会心里一动。我把它收在四个主题里，像是给懂的人留的小暗号。',
        'title': '被低估的温柔力量',
        'detail': '灰调豆沙粉在哑光质感下呈现出一种成熟的浪漫：不是少女梦里的粉红泡泡，'
            '而是成年后还愿意相信美好的那种笃定。暖棕色的强调色让整个界面有了温度，'
            '像一封手写信的封蜡，或一杯温水，不惊艳，但能安抚你一天的疲惫。'
            '这是一款值得细细品味的颜色，也是四款中最特别的存在。',
      },
    };
  }

  // ── Reusable components ──

  Widget _sectionTitle(String text, ThemeState theme) {
    return Text(
      text,
      style: TextStyle(
        color: theme.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _card(ThemeState theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.borderColor),
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

  Widget _inputRow(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    ThemeState theme,
    VoidCallback onSave,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            style: TextStyle(color: theme.textPrimary, fontSize: 14),
            cursorColor: theme.accentColor,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: theme.accentColor, size: 20),
              hintText: hint,
              hintStyle: TextStyle(color: theme.textTertiary, fontSize: 13),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.accentColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 44,
          child: FilledButton(
            onPressed: _saving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: theme.accentColor,
              foregroundColor: theme.textOnAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('保存'),
          ),
        ),
      ],
    );
  }

  Widget _switchTile(
    ThemeState theme, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _pwField(TextEditingController ctrl, String hint, ThemeState theme) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      cursorColor: theme.accentColor,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline, color: theme.accentColor, size: 18),
        hintText: hint,
        hintStyle: TextStyle(color: theme.textTertiary, fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.accentColor),
        ),
      ),
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
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.accentColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.accentColor, size: 20),
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
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
              Text(
                trailing,
                style: TextStyle(
                  color: onTap == null ? theme.textTertiary : theme.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dangerButton(
    ThemeState theme,
    String label,
    IconData icon,
    VoidCallback onTap, {
    required bool filled,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: filled
          ? FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: theme.errorColor,
                foregroundColor:
                    theme.isDark ? XqColors.darkBackground : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.errorColor,
                side: BorderSide(color: theme.errorColor.withAlpha(100)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
    );
  }
}
