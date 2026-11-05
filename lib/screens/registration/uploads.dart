import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

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

/// Lets the member crop and rotate a picture before it is used (phones only; the editor is the phone's own).
/// Returns the edited picture, or null when they backed out. The edited file is always a JPG.
Future<({String name, String path})?> _crop(
  BuildContext context,
  String name,
  String path, {
  required String title,
  required bool square,
}) async {
  if (!_hasCamera) return (name: name, path: path);
  final out = await ImageCropper().cropImage(
    sourcePath: path,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 90,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: title,
        toolbarColor: AppColors.magenta,
        toolbarWidgetColor: Colors.white,
        activeControlsWidgetColor: AppColors.magenta,
        initAspectRatio: square
            ? CropAspectRatioPreset.square
            : CropAspectRatioPreset.original,
        lockAspectRatio: false,
      ),
      IOSUiSettings(title: title),
    ],
  );
  if (out == null) return null;
  final dot = name.lastIndexOf('.');
  final base = dot > 0 ? name.substring(0, dot) : name;
  return (name: '$base.jpg', path: out.path);
}

/// Picks an ID document (JPG, PNG or PDF, up to 5 MB). A picture can be cropped and rotated first; a PDF
/// is used as it is. Null if cancelled.
Future<PickedUpload?> pickDocument(BuildContext context) async {
  try {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: kDocExtensions,
    );
    if (f == null || f.path == null) return null;
    var name = f.name;
    var path = f.path!;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (ext != 'pdf' && context.mounted) {
      final edited = await _crop(
        context,
        name,
        path,
        title: tr(context, 'reg_crop_title'),
        square: false,
      );
      if (edited == null) return null;
      name = edited.name;
      path = edited.path;
    }
    return await _validate(name, path, kDocExtensions);
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
    String name;
    String path;
    if (camera) {
      final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (x == null) return null;
      name = x.name;
      path = x.path;
    } else {
      final f = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: kPhotoExtensions,
      );
      if (f == null || f.path == null) return null;
      name = f.name;
      path = f.path!;
    }
    if (!context.mounted) return null;
    final edited = await _crop(
      context,
      name,
      path,
      title: tr(context, 'reg_crop_title'),
      square: true,
    );
    if (edited == null) return null;
    return await _validate(edited.name, edited.path, kPhotoExtensions);
  } catch (_) {
    return const PickedUpload(errorKey: 'reg_err_file_read');
  }
}

/// Result of [compressVideo]: the file to upload and its sizes in bytes.
class CompressedVideo {
  const CompressedVideo(this.path, this.before, this.after);

  final String path;
  final int before;
  final int after;
}

/// Videos up to this size are uploaded as recorded (the server accepts up to 100 MB; re-encoding a
/// 2 minute video on the phone takes longer than uploading it).
const kSkipCompressionBytes = 80 * 1024 * 1024;

/// Shrinks the recorded video (480p, 24 fps) before it is uploaded so it does
/// not fill up storage. Falls back to the original when the platform has no
/// compressor (desktop) or it fails. The backend should also cap and re-encode.
Future<CompressedVideo> compressVideo(String path) async {
  final before = await File(path).length();
  // Recorded at a low bitrate already: re-encoding would only make the member wait.
  if (before <= kSkipCompressionBytes) {
    return CompressedVideo(path, before, before);
  }
  try {
    final info = await VideoCompress.compressVideo(
      path,
      quality: VideoQuality.Res640x480Quality,
      frameRate: 24,
      includeAudio: true,
      deleteOrigin: false,
    );
    final out = info?.path;
    if (out != null && info!.filesize != null && info.filesize! < before) {
      return CompressedVideo(out, before, info.filesize!);
    }
  } catch (_) {}
  return CompressedVideo(path, before, before);
}

/// "3.2 MB" / "850 KB".
String formatBytes(int bytes) => bytes >= 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).round()} KB';
