import 'package:flutter/material.dart';

Map<String, dynamic> weatherDay(
  Map<String, dynamic>? data, {
  String key = 'today',
  int index = 0,
}) {
  final direct = data?[key];
  if (direct is Map) return Map<String, dynamic>.from(direct);
  final days = data?['days'] ?? data?['daily'];
  if (days is List && days.length > index && days[index] is Map) {
    return Map<String, dynamic>.from(days[index] as Map);
  }
  return {};
}

Map<String, dynamic> weatherCurrent(Map<String, dynamic>? data) {
  final current = data?['current'];
  if (current is Map) return Map<String, dynamic>.from(current);
  return {};
}

int? weatherInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

String weatherUpdatedText(DateTime? time) {
  if (time == null) return '刚刚更新';
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return '刚刚更新';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前更新';
  if (diff.inHours < 24) return '${diff.inHours} 小时前更新';
  return '${diff.inDays} 天前更新';
}

IconData weatherIcon(int code, String text) {
  final isSnow = text.contains('雪') ||
      code == 71 ||
      code == 73 ||
      code == 75 ||
      code == 77 ||
      code == 85 ||
      code == 86;
  final isRain = text.contains('雨') ||
      code == 51 ||
      code == 53 ||
      code == 55 ||
      code == 56 ||
      code == 57 ||
      code == 61 ||
      code == 63 ||
      code == 65 ||
      code == 66 ||
      code == 67 ||
      code == 80 ||
      code == 81 ||
      code == 82;
  if (isSnow) return Icons.ac_unit;
  if (isRain) return Icons.water_drop_outlined;
  if (text.contains('雷') || code == 95 || code == 96 || code == 99) {
    return Icons.thunderstorm_outlined;
  }
  if (text.contains('云') || code == 1 || code == 2) {
    return Icons.cloud_outlined;
  }
  if (text.contains('阴') || code == 3) return Icons.wb_cloudy_outlined;
  if (text.contains('雾') || code == 45 || code == 48) {
    return Icons.blur_on_outlined;
  }
  return Icons.wb_sunny_outlined;
}

String weatherPrompt(Map<String, dynamic>? weather) {
  return weatherCardPrompt(weather);
}

/// 天气卡片内部提示 — 偏天气感受
String weatherCardPrompt(Map<String, dynamic>? weather) {
  final current = weatherCurrent(weather);
  final today = weatherDay(weather);
  final text = (current['weather'] ?? today['weather'] ?? '').toString();
  if (text.contains('雨')) return '轻一点写，也记下这场雨带来的感觉。';
  if (text.contains('雪')) return '今天的安静很适合留下一小段只属于自己的记录。';
  if (text.contains('雷')) return '今天的天气有点锋利，更适合把情绪说清楚。';
  if (text.contains('雾')) return '今天有一点朦胧，适合慢慢写下心里还没说完的话。';
  if (text.contains('阴') || text.contains('云')) {
    return '云层收着一点光，让今天的心情也软下来。';
  }
  return '天气刚刚好，不如顺手记下今天最值得留住的一刻。';
}

/// 首页仪表盘提示 — 偏行动引导
String dashboardPrompt(Map<String, dynamic>? weather) {
  final current = weatherCurrent(weather);
  final today = weatherDay(weather);
  final text = (current['weather'] ?? today['weather'] ?? '').toString();
  if (text.contains('雨')) return '今天适合把心事写轻一点，也记下这场雨带来的感觉。';
  if (text.contains('雪')) return '今天外面的安静，正好适合给自己一小段慢下来的记录。';
  if (text.contains('雷')) return '今天能量很强，不如把想说的都写下来。';
  if (text.contains('雾')) return '朦胧的天气里，更值得好好看一眼今天的自己。';
  if (text.contains('阴') || text.contains('云')) {
    return '天气收着一点，正好把今天的心情也温柔记下来。';
  }
  return '今天心情怎么样？不想写很多的话，一句就够了。';
}
