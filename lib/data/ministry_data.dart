import 'dart:async';

import 'package:flutter/material.dart';

import 'adaptive_poll.dart';
import 'api_client.dart';
import 'jodie_data.dart' show ChatMessage, Receipt;

/// Demo data for the Me tab: the member's pastor, cell leader and the church
/// office, plus the record shown under "Your record". Replace with the API.

class MinistryContact {
  MinistryContact({
    required this.id,
    required this.name,
    required this.roleKey,
    required this.colors,
    List<ChatMessage>? messages,
    this.unread = 0,
    this.contactId,
    this.isMine = false,
  }) : messages = messages ?? [];

  /// The server's `activity` token from the last read of this chat (see api_client `since`).
  String? activityToken;

  /// True once the conversation has been read in full (even if it turned out to be empty).
  bool loaded = false;

  /// `pastor`, `leader`, `office`; live pastors are `pastor:<member id>`.
  final String id;
  String name;

  /// Live mode: the member id of the person on the other end (pastors), and
  /// whether this is the member's own pastor.
  final String? contactId;
  bool isMine;

  /// `pastor`, `leader` or `office`.
  String get kind => id.split(':').first;

  /// False when nobody is on duty to answer this kind of chat (live mode).
  bool available = true;

  /// Id of the newest message loaded from the server (live mode).
  String? lastServerId;

  /// How far the other person has got, as message ids (for the ticks).
  String? deliveredUpTo;
  String? readUpTo;

  /// Translation key of the role line, e.g. `ch_pastor_role`.
  final String roleKey;
  final List<Color> colors;
  final List<ChatMessage> messages;
  int unread;

  String get initials => name
      .replaceAll('Ps. ', '')
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  ChatMessage? get last => messages.isEmpty ? null : messages.last;
}

class MemberRecord {
  const MemberRecord({
    this.memberSince = 2014,
    this.place = 'Dadar',
    this.cell = '12',
    this.cellArea = 'Dadar East',
    this.familyLinked = 4,
  });

  final int memberSince;
  final String place;
  final String cell;
  final String cellArea;
  final int familyLinked;
}

class MinistryState extends ChangeNotifier {
  MinistryState() {
    _seed();
  }

  final record = const MemberRecord();
  late final MinistryContact pastor;
  late final MinistryContact leader;
  late final MinistryContact office;

  /// Live mode: the real pastors from the office, the member's own first.
  final _livePastors = <MinistryContact>[];

  bool get _live => liveApi && api.signedIn;

  List<MinistryContact> get contacts => _live
      ? [
          ..._livePastors,
          if (leader.available) leader,
          if (office.available) office,
        ]
      : [pastor, leader, office];

  /// The member's own pastor: the demo one, or the one the office linked.
  MinistryContact? get myPastor {
    if (!_live) return pastor;
    for (final p in _livePastors) {
      if (p.isMine) return p;
    }
    return null;
  }

  int get unreadTotal => contacts.fold(0, (sum, c) => sum + c.unread);

  void _seed() {
    final now = DateTime.now();
    DateTime at(int daysAgo, int h, int m) {
      final d = now.subtract(Duration(days: daysAgo));
      return DateTime(d.year, d.month, d.day, h, m);
    }

    pastor = MinistryContact(
      id: 'pastor',
      name: 'Ps. Emmanuel Kumar',
      roleKey: 'ch_pastor_role',
      colors: const [Color(0xFF3F3C9E), Color(0xFF7C6BD6)],
      unread: 2,
      messages: [
        ChatMessage(
          'Pastor, please pray for Hannah. Her exams begin on Monday.',
          mine: true,
          at: at(0, 8, 52),
        ),
        ChatMessage(
          'We will pray for Hannah\'s exams.',
          mine: false,
          at: at(0, 9, 18),
        ),
        ChatMessage(
          'Bring her on Sunday, we will pray over her after the second service.',
          mine: false,
          at: at(0, 9, 20),
        ),
      ],
    );
    leader = MinistryContact(
      id: 'leader',
      name: 'Blessy Mathew',
      roleKey: 'ch_leader_role',
      colors: const [Color(0xFFA0267F), Color(0xFFE07AB0)],
      messages: [
        ChatMessage(
          'Cell 12 meets this Wednesday at 7:30 pm at my home.',
          mine: false,
          at: at(1, 18, 5),
        ),
        ChatMessage(
          'I will be there. Thank you!',
          mine: true,
          at: at(1, 18, 20),
        ),
      ],
    );
    office = MinistryContact(
      id: 'office',
      name: 'Church office',
      roleKey: 'ch_office_role',
      colors: const [Color(0xFF1F7A6B), Color(0xFF58C0A5)],
      messages: [
        ChatMessage(
          'Your Aadhaar verification is pending. Please upload the consent form.',
          mine: false,
          at: at(2, 11, 40),
        ),
      ],
    );
  }

  // ── Live mode (the real API) ───────────────────────────────────────────

  AdaptivePoll? _poll;

  /// Oldest first: server ids are the time the message was saved. Unsent ones (no id) stay last.
  static int _byId(ChatMessage a, ChatMessage b) {
    final x = a.id == null ? null : BigInt.tryParse(a.id!);
    final y = b.id == null ? null : BigInt.tryParse(b.id!);
    if (x == null || y == null) return x == null ? (y == null ? 0 : 1) : -1;
    return x.compareTo(y);
  }

  static ChatMessage _fromServer(Map<String, dynamic> m) => ChatMessage(
    '${m['text']}',
    mine: m['fromMe'] == true,
    at: DateTime.tryParse('${m['createdAt']}')?.toLocal(),
    id: '${m['id']}',
    receipt: m['fromMe'] == true ? Receipt.sent : Receipt.none,
  );

  /// Updates the ticks of my messages. Returns true if any changed.
  bool _applyReceipts(MinistryContact c) {
    var changed = false;
    for (final m in c.messages) {
      if (!m.mine || m.id == null) continue;
      final r = ChatMessage.receiptFor(m.id, c.deliveredUpTo, c.readUpTo);
      if (m.receipt != r) {
        m.receipt = r;
        changed = true;
      }
    }
    return changed;
  }

  /// Drops the demo conversations: the server holds the real ones.
  void resetForLive() {
    _livePastors.clear();
    _contactsToken = null;
    _started = false;
    for (final c in [pastor, leader, office]) {
      c.activityToken = null;
      c.loaded = false;
      c.messages.clear();
      c.unread = 0;
      c.lastServerId = null;
    }
    // Until the server says who they are, show nobody (not the demo people).
    leader
      ..name = 'Cell leader'
      ..available = false;
    office
      ..name = 'Church office'
      ..available = false;
    notifyListeners();
  }

  static const _palette = [
    [Color(0xFF3F3C9E), Color(0xFF7C6BD6)],
    [Color(0xFFA0267F), Color(0xFFE07AB0)],
    [Color(0xFF1F7A6B), Color(0xFF58C0A5)],
    [Color(0xFF9A5B13), Color(0xFFE0A458)],
  ];

  String? _contactsToken;
  bool _started = false;

  /// True when people have written to this member as their cell leader or pastor: they answer from the
  /// inbox (the same page a pastor uses). Told by the server with the contacts.
  bool hasInbox = false;

  /// Called the first time the inbox is found, so it can start loading.
  VoidCallback? onInboxFound;

  /// Loads the chats list once and keeps it fresh. Called when the Me tab is first shown.
  void ensureLoaded() {
    if (_started || !liveApi || !api.signedIn || api.isPastor) return;
    _started = true;
    refreshContacts();
    startPolling();
  }

  /// Names, unread counts and the latest line of each chat. In live mode this
  /// is also where the list of real pastors comes from.
  /// Returns true when something in the list changed.
  Future<bool> refreshContacts() async {
    if (!liveApi || !api.signedIn) return false;
    String signature() => contacts
        .map((c) => '${c.id}|${c.unread}|${c.messages.isEmpty ? '' : c.messages.last.text}')
        .join(';');
    try {
      final before = signature();
      final d = await api.chatContacts(since: _contactsToken);
      _contactsToken = d['activity'] as String? ?? _contactsToken;
      // Nothing changed on the server: no need to look further.
      if (d['unchanged'] == true) return false;
      final raw = ((d['contacts'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();

      void apply(MinistryContact c, Map<String, dynamic> m) {
        if (m['name'] != null) c.name = '${m['name']}';
        c.available = m['available'] == true;
        c.isMine = m['isMine'] == true;
        c.unread = (m['unread'] as num?)?.toInt() ?? 0;
        // Until the chat is opened, show the latest line in the list.
        if (c.lastServerId == null && m['lastMessage'] != null) {
          c.messages
            ..clear()
            ..add(
              ChatMessage(
                '${m['lastMessage']}',
                mine: false,
                at: DateTime.tryParse('${m['lastMessageAt']}')?.toLocal(),
              ),
            );
        }
      }

      final pastors = <MinistryContact>[];
      for (final m in raw) {
        switch ('${m['kind']}') {
          case 'pastor':
            final cid = '${m['contactId']}';
            final c = _livePastors.firstWhere(
              (p) => p.contactId == cid,
              orElse: () => MinistryContact(
                id: 'pastor:$cid',
                name: '${m['name']}',
                roleKey: 'ch_pastor_role',
                colors: _palette[cid.hashCode.abs() % _palette.length],
                contactId: cid,
              ),
            );
            apply(c, m);
            pastors.add(c);
          case 'leader':
            apply(leader, m);
          case 'office':
            apply(office, m);
        }
      }
      _livePastors
        ..clear()
        ..addAll(pastors);
      final found = d['hasInbox'] == true;
      final first = found && !hasInbox;
      hasInbox = found;
      notifyListeners();
      if (first) onInboxFound?.call();
      return signature() != before;
    } on ApiException {
      // Offline: keep what is on screen.
      return false;
    }
  }

  /// Loads the conversation. The first call loads it all, later calls only
  /// what is new. Reading marks it read on the server.
  /// Returns true when something new came in (a message or a tick).
  Future<bool> loadMessages(MinistryContact c) async {
    if (!liveApi || !api.signedIn) return false;
    try {
      final first = !c.loaded;
      final d = await api.chatMessages(
        c.kind,
        contactId: c.contactId,
        after: c.lastServerId,
        since: first ? null : c.activityToken,
      );
      c.activityToken = d['activity'] as String? ?? c.activityToken;
      // Nothing changed on the server since the last look.
      if (d['unchanged'] == true) return false;
      c.loaded = true;
      final list = ((d['messages'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();
      if (first) c.messages.clear();
      for (final m in list.map(_fromServer)) {
        if (!c.messages.any((x) => x.id == m.id)) c.messages.add(m);
      }
      c.messages.sort(_byId);
      if (list.isNotEmpty) c.lastServerId = '${list.last['id']}';
      final receipts = d['receipts'] as Map<String, dynamic>?;
      c.deliveredUpTo = receipts?['deliveredUpTo'] as String?;
      c.readUpTo = receipts?['readUpTo'] as String?;
      final ticked = _applyReceipts(c);
      final unreadChanged = c.unread != 0;
      c.unread = 0;
      // Nothing new and no tick changed: leave the screen alone.
      if (list.isEmpty && !first && !ticked && !unreadChanged) return false;
      notifyListeners();
      return list.isNotEmpty || ticked;
    } on ApiException {
      // The next poll tries again.
      return false;
    }
  }

  /// Sends a message. Throws [ApiException] if the server refuses it.
  Future<void> sendLive(MinistryContact c, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final pending = ChatMessage(t, mine: true, receipt: Receipt.sending);
    c.messages.add(pending);
    notifyListeners();
    Map<String, dynamic> sent;
    try {
      sent = await api.chatSend(c.kind, t, contactId: c.contactId);
    } on ApiException {
      c.messages.remove(pending);
      notifyListeners();
      rethrow;
    }
    // The server's answer is the stored message: it replaces the local one without reading the whole
    // chat again (that costs database reads). The next poll brings the ticks and anything new.
    c.messages.remove(pending);
    final stored = _fromServer(sent);
    if (!c.messages.any((m) => m.id == stored.id)) c.messages.add(stored);
    notifyListeners();
  }

  void startPolling() {
    _poll?.stop();
    // The list changes rarely and a push tells the phone when it does, so it
    // is only double-checked every 5 minutes (every 15 once nothing is moving).
    _poll = AdaptivePoll(
      task: refreshContacts,
      fast: const Duration(seconds: 300),
      slow: const Duration(seconds: 900),
      backoffAfter: 2,
    )..start();
  }

  void stopPolling() {
    _poll?.stop();
    _poll = null;
  }

  void markRead(MinistryContact c) {
    if (c.unread != 0) {
      c.unread = 0;
      notifyListeners();
    }
  }

  void send(MinistryContact c, String text) {
    if (text.trim().isEmpty) return;
    c.messages.add(ChatMessage(text.trim(), mine: true));
    notifyListeners();
  }
}

final ministry = MinistryState();

/// Whether this person has an inbox to answer from: staff (pastor, admin) and any cell leader or pastor
/// whom members have written to.
bool get inboxEnabled => api.isStaff || ministry.hasInbox;
