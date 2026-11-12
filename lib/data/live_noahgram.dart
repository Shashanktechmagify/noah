import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Noahgram for a member signed in to the server: real posts and reels, likes, comments, views and follows.
/// There is no chat in it. A person's name and picture are always their own (from their registration and
/// profile photo); the screens only talk to [liveNoahgram].

/// Whoever wrote a post or comment.
class NgAuthor {
  const NgAuthor({
    required this.id,
    required this.name,
    this.photoFileId,
    this.isChurch = false,
    this.followedByMe = false,
    this.isMe = false,
  });

  final String id;
  final String name;
  final String? photoFileId;

  /// A post the office wrote has no member: the church is its author (no page to open).
  final bool isChurch;

  /// In a followers or following list: whether the signed-in member follows this person, and whether it is them.
  final bool followedByMe;
  final bool isMe;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  String? get photoUrl =>
      photoFileId == null ? null : api.mediaUrl(photoFileId!);

  factory NgAuthor.fromJson(Map<String, dynamic> j) => NgAuthor(
    id: '${j['id']}',
    name: '${j['name'] ?? 'Member'}',
    photoFileId: j['photoFileId'] == null ? null : '${j['photoFileId']}',
    isChurch: j['isChurch'] == true,
    followedByMe: j['followedByMe'] == true,
    isMe: j['isMe'] == true,
  );
}

class NgPost {
  NgPost._(this.id);

  final String id;
  late NgAuthor author;
  String caption = '';
  bool isReel = false;
  String? mediaFileId;
  String? mediaLink;
  String? thumbFileId;
  String? thumbLink;
  DateTime? createdAt;
  int likes = 0;
  int comments = 0;
  int views = 0;
  bool liked = false;
  bool saved = false;
  bool mine = false;
  String shareUrl = '';

  /// A web address the office added to its post, and whether the office pinned it to the top.
  String? link;
  bool pinned = false;

  /// Where the picture or the video is.
  String? get mediaSrc =>
      mediaFileId != null ? api.mediaUrl(mediaFileId!) : mediaLink;

  /// A still picture for a video (or the picture itself).
  String? get stillSrc {
    if (thumbFileId != null) return api.mediaUrl(thumbFileId!);
    if (thumbLink != null) return thumbLink;
    return isReel ? null : mediaSrc;
  }

  void _read(Map<String, dynamic> j) {
    author = NgAuthor.fromJson((j['author'] as Map).cast<String, dynamic>());
    caption = '${j['caption'] ?? ''}';
    isReel = j['isReel'] == true;
    final media = j['media'] as Map<String, dynamic>?;
    mediaFileId = media?['fileId'] == null ? null : '${media!['fileId']}';
    mediaLink = media?['url'] == null ? null : '${media!['url']}';
    final thumb = j['thumbnail'] as Map<String, dynamic>?;
    thumbFileId = thumb?['fileId'] == null ? null : '${thumb!['fileId']}';
    thumbLink = thumb?['url'] == null ? null : '${thumb!['url']}';
    createdAt = DateTime.tryParse('${j['createdAt'] ?? ''}');
    likes = (j['likes'] as num?)?.toInt() ?? 0;
    comments = (j['comments'] as num?)?.toInt() ?? 0;
    views = (j['views'] as num?)?.toInt() ?? 0;
    liked = j['likedByMe'] == true;
    saved = j['savedByMe'] == true;
    mine = j['mine'] == true;
    shareUrl = '${j['shareUrl'] ?? ''}';
    link = j['link'] == null ? null : '${j['link']}';
    pinned = j['pinned'] == true;
  }

  /// Whole hours since it was posted.
  int get hours {
    final at = createdAt;
    if (at == null) return 0;
    final d = DateTime.now().difference(at).inHours;
    return d < 0 ? 0 : d;
  }

  /// A post as a test or another screen builds it.
  @visibleForTesting
  factory NgPost.fromJson(Map<String, dynamic> j) =>
      NgPost._('${j['id']}').._read(j);
}

class NgComment {
  NgComment({
    required this.id,
    required this.author,
    required this.text,
    this.parentId,
    this.createdAt,
    this.mine = false,
    this.canRemove = false,
  });

  final String id;
  final NgAuthor author;
  final String text;
  final String? parentId;
  final DateTime? createdAt;
  final bool mine;
  final bool canRemove;

  factory NgComment.fromJson(Map<String, dynamic> j) => NgComment(
    id: '${j['id']}',
    author: NgAuthor.fromJson((j['author'] as Map).cast<String, dynamic>()),
    text: '${j['text'] ?? ''}',
    parentId: j['parentId'] == null ? null : '${j['parentId']}',
    createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
    mine: j['mine'] == true,
    canRemove: j['canRemove'] == true,
  );
}

class NgProfile {
  NgProfile({
    required this.author,
    required this.posts,
    required this.followers,
    required this.following,
    required this.followedByMe,
    required this.isMe,
  });

  final NgAuthor author;
  int posts;
  int followers;
  int following;
  bool followedByMe;
  final bool isMe;

  factory NgProfile.fromJson(Map<String, dynamic> j) => NgProfile(
    author: NgAuthor.fromJson(j),
    posts: (j['posts'] as num?)?.toInt() ?? 0,
    followers: (j['followers'] as num?)?.toInt() ?? 0,
    following: (j['following'] as num?)?.toInt() ?? 0,
    followedByMe: j['followedByMe'] == true,
    isMe: j['isMe'] == true,
  );
}

/// A list of posts with the id to ask for the next page (null at the end).
class NgPage {
  NgPage(this.items, this.next);
  final List<NgPost> items;
  final String? next;
}

class LiveNoahgram extends ChangeNotifier {
  /// One object for each post, whichever list it shows in, so a like in the feed shows on the profile too.
  final _byId = <String, NgPost>{};
  final _viewed = <String>{};

  final posts = <NgPost>[];
  String? postsNext;
  bool postsLoading = false;
  bool postsLoaded = false;
  String? postsError;

  final reels = <NgPost>[];
  String? reelsNext;
  bool reelsLoading = false;
  bool reelsLoaded = false;
  String? reelsError;

  NgProfile? me;

  /// What went wrong the last time something the member did failed (shown once by the screen).
  String? lastError;

  NgPost canon(Map<String, dynamic> j) {
    final id = '${j['id']}';
    final post = _byId.putIfAbsent(id, () => NgPost._(id));
    post._read(j);
    return post;
  }

  NgPage _page(Map<String, dynamic> d) => NgPage(
    ((d['items'] as List?) ?? const [])
        .map((e) => canon((e as Map).cast<String, dynamic>()))
        .toList(),
    d['next'] == null ? null : '${d['next']}',
  );

  String _say(Object e) =>
      e is ApiException ? e.message : 'Something went wrong. Try again.';

  /// Forgets everything (sign-out).
  void clear() {
    _byId.clear();
    _viewed.clear();
    posts.clear();
    reels.clear();
    postsNext = reelsNext = null;
    postsLoaded = reelsLoaded = false;
    postsLoading = reelsLoading = false;
    postsError = reelsError = null;
    me = null;
    lastError = null;
    notifyListeners();
  }

  // ── Lists ──────────────────────────────────────────────────────────────

  Future<void> loadPosts({bool refresh = false}) async {
    if (postsLoading) return;
    postsLoading = true;
    postsError = null;
    notifyListeners();
    try {
      final page = _page(await api.ngFeed(kind: 'all'));
      posts
        ..clear()
        ..addAll(page.items);
      postsNext = page.next;
      postsLoaded = true;
    } catch (e) {
      postsError = _say(e);
    }
    postsLoading = false;
    notifyListeners();
  }

  Future<void> morePosts() async {
    if (postsLoading || postsNext == null) return;
    postsLoading = true;
    notifyListeners();
    try {
      final page = _page(await api.ngFeed(kind: 'all', before: postsNext));
      final have = posts.map((p) => p.id).toSet();
      posts.addAll(page.items.where((p) => !have.contains(p.id)));
      postsNext = page.next;
    } catch (e) {
      lastError = _say(e);
    }
    postsLoading = false;
    notifyListeners();
  }

  Future<void> loadReels() async {
    if (reelsLoading) return;
    reelsLoading = true;
    reelsError = null;
    notifyListeners();
    try {
      final page = _page(await api.ngFeed(kind: 'reels'));
      reels
        ..clear()
        ..addAll(page.items);
      reelsNext = page.next;
      reelsLoaded = true;
    } catch (e) {
      reelsError = _say(e);
    }
    reelsLoading = false;
    notifyListeners();
  }

  Future<void> moreReels() async {
    if (reelsLoading || reelsNext == null) return;
    reelsLoading = true;
    notifyListeners();
    try {
      final page = _page(await api.ngFeed(kind: 'reels', before: reelsNext));
      final have = reels.map((p) => p.id).toSet();
      reels.addAll(page.items.where((p) => !have.contains(p.id)));
      reelsNext = page.next;
    } catch (e) {
      lastError = _say(e);
    }
    reelsLoading = false;
    notifyListeners();
  }

  /// One member's pictures and reels, newest first (their page, and the Saved tab for yourself).
  Future<NgPage> postsOf(String memberId, {String? before}) async =>
      _page(await api.ngFeed(kind: 'all', author: memberId, before: before));

  /// Members whose name matches the words.
  Future<List<NgAuthor>> people(String query) async {
    if (query.trim().length < 2) return const [];
    final d = await api.ngPeople(query.trim());
    return ((d['items'] as List?) ?? const [])
        .map((e) => NgAuthor.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Who follows [memberId] (`followers`) or whom they follow (`following`).
  Future<List<NgAuthor>> connections(String memberId, String kind) async {
    final d = await api.ngConnections(memberId, kind);
    return ((d['items'] as List?) ?? const [])
        .map((e) => NgAuthor.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<NgPost>> saved() async => _page(await api.ngSaved()).items;

  /// What matches the words (or the latest posts when [query] is empty).
  Future<List<NgPost>> explore(String query) async =>
      _page(await api.ngExplore(query.trim())).items;

  /// A post from a link or a notification. Null when it is gone.
  Future<NgPost?> fetchPost(String id) async {
    try {
      return canon(await api.ngPost(id));
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  // ── Doing things ───────────────────────────────────────────────────────

  Future<void> toggleLike(NgPost post) async {
    final wanted = !post.liked;
    post
      ..liked = wanted
      ..likes = (post.likes + (wanted ? 1 : -1)).clamp(0, 1 << 31);
    notifyListeners();
    try {
      final d = await api.ngLike(post.id, wanted);
      post
        ..liked = d['liked'] == true
        ..likes = (d['likes'] as num?)?.toInt() ?? post.likes;
    } catch (e) {
      post
        ..liked = !wanted
        ..likes = (post.likes + (wanted ? -1 : 1)).clamp(0, 1 << 31);
      lastError = _say(e);
    }
    notifyListeners();
  }

  Future<void> toggleSave(NgPost post) async {
    final wanted = !post.saved;
    post.saved = wanted;
    notifyListeners();
    try {
      await api.ngSave(post.id, wanted);
    } catch (e) {
      post.saved = !wanted;
      lastError = _say(e);
    }
    notifyListeners();
  }

  /// Counts a view, once for each post while the app is open (the server counts once for each member).
  Future<void> markViewed(NgPost post) async {
    if (!_viewed.add(post.id)) return;
    try {
      final d = await api.ngView(post.id);
      if (d['counted'] == true) {
        post.views = (d['views'] as num?)?.toInt() ?? post.views + 1;
        notifyListeners();
      }
    } catch (_) {
      _viewed.remove(post.id); // try again the next time it is shown
    }
  }

  /// Uploads the picture, or the video and its still picture, then makes the post.
  /// Returns the post, and whether it is already live (the office may approve first).
  Future<({NgPost post, bool live})> create({
    required String caption,
    String? photoPath,
    String? videoPath,
    String? thumbnailPath,
  }) async {
    String? photoId;
    String? videoId;
    String? thumbId;
    if (videoPath != null) {
      videoId = (await api.uploadFile('reel', videoPath)).id;
      if (thumbnailPath != null) {
        try {
          thumbId = (await api.uploadFile('post', thumbnailPath)).id;
        } catch (_) {
          thumbId = null; // a reel without a still picture is fine
        }
      }
    } else {
      photoId = (await api.uploadFile('post', photoPath!)).id;
    }
    final d = await api.ngCreate(
      caption: caption.trim(),
      photoFileId: photoId,
      videoFileId: videoId,
      thumbnailFileId: thumbId,
    );
    final post = canon(d);
    final live = d['status'] == 'live';
    if (live) {
      (post.isReel ? reels : posts).insert(0, post);
      if (me != null) me!.posts += 1;
    }
    notifyListeners();
    return (post: post, live: live);
  }

  Future<void> remove(NgPost post) async {
    await api.ngRemove(post.id);
    posts.removeWhere((p) => p.id == post.id);
    reels.removeWhere((p) => p.id == post.id);
    _byId.remove(post.id);
    if (me != null && me!.posts > 0) me!.posts -= 1;
    notifyListeners();
  }

  // ── Comments ───────────────────────────────────────────────────────────

  Future<List<NgComment>> comments(NgPost post) async {
    final d = await api.ngComments(post.id);
    post
      ..likes = (d['likes'] as num?)?.toInt() ?? post.likes
      ..views = (d['views'] as num?)?.toInt() ?? post.views
      ..comments = (d['commentCount'] as num?)?.toInt() ?? post.comments
      ..liked = d['liked'] == true;
    notifyListeners();
    return ((d['items'] as List?) ?? const [])
        .map((e) => NgComment.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<NgComment> addComment(
    NgPost post,
    String text, {
    String? parentId,
  }) async {
    final d = await api.ngAddComment(post.id, text, parentId: parentId);
    post.comments += 1;
    notifyListeners();
    return NgComment.fromJson(d);
  }

  Future<void> removeComment(NgPost post, NgComment comment) async {
    await api.ngRemoveComment(post.id, comment.id);
    if (post.comments > 0) post.comments -= 1;
    notifyListeners();
  }

  // ── People ─────────────────────────────────────────────────────────────

  Future<NgProfile> profile(String memberId) async {
    final p = NgProfile.fromJson(await api.ngProfile(memberId));
    if (p.isMe) me = p;
    return p;
  }

  /// Loads the signed-in member's own page (their name and photo, and counts).
  Future<void> loadMe() async {
    try {
      me = NgProfile.fromJson(await api.ngProfile('me'));
      notifyListeners();
    } catch (_) {
      // The tabs still work without it.
    }
  }

  /// Follows or unfollows [memberId] from a list of people. Returns whether it went through.
  Future<bool> setFollow(String memberId, bool wanted) async {
    try {
      await api.ngFollow(memberId, wanted);
      if (me != null) me!.following += wanted ? 1 : -1;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = _say(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFollow(NgProfile who) async {
    final wanted = !who.followedByMe;
    who
      ..followedByMe = wanted
      ..followers += wanted ? 1 : -1;
    notifyListeners();
    try {
      final d = await api.ngFollow(who.author.id, wanted);
      who.followers = (d['followers'] as num?)?.toInt() ?? who.followers;
      if (me != null) me!.following += wanted ? 1 : -1;
    } catch (e) {
      who
        ..followedByMe = !wanted
        ..followers += wanted ? -1 : 1;
      lastError = _say(e);
    }
    notifyListeners();
  }
}

final liveNoahgram = LiveNoahgram();
