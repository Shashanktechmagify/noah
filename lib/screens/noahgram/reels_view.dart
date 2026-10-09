import 'package:flutter/material.dart';

import '../../data/noahgram_data.dart';
import '../../l10n/app_strings.dart';
import 'noahgram_widgets.dart';

/// Vertical, full-height reels pager.
class ReelsView extends StatelessWidget {
  const ReelsView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: noahgram.reels.length,
      itemBuilder: (_, i) => _ReelPage(post: noahgram.reels[i]),
    );
  }
}

class _ReelPage extends StatefulWidget {
  const _ReelPage({required this.post});

  final Post post;

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  bool _paused = false;

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: noahgram,
      builder: (context, _) {
        final post = widget.post;
        final author = post.author;
        final following = noahgram.isFollowing(author);
        return GestureDetector(
          onTap: () => setState(() => _paused = !_paused),
          onDoubleTap: () {
            if (!post.liked) noahgram.toggleLike(post);
            _burst.forward(from: 0);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              LookCanvas(look: post.look, showText: false),
              // Darken the bottom so the caption stays readable.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xAA000000)],
                  ),
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (_, _) {
                    final t = _burst.value;
                    return Opacity(
                      opacity: t == 0 ? 0 : (t < 0.7 ? 1 : (1 - t) / 0.3),
                      child: Transform.scale(
                        scale: t < 0.4 ? 0.4 + t * 2 : 1.2 - (t - 0.4) * 0.3,
                        child: const Icon(Icons.favorite,
                            color: Colors.white, size: 100),
                      ),
                    );
                  },
                ),
              ),
              if (_paused)
                const Center(
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white70, size: 80),
                ),
              // Right-hand actions
              Positioned(
                right: 10,
                bottom: 118,
                child: Column(
                  children: [
                    _ReelAction(
                      icon: post.liked ? Icons.favorite : Icons.favorite_border,
                      color: post.liked ? const Color(0xFFFF4D67) : Colors.white,
                      label: compact(post.likes),
                      onTap: () => noahgram.toggleLike(post),
                    ),
                    _ReelAction(
                      icon: Icons.chat_bubble_outline,
                      label: compact(post.comments.length),
                      onTap: () => showCommentsSheet(context, post),
                    ),
                    _ReelAction(
                      icon: Icons.send_outlined,
                      onTap: () => showShareSheet(context),
                    ),
                    _ReelAction(
                      icon: post.saved ? Icons.bookmark : Icons.bookmark_border,
                      onTap: () => noahgram.toggleSave(post),
                    ),
                  ],
                ),
              ),
              // Author + caption
              Positioned(
                left: 14,
                right: 76,
                bottom: 112,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => openProfile(context, author),
                          child: Avatar(person: author, size: 34),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(author.handle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        ),
                        if (author != noahgram.me) ...[
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => noahgram.toggleFollow(author),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tr(context, following ? 'ng_following' : 'ng_follow'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(post.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13.5, height: 1.3)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.music_note,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${author.handle} · ${tr(context, 'ng_audio')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
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
              Icon(icon, color: color, size: 30, shadows: const [
                Shadow(color: Colors.black45, blurRadius: 6),
              ]),
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(label!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      );
}
