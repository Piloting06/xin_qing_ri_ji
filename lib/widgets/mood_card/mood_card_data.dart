import 'package:flutter/material.dart';

/// 心情卡片模板共享数据包：模板是无状态的，所有可编辑内容都从这里来
class MoodCardData {
  final String dateText;
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

  const MoodCardData({
    required this.dateText,
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
  });
}

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
