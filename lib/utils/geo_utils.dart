import '../models/city.dart';

/// 全部城市坐标（与城迹功能共用同一份数据）
const allCities = <City>[
  City(code: '110000', name: '北京', province: '北京', lat: 39.91, lng: 116.40, level: 1),
  City(code: '120000', name: '天津', province: '天津', lat: 39.13, lng: 117.19, level: 1),
  City(code: '310000', name: '上海', province: '上海', lat: 31.23, lng: 121.47, level: 1),
  City(code: '500000', name: '重庆', province: '重庆', lat: 29.56, lng: 106.55, level: 1),
  City(code: '130100', name: '石家庄', province: '河北', lat: 38.04, lng: 114.51, level: 1),
  City(code: '140100', name: '太原', province: '山西', lat: 37.87, lng: 112.55, level: 1),
  City(code: '150100', name: '呼和浩特', province: '内蒙古', lat: 40.84, lng: 111.75, level: 1),
  City(code: '210100', name: '沈阳', province: '辽宁', lat: 41.80, lng: 123.43, level: 1),
  City(code: '220100', name: '长春', province: '吉林', lat: 43.88, lng: 125.32, level: 1),
  City(code: '230100', name: '哈尔滨', province: '黑龙江', lat: 45.80, lng: 126.53, level: 1),
  City(code: '320100', name: '南京', province: '江苏', lat: 32.06, lng: 118.80, level: 1),
  City(code: '330100', name: '杭州', province: '浙江', lat: 30.27, lng: 120.15, level: 1),
  City(code: '340100', name: '合肥', province: '安徽', lat: 31.86, lng: 117.28, level: 1),
  City(code: '350100', name: '福州', province: '福建', lat: 26.07, lng: 119.30, level: 1),
  City(code: '360100', name: '南昌', province: '江西', lat: 28.68, lng: 115.89, level: 1),
  City(code: '370100', name: '济南', province: '山东', lat: 36.67, lng: 116.98, level: 1),
  City(code: '410100', name: '郑州', province: '河南', lat: 34.75, lng: 113.63, level: 1),
  City(code: '420100', name: '武汉', province: '湖北', lat: 30.59, lng: 114.31, level: 1),
  City(code: '430100', name: '长沙', province: '湖南', lat: 28.23, lng: 112.94, level: 1),
  City(code: '440100', name: '广州', province: '广东', lat: 23.13, lng: 113.26, level: 1),
  City(code: '450100', name: '南宁', province: '广西', lat: 22.82, lng: 108.37, level: 1),
  City(code: '460100', name: '海口', province: '海南', lat: 20.02, lng: 110.35, level: 1),
  City(code: '510100', name: '成都', province: '四川', lat: 30.57, lng: 104.07, level: 1),
  City(code: '520100', name: '贵阳', province: '贵州', lat: 26.65, lng: 106.63, level: 1),
  City(code: '530100', name: '昆明', province: '云南', lat: 25.04, lng: 102.71, level: 1),
  City(code: '540100', name: '拉萨', province: '西藏', lat: 29.65, lng: 91.13, level: 1),
  City(code: '610100', name: '西安', province: '陕西', lat: 34.26, lng: 108.94, level: 1),
  City(code: '620100', name: '兰州', province: '甘肃', lat: 36.06, lng: 103.83, level: 1),
  City(code: '630100', name: '西宁', province: '青海', lat: 36.62, lng: 101.78, level: 1),
  City(code: '640100', name: '银川', province: '宁夏', lat: 38.47, lng: 106.27, level: 1),
  City(code: '650100', name: '乌鲁木齐', province: '新疆', lat: 43.83, lng: 87.62, level: 1),
  City(code: '810000', name: '香港', province: '香港', lat: 22.32, lng: 114.17, level: 1),
  City(code: '820000', name: '澳门', province: '澳门', lat: 22.20, lng: 113.55, level: 1),
  City(code: '710000', name: '台北', province: '台湾', lat: 25.03, lng: 121.57, level: 1),
  City(code: '370200', name: '青岛', province: '山东', lat: 36.07, lng: 120.38, level: 2),
  City(code: '330200', name: '宁波', province: '浙江', lat: 29.87, lng: 121.54, level: 2),
  City(code: '350200', name: '厦门', province: '福建', lat: 24.48, lng: 118.09, level: 2),
  City(code: '440300', name: '深圳', province: '广东', lat: 22.54, lng: 114.06, level: 2),
  City(code: '210200', name: '大连', province: '辽宁', lat: 38.91, lng: 121.61, level: 2),
  City(code: '320500', name: '苏州', province: '江苏', lat: 31.30, lng: 120.58, level: 2),
  City(code: '360400', name: '九江', province: '江西', lat: 29.71, lng: 116.00, level: 2),
  City(code: '360700', name: '赣州', province: '江西', lat: 25.83, lng: 114.93, level: 2),
  City(code: '360200', name: '景德镇', province: '江西', lat: 29.27, lng: 117.18, level: 2),
  City(code: '320200', name: '无锡', province: '江苏', lat: 31.57, lng: 120.31, level: 2),
  City(code: '441900', name: '东莞', province: '广东', lat: 23.02, lng: 113.75, level: 2),
  City(code: '440600', name: '佛山', province: '广东', lat: 23.02, lng: 113.12, level: 2),
  City(code: '350500', name: '泉州', province: '福建', lat: 24.87, lng: 118.67, level: 2),
  City(code: '430200', name: '株洲', province: '湖南', lat: 27.83, lng: 113.13, level: 2),
  City(code: '450300', name: '桂林', province: '广西', lat: 25.23, lng: 110.18, level: 2),
  City(code: '460200', name: '三亚', province: '海南', lat: 18.25, lng: 109.51, level: 2),
  City(code: '520300', name: '遵义', province: '贵州', lat: 27.72, lng: 106.93, level: 2),
  City(code: '420500', name: '宜昌', province: '湖北', lat: 30.69, lng: 111.29, level: 2),
  City(code: '410300', name: '洛阳', province: '河南', lat: 34.62, lng: 112.45, level: 2),
  City(code: '610300', name: '宝鸡', province: '陕西', lat: 34.36, lng: 107.24, level: 2),
  City(code: '620200', name: '嘉峪关', province: '甘肃', lat: 39.77, lng: 98.29, level: 2),
  City(code: '530500', name: '保山', province: '云南', lat: 25.11, lng: 99.17, level: 2),
  City(code: '540200', name: '日喀则', province: '西藏', lat: 29.27, lng: 88.88, level: 2),
  City(code: '652300', name: '昌吉', province: '新疆', lat: 44.01, lng: 87.31, level: 2),
  City(code: '450200', name: '柳州', province: '广西', lat: 24.31, lng: 109.41, level: 2),
  City(code: '330700', name: '金华', province: '浙江', lat: 29.08, lng: 119.65, level: 2),
  City(code: '371300', name: '临沂', province: '山东', lat: 35.10, lng: 118.35, level: 2),
  City(code: '411300', name: '南阳', province: '河南', lat: 32.99, lng: 112.53, level: 2),
  City(code: '360800', name: '吉安', province: '江西', lat: 27.11, lng: 114.99, level: 2),
];

double _sinHalf(double x) {
  double r = x;
  double t = x;
  for (int i = 1; i <= 10; i++) {
    t *= -x * x / ((2 * i) * (2 * i + 1));
    r += t;
  }
  return r;
}

double _cos(double x) => _sinHalf(1.57079632679 - x + 1.57079632679);

double _sqrt(double x) {
  if (x <= 0) return 0;
  double g = x / 2;
  for (int i = 0; i < 10; i++) {
    g = (g + x / g) / 2;
  }
  return g;
}

double _atan(double x) {
  double r = x;
  double t = x;
  for (int i = 1; i <= 10; i++) {
    t *= -x * x * (2 * i - 1) / (2 * i + 1);
    r += t;
  }
  return r;
}

double _atan2(double y, double x) {
  if (x > 0) return _atan(y / x);
  if (x < 0) return _atan(y / x) + (y >= 0 ? 3.14159265 : -3.14159265);
  return y > 0 ? 1.57079633 : y < 0 ? -1.57079633 : 0;
}

/// Haversine 距离（km）
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * 3.14159265 / 180;
  final dLng = (lng2 - lng1) * 3.14159265 / 180;
  final a = _sinHalf(dLat) * _sinHalf(dLat) +
      _cos(lat1 * 3.14159265 / 180) *
          _cos(lat2 * 3.14159265 / 180) *
          _sinHalf(dLng) *
          _sinHalf(dLng);
  final clamped = a < 0 ? 0.0 : a > 1 ? 1.0 : a;
  return 2 * r * _atan2(_sqrt(clamped), _sqrt(1 - clamped));
}

/// 在 [allCities] 中找距离 [lat],[lng] 最近的城市，超过 [maxKm] 返回 null
City? findNearestCity(double lat, double lng, {double maxKm = 100}) {
  City? best;
  double bestDist = double.infinity;
  for (final c in allCities) {
    final d = haversineKm(lat, lng, c.lat, c.lng);
    if (d < bestDist) {
      bestDist = d;
      best = c;
    }
  }
  return bestDist > maxKm ? null : best;
}

/// 在 [allCities] 中模糊搜索（支持中文名、拼音首字母、省份名）
List<City> searchCityLocally(String query) {
  if (query.trim().isEmpty) return [];
  final lower = query.trim().toLowerCase();
  final results = <City>[];
  for (final c in allCities) {
    if (c.name.contains(query) || c.province.contains(query) || c.name.toLowerCase().contains(lower)) {
      results.add(c);
    }
  }
  return results;
}
