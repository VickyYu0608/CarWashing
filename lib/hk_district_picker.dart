import 'package:car_washing_app/hk_districts.dart';
import 'package:car_washing_app/hk_sub_areas.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HkDistrictPicker extends StatelessWidget {
  const HkDistrictPicker({
    required this.majorRegion,
    required this.districtName,
    required this.subAreaName,
    required this.detailController,
    required this.onMajorRegionChanged,
    required this.onDistrictChanged,
    required this.onSubAreaChanged,
    super.key,
  });

  final HkMajorRegion majorRegion;
  final String districtName;
  final String subAreaName;
  final TextEditingController detailController;
  final ValueChanged<HkMajorRegion> onMajorRegionChanged;
  final ValueChanged<HkDistrict> onDistrictChanged;
  final ValueChanged<HkSubArea> onSubAreaChanged;

  @override
  Widget build(BuildContext context) {
    final districts = hkDistrictsForRegion(majorRegion);
    final selectedDistrict =
        hkDistrictByName(districtName) ?? districts.first;
    final subAreas = hkSubAreasForDistrict(selectedDistrict.nameZh);
    final selectedSubArea = hkSubAreaByName(selectedDistrict.nameZh, subAreaName) ??
        (subAreas.isNotEmpty ? subAreas.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '香港地区（三大区 · 18区 · 细分区域）',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<HkMajorRegion>(
          initialValue: majorRegion,
          decoration: const InputDecoration(
            labelText: '三大区',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final region in HkMajorRegion.values)
              DropdownMenuItem(value: region, child: Text(region.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              onMajorRegionChanged(value);
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedDistrict.nameZh,
          decoration: const InputDecoration(
            labelText: '18区',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final district in districts)
              DropdownMenuItem(
                value: district.nameZh,
                child: Text(district.nameZh),
              ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            final district = hkDistrictByName(value);
            if (district != null) {
              onDistrictChanged(district);
            }
          },
        ),
        const SizedBox(height: 12),
        if (subAreas.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: selectedSubArea?.nameZh,
            decoration: const InputDecoration(
              labelText: '细分区域',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final area in subAreas)
                DropdownMenuItem(value: area.nameZh, child: Text(area.nameZh)),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              final area = hkSubAreaByName(selectedDistrict.nameZh, value);
              if (area != null) {
                onSubAreaChanged(area);
              }
            },
          ),
        if (selectedSubArea != null) ...[
          const SizedBox(height: 8),
          Text(
            '已选：${buildHkLocationLabel(majorRegion: majorRegion, district: selectedDistrict, subArea: selectedSubArea)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: detailController,
          decoration: const InputDecoration(
            labelText: '详细地址（街道/大厦，选填）',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

LatLng latLngForHkDistrict(HkDistrict district) {
  return LatLng(district.latitude, district.longitude);
}
