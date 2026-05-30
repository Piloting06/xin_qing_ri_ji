import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';

class XqToast {
  /// 成功提示 — 绿色底 2s
  static void success(BuildContext context, String msg) {
    final theme = context.read<ThemeState>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14))),
          ],
        ),
        backgroundColor: theme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 失败提示 — 柔和红底 3s
  static void error(BuildContext context, String msg) {
    final theme = context.read<ThemeState>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14))),
          ],
        ),
        backgroundColor: theme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 普通提示 — 主题色底 2s
  static void info(BuildContext context, String msg) {
    final theme = context.read<ThemeState>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14)),
        backgroundColor: theme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
