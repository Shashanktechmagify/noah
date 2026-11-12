import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/api_client.dart';
import '../../../data/live_noahgram.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../../me/profile_photo_screen.dart';
import '../noahgram_widgets.dart' show compact;
import 'ng_sheets.dart';
import 'ng_video.dart';
import 'ng_widgets.dart';

/// Shows a message with a Try again button, or a plain empty note.
class _Note extends StatelessWidget {
  const _Note({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(tr(context, 'ng_try_again')),
            ),
        ],
      ),
    ),
  );
}

// ── Feed ──────────────────────────────────────────────────────────────────

class NgFeedView extends StatefulWidget {
  const NgFeedView({super.key});

  @override
  State<NgFeedView> createState() => _NgFeedViewState();
}

class _NgFeedViewState extends State<NgFeedView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (!liveNoahgram.postsLoaded) liveNoahgram.loadPosts();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) liveNoahgram.morePosts();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: liveNoahgram,
      builder: (context, _) {
        final posts = liveNoahgram.posts;
        if (posts.isEmpty) {
          if (liveNoahgram.postsLoading ||
              !liveNoahgram.postsLoaded && liveNoahgram.postsError == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => liveNoahgram.loadPosts(refresh: true),
            child: ListView(
              children: [
                SizedBox(
                  height: 360,
                  child: _Note(
                    text:
                        liveNoahgram.postsError ?? tr(context, 'ng_feed_empty'),
                    onRetry: liveNoahgram.postsError == null
                        ? null
                        : () => liveNoahgram.loadPosts(refresh: true),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => liveNoahgram.loadPosts(refresh: true),
          child: ListView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            itemCount: posts.length + 1,
            itemBuilder: (_, i) => i == posts.length
                ? SizedBox(
                    height: 56,
                    child: liveNoahgram.postsNext != null
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : null,
                  )
                : NgPostCard(key: ValueKey(posts[i].id), post: posts[i]),
          ),
        );
      },
    );
  }
}

// ── Explore ───────────────────────────────────────────────────────────────

class NgExploreView extends StatefulWidget {
  const NgExploreView({super.key});

  @override
  State<NgExploreView> createState() => _NgExploreViewState();
}

class _NgExploreViewState extends State<NgExploreView> {
  final _query = TextEditingController();
  List<NgPost>? _results;
  List<NgAuthor> _people = const [];
  Timer? _typing;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // The tab is only built once it is opened (see LiveNoahgramScreen), so this is the first look.
    _run();
  }

  @override
  void dispose() {
    _typing?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final asked = _query.text;
      // People are found by name; a failure there never hides the posts.
      final people = liveNoahgram.people(asked).catchError((_) => <NgAuthor>[]);
      final r = await liveNoahgram.explore(asked);
      final found = await people;
      if (mounted && asked == _query.text) {
        setState(() {
          _results = r;
          _people = found;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException && e.code != 'network'
              ? e.message
              : tr(context, 'ng_no_internet'),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _run(),
            // Looks while typing, once the member pauses.
            onChanged: (_) {
              _typing?.cancel();
              _typing = Timer(const Duration(milliseconds: 450), _run);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              hintText: tr(context, 'ng_search_hint'),
              hintStyle: const TextStyle(color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _error != null
              ? _Note(text: _error!, onRetry: _run)
              : results == null || _loading && results.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : results.isEmpty && _people.isEmpty
              ? _Note(text: tr(context, 'ng_no_results'))
              : RefreshIndicator(
                  onRefresh: _run,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 110),
                    children: [
                      if (_people.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                          child: Text(
                            tr(context, 'ng_people'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        for (final person in _people)
                          ListTile(
                            leading: NgAvatar(author: person, size: 44),
                            title: Text(
                              person.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: () => openNgProfile(context, person.id),
                          ),
                        const SizedBox(height: 8),
                      ],
                      NgGrid(posts: results),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// A 3-column grid of pictures and reel stills; a tap opens the post.
class NgGrid extends StatelessWidget {
  const NgGrid({super.key, required this.posts});

  final List<NgPost> posts;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final p = posts[i];
        return GestureDetector(
          onTap: () => openNgPost(context, p),
          child: Stack(
            fit: StackFit.expand,
            children: [
              p.stillSrc == null
                  ? const ColoredBox(color: Colors.black87)
                  : NgPicture(url: p.stillSrc),
              if (p.isReel)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    Icons.smart_display,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Reels ─────────────────────────────────────────────────────────────────

class NgReelsView extends StatefulWidget {
  const NgReelsView({super.key, this.visible = true});

  /// False while another tab is showing, so the video stops.
  final bool visible;

  @override
  State<NgReelsView> createState() => _NgReelsViewState();
}

class _NgReelsViewState extends State<NgReelsView> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (!liveNoahgram.reelsLoaded) liveNoahgram.loadReels();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: liveNoahgram,
      builder: (context, _) {
        final reels = liveNoahgram.reels;
        if (reels.isEmpty) {
          if (liveNoahgram.reelsLoading ||
              !liveNoahgram.reelsLoaded && liveNoahgram.reelsError == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _Note(
            text: liveNoahgram.reelsError ?? tr(context, 'ng_reels_empty'),
            onRetry: liveNoahgram.reelsError == null
                ? null
                : liveNoahgram.loadReels,
          );
        }
        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: reels.length,
          onPageChanged: (i) {
            setState(() => _index = i);
            if (i >= reels.length - 3) liveNoahgram.moreReels();
          },
          itemBuilder: (_, i) => NgReelPage(
            key: ValueKey(reels[i].id),
            post: reels[i],
            active: widget.visible && i == _index,
          ),
        );
      },
    );
  }
}

class NgReelPage extends StatefulWidget {
  const NgReelPage({super.key, required this.post, required this.active});

  final NgPost post;
  final bool active;

  @override
  State<NgReelPage> createState() => _NgReelPageState();
}

class _NgReelPageState extends State<NgReelPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: liveNoahgram,
      builder: (context, _) {
        final post = widget.post;
        final author = post.author;
        return GestureDetector(
          onDoubleTap: () {
            if (!post.liked) liveNoahgram.toggleLike(post);
            _burst.forward(from: 0);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              NgVideo(post: post, active: widget.active),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xAA000000)],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _burst,
                    builder: (_, _) {
                      final t = _burst.value;
                      return Opacity(
                        opacity: t == 0 ? 0 : (t < 0.7 ? 1 : (1 - t) / 0.3),
                        child: Transform.scale(
                          scale: t < 0.4 ? 0.4 + t * 2 : 1.2 - (t - 0.4) * 0.3,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 100,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 118,
                child: Column(
                  children: [
                    _ReelAction(
                      icon: post.liked ? Icons.favorite : Icons.favorite_border,
                      color: post.liked
                          ? const Color(0xFFFF4D67)
                          : Colors.white,
                      label: compact(post.likes),
                      onTap: () => liveNoahgram.toggleLike(post),
                    ),
                    _ReelAction(
                      icon: Icons.chat_bubble_outline,
                      label: compact(post.comments),
                      onTap: () => showNgCommentsSheet(context, post),
                    ),
                    Builder(
                      builder: (btn) => _ReelAction(
                        icon: Icons.ios_share,
                        onTap: () => shareNgPost(btn, post),
                      ),
                    ),
                    _ReelAction(
                      icon: post.saved ? Icons.bookmark : Icons.bookmark_border,
                      onTap: () => liveNoahgram.toggleSave(post),
                    ),
                    _ReelAction(
                      icon: Icons.more_horiz,
                      onTap: () => showNgPostMenu(context, post),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 14,
                right: 76,
                bottom: 112,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => openNgProfile(context, author.id),
                      child: Row(
                        children: [
                          NgAvatar(author: author, size: 34),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              author.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (post.caption.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        post.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      tr(context, 'ng_views', args: {'n': compact(post.views)}),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReelAction extends StatelessWidget {
  const _ReelAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ── Profile ───────────────────────────────────────────────────────────────

/// Someone's page, opened by tapping their name.
class NgProfileScreen extends StatelessWidget {
  const NgProfileScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
      ),
      body: NgProfileView(memberId: memberId),
    );
  }
}

/// A member's Noahgram page: their own name and photo, counts, and their posts. [memberId] may be `me`.
class NgProfileView extends StatefulWidget {
  const NgProfileView({
    super.key,
    required this.memberId,
    this.bottomPadding = 24,
    this.refreshTick = 0,
  });

  final String memberId;
  final double bottomPadding;

  /// Changes each time the page is opened again, so its counts are read afresh (somebody may have followed you).
  final int refreshTick;

  @override
  State<NgProfileView> createState() => _NgProfileViewState();
}

class _NgProfileViewState extends State<NgProfileView> {
  @override
  void didUpdateWidget(NgProfileView old) {
    super.didUpdateWidget(old);
    if (widget.refreshTick != old.refreshTick) _load();
  }

  NgProfile? _profile;
  List<NgPost> _posts = const [];
  List<NgPost>? _saved;
  String? _error;
  bool _loading = true;
  int _tab = 0; // 0 pictures, 1 reels, 2 saved (yourself)
  int _loadedFor = -1;

  @override
  void initState() {
    super.initState();
    liveNoahgram.addListener(_onChange);
    _load();
  }

  @override
  void dispose() {
    liveNoahgram.removeListener(_onChange);
    super.dispose();
  }

  /// Your own page reads again when you post or delete something.
  void _onChange() {
    final mine = _profile?.isMe ?? widget.memberId == 'me';
    final count = liveNoahgram.me?.posts;
    if (mine &&
        count != null &&
        _loadedFor >= 0 &&
        count != _loadedFor &&
        !_loading) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await liveNoahgram.profile(widget.memberId);
      final page = await liveNoahgram.postsOf(profile.author.id);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _posts = page.items;
        _loadedFor = profile.posts;
        _saved = null;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException && e.code != 'network'
              ? e.message
              : tr(context, 'ng_no_internet'),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openPeople(String kind) {
    final p = _profile;
    if (p == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NgPeopleScreen(memberId: p.author.id, kind: kind),
      ),
    );
  }

  Future<void> _showSaved() async {
    setState(() => _tab = 2);
    if (_saved != null) return;
    try {
      final list = await liveNoahgram.saved();
      if (mounted) setState(() => _saved = list);
    } catch (_) {
      if (mounted) setState(() => _saved = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return _loading
          ? const Center(child: CircularProgressIndicator())
          : _Note(
              text: _error ?? tr(context, 'ng_no_internet'),
              onRetry: _load,
            );
    }
    return ListenableBuilder(
      listenable: liveNoahgram,
      builder: (context, _) {
        final isMe = profile.isMe;
        // Your own counts are the ones kept up to date when you follow someone.
        final counts = isMe ? (liveNoahgram.me ?? profile) : profile;
        final shown = switch (_tab) {
          0 => _posts.where((p) => !p.isReel).toList(),
          1 => _posts.where((p) => p.isReel).toList(),
          _ => _saved ?? const <NgPost>[],
        };
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.only(bottom: widget.bottomPadding),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    NgAvatar(author: profile.author, size: 84),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat(
                            value: compact(counts.posts),
                            label: tr(context, 'ng_posts'),
                          ),
                          _Stat(
                            value: compact(counts.followers),
                            label: tr(context, 'ng_followers'),
                            onTap: () => _openPeople('followers'),
                          ),
                          _Stat(
                            value: compact(counts.following),
                            label: tr(context, 'ng_following'),
                            onTap: () => _openPeople('following'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  profile.author.name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: isMe
                    ? _OutlineButton(
                        label: tr(context, 'ng_change_photo'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfilePhotoScreen(),
                          ),
                        ),
                      )
                    : _OutlineButton(
                        label: tr(
                          context,
                          profile.followedByMe ? 'ng_following' : 'ng_follow',
                        ),
                        filled: !profile.followedByMe,
                        onTap: () => liveNoahgram.toggleFollow(profile),
                      ),
              ),
              if (isMe)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    tr(context, 'ng_name_note'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final (i, icon) in [
                    Icons.grid_on,
                    Icons.smart_display_outlined,
                    if (isMe) Icons.bookmark_border,
                  ].indexed)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            i == 2 ? _showSaved() : setState(() => _tab = i),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: i == _tab
                                    ? AppColors.ink
                                    : AppColors.border,
                                width: i == _tab ? 1.6 : 1,
                              ),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: i == _tab ? AppColors.ink : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (_tab == 2 && _saved == null)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      tr(context, _tab == 2 ? 'ng_no_saved' : 'ng_no_posts'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                NgGrid(posts: shown),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
      ],
    ),
  );
}

/// The members who follow someone (`followers`) or whom they follow (`following`), each with a Follow button.
class NgPeopleScreen extends StatefulWidget {
  const NgPeopleScreen({super.key, required this.memberId, required this.kind});

  final String memberId;
  final String kind;

  @override
  State<NgPeopleScreen> createState() => _NgPeopleScreenState();
}

class _NgPeopleScreenState extends State<NgPeopleScreen> {
  List<NgAuthor>? _people;
  String? _error;
  // What the member changed on this page, over what the server said when it was opened.
  final _followed = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await liveNoahgram.connections(widget.memberId, widget.kind);
      if (mounted) setState(() => _people = list);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException && e.code != 'network'
              ? e.message
              : tr(context, 'ng_no_internet'),
        );
      }
    }
  }

  Future<void> _toggle(NgAuthor who) async {
    final wanted = !(_followed[who.id] ?? who.followedByMe);
    setState(() => _followed[who.id] = wanted);
    final ok = await liveNoahgram.setFollow(who.id, wanted);
    if (!ok && mounted) setState(() => _followed[who.id] = !wanted);
  }

  @override
  Widget build(BuildContext context) {
    final people = _people;
    final followers = widget.kind == 'followers';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        title: Text(
          tr(context, followers ? 'ng_followers' : 'ng_following'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: _error != null
          ? _Note(text: _error!, onRetry: _load)
          : people == null
          ? const Center(child: CircularProgressIndicator())
          : people.isEmpty
          ? _Note(
              text: tr(
                context,
                followers ? 'ng_no_followers' : 'ng_no_following',
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: people.length,
                itemBuilder: (_, i) {
                  final who = people[i];
                  final following = _followed[who.id] ?? who.followedByMe;
                  return ListTile(
                    leading: NgAvatar(author: who, size: 46),
                    title: Text(
                      who.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => openNgProfile(context, who.id),
                    trailing: who.isMe
                        ? null
                        : SizedBox(
                            width: 110,
                            child: _OutlineButton(
                              label: tr(
                                context,
                                following ? 'ng_following' : 'ng_follow',
                              ),
                              filled: !following,
                              onTap: () => _toggle(who),
                            ),
                          ),
                  );
                },
              ),
            ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.magenta : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: filled ? Colors.white : AppColors.ink,
        ),
      ),
    ),
  );
}

// ── One post ──────────────────────────────────────────────────────────────

/// A single post on its own page: opened from a grid, a shared link or a notification.
class NgPostScreen extends StatefulWidget {
  const NgPostScreen({
    super.key,
    this.post,
    this.postId,
    this.openComments = false,
  }) : assert(post != null || postId != null);

  final NgPost? post;
  final String? postId;
  final bool openComments;

  @override
  State<NgPostScreen> createState() => _NgPostScreenState();
}

class _NgPostScreenState extends State<NgPostScreen> {
  NgPost? _post;
  bool _gone = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final fresh = await liveNoahgram.fetchPost(
        widget.post?.id ?? widget.postId!,
      );
      if (!mounted) return;
      if (fresh == null) {
        setState(() => _gone = true);
        return;
      }
      setState(() => _post = fresh);
      if (!fresh.isReel) liveNoahgram.markViewed(fresh);
      if (widget.openComments) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showNgCommentsSheet(context, fresh);
        });
      }
    } catch (e) {
      if (mounted && _post == null) {
        setState(
          () => _error = e is ApiException && e.code != 'network'
              ? e.message
              : tr(context, 'ng_no_internet'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        title: Text(
          tr(context, 'ng_posts'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: _gone
          ? _Note(text: tr(context, 'ng_unavailable'))
          : post == null
          ? (_error != null
                ? _Note(text: _error!, onRetry: _load)
                : const Center(child: CircularProgressIndicator()))
          : ListView(children: [NgPostCard(post: post, detail: true)]),
    );
  }
}
