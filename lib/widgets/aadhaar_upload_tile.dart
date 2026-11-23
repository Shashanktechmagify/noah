import 'dart:io' show File;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../screens/registration/registration_widgets.dart' show DashedBox;
import '../screens/registration/uploads.dart';
import '../theme/app_theme.dart';
import 'rich_html.dart' show openImageProviderViewer;

/// The Aadhaar picture box, the same as the ID proof of the registration: a dashed box to upload; once a file is chosen a
/// green card with its name and **View**, **Replace** and **Remove** at once.
class AadhaarUploadTile extends StatelessWidget {
  const AadhaarUploadTile({
    super.key,
    required this.file,
    required this.onPick,
    required this.onRemove,
    this.busy = false,
  });

  /// The file the member chose (null: nothing yet).
  final PickedUpload? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool busy;

  Future<void> _view(BuildContext context) async {
    final path = file?.path;
    final isPdf = (file?.name ?? path ?? '').toLowerCase().endsWith('.pdf');
    if (path == null || isPdf || !File(path).existsSync()) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(tr(context, 'pf_doc_nopreview'))),
        );
      return;
    }
    // Read it now, so a replaced picture never shows the old one from the image cache.
    final bytes = await File(path).readAsBytes();
    if (!context.mounted) return;
    openImageProviderViewer(context, MemoryImage(bytes));
  }

  Widget _action(String text, VoidCallback onTap, {Color? color}) =>
      GestureDetector(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            text,
            style: TextStyle(
              color: color ?? AppColors.magenta,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (file == null || !file!.ok) {
      return DashedBox(
        height: 96,
        onTap: busy ? null : onPick,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: AppColors.magenta, size: 24),
            const SizedBox(height: 4),
            Text(
              tr(context, 'mm_aadhaar_doc'),
              style: const TextStyle(
                color: AppColors.magenta,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tr(context, 'reg_upload_hint'),
              style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F4EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E9D5B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check, color: Color(0xFF1F8A4C)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file!.name ?? tr(context, 'reg_uploaded'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  tr(context, 'reg_uploaded'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          _action(tr(context, 'reg_view'), () => _view(context)),
          _action(tr(context, 'reg_replace'), onPick),
          _action(
            tr(context, 'doc_remove'),
            onRemove,
            color: const Color(0xFFD6334B),
          ),
        ],
      ),
    );
  }
}
