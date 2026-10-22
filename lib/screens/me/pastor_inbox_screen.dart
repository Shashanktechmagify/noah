import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/adaptive_poll.dart';
import '../../data/api_client.dart';
import '../../data/open_target.dart';
import '../../data/jodie_data.dart' show ChatMessage, Receipt;
import '../../data/pastor_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/header_band.dart';
import '../../widgets/page_scaffold.dart';
import '../jodie/chat_screen.dart' show ChatBubble;

/// The pastor's inbox: every member who wrote to the pastor, newest first.
class PastorInboxScreen extends StatefulWidget {
  const PastorInboxScreen({super.key});

  @override
  State<PastorInboxScreen> createState() => _PastorInboxScreenState();
}

class _PastorInboxScreenState extends State<PastorInboxScreen> {
  @override
  void initState() {
    super.initState();
    pastorInbox.load();
  }

  String _kindLabel(String kind) => switch (kind) {
    'leader' => 'Cell leader chat',
    'office' => 'Church office chat',
    _ => 'Pastor chat',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: pastorInbox,
        builder: (context, _) => PageScaffold(
          title: tr(context, 'pastor_inbox'),
          subtitle: tr(context, 'pastor_inbox_sub'),
          leadingIcon: Icons.arrow_back,
          onLeading: () => Navigator.of(context).pop(),
          children: [
            if (pastorInbox.threads.isEmpty)
              WhiteCard(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr(context, 'pastor_inbox_empty'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
              )
            else
              WhiteCard(
                child: Column(
                  children: [
                    for (final (i, t) in pastorInbox.threads.indexed) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.border),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PastorChatScreen(thread: t),
                            ),
                          );
                          pastorInbox.load();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 23,
                                backgroundColor: AppColors.tint,
                                child: Text(
                                  t.initials,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.memberName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _kindLabel(t.kind),
                                      style: const TextStyle(
                                        color: AppColors.magenta,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      t.lastMessage ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: t.unread > 0
                                            ? AppColors.ink
                                            : AppColors.muted,
                                        fontWeight: t.unread > 0
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (t.unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.buttonGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${t.unread}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One member's conversation, from the pastor's side.
class PastorChatScreen extends StatefulWidget {
  const PastorChatScreen({super.key, required this.thread});

  final PastorThread thread;

  @override
  State<PastorChatScreen> createState() => _PastorChatScreenState();
}

class _PastorChatScreenState extends State<PastorChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <PastorMessage>[];
  AdaptivePoll? _poll;
  bool _sending = false;
  String? _lastId;
  String? _since;
  bool _loaded = false;
  String? _phone;
  String? _deliveredUpTo;
  String? _readUpTo;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _load();
    _poll = AdaptivePoll(
      task: _load,
      // A push asks for an immediate look (below), so this is only a safety net.
      fast: const Duration(seconds: 45),
      slow: const Duration(seconds: 180),
      backoffAfter: 2,
    )..start();
    pushTick.addListener(_onPush);
  }

  void _onPush() => _poll?.refreshNow();

  @override
  void dispose() {
    pushTick.removeListener(_onPush);
    _poll?.stop();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Returns true when something new came in.
  Future<bool> _load() async {
    try {
      final d = await api.pastorMessages(
        widget.thread.id,
        after: _lastId,
        since: _loaded ? _since : null,
      );
      _since = d['activity'] as String? ?? _since;
      // Nothing changed on the server since the last look.
      if (d['unchanged'] == true) return false;
      _loaded = true;
      final fresh = ((d['messages'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(PastorMessage.fromJson)
          .toList();
      final phone = (d['member'] as Map<String, dynamic>?)?['phone'] as String?;
      final receipts = d['receipts'] as Map<String, dynamic>?;
      final delivered = receipts?['deliveredUpTo'] as String?;
      final read = receipts?['readUpTo'] as String?;
      if (!mounted) return false;
      if (fresh.isEmpty &&
          phone == _phone &&
          delivered == _deliveredUpTo &&
          read == _readUpTo) {
        return false;
      }
      setState(() {
        _phone = phone;
        _deliveredUpTo = delivered;
        _readUpTo = read;
        for (final m in fresh) {
          if (!_messages.any((x) => x.id == m.id)) _messages.add(m);
        }
        _messages.sort((a, b) => (BigInt.tryParse(a.id) ?? BigInt.zero).compareTo(BigInt.tryParse(b.id) ?? BigInt.zero));
        if (fresh.isNotEmpty) _lastId = fresh.last.id;
      });
      if (fresh.isNotEmpty) _toBottom();
      return true;
    } on ApiException {
      // The next poll tries again.
      return false;
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      final sent = PastorMessage.fromJson(await api.pastorReply(widget.thread.id, text));
      // The stored copy comes back with the reply: no need to read the whole chat again.
      if (mounted && !_messages.any((m) => m.id == sent.id)) {
        setState(() => _messages.add(sent));
        _toBottom();
      }
      _poll?.nudge();
    } on ApiException catch (e) {
      if (!mounted) return;
      _controller.text = text;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final empty = _controller.text.trim().isEmpty;
    return Scaffold(
      body: Stack(
        children: [
          HeaderBand(controller: _scroll, height: 120),
          Column(
            children: [
              SizedBox(height: top + 14),
              PageHeaderRow(
                title: widget.thread.memberName,
                subtitle: _phone ?? '',
                leadingIcon: Icons.arrow_back,
                onLeading: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    for (final m in _messages)
                      ChatBubble(message: _asChat(m), theirColor: Colors.white),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  14,
                  10,
                  10,
                  10 + MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: AppColors.tint,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: tr(context, 'ch_write'),
                            hintStyle: const TextStyle(color: AppColors.muted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: empty ? null : AppColors.buttonGradient,
                          color: empty ? const Color(0xFFE2DDF1) : null,
                        ),
                        child: const Icon(
                          Icons.send_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ChatBubble draws the app's ChatMessage; the pastor's own messages are "mine".
  ChatMessage _asChat(PastorMessage m) => ChatMessage(
    m.text,
    mine: m.mine,
    at: m.at,
    id: m.id,
    receipt: m.mine
        ? ChatMessage.receiptFor(m.id, _deliveredUpTo, _readUpTo)
        : Receipt.none,
  );
}
