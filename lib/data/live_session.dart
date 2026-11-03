import 'api_client.dart';
import 'family_data.dart';
import 'ministry_data.dart';
import 'notifications_data.dart';
import 'pastor_data.dart';
import 'push_service.dart';

/// Live mode: starts what runs while a member is signed in (chats, the
/// notification list, the pastor inbox for staff, push registration).
Future<void> startLiveSession() async {
  if (!liveApi) return;
  ministry.resetForLive();
  // A cell leader's inbox starts loading once the contacts say there is one.
  ministry.onInboxFound = pastorInbox.ensureLoaded;
  // The notification list arrives with the sign-in call (/me/bootstrap). Chats and the pastor inbox
  // load when the member first opens the Me tab (see MainShell) or the bell. Reading them at sign-in
  // costs database reads that most sessions never use.
  pushService.start();
}

/// Stops it and signs out on the server.
Future<void> endLiveSession() async {
  if (!liveApi) return;
  ministry.stopPolling();
  pastorInbox.stop();
  notificationsState.clear();
  familyState.clear();
  await pushService.stop();
  await api.logout();
}
