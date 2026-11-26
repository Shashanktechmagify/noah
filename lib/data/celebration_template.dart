import 'package:shared_preferences/shared_preferences.dart';

/// The WhatsApp greeting a pastor or cell leader sends on a birthday or an anniversary. The standard one is in the app's words;
/// each person can write their own (kept on this phone). `{name}` is where the person's first name comes.
class CelebrationTemplate {
  static String _key(bool birthday) =>
      birthday ? 'noah_wa_template_birthday' : 'noah_wa_template_anniversary';

  /// The saved message, or null when the standard one is used.
  static Future<String?> read(bool birthday) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key(birthday))?.trim();
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      return null;
    }
  }

  /// Saves [text]; an empty one goes back to the standard message.
  static Future<void> write(bool birthday, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = text.trim();
      if (t.isEmpty) {
        await prefs.remove(_key(birthday));
      } else {
        await prefs.setString(_key(birthday), t);
      }
    } catch (_) {
      // Not saved: the standard message is used next time.
    }
  }
}
