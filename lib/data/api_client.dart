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
    this.sentTo,
    this.devMailError,
  });

  final String phoneKey;

  /// Where the code went, as the server wants it shown (an email address is partly hidden: a•••@example.com).
  final String? sentTo;
  final int otpLength;
  final int resendAfter;

  /// Only present while the server runs with OTP_DEV_ECHO (testing).
  final String? devOtp;

  /// Testing only: why the email could not be sent (the code is echoed instead).
  final String? devMailError;
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
  void restore({
    required String accessToken,
    required String refreshToken,
    required List<String> roles,
  }) {
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

    if (method != 'GET' &&
        res.statusCode < 400 &&
        (path.startsWith('/registration') ||
            path.startsWith('/profile') ||
            path.startsWith('/files') ||
            path == '/notifications/read')) {
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
        sessionStore.saveTokens(
          accessToken: accessToken!,
          refreshToken: refreshToken!,
        );
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
    return _otpSent(d);
  }

  OtpSent _otpSent(Map<String, dynamic> d) => OtpSent(
    phoneKey: '${d['phoneKey'] ?? ''}',
    otpLength: (d['otpLength'] as num?)?.toInt() ?? 6,
    resendAfter: (d['resendAfter'] as num?)?.toInt() ?? 24,
    devOtp: d['devOtp'] as String?,
    sentTo: d['sentTo'] as String?,
    devMailError: d['devMailError'] as String?,
  );

  /// Mails a sign-in code to [email].
  Future<OtpSent> sendEmailOtp(String email) async => _otpSent(
    await _send(
      'POST',
      '/auth/otp/send',
      json: {'email': email.trim().toLowerCase()},
      auth: false,
    ),
  );

  /// Asks for the code that confirms a contact during registration: the member's other email address or mobile
  /// number. Give either [email] or [dial] with [number].
  Future<OtpSent> sendContactCode({
    String? email,
    String? dial,
    String? number,
  }) async => _otpSent(
    await _send(
      'POST',
      '/registration/contact/code',
      json: _contact(email, dial, number),
    ),
  );

  /// Checks the code; the server keeps the address or number only when it is right.
  Future<void> verifyContact(
    String code, {
    String? email,
    String? dial,
    String? number,
  }) async {
    await _send(
      'POST',
      '/registration/contact/verify',
      json: {..._contact(email, dial, number), 'code': code},
    );
  }

  /// Members who match what the new member typed as their reference: by [name] (first letters) or by a whole
  /// [dial] + [number]. Each hit is `{name, dial, number}`.
  Future<List<Map<String, dynamic>>> findReference({
    String? name,
    String? dial,
    String? number,
  }) async {
    final q = <String, String>{
      'name': ?name,
      'dial': ?dial,
      'number': ?number,
    };
    final d = await _send('GET', '/registration/reference?${Uri(queryParameters: q).query}');
    return ((d['items'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  /// Sends the code that confirms the WhatsApp number a member wants to put in My information.
  Future<OtpSent> sendWhatsappCode(String dial, String number) async => _otpSent(
    await _send(
      'POST',
      '/profile/whatsapp/code',
      json: {'countryCode': dial, 'mobileNumber': number},
    ),
  );

  /// Checks that code; only then does the server take a request to change the WhatsApp number.
  Future<void> verifyWhatsapp(String dial, String number, String code) async {
    await _send(
      'POST',
      '/profile/whatsapp/verify',
      json: {'countryCode': dial, 'mobileNumber': number, 'code': code},
    );
  }

  Map<String, dynamic> _contact(String? email, String? dial, String? number) =>
      email != null
      ? {'channel': 'email', 'email': email.trim().toLowerCase()}
      : {'channel': 'phone', 'countryCode': dial, 'mobileNumber': number};

  Future<SignedIn> verifyOtp(
    String countryCode,
    String mobileNumber,
    String otp, {
    String? deviceId,
    String? deviceName,
  }) => _verify({
    'countryCode': countryCode,
    'mobileNumber': mobileNumber,
    'otp': otp,
    'deviceId': ?deviceId,
    'deviceName': ?deviceName,
  });

  /// Signs in with the code mailed to [email].
  Future<SignedIn> verifyEmailOtp(
    String email,
    String otp, {
    String? deviceId,
    String? deviceName,
  }) => _verify({
    'email': email.trim().toLowerCase(),
    'otp': otp,
    'deviceId': ?deviceId,
    'deviceName': ?deviceName,
  });

  Future<SignedIn> _verify(Map<String, dynamic> body) async {
    final d = await _send('POST', '/auth/otp/verify', json: body, auth: false);
    accessToken = d['accessToken'] as String?;
    refreshToken = d['refreshToken'] as String?;
    roles = ((d['roles'] as List?) ?? const []).map((e) => '$e').toList();
    if (accessToken != null && refreshToken != null) {
      sessionStore.saveTokens(
        accessToken: accessToken!,
        refreshToken: refreshToken!,
        roles: roles,
      );
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
  Future<Map<String, dynamic>> bootstrap({bool notifications = false}) => _send(
    'GET',
    notifications ? '/me/bootstrap?notifications=1' : '/me/bootstrap',
  );

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
    String? docType,
  }) async {
    final bytes = await File(path).readAsBytes();
    final fileName = name ?? path.split(RegExp(r'[\\/]')).last;
    final d = await _send(
      'POST',
      '/files?purpose=$purpose${docType == null ? '' : '&docType=$docType'}',
      bytes: bytes,
      headers: {
        'X-File-Name': Uri.encodeComponent(fileName),
        'Content-Type': 'application/octet-stream',
      },
      timeout: const Duration(minutes: 5),
    );
    return UploadedFile('${d['id']}', '${d['name']}');
  }

  // ── Door staff: scanning entry passes ────────────────────────────────

  /// The scanner role (or an office admin) may check and admit passes in the app.
  bool get canScan =>
      roles.any((r) => const {'scanner', 'admin', 'superAdmin'}.contains(r));

  /// Events that can be scanned for now.
  Future<List<Map<String, dynamic>>> getScanEvents() async {
    final d = await _send('GET', '/staff/events');
    return ((d['events'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  /// Checks a pass (a scanned [token] or a typed [reference]); with [confirm] it lets the member in.
  Future<Map<String, dynamic>> scanPass(
    String eventId, {
    String? token,
    String? reference,
    bool confirm = false,
  }) => _send(
    'POST',
    '/staff/events/$eventId/scan',
    json: {
      'token': ?token,
      'reference': ?reference,
      if (confirm) 'confirm': true,
      'deviceRef': ?deviceId,
    },
  );

  Future<Map<String, dynamic>> scanCounts(String eventId) =>
      _send('GET', '/staff/events/$eventId/attendance');

  // ── Noahgram ─────────────────────────────────────────────────────────

  /// A post's picture or video, or a member's profile photo, as other members may see it.
  String mediaUrl(String fileId) => '$kApiBase/noahgram/media/$fileId';

  /// A page of posts or reels (`kind`: `posts`, `reels`, or `all` for one member's own page), newest first.
  Future<Map<String, dynamic>> ngFeed({
    String kind = 'posts',
    String? before,
    String? author,
  }) => _send(
    'GET',
    '/noahgram/feed?kind=$kind${before == null ? '' : '&before=$before'}${author == null ? '' : '&author=$author'}',
  );

  Future<Map<String, dynamic>> ngExplore(String query) => _send(
    'GET',
    '/noahgram/explore${query.isEmpty ? '' : '?q=${Uri.encodeQueryComponent(query)}'}',
  );

  /// Members whose name matches [query].
  Future<Map<String, dynamic>> ngPeople(String query) =>
      _send('GET', '/noahgram/people?q=${Uri.encodeQueryComponent(query)}');

  /// The members who follow [id] (`kind` = followers) or whom [id] follows (`kind` = following).
  Future<Map<String, dynamic>> ngConnections(String id, String kind) =>
      _send('GET', '/noahgram/members/$id/$kind');

  Future<Map<String, dynamic>> ngSaved() => _send('GET', '/noahgram/saved');

  Future<Map<String, dynamic>> ngPost(String id) =>
      _send('GET', '/noahgram/posts/$id');

  /// Makes a post from files already uploaded with purpose `post` (a picture) or `reel` (a video).
  Future<Map<String, dynamic>> ngCreate({
    String caption = '',
    String? photoFileId,
    String? videoFileId,
    String? thumbnailFileId,
  }) => _send(
    'POST',
    '/noahgram/posts',
    json: {
      'caption': caption,
      'photoFileId': ?photoFileId,
      'videoFileId': ?videoFileId,
      'thumbnailFileId': ?thumbnailFileId,
    },
    timeout: const Duration(seconds: 40),
  );

  Future<Map<String, dynamic>> ngRemove(String id) =>
      _send('DELETE', '/noahgram/posts/$id');

  Future<Map<String, dynamic>> ngLike(String id, bool liked) =>
      _send('POST', '/noahgram/posts/$id/like', json: {'liked': liked});

  Future<Map<String, dynamic>> ngView(String id) =>
      _send('POST', '/noahgram/posts/$id/view', json: {});

  Future<Map<String, dynamic>> ngSave(String id, bool saved) =>
      _send('POST', '/noahgram/posts/$id/save', json: {'saved': saved});

  Future<Map<String, dynamic>> ngComments(String id) =>
      _send('GET', '/noahgram/posts/$id/comments');

  Future<Map<String, dynamic>> ngAddComment(
    String id,
    String text, {
    String? parentId,
  }) => _send(
    'POST',
    '/noahgram/posts/$id/comments',
    json: {'text': text, 'parentId': ?parentId},
  );

  Future<Map<String, dynamic>> ngLikeComment(String id, String commentId, bool liked) =>
      _send('POST', '/noahgram/posts/$id/comments/$commentId/like', json: {'liked': liked});

  Future<Map<String, dynamic>> ngReportComment(String id, String commentId) =>
      _send('POST', '/noahgram/posts/$id/comments/$commentId/report', json: {});

  Future<Map<String, dynamic>> ngRemoveComment(String id, String commentId) =>
      _send('DELETE', '/noahgram/posts/$id/comments/$commentId');

  /// A member's Noahgram page; `me` is the signed-in member.
  Future<Map<String, dynamic>> ngProfile(String id) =>
      _send('GET', '/noahgram/members/$id');

  Future<Map<String, dynamic>> ngFollow(String id, bool following) => _send(
    'POST',
    '/noahgram/members/$id/follow',
    json: {'following': following},
  );

  // ── Events and entry passes ──────────────────────────────────────────

  /// Events the office published for this member, each with its status, seats and this member's own booking.
  Future<List<Map<String, dynamic>>> getEvents() async {
    final d = await _send('GET', '/events');
    return ((d['events'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  /// Books an event: one pass with a QR code (asking again returns the same pass).
  Future<Map<String, dynamic>> bookEvent(String eventId) =>
      _send('POST', '/events/$eventId/book', json: const {});

  Future<List<Map<String, dynamic>>> getPasses() async {
    final d = await _send('GET', '/passes');
    return ((d['passes'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> cancelPass(String passId) =>
      _send('POST', '/passes/$passId/cancel', json: const {});

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
  Future<Map<String, dynamic>> content(
    String kind,
    int lang, {
    int limit = 30,
  }) => _send('GET', '/content/$kind?lang=$lang&limit=$limit');

  /// Counts a view of a Daily Manna (the server batches the writes).
  Future<Map<String, dynamic>> viewManna(String id) =>
      _send('POST', '/content/manna/$id/view', json: {});

  /// Sets whether the member likes the Manna: `{ liked, likes }`.
  Future<Map<String, dynamic>> likeManna(String id, bool liked) =>
      _send('POST', '/content/manna/$id/like', json: {'liked': liked});

  /// `{ liked, items: [{ id, author: {id, name}, text, createdAt, mine }] }`, newest first.
  Future<Map<String, dynamic>> mannaComments(String id) =>
      _send('GET', '/content/manna/$id/comments');

  Future<Map<String, dynamic>> addMannaComment(
    String id,
    String text, {
    String? parentId,
  }) => _send(
    'POST',
    '/content/manna/$id/comments',
    json: {'text': text, 'parentId': ?parentId},
  );

  Future<Map<String, dynamic>> likeMannaComment(
    String id,
    String commentId,
    bool liked,
  ) => _send(
    'POST',
    '/content/manna/$id/comments/${Uri.encodeComponent(commentId)}/like',
    json: {'liked': liked},
  );

  Future<Map<String, dynamic>> reportMannaComment(String id, String commentId) =>
      _send(
        'POST',
        '/content/manna/$id/comments/${Uri.encodeComponent(commentId)}/report',
        json: {},
      );

  Future<void> deleteMannaComment(String id, String commentId) => _send(
    'DELETE',
    '/content/manna/$id/comments/${Uri.encodeComponent(commentId)}',
  );

  // ── Bible study ────────────────────────────────────────────────────────

  /// `{ items: [plan] }`: the plans that are live, with the member's progress in each.
  Future<Map<String, dynamic>> biblePlans(int lang) =>
      _send('GET', '/bible-study/plans?lang=$lang');

  /// `{ plan, steps, progress }`.
  Future<Map<String, dynamic>> biblePlan(String id) =>
      _send('GET', '/bible-study/plans/$id');

  /// `{ id, name, description, passages: [{ book, chapter, verses: [{ n, text }] }], quiz }`.
  Future<Map<String, dynamic>> bibleStep(String id) =>
      _send('GET', '/bible-study/steps/$id');

  /// Marks a step as read: `{ progress }`. Fails with `come_back_tomorrow` on a one-step-a-day plan.
  Future<Map<String, dynamic>> bibleComplete(String stepId) =>
      _send('POST', '/bible-study/steps/$stepId/complete', json: {});

  Future<Map<String, dynamic>> bibleRestart(String planId) =>
      _send('POST', '/bible-study/plans/$planId/restart', json: {});

  // ── Prayer requests ───────────────────────────────────────────────────

  /// Sends a prayer request to the office's prayer inbox. [category] is `healing`, `family`, `guidance`,
  /// `thanks` or `other`; [everyone] true means the open prayer wall, false the prayer warriors only.
  Future<Map<String, dynamic>> createPrayerRequest({
    required String category,
    required String text,
    required bool anonymous,
    required bool everyone,
    String? mannaTitle,
  }) => _send(
    'POST',
    '/prayer-requests',
    json: {
      'category': category,
      'text': text.trim(),
      'anonymous': anonymous,
      'everyone': everyone,
      'mannaTitle': ?mannaTitle,
    },
  );

  // ── Family ──────────────────────────────────────────────────────────

  /// `{ family: [{kind: member|kid, name, relation, ...}], requests: [{id, relation, name, state, ...}] }`.
  Future<Map<String, dynamic>> family() => _send('GET', '/family');

  /// Asks the office to add someone to the family: `{ id, state: Pending, kid }`. A child under 18 needs
  /// [dateOfBirth] (YYYY-MM-DD) and no number; a grown-up needs [mobileNumber], to link their account.
  Future<Map<String, dynamic>> createFamilyRequest({
    required String relation,
    required String firstName,
    String lastName = '',
    String? dateOfBirth,
    String? countryCode,
    String? mobileNumber,
    String? gender,
    String? note,
  }) => _send(
    'POST',
    '/family/requests',
    json: {
      'relation': relation,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'dateOfBirth': ?dateOfBirth,
      'countryCode': ?countryCode,
      'mobileNumber': ?mobileNumber,
      'gender': ?gender,
      'note': ?note,
    },
  );

  Future<Map<String, dynamic>> cancelFamilyRequest(String id) =>
      _send('DELETE', '/family/requests/$id');

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
