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
  final isSnow =
      text.contains('雪') ||
      code == 71 ||
      code == 73 ||
      code == 75 ||
      code == 77 ||
      code == 85 ||
      code == 86;
  final isRain =
      text.contains('雨') ||
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

/// 天气卡片内部提示 — 偏天气感受
String weatherCardPrompt(Map<String, dynamic>? weather) {
  final current = weatherCurrent(weather);
  final today = weatherDay(weather);
  final text = (current['weather'] ?? today['weather'] ?? '').toString();
  if (text.contains('雨')) return '下雨天，适合给自己倒杯热的，慢慢写。';
  if (text.contains('雪')) return '雪落下来的时候，世界变得很安静。写几句今天的感受吧。';
  if (text.contains('雷')) return '雷声很大也没关系，写下来比放在心里更安全。';
  if (text.contains('雾')) return '大雾天不适合赶路，适合坐一会儿，想想最想写的事。';
  if (text.contains('阴') || text.contains('云')) {
    return '灰蒙蒙的天也没关系，心情可以是彩色的。';
  }
  return '窗外阳光正好，适合出去走走。或者坐在这里写几个字。';
}

/// 首页仪表盘提示 — 偏行动引导
String dashboardPrompt(Map<String, dynamic>? weather) {
  final current = weatherCurrent(weather);
  final today = weatherDay(weather);
  final text = (current['weather'] ?? today['weather'] ?? '').toString();
  if (text.contains('雨')) return '今天适合慢下来，心事写轻一点，也记下这场雨的感觉。';
  if (text.contains('雪')) return '雪天的安静值得珍惜，给自己一小段独处的时间。';
  if (text.contains('雷')) return '今天能量很强，不如把想说的都写下来。';
  if (text.contains('雾')) return '朦胧的天气里，更值得好好看一眼今天的自己。';
  if (text.contains('阴') || text.contains('云')) {
    return '天气收着一点，正好把今天的心情也温柔记下来。';
  }
  return '今天心情怎么样？不想写很多的话，一句就够了。';
}

/// 内部 weather_code → 中文文本（历史记录里的天气码用）
String weatherTextForCode(int? code) {
  final c = code ?? -1;
  if (c == 0) return '晴';
  if (c == 1) return '少云';
  if (c == 2) return '多云';
  if (c == 3) return '阴';
  if (c == 45) return '雾';
  if (c >= 51 && c <= 55) return '毛毛雨';
  if (c == 61) return '小雨';
  if (c == 63) return '中雨';
  if (c == 65) return '大雨';
  if (c == 66 || c == 67) return '冻雨';
  if (c == 71 || c == 77) return '小雪';
  if (c == 73) return '中雪';
  if (c == 75) return '大雪';
  if (c == 80 || c == 81) return '阵雨';
  if (c == 82) return '强阵雨';
  if (c == 85 || c == 86) return '阵雪';
  if (c == 95) return '雷阵雨';
  if (c == 96 || c == 99) return '强雷阵雨';
  return '';
}
