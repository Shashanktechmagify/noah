import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

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

  final http.Client _client;
  String? accessToken;
  String? refreshToken;
  Future<bool>? _refreshing;

  bool get signedIn => accessToken != null;

  void clear() {
    accessToken = null;
    refreshToken = null;
  }

  /// Address of a stored file, and the header that lets the member read it.
  String fileUrl(String id) => '$kApiBase/files/$id';
  Map<String, String> get authHeaders => {
    // Not "Authorization": Catalyst's gateway intercepts that header.
    if (accessToken != null) 'X-Noah-Token': accessToken!,
  };

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
    return SignedIn(
      next: '${d['next']}',
      isNewMember: d['isNewMember'] == true,
      accessToken: accessToken ?? '',
      refreshToken: refreshToken ?? '',
    );
  }

  Future<void> logout() async {
    final token = refreshToken;
    clear();
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
