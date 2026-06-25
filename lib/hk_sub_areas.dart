import 'package:car_washing_app/hk_districts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HkSubArea {
  const HkSubArea({
    required this.nameZh,
    required this.districtNameZh,
    required this.latitude,
    required this.longitude,
  });

  final String nameZh;
  final String districtNameZh;
  final double latitude;
  final double longitude;

  LatLng get position => LatLng(latitude, longitude);
}

/// Common neighbourhood names within each official district.
const List<HkSubArea> kHkSubAreas = [
  // 港岛 · 中西区
  HkSubArea(nameZh: '中环', districtNameZh: '中西区', latitude: 22.2819, longitude: 114.1589),
  HkSubArea(nameZh: '上环', districtNameZh: '中西区', latitude: 22.2860, longitude: 114.1490),
  HkSubArea(nameZh: '西环', districtNameZh: '中西区', latitude: 22.2830, longitude: 114.1300),
  HkSubArea(nameZh: '半山', districtNameZh: '中西区', latitude: 22.2760, longitude: 114.1500),
  HkSubArea(nameZh: '金钟', districtNameZh: '中西区', latitude: 22.2780, longitude: 114.1660),
  // 港岛 · 湾仔区
  HkSubArea(nameZh: '湾仔', districtNameZh: '湾仔区', latitude: 22.2764, longitude: 114.1828),
  HkSubArea(nameZh: '铜锣湾', districtNameZh: '湾仔区', latitude: 22.2800, longitude: 114.1840),
  HkSubArea(nameZh: '跑马地', districtNameZh: '湾仔区', latitude: 22.2700, longitude: 114.1840),
  HkSubArea(nameZh: '大坑', districtNameZh: '湾仔区', latitude: 22.2780, longitude: 114.1920),
  // 港岛 · 东区
  HkSubArea(nameZh: '北角', districtNameZh: '东区', latitude: 22.2910, longitude: 114.2000),
  HkSubArea(nameZh: '鰂魚涌', districtNameZh: '东区', latitude: 22.2840, longitude: 114.2100),
  HkSubArea(nameZh: '太古城', districtNameZh: '东区', latitude: 22.2860, longitude: 114.2180),
  HkSubArea(nameZh: '柴湾', districtNameZh: '东区', latitude: 22.2640, longitude: 114.2360),
  HkSubArea(nameZh: '筲箕湾', districtNameZh: '东区', latitude: 22.2780, longitude: 114.2300),
  // 港岛 · 南区
  HkSubArea(nameZh: '香港仔', districtNameZh: '南区', latitude: 22.2480, longitude: 114.1520),
  HkSubArea(nameZh: '赤柱', districtNameZh: '南区', latitude: 22.2200, longitude: 114.2130),
  HkSubArea(nameZh: '浅水湾', districtNameZh: '南区', latitude: 22.2360, longitude: 114.1960),
  HkSubArea(nameZh: '薄扶林', districtNameZh: '南区', latitude: 22.2580, longitude: 114.1300),
  HkSubArea(nameZh: '海怡', districtNameZh: '南区', latitude: 22.2430, longitude: 114.1480),
  // 九龙 · 油尖旺区
  HkSubArea(nameZh: '尖沙咀', districtNameZh: '油尖旺区', latitude: 22.2970, longitude: 114.1720),
  HkSubArea(nameZh: '油麻地', districtNameZh: '油尖旺区', latitude: 22.3120, longitude: 114.1700),
  HkSubArea(nameZh: '旺角', districtNameZh: '油尖旺区', latitude: 22.3190, longitude: 114.1690),
  HkSubArea(nameZh: '大角咀', districtNameZh: '油尖旺区', latitude: 22.3210, longitude: 114.1600),
  // 九龙 · 深水埗区
  HkSubArea(nameZh: '深水埗', districtNameZh: '深水埗区', latitude: 22.3300, longitude: 114.1628),
  HkSubArea(nameZh: '长沙湾', districtNameZh: '深水埗区', latitude: 22.3370, longitude: 114.1560),
  HkSubArea(nameZh: '荔枝角', districtNameZh: '深水埗区', latitude: 22.3370, longitude: 114.1400),
  HkSubArea(nameZh: '石硖尾', districtNameZh: '深水埗区', latitude: 22.3340, longitude: 114.1680),
  // 九龙 · 九龙城区
  HkSubArea(nameZh: '九龙城', districtNameZh: '九龙城区', latitude: 22.3282, longitude: 114.1910),
  HkSubArea(nameZh: '红磡', districtNameZh: '九龙城区', latitude: 22.3030, longitude: 114.1820),
  HkSubArea(nameZh: '土瓜湾', districtNameZh: '九龙城区', latitude: 22.3160, longitude: 114.1900),
  HkSubArea(nameZh: '何文田', districtNameZh: '九龙城区', latitude: 22.3120, longitude: 114.1830),
  HkSubArea(nameZh: '启德', districtNameZh: '九龙城区', latitude: 22.3240, longitude: 114.1980),
  // 九龙 · 黄大仙区
  HkSubArea(nameZh: '黄大仙', districtNameZh: '黄大仙区', latitude: 22.3400, longitude: 114.1950),
  HkSubArea(nameZh: '乐富', districtNameZh: '黄大仙区', latitude: 22.3370, longitude: 114.1870),
  HkSubArea(nameZh: '钻石山', districtNameZh: '黄大仙区', latitude: 22.3400, longitude: 114.2020),
  HkSubArea(nameZh: '新蒲岗', districtNameZh: '黄大仙区', latitude: 22.3340, longitude: 114.1980),
  HkSubArea(nameZh: '慈云山', districtNameZh: '黄大仙区', latitude: 22.3480, longitude: 114.1960),
  // 九龙 · 观塘区
  HkSubArea(nameZh: '观塘', districtNameZh: '观塘区', latitude: 22.3114, longitude: 114.2260),
  HkSubArea(nameZh: '牛头角', districtNameZh: '观塘区', latitude: 22.3140, longitude: 114.2140),
  HkSubArea(nameZh: '蓝田', districtNameZh: '观塘区', latitude: 22.3060, longitude: 114.2300),
  HkSubArea(nameZh: '九龙湾', districtNameZh: '观塘区', latitude: 22.3230, longitude: 114.2100),
  HkSubArea(nameZh: '秀茂坪', districtNameZh: '观塘区', latitude: 22.3200, longitude: 114.2380),
  // 新界 · 北区
  HkSubArea(nameZh: '上水', districtNameZh: '北区', latitude: 22.5010, longitude: 114.1280),
  HkSubArea(nameZh: '粉岭', districtNameZh: '北区', latitude: 22.4944, longitude: 114.1467),
  HkSubArea(nameZh: '沙头角', districtNameZh: '北区', latitude: 22.5450, longitude: 114.2160),
  HkSubArea(nameZh: '打鼓岭', districtNameZh: '北区', latitude: 22.5300, longitude: 114.1600),
  // 新界 · 大埔区
  HkSubArea(nameZh: '大埔', districtNameZh: '大埔区', latitude: 22.4505, longitude: 114.1644),
  HkSubArea(nameZh: '太和', districtNameZh: '大埔区', latitude: 22.4510, longitude: 114.1610),
  HkSubArea(nameZh: '林村', districtNameZh: '大埔区', latitude: 22.4380, longitude: 114.1420),
  HkSubArea(nameZh: '汀角', districtNameZh: '大埔区', latitude: 22.4720, longitude: 114.2300),
  // 新界 · 沙田区
  HkSubArea(nameZh: '沙田', districtNameZh: '沙田区', latitude: 22.3875, longitude: 114.1953),
  HkSubArea(nameZh: '大围', districtNameZh: '沙田区', latitude: 22.3740, longitude: 114.1780),
  HkSubArea(nameZh: '马鞍山', districtNameZh: '沙田区', latitude: 22.4250, longitude: 114.2320),
  HkSubArea(nameZh: '火炭', districtNameZh: '沙田区', latitude: 22.3950, longitude: 114.1960),
  HkSubArea(nameZh: '石门', districtNameZh: '沙田区', latitude: 22.3900, longitude: 114.2100),
  // 新界 · 西贡区
  HkSubArea(nameZh: '西贡', districtNameZh: '西贡区', latitude: 22.3814, longitude: 114.2708),
  HkSubArea(nameZh: '将军澳', districtNameZh: '西贡区', latitude: 22.3080, longitude: 114.2600),
  HkSubArea(nameZh: '坑口', districtNameZh: '西贡区', latitude: 22.3140, longitude: 114.2640),
  HkSubArea(nameZh: '宝琳', districtNameZh: '西贡区', latitude: 22.3260, longitude: 114.2580),
  HkSubArea(nameZh: '调景岭', districtNameZh: '西贡区', latitude: 22.3040, longitude: 114.2520),
  // 新界 · 荃湾区
  HkSubArea(nameZh: '荃湾', districtNameZh: '荃湾区', latitude: 22.3706, longitude: 114.1130),
  HkSubArea(nameZh: '葵涌', districtNameZh: '荃湾区', latitude: 22.3640, longitude: 114.1280),
  HkSubArea(nameZh: '深井', districtNameZh: '荃湾区', latitude: 22.3680, longitude: 114.0600),
  HkSubArea(nameZh: '马湾', districtNameZh: '荃湾区', latitude: 22.3520, longitude: 114.0620),
  // 新界 · 屯门区
  HkSubArea(nameZh: '屯门', districtNameZh: '屯门区', latitude: 22.3916, longitude: 113.9775),
  HkSubArea(nameZh: '青山湾', districtNameZh: '屯门区', latitude: 22.3840, longitude: 113.9600),
  HkSubArea(nameZh: '蓝地', districtNameZh: '屯门区', latitude: 22.4180, longitude: 113.9820),
  HkSubArea(nameZh: '兆康', districtNameZh: '屯门区', latitude: 22.4080, longitude: 113.9780),
  // 新界 · 元朗区
  HkSubArea(nameZh: '元朗', districtNameZh: '元朗区', latitude: 22.4450, longitude: 114.0220),
  HkSubArea(nameZh: '天水围', districtNameZh: '元朗区', latitude: 22.4580, longitude: 114.0040),
  HkSubArea(nameZh: '洪水桥', districtNameZh: '元朗区', latitude: 22.4340, longitude: 113.9980),
  HkSubArea(nameZh: '锦田', districtNameZh: '元朗区', latitude: 22.4400, longitude: 114.0680),
  // 新界 · 葵青区
  HkSubArea(nameZh: '葵芳', districtNameZh: '葵青区', latitude: 22.3639, longitude: 114.1394),
  HkSubArea(nameZh: '青衣', districtNameZh: '葵青区', latitude: 22.3540, longitude: 114.1080),
  HkSubArea(nameZh: '荔景', districtNameZh: '葵青区', latitude: 22.3480, longitude: 114.1320),
  HkSubArea(nameZh: '葵涌', districtNameZh: '葵青区', latitude: 22.3580, longitude: 114.1260),
  // 新界 · 离岛区
  HkSubArea(nameZh: '东涌', districtNameZh: '离岛区', latitude: 22.2880, longitude: 113.9420),
  HkSubArea(nameZh: '大屿山', districtNameZh: '离岛区', latitude: 22.2700, longitude: 113.9400),
  HkSubArea(nameZh: '长洲', districtNameZh: '离岛区', latitude: 22.2070, longitude: 114.0290),
  HkSubArea(nameZh: '南丫岛', districtNameZh: '离岛区', latitude: 22.2100, longitude: 114.1150),
  HkSubArea(nameZh: '坪洲', districtNameZh: '离岛区', latitude: 22.2840, longitude: 114.0380),
];

List<HkSubArea> hkSubAreasForDistrict(String districtNameZh) {
  return kHkSubAreas
      .where((area) => area.districtNameZh == districtNameZh)
      .toList(growable: false);
}

HkSubArea? hkSubAreaByName(String districtNameZh, String subAreaName) {
  for (final area in kHkSubAreas) {
    if (area.districtNameZh == districtNameZh && area.nameZh == subAreaName) {
      return area;
    }
  }
  return null;
}

String hkDistrictShortName(String districtNameZh) {
  if (districtNameZh.endsWith('区')) {
    return districtNameZh.substring(0, districtNameZh.length - 1);
  }
  return districtNameZh;
}

String buildHkLocationLabel({
  required HkMajorRegion majorRegion,
  required HkDistrict district,
  required HkSubArea subArea,
}) {
  return '${majorRegion.label}-${hkDistrictShortName(district.nameZh)}-${subArea.nameZh}';
}

String buildHkShopAddress({
  required HkDistrict district,
  required HkSubArea subArea,
  required String detail,
}) {
  final prefix =
      '香港${district.majorRegion.label}${hkDistrictShortName(district.nameZh)}${subArea.nameZh}';
  final trimmed = detail.trim();
  if (trimmed.isEmpty) {
    return prefix;
  }
  return '$prefix$trimmed';
}

LatLng latLngForHkSelection({
  required HkDistrict district,
  required HkSubArea subArea,
}) {
  return subArea.position;
}
