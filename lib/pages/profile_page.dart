import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../constants/keys.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';
import '../theme/xq_colors.dart';
import '../theme/xq_typography.dart';
import 'capsule_page.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _profileCard(theme, appState),
            const SizedBox(height: 18),
            _sectionTitle('日常偏好', theme),
            const SizedBox(height: 10),
            _settingsCard(theme),
            const SizedBox(height: 20),
            _sectionTitle('我的记录', theme),
            const SizedBox(height: 10),
            _recordsCard(theme),
            const SizedBox(height: 20),
            _sectionTitle('账号与安全', theme),
            const SizedBox(height: 10),
            _securityCard(theme),
            const SizedBox(height: 20),
            _sectionTitle('关于', theme),
            const SizedBox(height: 10),
            _aboutCard(theme),
            const SizedBox(height: 16),
            Text(
              '心晴日记 1.6.1+7',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(ThemeState theme, AppState appState) {
    final name = appState.displayName.isNotEmpty ? appState.displayName : '用户';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.isDark
              ? [theme.cardColor, theme.cardElevated]
              : [theme.cardElevated, theme.cardColor],
        ),
        border: Border.all(color: theme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(theme.isDark ? 44 : 14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.accentColor.withAlpha(22),
                border: Border.all(
                  color: theme.accentColor.withAlpha(90),
                  width: 1.4,
                ),
              ),
              child: _avatarPath != null
                  ? ClipOval(
                      child: Image.file(File(_avatarPath!), fit: BoxFit.cover),
                    )
                  : Icon(
                      Icons.camera_alt_outlined,
                      size: 28,
                      color: theme.accentColor,
                    ),
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
                  _phone.isEmpty ? '账号信息已同步' : _phone,
                  style: TextStyle(color: theme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _miniChip(
                      theme,
                      Icons.local_fire_department_outlined,
                      _checkedIn ? '已记录' : '待记录',
                    ),
                    _miniChip(
                      theme,
                      Icons.palette_outlined,
                      ThemeState.themeNames[theme.themeMode] ?? '主题',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(ThemeState theme) {
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputRow(
            _nameCtrl,
            '输入新的昵称',
            Icons.edit_outlined,
            theme,
            _updateName,
          ),
          const SizedBox(height: 14),
          _switchTile(
            theme,
            title: '胶囊提醒',
            subtitle: '到期那天用提醒卡把你带回这颗胶囊',
            value: _capsuleNotify,
            onChanged: _setCapsuleNotify,
          ),
          const SizedBox(height: 14),
          _infoRow(
            theme,
            icon: Icons.palette_outlined,
            title: '主题',
            subtitle: ThemeState.themeNames[theme.themeMode] ?? '晴日暖白',
            trailing: '更换',
            onTap: () => _openThemeSheet(),
          ),
        ],
      ),
    );
  }

  Widget _recordsCard(ThemeState theme) {
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
          Divider(color: theme.borderColor, height: 22),
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
        ],
      ),
    );
  }

  Widget _securityCard(ThemeState theme) {
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pwField(_oldPwCtrl, '当前密码', theme),
          const SizedBox(height: 10),
          _pwField(_newPwCtrl, '新密码（至少 6 位）', theme),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _saving ? null : _changePassword,
              style: FilledButton.styleFrom(
                backgroundColor: theme.accentColor,
                foregroundColor: theme.textOnAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(_saving ? '处理中...' : '修改密码'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '修改登录密码、退出账号和注销操作都在这里完成。',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: theme.borderColor, height: 1),
          const SizedBox(height: 12),
          _dangerButton(theme, '退出登录', Icons.logout, _logout, filled: false),
          const SizedBox(height: 10),
          _dangerButton(
            theme,
            '注销账号',
            Icons.delete_outline,
            _deleteAccount,
            filled: true,
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(ThemeState theme) {
    return _card(
      theme,
      child: Column(
        children: [
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
          Divider(color: theme.borderColor, height: 22),
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
        ],
      ),
    );
  }

  Widget _card(ThemeState theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.borderColor),
      ),
      child: child,
    );
  }

  Widget _miniChip(ThemeState theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.accentColor.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.accentColor.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.accentColor),
          const SizedBox(width: 4),
          Text(
            label,
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

  void _openThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final theme = sheetCtx.watch<ThemeState>();
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('选择主题', style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: ThemeState.themeNames.length,
                  itemBuilder: (_, i) {
                    final entry = ThemeState.themeNames.entries.elementAt(i);
                    final active = theme.themeMode == entry.key;
                    final colors = ThemeState.themeColors[entry.key]!;
                    return _themeCard(entry.key, entry.value, colors, active, theme);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _themeCard(
    String mode,
    String name,
    List<Color> colors,
    bool active,
    ThemeState theme,
  ) {
    final titleColor = mode == 'dark'
        ? XqColors.darkTextPrimary
        : XqColors.lightTextPrimary;
    final descColor = mode == 'dark'
        ? XqColors.darkTextSecondary
        : XqColors.lightTextSecondary;
    final desc = switch (mode) {
      'dark' => '夜色柔光渐变',
      'mint' => '水光朦胧雾感',
      'blush' => '莫兰迪哑光质',
      _ => '奶油手账纸感',
    };
    return Material(
      color: colors[1],
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => theme.setTheme(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? theme.accentColor : theme.borderColor,
              width: active ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ...colors.map(
                    (c) => Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(80)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    active ? Icons.check_circle : Icons.circle_outlined,
                    size: 18,
                    color: active ? theme.accentColor : descColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(color: descColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, ThemeState theme) {
    return Text(
      text,
      style: XqTypography.labelLarge.copyWith(color: theme.textSecondary),
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
            style: TextStyle(color: theme.textPrimary),
            cursorColor: theme.accentColor,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: theme.accentColor, size: 20),
              hintText: hint,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: _saving ? null : onSave,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.accentColor,
              side: BorderSide(color: theme.accentColor.withAlpha(90)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
      style: TextStyle(color: theme.textPrimary),
      cursorColor: theme.accentColor,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.lock_outline,
          color: theme.accentColor,
          size: 20,
        ),
        hintText: hint,
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
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.accentColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.accentColor, size: 21),
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
      height: 46,
      child: filled
          ? FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: theme.errorColor,
                foregroundColor: theme.isDark
                    ? XqColors.darkBackground
                    : Colors.white,
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
