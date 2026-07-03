import 'package:car_washing_app/license_file_viewer.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: files.isEmpty
          ? const Center(child: Text('暂无上传材料'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '共 ${files.length} 个文件，图片可直接在 App 内预览，点击可放大查看。',
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
