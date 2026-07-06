import 'package:car_washing_app/api_config.dart';
import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:flutter/material.dart';

class LicenseImageFullScreenPage extends StatelessWidget {
  const LicenseImageFullScreenPage({
    required this.filename,
    super.key,
  });

  final String filename;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final url = licenseFileUrl(filename);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          filename,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) {
                return child;
              }
              return const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image_outlined,
                        color: Colors.white70, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      s.imageLoadFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static Future<void> open(BuildContext context, String filename) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LicenseImageFullScreenPage(filename: filename),
      ),
    );
  }
}

class LicenseFilePreviewTile extends StatelessWidget {
  const LicenseFilePreviewTile({
    required this.filename,
    this.height = 200,
    super.key,
  });

  final String filename;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (isLicenseImageFile(filename)) {
      return _ImagePreviewCard(
        filename: filename,
        height: height,
        onTap: () => LicenseImageFullScreenPage.open(context, filename),
      );
    }
    return _PdfPreviewCard(filename: filename);
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({
    required this.filename,
    required this.height,
    required this.onTap,
  });

  final String filename;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final url = licenseFileUrl(filename);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hide_image_outlined,
                              size: 40,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.imageCannotLoad,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.fileNotUploadedYet,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              s.tapToZoom,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filename,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfPreviewCard extends StatelessWidget {
  const _PdfPreviewCard({required this.filename});

  final String filename;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.picture_as_pdf,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              filename,
              style: const TextStyle(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s.pdfNoPreview,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
