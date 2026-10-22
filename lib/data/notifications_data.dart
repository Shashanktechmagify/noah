import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// One entry in Me > Notifications (live mode).
class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.at,
    this.data = const {},
  });

  final String id;

  /// Extra details the server attached (thread id, kind, ...), used to open the right page.
  final Map<String, dynamic> data;

  /// `chat_reply`, `registration_approved`, ...
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? at;
}

class NotificationsState extends ChangeNotifier {
  List<AppNotification> items = [];
  int unread = 0;

  Future<void> load() async {
    if (!liveApi || !api.signedIn) return;
    try {
      apply(await api.notifications());
    } on ApiException {
      // Offline: keep what is on screen.
    }
  }

  /// Takes the server's `{ unread, notifications }` answer (from its own call, or from sign-in).
  void apply(Map<String, dynamic> d) {
    unread = (d['unread'] as num?)?.toInt() ?? 0;
    items = ((d['notifications'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (m) => AppNotification(
            id: '${m['id']}',
            type: '${m['type']}',
            title: '${m['title']}',
            body: '${m['body']}',
            isRead: m['isRead'] == true,
            at: DateTime.tryParse('${m['createdAt']}')?.toLocal(),
            data: (m['data'] is Map)
                ? Map<String, dynamic>.from(m['data'] as Map)
                : const {},
          ),
        )
        .toList();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (unread == 0 || !liveApi || !api.signedIn) return;
    try {
      await api.markNotificationsRead();
      unread = 0;
      notifyListeners();
    } on ApiException {
      // Stays unread; the next visit tries again.
    }
  }

  void clear() {
    items = [];
    unread = 0;
    notifyListeners();
  }
}

final notificationsState = NotificationsState();
