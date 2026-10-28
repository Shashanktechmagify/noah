import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'session_store.dart';

/// Base URL of the Noah API (the Catalyst function). Set it when running:
///   flutter run --dart-define=NOAH_API=https://YOUR-PROJECT.development.catalystserverless.in/server/noah_api
/// Left empty, the app stays in demo mode (fixed code, no network).
const kApiBase = String.fromEnvironment('NOAH_API');

bool get liveApi => kApiBase.isNotEmpty;

class ApiException implements Exception {
  ApiException(
    this.code,
    this.message, {
    this.status = 0,
    this.details = const {},
  });

  /// Machine code from the server, e.g. `otp_incorrect`, or `network`.
  final String code;
  final String message;
  final int status;
  final Map<String, dynamic> details;

  /// Field names the server rejected (`invalid_fields`, `registration_incomplete`).
  Map<String, dynamic> get fields =>
      (details['fields'] as Map<String, dynamic>?) ?? const {};

  @override
  String toString() => message;
}

class OtpSent {
  OtpSent({
    required this.phoneKey,
    required this.otpLength,
    required this.resendAfter,
    this.devOtp,
  });

  final String phoneKey;
  final int otpLength;
  final int resendAfter;

  /// Only present while the server runs with OTP_DEV_ECHO (testing).
  final String? devOtp;
}

class SignedIn {
  SignedIn({
    required this.next,
    required this.isNewMember,
    required this.accessToken,
    required this.refreshToken,
  });

  /// `home`, `registration` or `registrationStatus`.
  final String next;
  final bool isNewMember;
  final String accessToken;
  final String refreshToken;
}

/// A file stored on the server.
class UploadedFile {
  UploadedFile(this.id, this.name);
  final String id;
  final String name;
}

/// Calls the Noah API. Tokens are kept in memory for now.
/// TODO: move the refresh token to secure storage before release.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  int _sessionReads = 0;
  int _sessionWrites = 0;

  final http.Client _client;
  String? accessToken;
  String? refreshToken;
  Future<bool>? _refreshing;

  /// `pastor`, `admin` ... for staff accounts; empty for members.
  List<String> roles = [];

  /// Staff who can use the pastor inbox.
  bool get isStaff =>
      roles.any((r) => const {'pastor', 'admin', 'superAdmin'}.contains(r));

  /// A pastor answers messages instead of sending them to a pastor.
  bool get isPastor => roles.contains('pastor');

  bool get signedIn => accessToken != null;

  void clear() {
    final wasSignedIn = accessToken != null || refreshToken != null;
    accessToken = null;
    refreshToken = null;
    roles = [];
    sessionStore.clear();
    // Signed out without the member asking (the saved sign-in expired): the app shows the sign-in page.
    if (wasSignedIn && !_signingOut) onSessionLost?.call();
  }

  bool _signingOut = false;

  /// Called when the server no longer accepts the saved sign-in.
  void Function()? onSessionLost;

  /// Puts back a sign-in saved on this phone (see session_restore.dart).
  void restore({required String accessToken, required String refreshToken, required List<String> roles}) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.roles = roles;
  }

  /// Address of a stored file, and the header that lets the member read it.
  String fileUrl(String id) => '$kApiBase/files/$id';
  Map<String, String> get authHeaders => {
    // Not "Authorization": Catalyst's gateway intercepts that header.
    'X-Noah-Token': ?accessToken,
    // Which phone is calling, so a message you send never buzzes your own phone.
    'X-Noah-Device': ?deviceId,
  };

  /// Set by the push service once this install has an id.
  String? deviceId;

  // ── Plumbing ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? json,
    Uint8List? bytes,
    Map<String, String> headers = const {},
    bool auth = true,
    bool retried = false,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final request = http.Request(method, Uri.parse('$kApiBase$path'));
    request.headers.addAll({
      if (json != null) 'Content-Type': 'application/json',
      if (auth) ...authHeaders,
      ...headers,
    });
    if (json != null) request.body = jsonEncode(json);
    if (bytes != null) request.bodyBytes = bytes;

    http.Response res;
    try {
      res = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      ).timeout(timeout);
    } on TimeoutException {
      throw ApiException('network', 'The server did not respond. Try again.');
    } catch (_) {
      throw ApiException(
        'network',
        'Could not reach the server. Check your internet.',
      );
    }

    // Development: what each call cost the server's database, and the total since the app started.
    if (kDebugMode) {
      final reads = int.tryParse(res.headers['x-noah-reads'] ?? '') ?? 0;
      final writes = int.tryParse(res.headers['x-noah-writes'] ?? '') ?? 0;
      _sessionReads += reads;
      _sessionWrites += writes;
      debugPrint(
        '[api] $method $path -> ${res.statusCode}  reads=$reads writes=$writes  '
        '(since start: reads=$_sessionReads writes=$_sessionWrites)',
      );
    }

    if (method != 'GET' && res.statusCode < 400 &&
        (path.startsWith('/registration') || path.startsWith('/profile') || path.startsWith('/files') || path == '/notifications/read')) {
      sessionStore.markStale();
    }

    final text = res.body.isEmpty ? '{}' : res.body;
    Map<String, dynamic> data;
    try {
      data = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }
    if (res.statusCode >= 400) {
      final err = (data['error'] as Map<String, dynamic>?) ?? {};
      final code = '${err['code'] ?? 'error'}';
      // The access token lasts 15 minutes: swap it once and try again.
      if (auth && !retried && res.statusCode == 401 && refreshToken != null) {
        if (await _refresh()) {
          return _send(
            method,
            path,
            json: json,
            bytes: bytes,
            headers: headers,
            auth: auth,
            retried: true,
            timeout: timeout,
          );
        }
      }
      throw ApiException(
        code,
        '${err['message'] ?? 'Something went wrong (${res.statusCode})'}',
        status: res.statusCode,
        details: err,
      );
    }
    return data;
  }

  /// One refresh at a time: a refresh token only works once.
  Future<bool> _refresh() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    try {
      final d = await _send(
        'POST',
        '/auth/refresh',
        json: {'refreshToken': refreshToken},
        auth: false,
      );
      accessToken = d['accessToken'] as String?;
      refreshToken = d['refreshToken'] as String?;
      if (accessToken != null && refreshToken != null) {
        sessionStore.saveTokens(accessToken: accessToken!, refreshToken: refreshToken!);
      }
      return accessToken != null;
    } on ApiException {
      clear();
      return false;
    }
  }

  // ── Sign in ───────────────────────────────────────────────────────────

  Future<OtpSent> sendOtp(String countryCode, String mobileNumber) async {
    final d = await _send(
      'POST',
      '/auth/otp/send',
      json: {'countryCode': countryCode, 'mobileNumber': mobileNumber},
      auth: false,
    );
    return OtpSent(
      phoneKey: '${d['phoneKey']}',
      otpLength: (d['otpLength'] as num?)?.toInt() ?? 6,
      resendAfter: (d['resendAfter'] as num?)?.toInt() ?? 24,
      devOtp: d['devOtp'] as String?,
    );
  }

  Future<SignedIn> verifyOtp(
    String countryCode,
    String mobileNumber,
    String otp, {
    String? deviceId,
    String? deviceName,
  }) async {
    final d = await _send(
      'POST',
      '/auth/otp/verify',
      json: {
        'countryCode': countryCode,
        'mobileNumber': mobileNumber,
        'otp': otp,
        'deviceId': ?deviceId,
        'deviceName': ?deviceName,
      },
      auth: false,
    );
    accessToken = d['accessToken'] as String?;
    refreshToken = d['refreshToken'] as String?;
    roles = ((d['roles'] as List?) ?? const []).map((e) => '$e').toList();
    if (accessToken != null && refreshToken != null) {
      sessionStore.saveTokens(accessToken: accessToken!, refreshToken: refreshToken!, roles: roles);
    }
    return SignedIn(
      next: '${d['next']}',
      isNewMember: d['isNewMember'] == true,
      accessToken: accessToken ?? '',
      refreshToken: refreshToken ?? '',
    );
  }

  Future<void> logout() async {
    final token = refreshToken;
    _signingOut = true;
    clear();
    _signingOut = false;
    if (token == null) return;
    try {
      await _send(
        'POST',
        '/auth/logout',
        json: {'refreshToken': token},
        auth: false,
      );
    } on ApiException {
      // Signing out on this phone is enough.
    }
  }

  /// `{ member, registration: {status}, next }`.
  Future<Map<String, dynamic>> me() => _send('GET', '/me');

  // ── Registration ──────────────────────────────────────────────────────

  /// `{ registration, profile }` in one call (sign-in needs both).
  /// Registration and profile in one call; [notifications] adds the notification list too.
  Future<Map<String, dynamic>> bootstrap({bool notifications = false}) =>
      _send('GET', notifications ? '/me/bootstrap?notifications=1' : '/me/bootstrap');

  Future<Map<String, dynamic>> getRegistration() =>
      _send('GET', '/registration');

  Future<Map<String, dynamic>> saveRegistration(Map<String, dynamic> body) =>
      _send('PUT', '/registration', json: body);

  Future<Map<String, dynamic>> submitRegistration() =>
      _send('POST', '/registration/submit');

  // ── Files ─────────────────────────────────────────────────────────────

  /// Uploads a picked or recorded file. [purpose] is `photo`, `idProof` or `video`.
  Future<UploadedFile> uploadFile(
    String purpose,
    String path, {
    String? name,
  }) async {
    final bytes = await File(path).readAsBytes();
    final fileName = name ?? path.split(RegExp(r'[\\/]')).last;
    final d = await _send(
      'POST',
      '/files?purpose=$purpose',
      bytes: bytes,
      headers: {
        'X-File-Name': Uri.encodeComponent(fileName),
        'Content-Type': 'application/octet-stream',
      },
      timeout: const Duration(minutes: 5),
    );
    return UploadedFile('${d['id']}', '${d['name']}');
  }

  // ── Chat with the church ─────────────────────────────────────────────

  /// `{ contacts: [{kind, name, available, lastMessage, unread}], totalUnread }`.
  /// [since] is the `activity` token of the last answer: while nothing has changed the server
  /// replies `{unchanged: true}` without reading its database.
  Future<Map<String, dynamic>> chatContacts({String? since}) =>
      _send('GET', '/chat/contacts${since == null ? '' : '?since=$since'}');

  /// `{ messages: [{id, text, fromMe, isFromMinistry, createdAt}] }`. With
  /// [after] only newer messages come back. Reading marks them read.
  /// [contactId] is the pastor's member id (not needed for the leader or office).
  Future<Map<String, dynamic>> chatMessages(
    String kind, {
    String? contactId,
    String? after,
    String? since,
  }) {
    final query = [
      if (contactId != null) 'contact=$contactId',
      if (after != null) 'after=$after',
      if (since != null) 'since=$since',
    ].join('&');
    return _send(
      'GET',
      '/chat/$kind/messages${query.isEmpty ? '' : '?$query'}',
    );
  }

  Future<Map<String, dynamic>> chatSend(
    String kind,
    String text, {
    String? contactId,
  }) => _send(
    'POST',
    '/chat/$kind/messages',
    json: {'text': text, 'contactId': ?contactId},
  );

  // ── Pastor inbox (staff only) ────────────────────────────────────────

  Future<Map<String, dynamic>> pastorThreads({String? since}) =>
      _send('GET', '/pastor/threads${since == null ? '' : '?since=$since'}');

  Future<Map<String, dynamic>> pastorMessages(
    String threadId, {
    String? after,
    String? since,
  }) {
    final query = [
      if (after != null) 'after=$after',
      if (since != null) 'since=$since',
    ].join('&');
    return _send(
      'GET',
      '/pastor/threads/$threadId/messages${query.isEmpty ? '' : '?$query'}',
    );
  }

  Future<Map<String, dynamic>> pastorReply(String threadId, String text) =>
      _send('POST', '/pastor/threads/$threadId/messages', json: {'text': text});

  // ── Daily content (Manna, prayers, confessions) ─────────────────────

  /// `{ items: [...] }` for `manna`, `prayers` or `confessions`, newest first, in language [lang]
  /// (the server falls back to English for days that have no entry in it).
  Future<Map<String, dynamic>> content(String kind, int lang, {int limit = 30}) =>
      _send('GET', '/content/$kind?lang=$lang&limit=$limit');

  /// Counts a view of a Daily Manna (the server batches the writes).
  Future<void> viewManna(String id) => _send('POST', '/content/manna/$id/view', json: {});

  /// Sets whether the member likes the Manna: `{ liked, likes }`.
  Future<Map<String, dynamic>> likeManna(String id, bool liked) =>
      _send('POST', '/content/manna/$id/like', json: {'liked': liked});

  /// `{ liked, items: [{ id, author: {id, name}, text, createdAt, mine }] }`, newest first.
  Future<Map<String, dynamic>> mannaComments(String id) =>
      _send('GET', '/content/manna/$id/comments');

  Future<Map<String, dynamic>> addMannaComment(String id, String text) =>
      _send('POST', '/content/manna/$id/comments', json: {'text': text});

  Future<void> deleteMannaComment(String id, String commentId) =>
      _send('DELETE', '/content/manna/$id/comments/${Uri.encodeComponent(commentId)}');

  // ── Push and notifications ───────────────────────────────────────────

  Future<void> registerDevice(
    String deviceId,
    String pushToken,
    String platform,
  ) => _send(
    'PUT',
    '/devices',
    json: {'deviceId': deviceId, 'pushToken': pushToken, 'platform': platform},
  );

  Future<void> unregisterDevice(String deviceId) =>
      _send('DELETE', '/devices/${Uri.encodeComponent(deviceId)}');

  /// `{ unread, notifications: [{id, type, title, body, isRead, createdAt}] }`.
  Future<Map<String, dynamic>> notifications() =>
      _send('GET', '/notifications');

  Future<void> markNotificationsRead() =>
      _send('POST', '/notifications/read', json: {});

  // ── Profile ───────────────────────────────────────────────────────────

  /// `{ status, fields: {fieldId: value}, photo, requests: [...] }`.
  Future<Map<String, dynamic>> getProfile() => _send('GET', '/profile');

  Future<Map<String, dynamic>> requestChange(String fieldId, String newValue) =>
      _send(
        'POST',
        '/profile/change-requests',
        json: {'fieldId': fieldId, 'newValue': newValue},
      );
}

final api = ApiClient();
