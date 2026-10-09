import 'package:flutter/material.dart';

import '../../data/noahgram_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'noahgram_widgets.dart';
import 'story_viewer.dart';

/// Full-screen profile for someone other than yourself (opened by tapping a name).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        title: Text(person.handle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ProfileView(person: person),
    );
  }
}

/// A single post opened from a grid.
class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        title: Text(tr(context, 'ng_posts'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ListView(children: [PostCard(post: post)]),
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.person, this.bottomPadding = 24});

  final Person person;
  final double bottomPadding;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int _tab = 0; // 0 grid, 1 reels, 2 saved (me) / tagged

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: noahgram,
      builder: (context, _) {
        final person = widget.person;
        final isMe = person == noahgram.me;
        final posts = noahgram.postsBy(person);
        final reels = noahgram.reelsBy(person);
        final following = noahgram.isFollowing(person);

        final List<Post> shown = switch (_tab) {
          0 => posts,
          1 => reels,
          _ => isMe
              ? noahgram.saved
              : noahgram.posts.where((p) => p.author != person).take(3).toList(),
        };

        return ListView(
          padding: EdgeInsets.only(bottom: widget.bottomPadding),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, _, _) => StoryViewer(person: person),
                        transitionsBuilder: (_, a, _, c) =>
                            FadeTransition(opacity: a, child: c),
                      ),
                    ),
                    child: Avatar(person: person, size: 84, ring: 1),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(
                            value: compact(posts.length + reels.length),
                            label: tr(context, 'ng_posts')),
                        _Stat(
                            value: compact(noahgram.followersOf(person)),
                            label: tr(context, 'ng_followers')),
                        _Stat(
                            value: compact(noahgram.followingOf(person)),
                            label: tr(context, 'ng_following')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(person.name,
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w800)),
                      ),
                      if (person.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 15, color: Color(0xFF2E8BEA)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(person.bio, style: const TextStyle(fontSize: 13.5, height: 1.35)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: isMe
                  ? Row(children: [
                      Expanded(
                        child: _OutlineButton(
                            label: tr(context, 'ng_edit_profile'),
                            onTap: () => showEditProfileSheet(context)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OutlineButton(
                            label: tr(context, 'ng_share_profile'),
                            onTap: () => showShareSheet(context)),
                      ),
                    ])
                  : Row(children: [
                      Expanded(
                        child: _OutlineButton(
                          label: tr(context, following ? 'ng_following' : 'ng_follow'),
                          filled: !following,
                          onTap: () => noahgram.toggleFollow(person),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OutlineButton(
                            label: tr(context, 'ng_message'), onTap: () {}),
                      ),
                    ]),
            ),
            const SizedBox(height: 16),
            _Highlights(person: person),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final (i, icon) in [
                  Icons.grid_on,
                  Icons.smart_display_outlined,
                  isMe ? Icons.bookmark_border : Icons.person_pin_outlined,
                ].indexed)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: i == _tab ? AppColors.ink : AppColors.border,
                              width: i == _tab ? 1.6 : 1,
                            ),
                          ),
                        ),
                        child: Icon(icon,
                            color: i == _tab ? AppColors.ink : AppColors.muted),
                      ),
                    ),
                  ),
              ],
            ),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    tr(context, _tab == 2 && isMe ? 'ng_no_saved' : 'ng_no_posts'),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              PostGrid(posts: shown),
          ],
        );
      },
    );
  }
}

/// 3-column square grid of posts; tapping opens the post.
class PostGrid extends StatelessWidget {
  const PostGrid({super.key, required this.posts});

  final List<Post> posts;

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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: p)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              LookCanvas(look: p.look, showText: false),
              if (p.isReel)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.smart_display, color: Colors.white, size: 18),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.ink)),
        ],
      );
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

class _Highlights extends StatelessWidget {
  const _Highlights({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('ng_hl_sunday', kLooks[0]),
      ('ng_hl_camp', kLooks[3]),
      ('ng_hl_choir', kLooks[1]),
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, i) => Column(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: ClipOval(
                  child: LookCanvas(look: items[i].$2, showText: false)),
            ),
            const SizedBox(height: 6),
            Text(tr(context, items[i].$1),
                style: const TextStyle(fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}
