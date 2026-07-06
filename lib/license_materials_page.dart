import 'package:car_washing_app/license_file_viewer.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:flutter/material.dart';

class LicenseMaterialsPage extends StatelessWidget {
  const LicenseMaterialsPage({
    required this.title,
    required this.files,
    super.key,
  });

  final String title;
  final List<String> files;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: files.isEmpty
          ? Center(child: Text(s.noUploadedMaterials))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  s.materialsFileCount(files.length),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                for (final file in files) ...[
                  LicenseFilePreviewTile(filename: file),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}
