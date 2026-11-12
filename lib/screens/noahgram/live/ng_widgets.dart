import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/api_client.dart';
import '../../../data/live_noahgram.dart';
import '../../../data/noahgram_data.dart' show kLooks;
import '../../../l10n/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../noahgram_widgets.dart' show agoText, compact;
import 'ng_pages.dart';
import 'ng_sheets.dart';
import 'ng_video.dart';

const _heart = Color(0xFFE5334B);

/// The phone's own share sheet (see MainActivity and AppDelegate).
const _shareChannel = MethodChannel('noah/share');

/// A person's picture (the member's own profile photo), or their initials when there is none.
class NgAvatar extends StatelessWidget {
  const NgAvatar({super.key, required this.author, this.size = 40});

  final NgAuthor author;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = kLooks[author.id.hashCode.abs() % kLooks.length].colors;
    Widget initials() => Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Text(
        author.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );
    final url = author.photoUrl;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: author.isChurch
            ? Image.asset('assets/images/noah.png', fit: BoxFit.cover)
            : url == null
            ? initials()
            : Image.network(
                url,
                headers: api.authHeaders,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initials(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : initials(),
              ),
      ),
    );
  }
}

/// A picture from the server, with a grey box while it loads and a plain icon when it cannot be shown.
class NgPicture extends StatelessWidget {
  const NgPicture({super.key, required this.url, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget empty([IconData icon = Icons.image_outlined]) => Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.muted, size: 32),
    );
    final u = url;
    if (u == null) return empty();
    return Image.network(
      u,
      headers: api.authHeaders,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => empty(Icons.broken_image_outlined),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : Container(color: AppColors.surface),
    );
  }
}

void openNgProfile(BuildContext context, String memberId) {
  // The church (an office post) has no Noahgram page.
  if (memberId == '0') return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => NgProfileScreen(memberId: memberId)),
  );
}

void openNgPost(BuildContext context, NgPost post, {bool comments = false}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => NgPostScreen(post: post, openComments: comments),
    ),
  );
}

/// Opens the phone's share sheet with a link to the post. Whoever taps the link lands on that post.
Future<void> shareNgPost(BuildContext context, NgPost post) async {
  final text = tr(context, 'ng_share_text', args: {'url': post.shareUrl});
  try {
    await _shareChannel.invokeMethod<void>('text', text);
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: post.shareUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr(context, 'ng_link_copied'))));
    }
  }
}

/// A short message under the bottom bar, once.
void ngSay(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
    ),
  );
}

/// The ⋯ menu of a post: share, copy the link, and (for your own post) delete.
Future<void> showNgPostMenu(BuildContext context, NgPost post) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: Text(tr(sheet, 'ng_share_post')),
            onTap: () => Navigator.of(sheet).pop('share'),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(tr(sheet, 'ng_copy_link')),
            onTap: () => Navigator.of(sheet).pop('copy'),
          ),
          if (post.mine)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: _heart),
              title: Text(
                tr(sheet, 'ng_delete'),
                style: const TextStyle(color: _heart),
              ),
              onTap: () => Navigator.of(sheet).pop('delete'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case 'share':
      await shareNgPost(context, post);
    case 'copy':
      await Clipboard.setData(ClipboardData(text: post.shareUrl));
      if (context.mounted) ngSay(context, tr(context, 'ng_link_copied'));
    case 'delete':
      final sure = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          content: Text(tr(d, 'ng_delete_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: Text(tr(d, 'ng_cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: Text(
                tr(d, 'ng_delete'),
                style: const TextStyle(color: _heart),
              ),
            ),
          ],
        ),
      );
      if (sure != true || !context.mounted) return;
      try {
        await liveNoahgram.remove(post);
        if (context.mounted) {
          ngSay(context, tr(context, 'ng_deleted'));
          // A post opened on its own page has nothing left to show.
          if (context.findAncestorWidgetOfExactType<NgPostScreen>() != null) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (context.mounted) {
          ngSay(
            context,
            e is ApiException ? e.message : tr(context, 'ng_post_failed'),
          );
        }
      }
  }
}

/// One post in a list: author, picture or video, like / comment / share / save, caption, counts.
class NgPostCard extends StatefulWidget {
  const NgPostCard({super.key, required this.post, this.detail = false});

  final NgPost post;

  /// On the post's own page a video plays right here.
  final bool detail;

  @override
  State<NgPostCard> createState() => _NgPostCardState();
}

class _NgPostCardState extends State<NgPostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  /// A reel in the feed starts playing right here when it is tapped.
  bool _playing = false;

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _doubleTapLike() {
    if (!widget.post.liked) liveNoahgram.toggleLike(widget.post);
    _burst.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: liveNoahgram,
      builder: (context, _) {
        final post = widget.post;
        final author = post.author;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => openNgProfile(context, author.id),
                    child: NgAvatar(author: author, size: 36),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => openNgProfile(context, author.id),
                      child: Text(
                        author.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (post.pinned)
                    const Icon(
                      Icons.push_pin,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  IconButton(
                    onPressed: () => showNgPostMenu(context, post),
                    icon: const Icon(Icons.more_horiz, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: post.isReel && !widget.detail && !_playing
                  ? () => setState(() => _playing = true)
                  : null,
              onDoubleTap: _doubleTapLike,
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (post.isReel && (widget.detail || _playing))
                      NgVideo(post: post, fit: BoxFit.contain, controls: true)
                    else
                      NgPicture(url: post.stillSrc),
                    if (post.isReel && !widget.detail && !_playing)
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white70,
                          size: 64,
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
                              scale: t < 0.4
                                  ? 0.4 + t * 2.0
                                  : 1.2 - (t - 0.4) * 0.3,
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 96,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
              child: Row(
                children: [
                  _ActionIcon(
                    icon: post.liked ? Icons.favorite : Icons.favorite_border,
                    color: post.liked ? _heart : AppColors.ink,
                    onTap: () => liveNoahgram.toggleLike(post),
                  ),
                  _ActionIcon(
                    icon: Icons.chat_bubble_outline,
                    onTap: () => showNgCommentsSheet(context, post),
                  ),
                  Builder(
                    builder: (btn) => _ActionIcon(
                      icon: Icons.ios_share,
                      onTap: () => shareNgPost(btn, post),
                    ),
                  ),
                  const Spacer(),
                  _ActionIcon(
                    icon: post.saved ? Icons.bookmark : Icons.bookmark_border,
                    onTap: () => liveNoahgram.toggleSave(post),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'ng_likes', args: {'n': compact(post.likes)}) +
                        (post.isReel || widget.detail
                            ? '  ·  ${tr(context, 'ng_views', args: {'n': compact(post.views)})}'
                            : ''),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (post.caption.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${author.name}  ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: post.caption),
                        ],
                      ),
                      style: const TextStyle(fontSize: 13.5, height: 1.35),
                    ),
                  ],
                  if (post.link != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse(post.link!),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        post.link!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2E6FD8),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                  if (post.comments > 0) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => showNgCommentsSheet(context, post),
                      child: Text(
                        tr(
                          context,
                          'ng_view_comments',
                          args: {'n': '${post.comments}'},
                        ),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    agoText(context, post.hours),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
                  ),
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
      child: Icon(
        icon,
        key: ValueKey(icon),
        size: 26,
        color: color ?? AppColors.ink,
      ),
    ),
  );
}
