import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'open_target.dart';

/// A shared Noahgram link opens the app on that post: the link's page hands over to `noah://post/<id>`.
/// The request waits in [openRequest] until the main shell exists (a launch from the link, or a sign-in first).
StreamSubscription<Uri>? _links;

/// The post a `noah://post/<id>` link names, or null for any other address.
@visibleForTesting
String? postIdOfLink(Uri uri) {
  if (uri.scheme != 'noah' || uri.host != 'post') return null;
  final id = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
  return RegExp(r'^\d{1,20}$').hasMatch(id) ? id : null;
}

void _open(Uri uri) {
  final id = postIdOfLink(uri);
  if (id != null) {
    openRequest.value = OpenTarget(type: 'noahgram_link', postId: id);
  }
}

Future<void> startDeepLinks() async {
  if (!liveApi || _links != null) return;
  try {
    final links = AppLinks();
    final first = await links.getInitialLink();
    if (first != null) _open(first);
    _links = links.uriLinkStream.listen(_open, onError: (_) {});
  } catch (_) {
    // A phone without link support still works; the link's page just cannot open the app.
  }
}
