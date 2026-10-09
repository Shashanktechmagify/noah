import 'package:flutter/material.dart';

import '../../data/noahgram_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'profile_view.dart';

const _heart = Color(0xFFE5334B);
const _storyRing = [Color(0xFFF2A33A), Color(0xFFE5334B), Color(0xFFA81BC4)];

String agoText(BuildContext context, int hours) {
  if (hours <= 0) return tr(context, 'ng_just_now');
  if (hours < 24) return tr(context, 'ng_ago_h', args: {'n': '$hours'});
  return tr(context, 'ng_ago_d', args: {'n': '${hours ~/ 24}'});
}

String compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}K';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

void openProfile(BuildContext context, Person who) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ProfileScreen(person: who)),
  );
}

/// Circular profile picture; initials on a gradient (the church uses the logo).
/// [ring]: 0 none, 1 unseen story, 2 seen story.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.person, this.size = 40, this.ring = 0});

  final Person person;
  final double size;
  final int ring;

  @override
  Widget build(BuildContext context) {
    final core = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: person.isChurch
            ? Image.asset('assets/images/noah.png', fit: BoxFit.cover)
            : Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: person.colors,
                  ),
                ),
                child: Text(
                  person.initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.36,
                  ),
                ),
              ),
      ),
    );
    if (ring == 0) return core;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring == 1
            ? const LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: _storyRing,
              )
            : null,
        color: ring == 2 ? const Color(0xFFD5D7E6) : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: core,
      ),
    );
  }
}

/// The coloured stand-in for a photo, with an optional quote on top.
class LookCanvas extends StatelessWidget {
  const LookCanvas({super.key, required this.look, this.showText = true});

  final Look look;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final side = c.biggest.shortestSide;
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: look.colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -side * 0.08,
              bottom: -side * 0.08,
              child: Icon(look.icon,
                  size: side * 0.62, color: Colors.white.withValues(alpha: 0.16)),
            ),
            if (showText && look.text != null && side > 140)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(side * 0.08),
                  child: Text(
                    look.text!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: side * 0.075,
                      height: 1.3,
                    ),
                  ),
                ),
              )
            else if (side > 40)
              Center(
                child: Icon(look.icon,
                    size: side * 0.3, color: Colors.white.withValues(alpha: 0.9)),
              ),
          ],
        ),
      );
    });
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Post card
// ──────────────────────────────────────────────────────────────────────────

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
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

  void _doubleTapLike() {
    if (!widget.post.liked) noahgram.toggleLike(widget.post);
    _burst.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: noahgram,
      builder: (context, _) {
        final post = widget.post;
        final author = post.author;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => openProfile(context, author),
                    child: Avatar(person: author, size: 36),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => openProfile(context, author),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(author.handle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800)),
                          ),
                          if (author.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                size: 14, color: Color(0xFF2E8BEA)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const IconButton(
                    onPressed: null,
                    icon: Icon(Icons.more_horiz, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            // Media
            GestureDetector(
              onDoubleTap: _doubleTapLike,
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LookCanvas(look: post.look),
                    Center(
                      child: AnimatedBuilder(
                        animation: _burst,
                        builder: (_, _) {
                          final t = _burst.value;
                          final scale = t < 0.4 ? 0.4 + t * 2.0 : 1.2 - (t - 0.4) * 0.3;
                          return Opacity(
                            opacity: t == 0 ? 0 : (t < 0.7 ? 1 : (1 - t) / 0.3),
                            child: Transform.scale(
                              scale: scale,
                              child: const Icon(Icons.favorite,
                                  color: Colors.white, size: 96),
                            ),
                          );
                        },
                      ),
                    ),
                    if (post.isReel)
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: Icon(Icons.smart_display_outlined,
                            color: Colors.white, size: 22),
                      ),
                  ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
              child: Row(
                children: [
                  _ActionIcon(
                    icon: post.liked ? Icons.favorite : Icons.favorite_border,
                    color: post.liked ? _heart : AppColors.ink,
                    onTap: () => noahgram.toggleLike(post),
                  ),
                  _ActionIcon(
                    icon: Icons.chat_bubble_outline,
                    onTap: () => showCommentsSheet(context, post),
                  ),
                  _ActionIcon(
                    icon: Icons.send_outlined,
                    onTap: () => showShareSheet(context),
                  ),
                  const Spacer(),
                  _ActionIcon(
                    icon: post.saved ? Icons.bookmark : Icons.bookmark_border,
                    onTap: () => noahgram.toggleSave(post),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(context, 'ng_likes', args: {'n': compact(post.likes)}),
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: '${author.handle}  ',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(text: post.caption),
                      ],
                    ),
                    style: const TextStyle(fontSize: 13.5, height: 1.35),
                  ),
                  if (post.comments.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => showCommentsSheet(context, post),
                      child: Text(
                        tr(context, 'ng_view_comments',
                            args: {'n': '${post.comments.length}'}),
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(agoText(context, post.hours),
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11.5)),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        splashRadius: 22,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: Icon(icon,
              key: ValueKey(icon), size: 26, color: color ?? AppColors.ink),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────
// Bottom sheets
// ──────────────────────────────────────────────────────────────────────────

Future<void> _sheet(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: builder,
    );

Widget _grabber() => Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

Future<void> showCommentsSheet(BuildContext context, Post post) =>
    _sheet(context, (_) => _CommentsSheet(post: post));

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.post});

  final Post post;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    noahgram.addComment(widget.post, text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.72;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            _grabber(),
            Text(tr(context, 'ng_comments'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const Divider(height: 24, color: AppColors.border),
            Expanded(
              child: ListenableBuilder(
                listenable: noahgram,
                builder: (context, _) {
                  final items = widget.post.comments;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length + 1,
                    itemBuilder: (_, i) {
                      // First row is the caption, like on Instagram.
                      final author =
                          i == 0 ? widget.post.author : items[i - 1].author;
                      final text =
                          i == 0 ? widget.post.caption : items[i - 1].text;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Avatar(person: author, size: 34),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                      text: '${author.handle}  ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  TextSpan(text: text),
                                ]),
                                style:
                                    const TextStyle(fontSize: 13.5, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
              child: Row(
                children: [
                  Avatar(person: noahgram.me, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: tr(context, 'ng_add_comment_link'),
                        hintStyle: const TextStyle(color: AppColors.muted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _controller.text.trim().isEmpty ? null : _send,
                    child: Text(tr(context, 'ng_post'),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showShareSheet(BuildContext context) =>
    _sheet(context, (_) => const _ShareSheet());

class _ShareSheet extends StatefulWidget {
  const _ShareSheet();

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _sent = <String>{};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _grabber(),
          Text(tr(context, 'ng_share_to'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final p in noahgram.others)
            ListTile(
              leading: Avatar(person: p, size: 42),
              title: Text(p.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              subtitle: Text('@${p.handle}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              trailing: GestureDetector(
                onTap: () => setState(() => _sent.add(p.id)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _sent.contains(p.id)
                        ? AppColors.tint
                        : AppColors.magenta,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tr(context, _sent.contains(p.id) ? 'ng_sent' : 'ng_send'),
                    style: TextStyle(
                      color: _sent.contains(p.id)
                          ? AppColors.magenta
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Future<void> showCreatePostSheet(BuildContext context) =>
    _sheet(context, (_) => const _CreatePostSheet());

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _caption = TextEditingController();
  int _look = 0;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _share() {
    noahgram.addPost(kLooks[_look], _caption.text);
    final messenger = ScaffoldMessenger.of(context);
    final message = tr(context, 'ng_posted');
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _grabber(),
              Center(
                child: Text(tr(context, 'ng_new_post'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 14),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: LookCanvas(look: kLooks[_look], showText: false),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(tr(context, 'ng_choose_look'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kLooks.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _look = i),
                    child: Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == _look
                              ? AppColors.magenta
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                          child: LookCanvas(look: kLooks[i], showText: false)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _caption,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: tr(context, 'ng_caption_hint'),
                  hintStyle: const TextStyle(color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.magenta,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: _share,
                  child: Text(tr(context, 'ng_share'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showEditProfileSheet(BuildContext context) =>
    _sheet(context, (_) => const _EditProfileSheet());

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _name = TextEditingController(text: noahgram.me.name);
  final _bio = TextEditingController(text: noahgram.me.bio);

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _grabber(),
              Text(tr(context, 'ng_edit_profile'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(controller: _name, decoration: _decoration(tr(context, 'ng_name'))),
              const SizedBox(height: 12),
              TextField(
                controller: _bio,
                maxLines: 3,
                decoration: _decoration(tr(context, 'ng_bio')),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.magenta,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () {
                    noahgram.updateProfile(name: _name.text, bio: _bio.text);
                    Navigator.of(context).pop();
                  },
                  child: Text(tr(context, 'ng_save'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
