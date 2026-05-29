import '../models/city.dart';

/// 全部城市坐标（与城迹功能共用同一份数据）
/// 覆盖全国地级市，确保定位精度
const allCities = <City>[
  // 直辖市
  City(code: '110000', name: '北京', province: '北京', lat: 39.91, lng: 116.40, level: 1),
  City(code: '120000', name: '天津', province: '天津', lat: 39.13, lng: 117.19, level: 1),
  City(code: '310000', name: '上海', province: '上海', lat: 31.23, lng: 121.47, level: 1),
  City(code: '500000', name: '重庆', province: '重庆', lat: 29.56, lng: 106.55, level: 1),
  // 河北
  City(code: '130100', name: '石家庄', province: '河北', lat: 38.04, lng: 114.51, level: 1),
  City(code: '130200', name: '唐山', province: '河北', lat: 39.63, lng: 118.18, level: 2),
  City(code: '130300', name: '秦皇岛', province: '河北', lat: 39.93, lng: 119.60, level: 2),
  City(code: '130400', name: '邯郸', province: '河北', lat: 36.60, lng: 114.48, level: 2),
  City(code: '130500', name: '邢台', province: '河北', lat: 37.05, lng: 114.50, level: 2),
  City(code: '130600', name: '保定', province: '河北', lat: 38.87, lng: 115.46, level: 2),
  City(code: '130700', name: '张家口', province: '河北', lat: 40.77, lng: 114.88, level: 2),
  City(code: '130800', name: '承德', province: '河北', lat: 40.97, lng: 117.93, level: 2),
  City(code: '130900', name: '沧州', province: '河北', lat: 38.30, lng: 116.84, level: 2),
  City(code: '131000', name: '廊坊', province: '河北', lat: 39.52, lng: 116.68, level: 2),
  City(code: '131100', name: '衡水', province: '河北', lat: 37.73, lng: 115.67, level: 2),
  // 山西
  City(code: '140100', name: '太原', province: '山西', lat: 37.87, lng: 112.55, level: 1),
  City(code: '140200', name: '大同', province: '山西', lat: 40.08, lng: 113.30, level: 2),
  City(code: '140300', name: '阳泉', province: '山西', lat: 37.86, lng: 113.58, level: 2),
  City(code: '140400', name: '长治', province: '山西', lat: 36.19, lng: 113.12, level: 2),
  City(code: '140500', name: '晋城', province: '山西', lat: 35.49, lng: 112.85, level: 2),
  City(code: '140600', name: '朔州', province: '山西', lat: 39.33, lng: 112.43, level: 2),
  City(code: '140700', name: '晋中', province: '山西', lat: 37.69, lng: 112.75, level: 2),
  City(code: '140800', name: '运城', province: '山西', lat: 35.03, lng: 111.01, level: 2),
  City(code: '140900', name: '忻州', province: '山西', lat: 38.42, lng: 112.73, level: 2),
  City(code: '141000', name: '临汾', province: '山西', lat: 36.09, lng: 111.52, level: 2),
  City(code: '141100', name: '吕梁', province: '山西', lat: 37.52, lng: 111.14, level: 2),
  // 内蒙古
  City(code: '150100', name: '呼和浩特', province: '内蒙古', lat: 40.84, lng: 111.75, level: 1),
  City(code: '150200', name: '包头', province: '内蒙古', lat: 40.66, lng: 109.84, level: 2),
  City(code: '150300', name: '乌海', province: '内蒙古', lat: 39.66, lng: 106.82, level: 2),
  City(code: '150400', name: '赤峰', province: '内蒙古', lat: 42.26, lng: 118.89, level: 2),
  City(code: '150500', name: '通辽', province: '内蒙古', lat: 43.65, lng: 122.24, level: 2),
  City(code: '150600', name: '鄂尔多斯', province: '内蒙古', lat: 39.61, lng: 109.78, level: 2),
  City(code: '150700', name: '呼伦贝尔', province: '内蒙古', lat: 49.21, lng: 119.77, level: 2),
  City(code: '150800', name: '巴彦淖尔', province: '内蒙古', lat: 40.74, lng: 107.39, level: 2),
  City(code: '150900', name: '乌兰察布', province: '内蒙古', lat: 41.02, lng: 113.11, level: 2),
  // 辽宁
  City(code: '210100', name: '沈阳', province: '辽宁', lat: 41.80, lng: 123.43, level: 1),
  City(code: '210200', name: '大连', province: '辽宁', lat: 38.91, lng: 121.61, level: 2),
  City(code: '210300', name: '鞍山', province: '辽宁', lat: 41.11, lng: 122.99, level: 2),
  City(code: '210400', name: '抚顺', province: '辽宁', lat: 41.88, lng: 123.96, level: 2),
  City(code: '210500', name: '本溪', province: '辽宁', lat: 41.29, lng: 123.77, level: 2),
  City(code: '210600', name: '丹东', province: '辽宁', lat: 40.00, lng: 124.35, level: 2),
  City(code: '210700', name: '锦州', province: '辽宁', lat: 41.10, lng: 121.13, level: 2),
  City(code: '210800', name: '营口', province: '辽宁', lat: 40.67, lng: 122.24, level: 2),
  City(code: '210900', name: '阜新', province: '辽宁', lat: 42.01, lng: 121.65, level: 2),
  City(code: '211000', name: '辽阳', province: '辽宁', lat: 41.27, lng: 123.17, level: 2),
  City(code: '211100', name: '盘锦', province: '辽宁', lat: 41.12, lng: 122.07, level: 2),
  City(code: '211200', name: '铁岭', province: '辽宁', lat: 42.29, lng: 123.84, level: 2),
  City(code: '211300', name: '朝阳', province: '辽宁', lat: 41.57, lng: 120.45, level: 2),
  City(code: '211400', name: '葫芦岛', province: '辽宁', lat: 40.72, lng: 120.84, level: 2),
  // 吉林
  City(code: '220100', name: '长春', province: '吉林', lat: 43.88, lng: 125.32, level: 1),
  City(code: '220200', name: '吉林', province: '吉林', lat: 43.84, lng: 126.55, level: 2),
  City(code: '220300', name: '四平', province: '吉林', lat: 43.17, lng: 124.35, level: 2),
  City(code: '220400', name: '辽源', province: '吉林', lat: 42.90, lng: 125.14, level: 2),
  City(code: '220500', name: '通化', province: '吉林', lat: 41.73, lng: 125.94, level: 2),
  City(code: '220600', name: '白山', province: '吉林', lat: 41.94, lng: 126.42, level: 2),
  City(code: '220700', name: '松原', province: '吉林', lat: 45.12, lng: 124.83, level: 2),
  City(code: '220800', name: '白城', province: '吉林', lat: 45.62, lng: 122.84, level: 2),
  // 黑龙江
  City(code: '230100', name: '哈尔滨', province: '黑龙江', lat: 45.80, lng: 126.53, level: 1),
  City(code: '230200', name: '齐齐哈尔', province: '黑龙江', lat: 47.35, lng: 123.97, level: 2),
  City(code: '230300', name: '鸡西', province: '黑龙江', lat: 45.30, lng: 130.97, level: 2),
  City(code: '230400', name: '鹤岗', province: '黑龙江', lat: 47.35, lng: 130.30, level: 2),
  City(code: '230500', name: '双鸭山', province: '黑龙江', lat: 46.65, lng: 131.16, level: 2),
  City(code: '230600', name: '大庆', province: '黑龙江', lat: 46.59, lng: 125.10, level: 2),
  City(code: '230700', name: '伊春', province: '黑龙江', lat: 47.73, lng: 128.91, level: 2),
  City(code: '230800', name: '佳木斯', province: '黑龙江', lat: 46.80, lng: 130.32, level: 2),
  City(code: '230900', name: '七台河', province: '黑龙江', lat: 45.77, lng: 131.00, level: 2),
  City(code: '231000', name: '牡丹江', province: '黑龙江', lat: 44.55, lng: 129.63, level: 2),
  City(code: '231100', name: '黑河', province: '黑龙江', lat: 50.25, lng: 127.49, level: 2),
  City(code: '231200', name: '绥化', province: '黑龙江', lat: 46.64, lng: 126.97, level: 2),
  // 江苏
  City(code: '320100', name: '南京', province: '江苏', lat: 32.06, lng: 118.80, level: 1),
  City(code: '320200', name: '无锡', province: '江苏', lat: 31.57, lng: 120.31, level: 2),
  City(code: '320300', name: '徐州', province: '江苏', lat: 34.26, lng: 117.18, level: 2),
  City(code: '320400', name: '常州', province: '江苏', lat: 31.81, lng: 119.97, level: 2),
  City(code: '320500', name: '苏州', province: '江苏', lat: 31.30, lng: 120.58, level: 2),
  City(code: '320600', name: '南通', province: '江苏', lat: 32.01, lng: 120.87, level: 2),
  City(code: '320700', name: '连云港', province: '江苏', lat: 34.60, lng: 119.22, level: 2),
  City(code: '320800', name: '淮安', province: '江苏', lat: 33.60, lng: 119.01, level: 2),
  City(code: '320900', name: '盐城', province: '江苏', lat: 33.35, lng: 120.16, level: 2),
  City(code: '321000', name: '扬州', province: '江苏', lat: 32.39, lng: 119.42, level: 2),
  City(code: '321100', name: '镇江', province: '江苏', lat: 32.19, lng: 119.45, level: 2),
  City(code: '321200', name: '泰州', province: '江苏', lat: 32.46, lng: 119.92, level: 2),
  City(code: '321300', name: '宿迁', province: '江苏', lat: 33.96, lng: 118.28, level: 2),
  // 浙江
  City(code: '330100', name: '杭州', province: '浙江', lat: 30.27, lng: 120.15, level: 1),
  City(code: '330200', name: '宁波', province: '浙江', lat: 29.87, lng: 121.54, level: 2),
  City(code: '330300', name: '温州', province: '浙江', lat: 28.00, lng: 120.67, level: 2),
  City(code: '330400', name: '嘉兴', province: '浙江', lat: 30.75, lng: 120.76, level: 2),
  City(code: '330500', name: '湖州', province: '浙江', lat: 30.87, lng: 120.09, level: 2),
  City(code: '330600', name: '绍兴', province: '浙江', lat: 30.00, lng: 120.58, level: 2),
  City(code: '330700', name: '金华', province: '浙江', lat: 29.08, lng: 119.65, level: 2),
  City(code: '330800', name: '衢州', province: '浙江', lat: 28.94, lng: 118.87, level: 2),
  City(code: '330900', name: '舟山', province: '浙江', lat: 30.00, lng: 122.10, level: 2),
  City(code: '331000', name: '台州', province: '浙江', lat: 28.68, lng: 121.42, level: 2),
  City(code: '331100', name: '丽水', province: '浙江', lat: 28.47, lng: 119.91, level: 2),
  // 安徽
  City(code: '340100', name: '合肥', province: '安徽', lat: 31.86, lng: 117.28, level: 1),
  City(code: '340200', name: '芜湖', province: '安徽', lat: 31.35, lng: 118.38, level: 2),
  City(code: '340300', name: '蚌埠', province: '安徽', lat: 32.92, lng: 117.39, level: 2),
  City(code: '340400', name: '淮南', province: '安徽', lat: 32.63, lng: 117.02, level: 2),
  City(code: '340500', name: '马鞍山', province: '安徽', lat: 31.67, lng: 118.51, level: 2),
  City(code: '340600', name: '淮北', province: '安徽', lat: 33.97, lng: 116.80, level: 2),
  City(code: '340700', name: '铜陵', province: '安徽', lat: 30.93, lng: 117.81, level: 2),
  City(code: '340800', name: '安庆', province: '安徽', lat: 30.53, lng: 117.05, level: 2),
  City(code: '341000', name: '黄山', province: '安徽', lat: 29.71, lng: 118.34, level: 2),
  City(code: '341100', name: '滁州', province: '安徽', lat: 32.30, lng: 118.32, level: 2),
  City(code: '341200', name: '阜阳', province: '安徽', lat: 32.89, lng: 115.81, level: 2),
  City(code: '341300', name: '宿州', province: '安徽', lat: 33.63, lng: 116.96, level: 2),
  City(code: '341500', name: '六安', province: '安徽', lat: 31.74, lng: 116.51, level: 2),
  City(code: '341600', name: '亳州', province: '安徽', lat: 33.84, lng: 115.78, level: 2),
  City(code: '341700', name: '池州', province: '安徽', lat: 30.66, lng: 117.49, level: 2),
  City(code: '341800', name: '宣城', province: '安徽', lat: 30.94, lng: 118.76, level: 2),
  // 福建
  City(code: '350100', name: '福州', province: '福建', lat: 26.07, lng: 119.30, level: 1),
  City(code: '350200', name: '厦门', province: '福建', lat: 24.48, lng: 118.09, level: 2),
  City(code: '350300', name: '莆田', province: '福建', lat: 25.45, lng: 119.01, level: 2),
  City(code: '350400', name: '三明', province: '福建', lat: 26.27, lng: 117.64, level: 2),
  City(code: '350500', name: '泉州', province: '福建', lat: 24.87, lng: 118.67, level: 2),
  City(code: '350600', name: '漳州', province: '福建', lat: 24.51, lng: 117.65, level: 2),
  City(code: '350700', name: '南平', province: '福建', lat: 26.64, lng: 118.18, level: 2),
  City(code: '350800', name: '龙岩', province: '福建', lat: 25.08, lng: 117.02, level: 2),
  City(code: '350900', name: '宁德', province: '福建', lat: 26.66, lng: 119.55, level: 2),
  // 江西
  City(code: '360100', name: '南昌', province: '江西', lat: 28.68, lng: 115.89, level: 1),
  City(code: '360200', name: '景德镇', province: '江西', lat: 29.27, lng: 117.18, level: 2),
  City(code: '360300', name: '萍乡', province: '江西', lat: 27.62, lng: 113.85, level: 2),
  City(code: '360400', name: '九江', province: '江西', lat: 29.71, lng: 116.00, level: 2),
  City(code: '360500', name: '新余', province: '江西', lat: 27.80, lng: 114.92, level: 2),
  City(code: '360600', name: '鹰潭', province: '江西', lat: 28.23, lng: 117.07, level: 2),
  City(code: '360700', name: '赣州', province: '江西', lat: 25.83, lng: 114.93, level: 2),
  City(code: '360800', name: '吉安', province: '江西', lat: 27.11, lng: 114.99, level: 2),
  City(code: '360900', name: '宜春', province: '江西', lat: 27.80, lng: 114.39, level: 2),
  City(code: '361000', name: '抚州', province: '江西', lat: 27.95, lng: 116.36, level: 2),
  City(code: '361100', name: '上饶', province: '江西', lat: 28.45, lng: 117.97, level: 2),
  // 山东
  City(code: '370100', name: '济南', province: '山东', lat: 36.67, lng: 116.98, level: 1),
  City(code: '370200', name: '青岛', province: '山东', lat: 36.07, lng: 120.38, level: 2),
  City(code: '370300', name: '淄博', province: '山东', lat: 36.81, lng: 118.05, level: 2),
  City(code: '370400', name: '枣庄', province: '山东', lat: 34.86, lng: 117.56, level: 2),
  City(code: '370500', name: '东营', province: '山东', lat: 37.46, lng: 118.67, level: 2),
  City(code: '370600', name: '烟台', province: '山东', lat: 37.46, lng: 121.45, level: 2),
  City(code: '370700', name: '潍坊', province: '山东', lat: 36.71, lng: 119.16, level: 2),
  City(code: '370800', name: '济宁', province: '山东', lat: 35.40, lng: 116.59, level: 2),
  City(code: '370900', name: '泰安', province: '山东', lat: 36.20, lng: 117.09, level: 2),
  City(code: '371000', name: '威海', province: '山东', lat: 37.51, lng: 122.12, level: 2),
  City(code: '371100', name: '日照', province: '山东', lat: 35.38, lng: 119.53, level: 2),
  City(code: '371300', name: '临沂', province: '山东', lat: 35.10, lng: 118.35, level: 2),
  City(code: '371400', name: '德州', province: '山东', lat: 37.43, lng: 116.36, level: 2),
  City(code: '371500', name: '聊城', province: '山东', lat: 36.46, lng: 115.99, level: 2),
  City(code: '371600', name: '滨州', province: '山东', lat: 37.38, lng: 117.97, level: 2),
  City(code: '371700', name: '菏泽', province: '山东', lat: 35.23, lng: 115.48, level: 2),
  // 河南
  City(code: '410100', name: '郑州', province: '河南', lat: 34.75, lng: 113.63, level: 1),
  City(code: '410200', name: '开封', province: '河南', lat: 34.79, lng: 114.31, level: 2),
  City(code: '410300', name: '洛阳', province: '河南', lat: 34.62, lng: 112.45, level: 2),
  City(code: '410400', name: '平顶山', province: '河南', lat: 33.77, lng: 113.19, level: 2),
  City(code: '410500', name: '安阳', province: '河南', lat: 36.10, lng: 114.35, level: 2),
  City(code: '410600', name: '鹤壁', province: '河南', lat: 35.75, lng: 114.30, level: 2),
  City(code: '410700', name: '新乡', province: '河南', lat: 35.30, lng: 113.87, level: 2),
  City(code: '410800', name: '焦作', province: '河南', lat: 35.22, lng: 113.24, level: 2),
  City(code: '410900', name: '濮阳', province: '河南', lat: 35.76, lng: 115.03, level: 2),
  City(code: '411000', name: '许昌', province: '河南', lat: 34.02, lng: 113.85, level: 2),
  City(code: '411100', name: '漯河', province: '河南', lat: 33.58, lng: 114.02, level: 2),
  City(code: '411200', name: '三门峡', province: '河南', lat: 34.77, lng: 111.20, level: 2),
  City(code: '411300', name: '南阳', province: '河南', lat: 32.99, lng: 112.53, level: 2),
  City(code: '411400', name: '商丘', province: '河南', lat: 34.44, lng: 115.65, level: 2),
  City(code: '411500', name: '信阳', province: '河南', lat: 32.12, lng: 114.07, level: 2),
  City(code: '411600', name: '周口', province: '河南', lat: 33.63, lng: 114.65, level: 2),
  City(code: '411700', name: '驻马店', province: '河南', lat: 33.01, lng: 114.02, level: 2),
  // 湖北
  City(code: '420100', name: '武汉', province: '湖北', lat: 30.59, lng: 114.31, level: 1),
  City(code: '420200', name: '黄石', province: '湖北', lat: 30.20, lng: 115.04, level: 2),
  City(code: '420300', name: '十堰', province: '湖北', lat: 32.63, lng: 110.80, level: 2),
  City(code: '420500', name: '宜昌', province: '湖北', lat: 30.69, lng: 111.29, level: 2),
  City(code: '420600', name: '襄阳', province: '湖北', lat: 32.01, lng: 112.14, level: 2),
  City(code: '420700', name: '鄂州', province: '湖北', lat: 30.39, lng: 114.89, level: 2),
  City(code: '420800', name: '荆门', province: '湖北', lat: 31.04, lng: 112.20, level: 2),
  City(code: '420900', name: '孝感', province: '湖北', lat: 30.92, lng: 113.91, level: 2),
  City(code: '421000', name: '荆州', province: '湖北', lat: 30.33, lng: 112.24, level: 2),
  City(code: '421100', name: '黄冈', province: '湖北', lat: 30.45, lng: 114.87, level: 2),
  City(code: '421200', name: '咸宁', province: '湖北', lat: 29.83, lng: 114.32, level: 2),
  City(code: '421300', name: '随州', province: '湖北', lat: 31.69, lng: 113.38, level: 2),
  // 湖南
  City(code: '430100', name: '长沙', province: '湖南', lat: 28.23, lng: 112.94, level: 1),
  City(code: '430200', name: '株洲', province: '湖南', lat: 27.83, lng: 113.13, level: 2),
  City(code: '430300', name: '湘潭', province: '湖南', lat: 27.83, lng: 112.94, level: 2),
  City(code: '430400', name: '衡阳', province: '湖南', lat: 26.89, lng: 112.57, level: 2),
  City(code: '430500', name: '邵阳', province: '湖南', lat: 27.24, lng: 111.47, level: 2),
  City(code: '430600', name: '岳阳', province: '湖南', lat: 29.37, lng: 113.13, level: 2),
  City(code: '430700', name: '常德', province: '湖南', lat: 29.03, lng: 111.69, level: 2),
  City(code: '430800', name: '张家界', province: '湖南', lat: 29.13, lng: 110.48, level: 2),
  City(code: '430900', name: '益阳', province: '湖南', lat: 28.55, lng: 112.33, level: 2),
  City(code: '431000', name: '郴州', province: '湖南', lat: 25.77, lng: 113.01, level: 2),
  City(code: '431100', name: '永州', province: '湖南', lat: 26.42, lng: 111.61, level: 2),
  City(code: '431200', name: '怀化', province: '湖南', lat: 27.55, lng: 109.98, level: 2),
  City(code: '431300', name: '娄底', province: '湖南', lat: 27.70, lng: 112.00, level: 2),
  // 广东
  City(code: '440100', name: '广州', province: '广东', lat: 23.13, lng: 113.26, level: 1),
  City(code: '440200', name: '韶关', province: '广东', lat: 24.81, lng: 113.60, level: 2),
  City(code: '440300', name: '深圳', province: '广东', lat: 22.54, lng: 114.06, level: 2),
  City(code: '440400', name: '珠海', province: '广东', lat: 22.27, lng: 113.58, level: 2),
  City(code: '440500', name: '汕头', province: '广东', lat: 23.35, lng: 116.68, level: 2),
  City(code: '440600', name: '佛山', province: '广东', lat: 23.02, lng: 113.12, level: 2),
  City(code: '440700', name: '江门', province: '广东', lat: 22.58, lng: 113.08, level: 2),
  City(code: '440800', name: '湛江', province: '广东', lat: 21.27, lng: 110.36, level: 2),
  City(code: '440900', name: '茂名', province: '广东', lat: 21.66, lng: 110.93, level: 2),
  City(code: '441200', name: '肇庆', province: '广东', lat: 23.05, lng: 112.47, level: 2),
  City(code: '441300', name: '惠州', province: '广东', lat: 23.11, lng: 114.42, level: 2),
  City(code: '441400', name: '梅州', province: '广东', lat: 24.29, lng: 116.12, level: 2),
  City(code: '441500', name: '汕尾', province: '广东', lat: 22.77, lng: 115.36, level: 2),
  City(code: '441600', name: '河源', province: '广东', lat: 23.74, lng: 114.69, level: 2),
  City(code: '441700', name: '阳江', province: '广东', lat: 21.86, lng: 111.98, level: 2),
  City(code: '441800', name: '清远', province: '广东', lat: 23.68, lng: 113.05, level: 2),
  City(code: '441900', name: '东莞', province: '广东', lat: 23.02, lng: 113.75, level: 2),
  City(code: '442000', name: '中山', province: '广东', lat: 22.52, lng: 113.39, level: 2),
  City(code: '445100', name: '潮州', province: '广东', lat: 23.66, lng: 116.62, level: 2),
  City(code: '445200', name: '揭阳', province: '广东', lat: 23.55, lng: 116.37, level: 2),
  City(code: '445300', name: '云浮', province: '广东', lat: 22.92, lng: 112.04, level: 2),
  // 广西
  City(code: '450100', name: '南宁', province: '广西', lat: 22.82, lng: 108.37, level: 1),
  City(code: '450200', name: '柳州', province: '广西', lat: 24.31, lng: 109.41, level: 2),
  City(code: '450300', name: '桂林', province: '广西', lat: 25.23, lng: 110.18, level: 2),
  City(code: '450400', name: '梧州', province: '广西', lat: 23.48, lng: 111.28, level: 2),
  City(code: '450500', name: '北海', province: '广西', lat: 21.48, lng: 109.12, level: 2),
  City(code: '450600', name: '防城港', province: '广西', lat: 21.61, lng: 108.35, level: 2),
  City(code: '450700', name: '钦州', province: '广西', lat: 21.98, lng: 108.62, level: 2),
  City(code: '450800', name: '贵港', province: '广西', lat: 23.10, lng: 109.60, level: 2),
  City(code: '450900', name: '玉林', province: '广西', lat: 22.63, lng: 110.15, level: 2),
  City(code: '451000', name: '百色', province: '广西', lat: 23.90, lng: 106.62, level: 2),
  City(code: '451100', name: '贺州', province: '广西', lat: 24.40, lng: 111.56, level: 2),
  City(code: '451200', name: '河池', province: '广西', lat: 24.69, lng: 108.09, level: 2),
  City(code: '451300', name: '来宾', province: '广西', lat: 23.73, lng: 109.22, level: 2),
  City(code: '451400', name: '崇左', province: '广西', lat: 22.38, lng: 107.36, level: 2),
  // 海南
  City(code: '460100', name: '海口', province: '海南', lat: 20.02, lng: 110.35, level: 1),
  City(code: '460200', name: '三亚', province: '海南', lat: 18.25, lng: 109.51, level: 2),
  City(code: '460300', name: '三沙', province: '海南', lat: 16.83, lng: 112.33, level: 2),
  City(code: '460400', name: '儋州', province: '海南', lat: 19.52, lng: 109.58, level: 2),
  // 四川
  City(code: '510100', name: '成都', province: '四川', lat: 30.57, lng: 104.07, level: 1),
  City(code: '510300', name: '自贡', province: '四川', lat: 29.34, lng: 104.78, level: 2),
  City(code: '510400', name: '攀枝花', province: '四川', lat: 26.58, lng: 101.72, level: 2),
  City(code: '510500', name: '泸州', province: '四川', lat: 28.87, lng: 105.44, level: 2),
  City(code: '510600', name: '德阳', province: '四川', lat: 31.13, lng: 104.40, level: 2),
  City(code: '510700', name: '绵阳', province: '四川', lat: 31.47, lng: 104.73, level: 2),
  City(code: '510800', name: '广元', province: '四川', lat: 32.44, lng: 105.84, level: 2),
  City(code: '510900', name: '遂宁', province: '四川', lat: 30.53, lng: 105.57, level: 2),
  City(code: '511000', name: '内江', province: '四川', lat: 29.58, lng: 105.06, level: 2),
  City(code: '511100', name: '乐山', province: '四川', lat: 29.55, lng: 103.77, level: 2),
  City(code: '511300', name: '南充', province: '四川', lat: 30.84, lng: 106.11, level: 2),
  City(code: '511400', name: '眉山', province: '四川', lat: 30.08, lng: 103.85, level: 2),
  City(code: '511500', name: '宜宾', province: '四川', lat: 28.77, lng: 104.64, level: 2),
  City(code: '511600', name: '广安', province: '四川', lat: 30.46, lng: 106.63, level: 2),
  City(code: '511700', name: '达州', province: '四川', lat: 31.21, lng: 107.47, level: 2),
  City(code: '511800', name: '雅安', province: '四川', lat: 29.99, lng: 103.00, level: 2),
  City(code: '511900', name: '巴中', province: '四川', lat: 31.87, lng: 106.75, level: 2),
  City(code: '512000', name: '资阳', province: '四川', lat: 30.12, lng: 104.65, level: 2),
  // 贵州
  City(code: '520100', name: '贵阳', province: '贵州', lat: 26.65, lng: 106.63, level: 1),
  City(code: '520200', name: '六盘水', province: '贵州', lat: 26.59, lng: 104.83, level: 2),
  City(code: '520300', name: '遵义', province: '贵州', lat: 27.72, lng: 106.93, level: 2),
  City(code: '520400', name: '安顺', province: '贵州', lat: 26.25, lng: 105.95, level: 2),
  City(code: '520500', name: '毕节', province: '贵州', lat: 27.30, lng: 105.29, level: 2),
  City(code: '520600', name: '铜仁', province: '贵州', lat: 27.72, lng: 109.19, level: 2),
  // 云南
  City(code: '530100', name: '昆明', province: '云南', lat: 25.04, lng: 102.71, level: 1),
  City(code: '530300', name: '曲靖', province: '云南', lat: 25.49, lng: 103.80, level: 2),
  City(code: '530400', name: '玉溪', province: '云南', lat: 24.35, lng: 102.55, level: 2),
  City(code: '530500', name: '保山', province: '云南', lat: 25.11, lng: 99.17, level: 2),
  City(code: '530600', name: '昭通', province: '云南', lat: 27.34, lng: 103.72, level: 2),
  City(code: '530700', name: '丽江', province: '云南', lat: 26.87, lng: 100.23, level: 2),
  City(code: '530800', name: '普洱', province: '云南', lat: 22.78, lng: 100.97, level: 2),
  City(code: '530900', name: '临沧', province: '云南', lat: 23.88, lng: 100.09, level: 2),
  // 西藏
  City(code: '540100', name: '拉萨', province: '西藏', lat: 29.65, lng: 91.13, level: 1),
  City(code: '540200', name: '日喀则', province: '西藏', lat: 29.27, lng: 88.88, level: 2),
  City(code: '540300', name: '昌都', province: '西藏', lat: 31.14, lng: 97.17, level: 2),
  City(code: '540400', name: '林芝', province: '西藏', lat: 29.65, lng: 94.36, level: 2),
  City(code: '540500', name: '山南', province: '西藏', lat: 29.24, lng: 91.77, level: 2),
  City(code: '540600', name: '那曲', province: '西藏', lat: 31.48, lng: 92.05, level: 2),
  City(code: '542500', name: '阿里', province: '西藏', lat: 32.50, lng: 80.11, level: 2),
  // 陕西
  City(code: '610100', name: '西安', province: '陕西', lat: 34.26, lng: 108.94, level: 1),
  City(code: '610200', name: '铜川', province: '陕西', lat: 34.90, lng: 108.94, level: 2),
  City(code: '610300', name: '宝鸡', province: '陕西', lat: 34.36, lng: 107.24, level: 2),
  City(code: '610400', name: '咸阳', province: '陕西', lat: 34.33, lng: 108.72, level: 2),
  City(code: '610500', name: '渭南', province: '陕西', lat: 34.50, lng: 109.51, level: 2),
  City(code: '610600', name: '延安', province: '陕西', lat: 36.59, lng: 109.49, level: 2),
  City(code: '610700', name: '汉中', province: '陕西', lat: 33.07, lng: 107.03, level: 2),
  City(code: '610800', name: '榆林', province: '陕西', lat: 38.29, lng: 109.73, level: 2),
  City(code: '610900', name: '安康', province: '陕西', lat: 32.68, lng: 109.03, level: 2),
  City(code: '611000', name: '商洛', province: '陕西', lat: 33.87, lng: 109.94, level: 2),
  // 甘肃
  City(code: '620100', name: '兰州', province: '甘肃', lat: 36.06, lng: 103.83, level: 1),
  City(code: '620200', name: '嘉峪关', province: '甘肃', lat: 39.77, lng: 98.29, level: 2),
  City(code: '620300', name: '金昌', province: '甘肃', lat: 38.52, lng: 102.19, level: 2),
  City(code: '620400', name: '白银', province: '甘肃', lat: 36.55, lng: 104.17, level: 2),
  City(code: '620500', name: '天水', province: '甘肃', lat: 34.58, lng: 105.72, level: 2),
  City(code: '620600', name: '武威', province: '甘肃', lat: 37.93, lng: 102.64, level: 2),
  City(code: '620700', name: '张掖', province: '甘肃', lat: 38.93, lng: 100.45, level: 2),
  City(code: '620800', name: '平凉', province: '甘肃', lat: 35.54, lng: 106.67, level: 2),
  City(code: '620900', name: '酒泉', province: '甘肃', lat: 39.74, lng: 98.51, level: 2),
  City(code: '621000', name: '庆阳', province: '甘肃', lat: 35.73, lng: 107.64, level: 2),
  City(code: '621100', name: '定西', province: '甘肃', lat: 35.58, lng: 104.63, level: 2),
  City(code: '621200', name: '陇南', province: '甘肃', lat: 33.39, lng: 104.92, level: 2),
  // 青海
  City(code: '630100', name: '西宁', province: '青海', lat: 36.62, lng: 101.78, level: 1),
  City(code: '630200', name: '海东', province: '青海', lat: 36.50, lng: 102.10, level: 2),
  // 宁夏
  City(code: '640100', name: '银川', province: '宁夏', lat: 38.47, lng: 106.27, level: 1),
  City(code: '640200', name: '石嘴山', province: '宁夏', lat: 38.98, lng: 106.38, level: 2),
  City(code: '640300', name: '吴忠', province: '宁夏', lat: 37.99, lng: 106.20, level: 2),
  City(code: '640400', name: '固原', province: '宁夏', lat: 36.00, lng: 106.24, level: 2),
  City(code: '640500', name: '中卫', province: '宁夏', lat: 37.51, lng: 105.19, level: 2),
  // 新疆
  City(code: '650100', name: '乌鲁木齐', province: '新疆', lat: 43.83, lng: 87.62, level: 1),
  City(code: '650200', name: '克拉玛依', province: '新疆', lat: 45.59, lng: 84.87, level: 2),
  City(code: '652300', name: '昌吉', province: '新疆', lat: 44.01, lng: 87.31, level: 2),
  City(code: '652700', name: '博尔塔拉', province: '新疆', lat: 44.91, lng: 82.07, level: 2),
  City(code: '652800', name: '巴音郭楞', province: '新疆', lat: 41.76, lng: 86.15, level: 2),
  City(code: '652900', name: '阿克苏', province: '新疆', lat: 41.17, lng: 80.26, level: 2),
  City(code: '653000', name: '克孜勒苏', province: '新疆', lat: 39.71, lng: 76.17, level: 2),
  City(code: '653100', name: '喀什', province: '新疆', lat: 39.47, lng: 75.99, level: 2),
  City(code: '653200', name: '和田', province: '新疆', lat: 37.11, lng: 79.92, level: 2),
  City(code: '654000', name: '伊犁', province: '新疆', lat: 43.92, lng: 81.32, level: 2),
  City(code: '654200', name: '塔城', province: '新疆', lat: 46.75, lng: 82.98, level: 2),
  City(code: '654300', name: '阿勒泰', province: '新疆', lat: 47.85, lng: 88.14, level: 2),
  // 港澳台
  City(code: '810000', name: '香港', province: '香港', lat: 22.32, lng: 114.17, level: 1),
  City(code: '820000', name: '澳门', province: '澳门', lat: 22.20, lng: 113.55, level: 1),
  City(code: '710000', name: '台北', province: '台湾', lat: 25.03, lng: 121.57, level: 1),
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

/// 在 [allCities] 中找距离 [lat],[lng] 最近的城市
/// 始终返回最近城市（不管多远），确保不会因为阈值过严导致定位失败
City? findNearestCity(double lat, double lng, {double maxKm = 100}) {
  if (allCities.isEmpty) return null;
  City? best;
  double bestDist = double.infinity;
  for (final c in allCities) {
    final d = haversineKm(lat, lng, c.lat, c.lng);
    if (d < bestDist) {
      bestDist = d;
      best = c;
    }
  }
  return best;
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
