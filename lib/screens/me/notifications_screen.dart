import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/ministry_data.dart';
import '../../data/notifications_data.dart';
import '../../data/open_target.dart';
import '../../data/pastor_data.dart';
import '../../data/me_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import 'sub_page.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (liveApi) return const _LiveNotifications();
    final items = [
      (
        Icons.confirmation_number_outlined,
        tr(context, 'nf_pass', args: {'event': tr(context, 'ev_sunday2')}),
        tr(context, 'manna_days_ago', args: {'n': '2'}),
      ),
      (
        Icons.description_outlined,
        tr(
          context,
          'nf_receipt',
          args: {'no': 'KS/26-27/04412', 'amount': rupees(1100)},
        ),
        tr(context, 'manna_days_ago', args: {'n': '15'}),
      ),
      (
        Icons.group_outlined,
        tr(
          context,
          'nf_added',
          args: {'name': ministry.leader.name, 'n': ministry.record.cell},
        ),
        tr(context, 'nf_weeks', args: {'n': '3'}),
      ),
    ];
    return SubPage(
      title: tr(context, 'me_notifications'),
      children: [
        WhiteCard(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Column(
            children: [
              const _CaughtUpArt(),
              const SizedBox(height: 14),
              Text(
                tr(context, 'nf_caught'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(context, 'nf_caught_sub'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionTitle(title: tr(context, 'nf_earlier')),
        const SizedBox(height: 12),
        WhiteCard(
          child: Column(
            children: [
              for (final (i, n) in items.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.tint,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(n.$1, color: AppColors.ink, size: 21),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.$2,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              n.$3,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Small illustration for the empty state: a bell on a mint disc with leaves.
class _CaughtUpArt extends StatelessWidget {
  const _CaughtUpArt();

  static const _mint = Color(0xFFE3F5EE);
  static const _teal = Color(0xFF2BB68F);
  static const _orange = Color(0xFFFF7A59);

  Widget _leaf(double angle, Alignment at, Color color) => Align(
    alignment: at,
    child: Transform.rotate(
      angle: angle,
      child: Container(
        width: 20,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
        ),
      ),
    ),
  );

  Widget _person(Alignment at) => Align(
    alignment: at,
    child: Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
      child: const Icon(Icons.person_outline, color: Colors.white, size: 19),
    ),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 230,
    height: 170,
    child: Stack(
      children: [
        Align(
          child: Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              color: _mint,
              shape: BoxShape.circle,
            ),
          ),
        ),
        _leaf(
          -math.pi / 5,
          const Alignment(-0.78, -0.1),
          const Color(0xFF8AD9BF),
        ),
        _leaf(math.pi / 4, const Alignment(0.82, 0.05), _teal),
        _leaf(
          math.pi / 6,
          const Alignment(0.55, -0.75),
          const Color(0xFF8AD9BF),
        ),
        _person(const Alignment(-0.7, -0.75)),
        _person(const Alignment(0.72, 0.62)),
        const Align(
          alignment: Alignment(0, -0.1),
          child: Icon(Icons.notifications, color: _teal, size: 78),
        ),
        Align(
          alignment: const Alignment(0, 0.72),
          child: Container(
            width: 70,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFBFE8D9),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Live mode: the member's real notifications from the server.
class _LiveNotifications extends StatefulWidget {
  const _LiveNotifications();

  @override
  State<_LiveNotifications> createState() => _LiveNotificationsState();
}

class _LiveNotificationsState extends State<_LiveNotifications> {
  @override
  void initState() {
    super.initState();
    notificationsState.load();
    if (api.isStaff) {
      pastorInbox.load();
    } else {
      ministry.refreshContacts();
    }
  }

  @override
  void dispose() {
    // Leaving the page counts as having seen them.
    notificationsState.markAllRead();
    super.dispose();
  }

  IconData _icon(String type) {
    if (type.startsWith('chat')) return Icons.chat_bubble_outline;
    if (type.startsWith('registration')) return Icons.verified_user_outlined;
    return Icons.notifications_none;
  }

  String _when(DateTime? d) {
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  /// Unread chats first (messages are not stored as notifications), then the notification list.
  List<_Entry> _entries() {
    final out = <_Entry>[];
    if (api.isStaff) {
      for (final t in pastorInbox.threads.where((t) => t.unread > 0)) {
        out.add(
          _Entry(
            icon: Icons.chat_bubble_outline,
            title: t.memberName,
            body: t.lastMessage ?? '',
            when: _when(t.lastAt),
            unread: true,
            target: OpenTarget(type: 'chat_message', threadId: t.id, kind: t.kind),
          ),
        );
      }
    } else {
      for (final c in ministry.contacts.where((c) => c.unread > 0)) {
        out.add(
          _Entry(
            icon: Icons.chat_bubble_outline,
            title: c.name,
            body: c.last?.text ?? '',
            when: _when(c.last?.at),
            unread: true,
            target: OpenTarget(type: 'chat_message', kind: c.kind),
          ),
        );
      }
    }
    for (final n in notificationsState.items) {
      // Old chat rows (from before messages were push-only) still open the chat.
      out.add(
        _Entry(
          icon: _icon(n.type),
          title: n.title,
          body: n.body,
          when: _when(n.at),
          unread: !n.isRead,
          target: OpenTarget.fromData({...n.data, 'type': n.type}),
        ),
      );
    }
    return out;
  }

  void _open(OpenTarget target) {
    Navigator.of(context).pop();
    openRequest.value = target;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([notificationsState, ministry, pastorInbox]),
      builder: (context, _) {
        final items = _entries();
        return SubPage(
          title: tr(context, 'me_notifications'),
          children: [
            if (items.isEmpty)
              WhiteCard(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                child: Column(
                  children: [
                    const _CaughtUpArt(),
                    const SizedBox(height: 14),
                    Text(
                      tr(context, 'nf_caught'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(context, 'nf_caught_sub'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              WhiteCard(
                child: Column(
                  children: [
                    for (final (i, n) in items.indexed) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.border),
                      InkWell(
                        onTap: () => _open(n.target),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.tint,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  n.icon,
                                  color: AppColors.ink,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: n.unread
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      n.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      n.when,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (n.unread)
                                Container(
                                  margin: const EdgeInsets.only(top: 6, left: 8),
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE5334B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.muted,
                                size: 20,
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
        );
      },
    );
  }
}

class _Entry {
  const _Entry({
    required this.icon,
    required this.title,
    required this.body,
    required this.when,
    required this.unread,
    required this.target,
  });

  final IconData icon;
  final String title;
  final String body;
  final String when;
  final bool unread;
  final OpenTarget target;
}
