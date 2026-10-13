import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/registration_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

/// A file the member picked (or the reason it was rejected).
class PickedUpload {
  const PickedUpload({this.name, this.path, this.errorKey});

  final String? name;
  final String? path;

  /// Translation key of the validation error, when the file was rejected.
  final String? errorKey;

  bool get ok => errorKey == null && path != null;
}

bool get _hasCamera =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<PickedUpload> _validate(
  String name,
  String path,
  List<String> exts,
) async {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  if (!exts.contains(ext)) {
    return const PickedUpload(errorKey: 'reg_err_file_type');
  }
  final size = await File(path).length();
  if (size > kMaxUploadBytes) {
    return const PickedUpload(errorKey: 'reg_err_file_size');
  }
  if (size == 0) return const PickedUpload(errorKey: 'reg_err_file_type');
  return PickedUpload(name: name, path: path);
}

/// Picks an ID document (JPG, PNG or PDF, up to 5 MB). Null if cancelled.
Future<PickedUpload?> pickDocument() async {
  try {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: kDocExtensions,
    );
    if (f == null || f.path == null) return null;
    return await _validate(f.name, f.path!, kDocExtensions);
  } catch (_) {
    return const PickedUpload(errorKey: 'reg_err_file_read');
  }
}

/// Picks a profile photo: camera or gallery on phones, a file on desktop.
Future<PickedUpload?> pickPhoto(BuildContext context) async {
  var camera = false;
  if (_hasCamera) {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.magenta,
              ),
              title: Text(tr(sheet, 'reg_pick_camera')),
              onTap: () => Navigator.of(sheet).pop(true),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.magenta,
              ),
              title: Text(tr(sheet, 'reg_pick_gallery')),
              onTap: () => Navigator.of(sheet).pop(false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return null;
    camera = choice;
  }
  try {
    if (camera) {
      final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (x == null) return null;
      return await _validate(x.name, x.path, kPhotoExtensions);
    }
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: kPhotoExtensions,
    );
    if (f == null || f.path == null) return null;
    return await _validate(f.name, f.path!, kPhotoExtensions);
  } catch (_) {
    return const PickedUpload(errorKey: 'reg_err_file_read');
  }
}
