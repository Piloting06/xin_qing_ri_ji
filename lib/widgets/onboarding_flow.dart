import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../constants/keys.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';

class OnboardingFlow {
  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final dn = prefs.getString(StorageKeys.displayName) ?? '';
    final onboarded = prefs.getBool(StorageKeys.onboardingDone) ?? false;

    if (!context.mounted) return;

    if (dn.isEmpty) {
      final name = await _showNameDialog(context);
      if (name == null || !context.mounted) return;
      try {
        await Api.updateDisplayName(name);
      } catch (_) {}
      if (context.mounted) context.read<AppState>().setDisplayName(name);
    }

    if (!onboarded && context.mounted) {
      final ok = await _showPermissionDialog(context);
      if (ok == true) {
        prefs.setBool(StorageKeys.onboardingDone, true);
      }
    }
  }

  static Future<String?> _showNameDialog(BuildContext context) {
    final ctrl = TextEditingController();
    final theme = context.read<ThemeState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFC4A46C).withAlpha(60)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('欢迎来到心晴日记',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC4A46C))),
                const SizedBox(height: 8),
                Text('先给自己起一个名字吧～',
                    style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondary)),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: TextStyle(color: theme.textPrimary, fontSize: 18),
                  textAlign: TextAlign.center,
                  cursorColor: const Color(0xFFC4A46C),
                  decoration: InputDecoration(
                    hintText: '你的名字',
                    hintStyle:
                        TextStyle(color: theme.textSecondary.withAlpha(120)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFC4A46C), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = ctrl.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(ctx, name);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4A46C),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: const Text('确定',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> _showPermissionDialog(BuildContext context) {
    final theme = context.read<ThemeState>();

    final permissions = [
      {
        'icon': Icons.location_on_outlined,
        'title': '定位',
        'desc': '获取你所在的城市，展示准确的天气信息',
      },
      {
        'icon': Icons.photo_library_outlined,
        'title': '相册',
        'desc': '上传心情照片——照片只存在你的手机本地，不上传服务器',
      },
      {
        'icon': Icons.notifications_outlined,
        'title': '通知',
        'desc': '早晚安提醒、时光胶囊到期通知',
      },
      {
        'icon': Icons.folder_outlined,
        'title': '存储',
        'desc': '保存天气心情卡和限定壁纸到本地',
      },
    ];

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFC4A46C).withAlpha(60)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text('我们需要以下权限',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC4A46C))),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text('你的情绪数据只属于你自己',
                      style: TextStyle(
                          fontSize: 13, color: theme.textSecondary)),
                ),
                const SizedBox(height: 20),
                ...permissions.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                                p['icon'] as IconData,
                                size: 22,
                                color: const Color(0xFFC4A46C)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(p['title'] as String,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: theme.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(p['desc'] as String,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: theme.textSecondary)),
                                ])),
                          ]),
                    )),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx, true);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4A46C),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: const Text('我知道了',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
