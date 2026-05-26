/// 统一时间格式化工具。
/// 所有时间字符串应为 ISO 8601 格式（含 Z 后缀或 UTC offset），通过 .toLocal() 转为本地时间后展示。
class TimeUtils {
  /// 相对时间：刚刚 / X分钟前 / X小时前 / 昨天 HH:MM / M月D日 HH:MM
  static String relative(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '刚刚';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(targetDay).inDays;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (diffDays == 0) return '$hh:$mm';
    if (diffDays == 1) return '昨天 $hh:$mm';
    return '${local.month}月${local.day}日 $hh:$mm';
  }

  /// 绝对时间：2026年5月26日 周二 14:30
  static String absolute(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final wd = weekdays[local.weekday - 1];
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.year}年${local.month}月${local.day}日 $wd $hh:$mm';
  }

  /// 短格式绝对时间：5月26日 周二 · 14:30（卡片专用）
  static String short(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final wd = weekdays[local.weekday - 1];
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.month}月${local.day}日 $wd · $hh:$mm';
  }
}
