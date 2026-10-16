import 'api_client.dart';
import 'profile_data.dart';
import 'registration_data.dart';

/// Live mode: loads the signed-in member's registration and profile from the
/// server into the app's state. [phone] is the number shown in the app.
Future<void> loadMemberFromServer(String phone) async {
  final results = await Future.wait([api.getRegistration(), api.getProfile()]);
  registration.loadFromServer(results[0], phone);
  profile.loadFromServer(results[1]);
}
