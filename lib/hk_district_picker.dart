import 'package:car_washing_app/hk_districts.dart';
import 'package:car_washing_app/hk_sub_areas.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
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
    this.onDetailChanged,
    super.key,
  });

  final HkMajorRegion majorRegion;
  final String districtName;
  final String subAreaName;
  final TextEditingController detailController;
  final ValueChanged<HkMajorRegion> onMajorRegionChanged;
  final ValueChanged<HkDistrict> onDistrictChanged;
  final ValueChanged<HkSubArea> onSubAreaChanged;
  final ValueChanged<String>? onDetailChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final districts = hkDistrictsForRegion(majorRegion);
    final selectedDistrict =
        hkDistrictByName(districtName) ?? districts.first;
    final subAreas = hkSubAreasForDistrict(selectedDistrict.nameZh);
    final selectedSubArea = hkSubAreaByName(selectedDistrict.nameZh, subAreaName) ??
        (subAreas.isNotEmpty ? subAreas.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.hkRegionTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<HkMajorRegion>(
          initialValue: majorRegion,
          decoration: InputDecoration(
            labelText: s.hkMajorRegion,
            border: const OutlineInputBorder(),
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
          decoration: InputDecoration(
            labelText: s.hk18Districts,
            border: const OutlineInputBorder(),
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
            decoration: InputDecoration(
              labelText: s.hkSubArea,
              border: const OutlineInputBorder(),
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
            s.hkSelected(buildHkLocationLabel(
              majorRegion: majorRegion,
              district: selectedDistrict,
              subArea: selectedSubArea,
            )),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: detailController,
          onChanged: onDetailChanged,
          decoration: InputDecoration(
            labelText: s.hkDetailAddress,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

LatLng latLngForHkDistrict(HkDistrict district) {
  return LatLng(district.latitude, district.longitude);
}
