import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../../../data/api_client.dart';
import '../../../data/live_noahgram.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../../registration/uploads.dart' show compressVideo;
import '../noahgram_widgets.dart' show agoText;
import 'ng_widgets.dart';

Future<void> _sheet(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<void>(
      context: context,
      // Over the whole app, including the bottom bar (which would hide the typing box).
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
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

String _why(BuildContext context, Object e, String fallbackKey) =>
    e is ApiException && e.code != 'network'
    ? e.message
    : tr(context, fallbackKey);

// ── Comments ──────────────────────────────────────────────────────────────

Future<void> showNgCommentsSheet(BuildContext context, NgPost post) =>
    _sheet(context, (_) => _CommentsSheet(post: post));

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.post});

  final NgPost post;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  String? _sendError;
  String? _notice;
  List<NgComment>? _items;
  String? _error;
  NgComment? _replyTo;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    liveNoahgram.addListener(_changed);
    _load();
  }

  /// A like on a comment changes its count on this sheet.
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    liveNoahgram.removeListener(_changed);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await liveNoahgram.comments(widget.post);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = _why(context, e, 'ng_no_internet'));
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final made = await liveNoahgram.addComment(
        widget.post,
        text,
        parentId: _replyTo?.id,
      );
      _controller.clear();
      if (mounted) {
        setState(() {
          _items = [...?_items, made];
          _replyTo = null;
        });
        // Show the new comment: it is added at the end of the list.
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
    } catch (e) {
      // Said inside the sheet: a message under it would be hidden behind it.
      if (mounted) {
        setState(() => _sendError = _why(context, e, 'ng_comment_failed'));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _report(NgComment c) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        content: Text(tr(d, 'manna_report_ask')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(tr(d, 'ng_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: Text(
              tr(d, 'manna_report'),
              style: const TextStyle(color: Color(0xFFE5334B)),
            ),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await liveNoahgram.reportComment(widget.post, c);
      // Said inside the sheet: a message under it would be hidden behind it.
      if (mounted) {
        setState(() {
          _items = _items?.where((x) => x.id != c.id).toList();
          _sendError = null;
          _notice = tr(context, 'manna_reported');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendError = _why(context, e, 'ng_comment_failed'));
      }
    }
  }

  Future<void> _remove(NgComment c) async {
    try {
      await liveNoahgram.removeComment(widget.post, c);
      if (mounted) {
        setState(() => _items = _items?.where((x) => x.id != c.id).toList());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendError = _why(context, e, 'ng_comment_failed'));
      }
    }
  }

  /// Top-level comments in order, each followed by the replies to it.
  List<NgComment> _ordered(List<NgComment> all) {
    final ids = all.map((c) => c.id).toSet();
    final top = all.where(
      (c) => c.parentId == null || !ids.contains(c.parentId),
    );
    return [
      for (final c in top) ...[c, ...all.where((r) => r.parentId == c.id)],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.72;
    final me = liveNoahgram.me?.author;
    final items = _items;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            _grabber(),
            Text(
              tr(context, 'ng_comments'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const Divider(height: 24, color: AppColors.border),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          TextButton(
                            onPressed: _load,
                            child: Text(tr(context, 'ng_try_again')),
                          ),
                        ],
                      ),
                    )
                  : items == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (widget.post.caption.isNotEmpty)
                          _row(
                            author: widget.post.author,
                            text: widget.post.caption,
                            indent: 0,
                          ),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: Text(
                                tr(context, 'ng_no_comments'),
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ),
                          ),
                        for (final c in _ordered(items))
                          _row(
                            author: c.author,
                            text: c.text,
                            indent: c.parentId == null ? 0 : 44,
                            comment: c,
                          ),
                      ],
                    ),
            ),
            const Divider(height: 1, color: AppColors.border),
            if (_notice != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _notice!,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ),
              ),
            if (_sendError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _sendError!,
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            if (_replyTo != null)
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(
                          context,
                          'ng_replying_to',
                          args: {'name': _replyTo!.author.name},
                        ),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _replyTo = null),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
              child: Row(
                children: [
                  if (me != null) NgAvatar(author: me, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      maxLength: 500,
                      buildCounter: (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                      decoration: InputDecoration(
                        hintText: tr(context, 'ng_add_comment_link'),
                        hintStyle: const TextStyle(color: AppColors.muted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _controller.text.trim().isEmpty || _sending
                        ? null
                        : _send,
                    child: Text(
                      tr(context, 'ng_post'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required NgAuthor author,
    required String text,
    required double indent,
    NgComment? comment,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16, left: indent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              openNgProfile(context, author.id);
            },
            child: NgAvatar(author: author, size: indent == 0 ? 34 : 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${author.name}  ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: text),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13.5, height: 1.35),
                ),
                if (comment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text(
                          agoText(
                            context,
                            comment.createdAt == null
                                ? 0
                                : DateTime.now()
                                      .difference(comment.createdAt!)
                                      .inHours
                                      .clamp(0, 100000),
                          ),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => setState(() => _replyTo = comment),
                          child: Text(
                            tr(context, 'ng_reply'),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!comment.mine) ...[
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () => _report(comment),
                            child: Text(
                              tr(context, 'manna_report'),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (comment.canRemove) ...[
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () => _remove(comment),
                            child: Text(
                              tr(context, 'ng_remove_comment'),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
          // Like (with its count) on the right, as on Instagram.
          if (comment != null)
            GestureDetector(
              onTap: () => liveNoahgram.toggleCommentLike(widget.post, comment),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                child: Column(
                  children: [
                    Icon(
                      comment.likedByMe ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: comment.likedByMe
                          ? const Color(0xFFE5334B)
                          : AppColors.muted,
                    ),
                    if (comment.likes > 0)
                      Text(
                        '${comment.likes}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── New post ──────────────────────────────────────────────────────────────

Future<void> showNgCreateSheet(BuildContext context) =>
    _sheet(context, (_) => const _CreateSheet());

class _CreateSheet extends StatefulWidget {
  const _CreateSheet();

  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  final _caption = TextEditingController();
  String? _photoPath;
  String? _videoPath;
  String? _stillPath;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool video, required bool camera}) async {
    try {
      final picker = ImagePicker();
      final source = camera ? ImageSource.camera : ImageSource.gallery;
      if (video) {
        final x = await picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 2),
        );
        if (x == null) return;
        String? still;
        try {
          still = (await VideoCompress.getFileThumbnail(
            x.path,
            quality: 70,
          )).path;
        } catch (_) {
          still = null; // a reel without a still picture is fine
        }
        setState(() {
          _videoPath = x.path;
          _stillPath = still;
          _photoPath = null;
          _error = null;
        });
      } else {
        final x = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1600,
        );
        if (x == null) return;
        setState(() {
          _photoPath = x.path;
          _videoPath = null;
          _stillPath = null;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = tr(context, 'ng_post_failed'));
    }
  }

  Future<void> _share() async {
    if (_busy || (_photoPath == null && _videoPath == null)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String? video = _videoPath;
      if (video != null) video = (await compressVideo(video)).path;
      final made = await liveNoahgram.create(
        caption: _caption.text,
        photoPath: _photoPath,
        videoPath: video,
        thumbnailPath: _stillPath,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = tr(context, made.live ? 'ng_posted' : 'ng_posted_wait');
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _why(context, e, 'ng_post_failed');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _photoPath ?? _stillPath;
    final hasMedia = _photoPath != null || _videoPath != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _grabber(),
                    Center(
                      child: Text(
                        tr(context, 'ng_new_post'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (hasMedia)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                preview != null
                                    ? Image.file(
                                        File(preview),
                                        fit: BoxFit.cover,
                                      )
                                    : const ColoredBox(color: Colors.black87),
                                if (_videoPath != null)
                                  const Center(
                                    child: Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.white70,
                                      size: 56,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (hasMedia) const SizedBox(height: 12),
                    Text(
                      tr(context, 'ng_add_media'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _PickTile(
                          icon: Icons.photo_camera_outlined,
                          label:
                              '${tr(context, 'ng_pick_photo')} · ${tr(context, 'ng_pick_camera')}',
                          onTap: _busy
                              ? null
                              : () => _pick(video: false, camera: true),
                        ),
                        const SizedBox(width: 8),
                        _PickTile(
                          icon: Icons.photo_library_outlined,
                          label:
                              '${tr(context, 'ng_pick_photo')} · ${tr(context, 'ng_pick_gallery')}',
                          onTap: _busy
                              ? null
                              : () => _pick(video: false, camera: false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _PickTile(
                          icon: Icons.videocam_outlined,
                          label:
                              '${tr(context, 'ng_pick_video')} · ${tr(context, 'ng_pick_camera')}',
                          onTap: _busy
                              ? null
                              : () => _pick(video: true, camera: true),
                        ),
                        const SizedBox(width: 8),
                        _PickTile(
                          icon: Icons.video_library_outlined,
                          label:
                              '${tr(context, 'ng_pick_video')} · ${tr(context, 'ng_pick_gallery')}',
                          onTap: _busy
                              ? null
                              : () => _pick(video: true, camera: false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _caption,
                      maxLines: 3,
                      maxLength: 2200,
                      enabled: !_busy,
                      decoration: InputDecoration(
                        hintText: tr(context, 'ng_caption_optional'),
                        hintStyle: const TextStyle(color: AppColors.muted),
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // The Share button stays in view while the form scrolls.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.magenta,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: hasMedia && !_busy ? _share : null,
                  child: _busy
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(tr(context, 'ng_posting')),
                          ],
                        )
                      : Text(
                          tr(context, 'ng_share'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: onTap == null ? AppColors.muted : AppColors.magenta,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
