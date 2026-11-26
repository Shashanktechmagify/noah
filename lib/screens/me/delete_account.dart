import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../l10n/app_strings.dart';

/// "Delete my account" (Google Play requires it): a message that says what happens, and on "Delete" the server switches the
/// account off at once (the church office removes the personal data within 30 days). Then [onDeleted] signs the member out.
///
/// [delete] is the call to the server (tests give their own). Returns true when the account was deleted.
Future<bool> confirmAndDeleteAccount(
  BuildContext context, {
  required VoidCallback onDeleted,
  Future<void> Function()? delete,
}) async {
  // The messenger of the app itself: it outlives the page, which is replaced by the login page after a deletion.
  final messenger = ScaffoldMessenger.of(context);
  final done = tr(context, 'del_done');
  final sure = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Text(tr(d, 'del_title')),
      content: Text(tr(d, 'del_body')),
      actions: [
        TextButton(
          key: const ValueKey('delete-cancel'),
          onPressed: () => Navigator.of(d).pop(false),
          child: Text(tr(d, 'del_cancel')),
        ),
        TextButton(
          key: const ValueKey('delete-confirm'),
          onPressed: () => Navigator.of(d).pop(true),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD6334B)),
          child: Text(tr(d, 'del_confirm')),
        ),
      ],
    ),
  );
  if (sure != true) return false;
  try {
    await (delete ?? api.deleteAccount)();
  } on ApiException catch (e) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
  onDeleted();
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(done)));
  return true;
}
