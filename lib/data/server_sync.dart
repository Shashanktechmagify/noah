import 'api_client.dart';
import 'notifications_data.dart';
import 'session_store.dart';
import 'profile_data.dart';
import 'registration_data.dart';

/// Live mode: loads the signed-in member's registration and profile from the
/// server into the app's state. [phone] is the number shown in the app.
Future<void> loadMemberFromServer(String phone, {bool withNotifications = false}) async {
  final d = await api.bootstrap(notifications: withNotifications);
  registration.loadFromServer(d['registration'] as Map<String, dynamic>, phone);
  profile.loadFromServer(d['profile'] as Map<String, dynamic>);
  final list = d['notifications'];
  if (list is Map<String, dynamic>) notificationsState.apply(list);
  // Kept on the phone, so the next start can open straight to Home without asking the server.
  await sessionStore.saveBootstrap(phone, d);
}
