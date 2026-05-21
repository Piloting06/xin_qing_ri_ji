/// 中国城市数据模型
class City {
  final String code;      // 行政区划代码 "360100"
  final String name;       // "南昌"
  final String province;   // "江西"
  final double lat;        // 纬度
  final double lng;        // 经度
  final int level;         // 1=省会 2=地级市 3=县级市

  const City({
    required this.code,
    required this.name,
    required this.province,
    required this.lat,
    required this.lng,
    required this.level,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
    code: json['code'] as String,
    name: json['name'] as String,
    province: json['province'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    level: (json['level'] as num?)?.toInt() ?? 2,
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'province': province,
    'lat': lat,
    'lng': lng,
    'level': level,
  };
}
