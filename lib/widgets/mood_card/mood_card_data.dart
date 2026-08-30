import 'package:flutter/material.dart';
import '../../constants/mood.dart';

/// 心情卡片模板共享数据包：模板是无状态的，所有可编辑内容都从这里来
class MoodCardData {
  final String dateText;
  final String rawDate; // YYYY-MM-DD 原始日期（节气等按真实日期计算）
  final int moodScore;
  final String moodEmoji;
  final String moodLabel;
  final String moodEn;
  final String bodyText;
  final List<String> tags;
  final String username;
  final String watermark; // cn | en | sq | sqrj | xiaoqing
  final String? weatherText;
  final String? cityName;
  final String? temperature;
  final bool square; // false=温润圆角 true=方寸直角
  final int streakDays; // 连续记录天数（含今天或昨天）
  final List<MoodDay> week; // 最近7天（今天在前）

  const MoodCardData({
    required this.dateText,
    this.rawDate = '',
    required this.moodScore,
    required this.moodEmoji,
    required this.moodLabel,
    required this.moodEn,
    required this.bodyText,
    required this.tags,
    required this.username,
    required this.watermark,
    this.weatherText,
    this.cityName,
    this.temperature,
    required this.square,
    this.streakDays = 0,
    this.week = const [],
  });
}

/// 单日心情聚合（用于火焰卡/周历卡）
class MoodDay {
  final String label; // 星期缩写
  final String? emoji;
  final int? color; // moodColors 值
  final bool isToday;

  const MoodDay({
    required this.label,
    this.emoji,
    this.color,
    required this.isToday,
  });
}

/// 由全部心情记录计算：连续天数 + 最近7天聚合
/// moods 元素至少含 date(YYYY-MM-DD) 和 emotion_type(int)
({
  int streak,
  List<MoodDay> week,
}) computeMoodStats(List<Map<String, dynamic>> moods, DateTime now) {
  // 按日期聚合（一天多条取最后一条的心情）
  final byDate = <String, Map<String, dynamic>>{};
  for (final m in moods) {
    final d = m['date']?.toString();
    if (d == null || d.isEmpty) continue;
    byDate[d] = m;
  }

  // 连续天数：从今天往前数；今天没记则从昨天开始（宽限）
  var streak = 0;
  var cursor = DateTime(now.year, now.month, now.day);
  if (!byDate.containsKey(_fmt(cursor))) cursor = cursor.subtract(const Duration(days: 1));
  while (byDate.containsKey(_fmt(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // 最近7天：今天在最前
  const weekLabels = ['一', '二', '三', '四', '五', '六', '日'];
  final week = <MoodDay>[];
  for (int i = 0; i < 7; i++) {
    final day = now.subtract(Duration(days: i));
    final rec = byDate[_fmt(day)];
    if (rec == null) {
      week.add(MoodDay(label: weekLabels[day.weekday - 1], isToday: i == 0));
    } else {
      final score = (rec['emotion_type'] as num?)?.toInt();
      week.add(MoodDay(
        label: weekLabels[day.weekday - 1],
        emoji: score != null ? (moodEmojis[score] ?? '') : '',
        color: score != null ? moodColors[score] : null,
        isToday: i == 0,
      ));
    }
  }
  return (streak: streak, week: week);
}

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';


/// 水印文案（共享给各模板）
String watermarkTextFor(String watermark) => switch (watermark) {
  'cn' => '拾晴日记',
  'sq' => 'sq.',
  'sqrj' => 's q r j',
  'xiaoqing' => '小晴',
  _ => 'SHI QING',
};

/// 模板描述与注册表：新增模板 = 写一个 builder + 在这里注册一行
class MoodCardTemplateSpec {
  final String id;
  final String name; // 中文名（色点提示用）
  final String label; // 卡面右上角 branding
  final List<Color> dotColors; // 选择器色点渐变
  final Widget Function(MoodCardData data) buildCard;

  const MoodCardTemplateSpec({
    required this.id,
    required this.name,
    required this.label,
    required this.dotColors,
    required this.buildCard,
  });
}
