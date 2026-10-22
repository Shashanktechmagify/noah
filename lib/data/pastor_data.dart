import 'dart:async';

import 'package:flutter/foundation.dart';

import 'adaptive_poll.dart';
import 'api_client.dart';

/// One member's conversation in the pastor's inbox.
class PastorThread {
  PastorThread({
    required this.id,
    required this.kind,
    required this.memberName,
    this.lastMessage,
    this.lastAt,
    this.unread = 0,
  });

  final String id;

  /// `pastor`, `leader` or `office`: which chat the member used.
  final String kind;
  final String memberName;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;

  String get initials => memberName
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  factory PastorThread.fromJson(Map<String, dynamic> m) => PastorThread(
    id: '${m['threadId']}',
    kind: '${m['kind']}',
    memberName: '${m['memberName']}',
    lastMessage: m['lastMessage'] as String?,
    lastAt: DateTime.tryParse('${m['lastMessageAt']}')?.toLocal(),
    unread: (m['unread'] as num?)?.toInt() ?? 0,
  );
}

/// A message in a thread, as the pastor sees it.
class PastorMessage {
  PastorMessage(this.id, this.text, this.mine, this.at);

  final String id;
  final String text;
  final bool mine;
  final DateTime at;

  factory PastorMessage.fromJson(Map<String, dynamic> m) => PastorMessage(
    '${m['id']}',
    '${m['text']}',
    m['fromMe'] == true,
    DateTime.tryParse('${m['createdAt']}')?.toLocal() ?? DateTime.now(),
  );
}

/// The pastor's inbox (staff accounts only).
class PastorInboxState extends ChangeNotifier {
  List<PastorThread> threads = [];
  int totalUnread = 0;
  AdaptivePoll? _poll;
  String? _token;
  bool _started = false;

  /// Loads the inbox once and keeps it fresh (staff only). Called when the Me tab is first shown.
  void ensureLoaded() {
    if (_started || !liveApi || !api.signedIn || !api.isStaff) return;
    _started = true;
    load();
    startPolling();
  }

  /// Returns true when the list changed.
  Future<bool> load() async {
    if (!liveApi || !api.signedIn || !api.isStaff) return false;
    try {
      final before = '$totalUnread|${threads.map((t) => '${t.id}:${t.unread}:${t.lastMessage}').join(',')}';
      final d = await api.pastorThreads(since: _token);
      _token = d['activity'] as String? ?? _token;
      if (d['unchanged'] == true) return false;
      threads = ((d['threads'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(PastorThread.fromJson)
          .toList();
      totalUnread = (d['totalUnread'] as num?)?.toInt() ?? 0;
      notifyListeners();
      return before !=
          '$totalUnread|${threads.map((t) => '${t.id}:${t.unread}:${t.lastMessage}').join(',')}';
    } on ApiException {
      // Offline: keep what is on screen.
      return false;
    }
  }

  void startPolling() {
    _poll?.stop();
    _poll = AdaptivePoll(
      task: load,
      fast: const Duration(seconds: 300),
      slow: const Duration(seconds: 900),
      backoffAfter: 2,
    )..start();
  }

  void stop() {
    _poll?.stop();
    _poll = null;
    _token = null;
    _started = false;
    threads = [];
    totalUnread = 0;
    notifyListeners();
  }
}

final pastorInbox = PastorInboxState();
