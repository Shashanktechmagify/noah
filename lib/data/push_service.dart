import 'dart:convert';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'live_events.dart';
import 'ministry_data.dart';
import 'notifications_data.dart';
import 'open_target.dart';
import 'pastor_data.dart';
import 'registration_data.dart';

/// Push notifications through Firebase Cloud Messaging.
///
/// Needs `android/app/google-services.json` from the Firebase console. Without
/// it Firebase cannot start, this does nothing, and the app still works (chats
/// and notifications refresh while the app is open).
class PushService {
  bool _started = false;
  String? _deviceId;
  String? _token;

  /// A random id for this install, kept between launches.
  Future<String> _id() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('noah_device_id');
    if (id == null) {
      final r = Random.secure();
      id = List.generate(
        16,
        (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await prefs.setString('noah_device_id', id);
    }
    return _deviceId = id;
  }

  /// Call after sign-in. Safe to call more than once.
  Future<void> start() async {
    if (!liveApi || kIsWeb || !api.signedIn) return;
    api.deviceId = await _id();
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      // getToken is deprecated in favour of onRegistered, which gives an
      // installation id. The server sends with FCM v1 to the classic token,
      // so keep getToken until the new id is confirmed to work there.
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await _register(token);
      if (_started) return;
      _started = true;
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen(_register);
      // A push arrived while the app is open: refresh what it is about.
      await _initBanners();
      FirebaseMessaging.onMessage.listen((m) {
        _refresh(m.data);
        _banner(m);
      });
      // Tapped while the app was in the background, or the tap that launched it.
      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        _refresh(m.data);
        _open(m.data);
      });
      final launch = await messaging.getInitialMessage();
      if (launch != null) _open(launch.data);
    } catch (e) {
      // Firebase is not configured (no google-services.json) or permission was denied.
      debugPrint('Push not started: $e');
    }
  }

  Future<void> _register(String token) async {
    _token = token;
    if (!api.signedIn) return;
    // Registered with this token in the last 12 hours: the server already knows (each call is a read).
    final prefs = await SharedPreferences.getInstance();
    final mine = '${registration.phone}|$token';
    final seen = (prefs.getString('noah_push_reg') ?? '').split('@');
    final recent =
        seen.length == 2 &&
        seen[0] == mine &&
        DateTime.now().millisecondsSinceEpoch - (int.tryParse(seen[1]) ?? 0) <
            12 * 3600 * 1000;
    if (recent) return;
    try {
      await api.registerDevice(
        await _id(),
        token,
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      );
      await prefs.setString(
        'noah_push_reg',
        '$mine@${DateTime.now().millisecondsSinceEpoch}',
      );
    } on ApiException catch (e) {
      debugPrint('Could not register this phone for push: ${e.message}');
    }
  }

  final _banners = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'noah_default',
    'Noah',
    description: 'Messages and updates from Noah',
    importance: Importance.high,
  );

  /// Android shows no banner for a push that arrives while the app is open, so draw one.
  Future<void> _initBanners() async {
    await _banners.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      // A banner drawn by the app itself was tapped.
      onDidReceiveNotificationResponse: (r) {
        final payload = r.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _open(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        } catch (_) {}
      },
    );
    await _banners
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  void _banner(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return;
    _banners.show(
      id: m.hashCode,
      title: n.title,
      body: n.body,
      payload: jsonEncode(m.data),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void _open(Map<String, dynamic> data) {
    if (data['type'] == null) return;
    openRequest.value = OpenTarget.fromData(data);
  }

  /// A push arrived: refresh only what it is about (each look costs database reads).
  void _refresh(Map<String, dynamic> data) {
    if ('${data['type']}'.startsWith('chat')) {
      pushTick.value++; // an open chat looks for the new message
      // A staff account only has the inbox; anyone else has their own chats, and a cell leader an inbox too.
      if (api.isStaff) {
        pastorInbox.load();
      } else {
        ministry.refreshContacts();
        if (ministry.hasInbox) pastorInbox.load();
      }
    } else {
      notificationsState.load();
      // A new event, or being marked present: the Events tab shows it at once.
      if ('${data['type']}'.startsWith('event')) liveEvents.load();
    }
  }

  /// Call before signing out so this phone stops getting that member's pushes.
  Future<void> stop() async {
    if (_token == null || !api.signedIn) return;
    try {
      await api.unregisterDevice(await _id());
      (await SharedPreferences.getInstance()).remove('noah_push_reg');
    } on ApiException {
      // The server removes dead tokens itself.
    }
  }
}

final pushService = PushService();
