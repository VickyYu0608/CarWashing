import 'dart:convert';

import 'package:car_washing_app/api_client.dart';
import 'package:car_washing_app/api_config.dart';
import 'package:car_washing_app/license_file_viewer.dart';
import 'package:car_washing_app/l10n/app_strings.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const _allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
const _maxFileSize = 10 * 1024 * 1024;

class LicenseUploadService {
  static Future<LicenseUploadResult> pickAndUpload() async {
    final s = AppStrings.current;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      throw LicenseUploadException(s.noFileSelected);
    }

    final picked = result.files.single;
    final originalName = picked.name.trim();
    if (originalName.isEmpty) {
      throw LicenseUploadException(s.cannotReadFilename);
    }

    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw LicenseUploadException(s.cannotReadFileContent);
    }
    if (bytes.length > _maxFileSize) {
      throw LicenseUploadException(s.fileTooLarge);
    }

    final lower = originalName.toLowerCase();
    final ok = _allowedExtensions.any((ext) => lower.endsWith('.$ext'));
    if (!ok) {
      throw LicenseUploadException(s.unsupportedLicenseFormat);
    }

    return _uploadBytes(originalName, bytes);
  }

  static Future<LicenseUploadResult> _uploadBytes(
    String originalName,
    List<int> bytes,
  ) async {
    final s = AppStrings.current;
    final uri = Uri.parse('$kApiBaseUrl/api/uploads/license');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        if (ApiClient.accessToken != null)
          'Authorization': 'Bearer ${ApiClient.accessToken}',
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: originalName,
          contentType: _contentTypeForName(originalName),
        ),
      );

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final storedName = (json['filename'] as String?)?.trim();
        if (storedName == null || storedName.isEmpty) {
          throw LicenseUploadException(s.uploadNoFilename);
        }
        return LicenseUploadResult(
          storedName: storedName,
          originalName: (json['original_name'] as String?)?.trim() ?? originalName,
          url: (json['url'] as String?)?.trim() ?? '/uploads/licenses/$storedName',
        );
      }

      var message = s.uploadFailedWithCode(streamed.statusCode);
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final detail = json['detail'];
        if (detail is String && detail.isNotEmpty) {
          message = detail;
        }
      } on Object {
        // Keep default message.
      }
      throw LicenseUploadException(message);
    } on LicenseUploadException {
      rethrow;
    } on Object catch (error) {
      throw LicenseUploadException(
        s.cannotConnectUpload(
          kApiBaseUrl,
          debug: kDebugMode ? ' ($error)' : null,
        ),
      );
    }
  }

  static MediaType? _contentTypeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return MediaType('application', 'pdf');
    }
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    return null;
  }
}

class LicenseUploadResult {
  const LicenseUploadResult({
    required this.storedName,
    required this.originalName,
    required this.url,
  });

  final String storedName;
  final String originalName;
  final String url;
}

class LicenseUploadException implements Exception {
  LicenseUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LicenseUploadSection extends StatefulWidget {
  const LicenseUploadSection({
    required this.files,
    required this.onChanged,
    this.emptyHint,
    super.key,
  });

  final List<String> files;
  final ValueChanged<List<String>> onChanged;
  final String? emptyHint;

  @override
  State<LicenseUploadSection> createState() => _LicenseUploadSectionState();
}

class _LicenseUploadSectionState extends State<LicenseUploadSection> {
  bool uploading = false;
  String? error;

  Future<void> _pickAndUpload() async {
    setState(() {
      uploading = true;
      error = null;
    });
    try {
      final uploaded = await LicenseUploadService.pickAndUpload();
      if (!mounted) {
        return;
      }
      final next = [...widget.files, uploaded.storedName];
      widget.onChanged(next);
      setState(() => error = null);
    } on LicenseUploadException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = exception.message);
    } on Object catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = exception.toString());
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
  }

  void _removeFile(String file) {
    widget.onChanged(widget.files.where((item) => item != file).toList());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final hint = widget.emptyHint ?? s.licenseUploadHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: uploading ? null : _pickAndUpload,
              icon: uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(uploading ? s.uploading : s.selectAndUpload),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.files.isEmpty)
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final file in widget.files)
                InputChip(
                  avatar: Icon(
                    isLicenseImageFile(file)
                        ? Icons.image_outlined
                        : Icons.attach_file,
                    size: 18,
                  ),
                  label: Text(file),
                  onPressed: uploading
                      ? null
                      : () {
                          if (isLicenseImageFile(file)) {
                            LicenseImageFullScreenPage.open(context, file);
                          }
                        },
                  onDeleted: uploading ? null : () => _removeFile(file),
                ),
            ],
          ),
          if (widget.files.any(isLicenseImageFile)) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount:
                    widget.files.where(isLicenseImageFile).length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final imageFiles =
                      widget.files.where(isLicenseImageFile).toList();
                  final file = imageFiles[index];
                  return GestureDetector(
                    onTap: () =>
                        LicenseImageFullScreenPage.open(context, file),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        licenseFileUrl(file),
                        width: 130,
                        height: 130,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 130,
                            height: 130,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Text(
              s.tapImageFullPreview,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}
