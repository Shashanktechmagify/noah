import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/main_shell.dart';
import '../screens/registration/registration_flow.dart';
import '../screens/registration/registration_status.dart';
import 'api_client.dart';
import 'live_session.dart';
import 'notifications_data.dart';
import 'profile_data.dart';
import 'registration_data.dart';
import 'server_sync.dart';
import 'session_store.dart';

/// The saved details are used as they are for this long; after it they are read again in the
/// background (the screen does not wait for it). A change the member makes themselves marks them stale sooner.
const _freshFor = Duration(minutes: 30);

/// If this phone is still signed in, puts the saved details into the app and returns the page to open
/// (no server call at all). Returns null when the member has to sign in.
Future<Widget?> restoreSavedSession() async {
  if (!liveApi) return null;
  final saved = await sessionStore.load();
  if (saved == null) return null;

  api.restore(
    accessToken: saved.accessToken,
    refreshToken: saved.refreshToken,
    roles: saved.roles,
  );
  final boot = saved.bootstrap;
  try {
    registration.loadFromServer(boot['registration'] as Map<String, dynamic>, saved.phone);
    profile.loadFromServer(boot['profile'] as Map<String, dynamic>);
    final list = boot['notifications'];
    if (list is Map<String, dynamic>) notificationsState.apply(list);
  } catch (_) {
    // The saved copy cannot be read (an older app version wrote it): sign in again.
    api.clear();
    return null;
  }
  await startLiveSession();

  final age = DateTime.now().millisecondsSinceEpoch - saved.savedAt;
  if (saved.savedAt == 0 || age > _freshFor.inMilliseconds) {
    // Read again quietly. If the sign-in has expired meanwhile the app sends the member to sign in.
    unawaited(loadMemberFromServer(saved.phone, withNotifications: true).catchError((_) {}));
  }

  if (registration.status == RegStatus.approved) {
    registration.approve();
    return const MainShell();
  }
  if (registration.completed) return const RegistrationStatusScreen();
  return RegistrationFlow(initialStep: registration.firstIncompleteStep);
}
