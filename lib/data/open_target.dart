import 'package:flutter/foundation.dart';

/// A page the app should open because of a notification: a tapped push banner, or a tapped
/// row in the notification list. The main shell watches [openRequest] and does the navigating.
class OpenTarget {
  OpenTarget({
    required this.type,
    this.threadId,
    this.kind,
    this.postId,
    this.memberId,
  });

  /// `chat_message`, `chat_reply`, `registration_approved`, ...
  final String type;

  /// Chat pushes: the thread, and which chat it is (`pastor`, `leader`, `office`).
  final String? threadId;
  final String? kind;

  /// Noahgram pushes (a like, a comment, a reply, a follow, an approval) and shared links: the post, or the member.
  final String? postId;
  final String? memberId;

  bool get isChat => type.startsWith('chat');
  bool get isNoahgram => type.startsWith('noahgram');

  factory OpenTarget.fromData(Map<String, dynamic> d) => OpenTarget(
    type: '${d['type'] ?? ''}',
    threadId: d['threadId'] == null ? null : '${d['threadId']}',
    kind: d['kind'] == null ? null : '${d['kind']}',
    postId: d['postId'] == null ? null : '${d['postId']}',
    memberId: d['memberId'] == null ? null : '${d['memberId']}',
  );
}

/// Bumped whenever a chat push arrives, so an open chat screen can look for the new message now.
final pushTick = ValueNotifier<int>(0);

/// Set a new [OpenTarget] to ask the shell to open it. Cleared by the shell once handled
/// (a push that launched the app is waiting here until the shell exists).
final openRequest = ValueNotifier<OpenTarget?>(null);
