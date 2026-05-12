import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../api/api_client.dart';
import '../constants/keys.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';
import '../widgets/white_noise_player.dart';
import '../widgets/wallpaper_manager.dart';
import 'login_page.dart';
import 'capsule_page.dart';
import 'legal_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  bool _saving = false;
  bool _checkedIn = false;
  int _consecutive = 0;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadCheckin();
    _loadAvatar();
  }

  Future<void> _loadCheckin() async {
    try {
      final s = await Api.getCheckinStatus();
      if (mounted) setState(() {
        _checkedIn = s['checked_in'] == true || s['checked_in'] == 1;
        _consecutive = s['consecutive_days'] ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString('avatar_path');
    if (p != null && File(p).existsSync() && mounted) {
      setState(() => _avatarPath = p);
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 256, imageQuality: 80);
      if (img != null) {
        final dir = await getApplicationDocumentsDirectory();
        final dest = '${dir.path}/avatar.jpg';
        File(img.path).copySync(dest);
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('avatar_path', dest);
        if (mounted) setState(() => _avatarPath = dest);
      }
    } catch (_) {}
  }

  Future<void> _doCheckin() async {
    HapticFeedback.heavyImpact();
    try {
      final r = await Api.checkin();
      if (mounted) setState(() {
        _checkedIn = true;
        _consecutive = r['consecutive_days'] ?? _consecutive + 1;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _oldPwCtrl.dispose();
    _newPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await Api.updateDisplayName(name);
      if (mounted) {
        context.read<AppState>().setDisplayName(name);
        _nameCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
            _snack('名字已更新', true));
      }
    } catch (e) {
      if (mounted) _showErr('保存失败: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_oldPwCtrl.text.isEmpty || _newPwCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await Api.changePassword(_oldPwCtrl.text, _newPwCtrl.text);
      if (mounted) {
        _oldPwCtrl.clear();
        _newPwCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
            _snack('密码已更改', true));
      }
    } catch (e) {
      if (mounted) _showErr('修改失败: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final ok1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('注销账号',
            style: TextStyle(color: Color(0xFFD4837A))),
        content: const Text('注销后你的所有云端数据将被永久删除，且无法恢复。确定要继续吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定注销',
                  style: TextStyle(color: Color(0xFFD4837A)))),
        ],
      ),
    );
    if (ok1 != true) return;
    try {
      await Api.deleteAccount();
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false);
      }
    } catch (e) {
      if (mounted) _showErr('注销失败，请稍后重试');
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('退出',
                  style: TextStyle(color: Color(0xFFD4837A)))),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.token);
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false);
    }
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  SnackBar _snack(String msg, bool ok) {
    return SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        duration: const Duration(seconds: 2),
        backgroundColor: ok ? const Color(0xFF7B9E7B) : null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final appState = context.watch<AppState>();
    final isDark = theme.isDark;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            // Header with avatar
            Center(
              child: Column(children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.accentColor.withAlpha(20),
                      border: Border.all(color: theme.accentColor.withAlpha(80), width: 1.5),
                    ),
                    child: _avatarPath != null
                        ? ClipOval(child: Image.file(File(_avatarPath!), fit: BoxFit.cover))
                        : Icon(Icons.camera_alt_outlined, size: 28, color: theme.accentColor),
                  ),
                ),
                const SizedBox(height: 10),
                Text(appState.displayName.isNotEmpty ? appState.displayName : '用户',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: theme.textPrimary)),
              ]),
            ),
            const SizedBox(height: 16),
            // Check-in
            GestureDetector(
              onTap: _checkedIn ? null : _doCheckin,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: theme.accentColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.accentColor.withAlpha(60)),
                ),
                child: Center(
                  child: Text(
                    _checkedIn ? '已连续签到 $_consecutive 天' : '今日签到',
                    style: TextStyle(color: theme.accentColor, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Section: 修改名字
            _sectionTitle('修改名字', theme),
            const SizedBox(height: 8),
            _inputRow(_nameCtrl, '输入新名字...', Icons.edit_outlined,
                theme, _updateName),
            const SizedBox(height: 24),
            // Section: 修改密码
            _sectionTitle('修改密码', theme),
            const SizedBox(height: 8),
            _pwField(_oldPwCtrl, '当前密码', theme),
            const SizedBox(height: 8),
            _pwField(_newPwCtrl, '新密码', theme),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saving ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentColor,
                  minimumSize: const Size(100, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_saving ? '...' : '修改密码',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            // Section: 主题切换
            _sectionTitle('主题切换', theme),
            const SizedBox(height: 8),
            Row(
              children: ThemeState.themeNames.entries.map((e) {
                final active = theme.themeMode == e.key;
                final colors = ThemeState.themeColors[e.key]!;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => theme.setTheme(e.key),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: colors[1],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: active
                                ? colors[0]
                                : Colors.transparent,
                            width: 2),
                      ),
                      child: Column(children: [
                        Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors[0])),
                        const SizedBox(height: 6),
                        Text(e.value,
                            style: TextStyle(
                                fontSize: 12,
                                color: active
                                    ? colors[0]
                                    : theme.textSecondary)),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            // Section: 其他
            _sectionTitle('其他', theme),
            const SizedBox(height: 8),
            _linkItem(Icons.hourglass_empty, '时光胶囊', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CapsulePage()));
            }, theme),
            _linkItem(Icons.description_outlined, '隐私政策', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LegalPage(isPrivacy: true)));
            }, theme),
            _linkItem(Icons.article_outlined, '用户协议', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LegalPage(isPrivacy: false)));
            }, theme),
            _linkItem(Icons.delete_outline, '注销账号', _deleteAccount,
                theme, danger: true),
            const SizedBox(height: 24),
            _sectionTitle('专属壁纸', theme),
            const SizedBox(height: 8),
            _WallpaperPicker(),
            const SizedBox(height: 24),
            _sectionTitle('白噪音', theme),
            const SizedBox(height: 8),
            const WhiteNoisePlayer(),
            const Divider(height: 32),
            // Logout
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD4837A)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('退出登录',
                    style: TextStyle(color: Color(0xFFD4837A))),
              ),
            ),
            const SizedBox(height: 40),
            // ICP
            Center(
              child: Text('ICP备XXXXXX号',
                  style: TextStyle(
                      fontSize: 11, color: theme.textSecondary)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, ThemeState theme) {
    return Text(text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.textSecondary));
  }

  Widget _inputRow(TextEditingController ctrl, String hint, IconData icon,
      ThemeState theme, VoidCallback onSave) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(icon, size: 20, color: theme.accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: ctrl,
            style: TextStyle(color: theme.textPrimary),
            cursorColor: theme.accentColor,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: theme.textSecondary.withAlpha(120)),
              border: InputBorder.none,
            ),
          ),
        ),
        TextButton(
            onPressed: _saving ? null : onSave,
            child: const Text('保存',
                style: TextStyle(color: Color(0xFFC4A46C)))),
        const SizedBox(width: 4),
      ]),
    );
  }

  Widget _pwField(
      TextEditingController ctrl, String hint, ThemeState theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: true,
        style: TextStyle(color: theme.textPrimary),
        cursorColor: theme.accentColor,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: theme.textSecondary.withAlpha(120)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _linkItem(IconData icon, String text, VoidCallback onTap,
      ThemeState theme,
      {bool danger = false}) {
    return ListTile(
      leading: Icon(icon,
          size: 22,
          color: danger
              ? const Color(0xFFD4837A)
              : theme.textSecondary),
      title: Text(text,
          style: TextStyle(
              color:
                  danger ? const Color(0xFFD4837A) : theme.textPrimary)),
      trailing: const Icon(Icons.chevron_right,
          size: 20, color: Color(0xFF787060)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── Wallpaper Picker ──
class _WallpaperPicker extends StatefulWidget {
  @override
  State<_WallpaperPicker> createState() => _WallpaperPickerState();
}

class _WallpaperPickerState extends State<_WallpaperPicker> {
  String _active = 'none';
  List<String> _unlocked = ['none'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() {
      _active = p.getString('active_wallpaper') ?? 'none';
      _unlocked = p.getStringList('unlocked_wallpapers') ?? ['none'];
    });
  }

  Future<void> _pick(String id) async {
    final p = await SharedPreferences.getInstance();
    p.setString('active_wallpaper', id);
    setState(() => _active = id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeState>(context, listen: false);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: wallpapers.take(8).map((w) {
        final unlocked = _unlocked.contains(w.id);
        final active = _active == w.id;
        return GestureDetector(
          onTap: unlocked
              ? () => _pick(w.id)
              : null,
          child: Container(
            width: (MediaQuery.of(context).size.width - 56) / 3,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: unlocked
                  ? (active
                      ? const Color(0xFFC4A46C).withAlpha(20)
                      : theme.surfaceAlpha)
                  : theme.surfaceAlpha.withAlpha(60),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: active
                      ? const Color(0xFFC4A46C)
                      : theme.borderColor,
                  width: active ? 2 : 1),
            ),
            child: Column(children: [
              if (unlocked)
                Text(w.name,
                    style: TextStyle(
                        fontSize: 12,
                        color: active
                            ? const Color(0xFFC4A46C)
                            : theme.textSecondary))
              else ...[
                const Icon(Icons.lock_outline, size: 16,
                    color: Color(0xFF787060)),
                const SizedBox(height: 4),
                Text(w.desc,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF787060))),
              ],
            ]),
          ),
        );
      }).toList(),
    );
  }
}
