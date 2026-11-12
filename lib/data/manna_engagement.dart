import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'manna_data.dart';

/// A comment a member wrote on a Daily Manna.
class MannaComment {
  MannaComment({
    required this.id,
    required this.author,
    required this.text,
    required this.at,
    required this.mine,
    this.parentId,
    this.likes = 0,
    this.likedByMe = false,
  });

  final String id;
  final String author;
  final String text;
  final DateTime at;

  /// True for the signed-in member's own comment (they can take it back).
  final bool mine;

  /// The first-level comment this one answers (null for a first-level comment).
  final String? parentId;
  int likes;
  bool likedByMe;

  factory MannaComment.fromJson(Map<String, dynamic> j) => MannaComment(
    id: '${j['id']}',
    author: '${(j['author'] as Map?)?['name'] ?? ''}',
    text: '${j['text'] ?? ''}',
    at: DateTime.tryParse('${j['createdAt']}')?.toLocal() ?? DateTime.now(),
    mine: j['mine'] == true,
    parentId: j['parentId'] == null ? null : '${j['parentId']}',
    likes: (j['likes'] as num?)?.toInt() ?? 0,
    likedByMe: j['likedByMe'] == true,
  );
}

/// Likes, views and comments of one Daily Manna. The counts start from the list the server sent; the
/// comments and "do I like it" are read when the Manna is opened.
class MannaEngagement extends ChangeNotifier {
  MannaEngagement(Manna manna)
    : id = manna.id,
      likes = manna.likes,
      views = manna.views,
      commentCount = manna.comments;

  final String id;
  int likes;
  int views;
  int commentCount;
  bool liked = false;
  bool loaded = false;
  bool posting = false;
  String? error;
  List<MannaComment> comments = [];
  bool _opened = false;

  static const _viewedKey = 'noah_viewed_manna';

  /// Takes the counts of a newer list from the server.
  void adopt(Manna m) {
    likes = m.likes;
    views = m.views;
    commentCount = m.comments;
    notifyListeners();
  }

  /// Called when the Manna page is opened: counts a view (once per member and Manna) and reads the comments.
  Future<void> open() async {
    if (!liveApi || !api.signedIn || _opened) return;
    _opened = true;
    // The view is counted first, so the numbers read next already include it.
    await _countView();
    await refresh();
  }

  Future<void> _countView() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getStringList(_viewedKey) ?? <String>[];
      if (seen.contains(id)) return;
      final d = await api.viewManna(id);
      await prefs.setStringList(_viewedKey, [
        ...seen.skip(seen.length > 400 ? 100 : 0),
        id,
      ]);
      views = (d['views'] as num?)?.toInt() ?? views + 1;
      notifyListeners();
    } catch (_) {
      // A view that could not be counted is tried again the next time the page is opened.
    }
  }

  Future<void> refresh() async {
    try {
      final d = await api.mannaComments(id);
      liked = d['liked'] == true;
      // The server's current numbers (the list this page came from may be old).
      likes = (d['likes'] as num?)?.toInt() ?? likes;
      views = (d['views'] as num?)?.toInt() ?? views;
      commentCount = (d['commentCount'] as num?)?.toInt() ?? commentCount;
      comments = ((d['items'] as List?) ?? const [])
          .map(
            (e) => MannaComment.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      loaded = true;
      error = null;
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  Future<void> toggleLike() async {
    if (!liveApi || !api.signedIn) return;
    final want = !liked;
    // Shown at once, and put back if the server says no.
    liked = want;
    likes = (likes + (want ? 1 : -1)).clamp(0, 1 << 30);
    notifyListeners();
    try {
      final d = await api.likeManna(id, want);
      liked = d['liked'] == true;
      likes = (d['likes'] as num?)?.toInt() ?? likes;
    } on ApiException {
      liked = !want;
      likes = (likes + (want ? -1 : 1)).clamp(0, 1 << 30);
    }
    notifyListeners();
  }

  /// Returns true when the comment was posted. With [parentId] it is a reply to that comment.
  Future<bool> post(String text, {String? parentId}) async {
    if (!liveApi || !api.signedIn || posting) return false;
    posting = true;
    error = null;
    notifyListeners();
    try {
      final c = MannaComment.fromJson(
        await api.addMannaComment(id, text, parentId: parentId),
      );
      comments = [c, ...comments];
      commentCount += 1;
      posting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      posting = false;
      notifyListeners();
      return false;
    }
  }

  /// Likes or unlikes a comment: shown at once, put back if the server says no.
  Future<void> toggleCommentLike(MannaComment c) async {
    if (!liveApi || !api.signedIn) return;
    final want = !c.likedByMe;
    c
      ..likedByMe = want
      ..likes = (c.likes + (want ? 1 : -1)).clamp(0, 1 << 30);
    notifyListeners();
    try {
      final d = await api.likeMannaComment(id, c.id, want);
      c
        ..likedByMe = d['liked'] == true
        ..likes = (d['likes'] as num?)?.toInt() ?? c.likes;
    } on ApiException catch (e) {
      c
        ..likedByMe = !want
        ..likes = (c.likes + (want ? -1 : 1)).clamp(0, 1 << 30);
      error = e.message;
    }
    notifyListeners();
  }

  /// Reports a comment to the office. It goes from this member's list at once. Returns true when it was sent.
  Future<bool> report(MannaComment c) async {
    try {
      await api.reportMannaComment(id, c.id);
      comments = comments.where((x) => x.id != c.id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> remove(MannaComment c) async {
    try {
      await api.deleteMannaComment(id, c.id);
      comments = comments.where((x) => x.id != c.id).toList();
      commentCount = (commentCount - 1).clamp(0, 1 << 30);
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }
}

final _byId = <String, MannaEngagement>{};

/// The one [MannaEngagement] for a Manna, so a like given on its page shows in the list too.
MannaEngagement engagementOf(Manna manna) =>
    _byId.putIfAbsent(manna.id, () => MannaEngagement(manna));

/// Called when the saved lists are replaced by newer ones: the server's counts win, except on pages that
/// already hold comments (their numbers are as fresh as the page).
void syncEngagement(Iterable<Manna> mannas) {
  for (final m in mannas) {
    final e = _byId[m.id];
    if (e == null) continue;
    if (!e.loaded) e.adopt(m);
  }
}
