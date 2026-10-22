import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What is kept on this phone so the app opens straight to Home next time: the sign-in tokens
/// and the data the last sign-in read (profile, registration, notifications). It lives in the
/// app's private storage on the phone (other apps cannot read it), and is wiped when the member
/// signs out. TODO: move to the platform keystore before release.
class SavedSession {
  SavedSession({
    required this.accessToken,
    required this.refreshToken,
    required this.roles,
    required this.phone,
    required this.bootstrap,
    required this.savedAt,
  });

  final String accessToken;
  final String refreshToken;
  final List<String> roles;
  final String phone;

  /// The `/me/bootstrap` answer (registration, profile, notifications) as it was read.
  final Map<String, dynamic> bootstrap;

  /// When [bootstrap] was read (milliseconds since 1970). 0 means "read it again at the next start".
  final int savedAt;
}

class SessionStore {
  static const _key = 'noah_session_v1';

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _read() async {
    if (_cache != null) return _cache!;
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      _cache = raw == null ? <String, dynamic>{} : (jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _cache = <String, dynamic>{};
    }
    return _cache!;
  }

  Future<void> _write(Map<String, dynamic> data) async {
    _cache = data;
    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(data));
    } catch (e) {
      debugPrint('Could not save the session: $e');
    }
  }

  /// After sign-in or a token refresh.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    List<String>? roles,
  }) async {
    final d = Map<String, dynamic>.from(await _read());
    d['accessToken'] = accessToken;
    d['refreshToken'] = refreshToken;
    if (roles != null) d['roles'] = roles;
    await _write(d);
  }

  /// After the app has read the member's details from the server.
  Future<void> saveBootstrap(String phone, Map<String, dynamic> bootstrap) async {
    final d = Map<String, dynamic>.from(await _read());
    final old = d['bootstrap'] is Map ? Map<String, dynamic>.from(d['bootstrap'] as Map) : <String, dynamic>{};
    // A read without the notification list keeps the list saved earlier.
    if (!bootstrap.containsKey('notifications') && old['notifications'] != null) {
      bootstrap = {...bootstrap, 'notifications': old['notifications']};
    }
    d['phone'] = phone;
    d['bootstrap'] = bootstrap;
    d['savedAt'] = DateTime.now().millisecondsSinceEpoch;
    await _write(d);
  }

  /// Something the saved copy shows was changed on the server (a profile edit...): read it again at the next start.
  Future<void> markStale() async {
    final d = await _read();
    if (d['bootstrap'] == null || d['savedAt'] == 0) return;
    await _write({...d, 'savedAt': 0});
  }

  Future<SavedSession?> load() async {
    final d = await _read();
    final access = d['accessToken'];
    final refresh = d['refreshToken'];
    final boot = d['bootstrap'];
    final phone = d['phone'];
    if (access is! String || refresh is! String || boot is! Map || phone is! String) return null;
    return SavedSession(
      accessToken: access,
      refreshToken: refresh,
      roles: ((d['roles'] as List?) ?? const []).map((e) => '$e').toList(),
      phone: phone,
      bootstrap: Map<String, dynamic>.from(boot),
      savedAt: (d['savedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> clear() async {
    _cache = <String, dynamic>{};
    try {
      await (await SharedPreferences.getInstance()).remove(_key);
    } catch (_) {}
  }
}

final sessionStore = SessionStore();
