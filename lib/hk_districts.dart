/// Hong Kong official 18 districts grouped into three major regions.
enum HkMajorRegion {
  hongKongIsland('港岛'),
  kowloon('九龙'),
  newTerritories('新界');

  const HkMajorRegion(this.label);
  final String label;
}

class HkDistrict {
  const HkDistrict({
    required this.nameZh,
    required this.majorRegion,
    required this.latitude,
    required this.longitude,
  });

  final String nameZh;
  final HkMajorRegion majorRegion;
  final double latitude;
  final double longitude;

  String get fullAddressPrefix => '香港${majorRegion.label}$nameZh';
}

/// Source: Hong Kong SAR 18 districts (官方行政区划).
const List<HkDistrict> kHkDistricts = [
  HkDistrict(
    nameZh: '中西区',
    majorRegion: HkMajorRegion.hongKongIsland,
    latitude: 22.2819,
    longitude: 114.1589,
  ),
  HkDistrict(
    nameZh: '湾仔区',
    majorRegion: HkMajorRegion.hongKongIsland,
    latitude: 22.2764,
    longitude: 114.1828,
  ),
  HkDistrict(
    nameZh: '东区',
    majorRegion: HkMajorRegion.hongKongIsland,
    latitude: 22.2844,
    longitude: 114.2244,
  ),
  HkDistrict(
    nameZh: '南区',
    majorRegion: HkMajorRegion.hongKongIsland,
    latitude: 22.2456,
    longitude: 114.1569,
  ),
  HkDistrict(
    nameZh: '油尖旺区',
    majorRegion: HkMajorRegion.kowloon,
    latitude: 22.3117,
    longitude: 114.1703,
  ),
  HkDistrict(
    nameZh: '深水埗区',
    majorRegion: HkMajorRegion.kowloon,
    latitude: 22.3300,
    longitude: 114.1628,
  ),
  HkDistrict(
    nameZh: '九龙城区',
    majorRegion: HkMajorRegion.kowloon,
    latitude: 22.3282,
    longitude: 114.1910,
  ),
  HkDistrict(
    nameZh: '黄大仙区',
    majorRegion: HkMajorRegion.kowloon,
    latitude: 22.3400,
    longitude: 114.1950,
  ),
  HkDistrict(
    nameZh: '观塘区',
    majorRegion: HkMajorRegion.kowloon,
    latitude: 22.3114,
    longitude: 114.2260,
  ),
  HkDistrict(
    nameZh: '北区',
    majorRegion: HkMajorRegion.newTerritories,
    latitude: 22.4944,
    longitude: 114.1467,
  ),
  HkDistrict(
    nameZh: '大埔区',
    majorRegion: HkMajorRegion.newTerritories,
    latitude: 22.4505,
    longitude: 114.1644,
  ),
  HkDistrict(
    nameZh: '沙田区',
    majorRegion: HkMajorRegion.newTerritories,
    latitude: 22.3875,
    longitude: 114.1953,
  ),
  HkDistrict(
    nameZh: '西贡区',
    majorRegion: HkMajorRegion.newTerritories,
    latitude: 22.3814,
    longitude: 114.2708,
  ),
  HkDistrict(
    nameZh: '荃湾区',
    majorRegion: HkMajorRegion.newTerritories,
    latitude: 22.3706,
    longitude: 114.1130,
  ),
  HkDistrict(
    nameZh: '屯门区',
    majorRegion: HkMajorRegion.newTerritories,
    latitude: 22.3916,
    longitude: 113.9775,
  ),
  HkDistrict(
    nameZh: '元朗区',
    majorRegion: HkMajorRegion.newTerritories,
    latitude: 22.4450,
    longitude: 114.0220,
  ),
  HkDistrict(
    nameZh: '葵青区',
    majorRegion: HkMajorRegion.newTerritories,
    latitude: 22.3639,
    longitude: 114.1394,
  ),
  HkDistrict(
    nameZh: '离岛区',
    majorRegion: HkMajorRegion.newTerritories,
    latitude: 22.2810,
    longitude: 113.9420,
  ),
];

List<HkDistrict> hkDistrictsForRegion(HkMajorRegion region) {
  return kHkDistricts
      .where((district) => district.majorRegion == region)
      .toList(growable: false);
}

HkDistrict? hkDistrictByName(String nameZh) {
  for (final district in kHkDistricts) {
    if (district.nameZh == nameZh) {
      return district;
    }
  }
  return null;
}

String _hkDistrictShortName(String districtNameZh) {
  if (districtNameZh.endsWith('区')) {
    return districtNameZh.substring(0, districtNameZh.length - 1);
  }
  return districtNameZh;
}

/// Resolves the official HK district from a full shop address string.
HkDistrict? hkDistrictForAddress(String address) {
  HkDistrict? best;
  var bestLength = 0;
  for (final district in kHkDistricts) {
    if (address.contains(district.nameZh) &&
        district.nameZh.length > bestLength) {
      best = district;
      bestLength = district.nameZh.length;
      continue;
    }
    final shortName = _hkDistrictShortName(district.nameZh);
    if (shortName != district.nameZh &&
        address.contains(shortName) &&
        shortName.length > bestLength) {
      best = district;
      bestLength = shortName.length;
    }
  }
  return best;
}

/// Resolves the major HK region (港岛 / 九龙 / 新界) from a shop address.
HkMajorRegion? hkMajorRegionForAddress(String address) {
  final district = hkDistrictForAddress(address);
  if (district != null) {
    return district.majorRegion;
  }
  for (final region in HkMajorRegion.values) {
    if (address.contains(region.label)) {
      return region;
    }
  }
  return null;
}
