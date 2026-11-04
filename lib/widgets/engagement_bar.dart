import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/manna_data.dart';
import '../data/manna_engagement.dart';
import '../l10n/app_strings.dart';
import '../screens/events/events_widgets.dart' show monthShort;
import '../theme/app_theme.dart';

const _likeBlue = Color(0xFF3B82F6);
const _viewPurple = Color(0xFF6D5BD0);
const _commentAmber = Color(0xFFF5A524);
const _dateRed = Color(0xFF9B1C1C);

/// The day a Manna belongs to.
DateTime _dayOf(Manna m) {
  if (m.date != null) return m.date!;
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: m.daysAgo));
}

String _weekday(BuildContext context, DateTime d) =>
    tr(context, 'wdshort_${d.weekday}');

/// "Tue / 27 Oct / 2026", then the likes, views and comments of the Manna and who wrote it.
/// The like can be tapped. Only shown when the app is talking to the server (the sample content has none).
class EngagementBar extends StatelessWidget {
  const EngagementBar({super.key, required this.manna});

  final Manna manna;

  @override
  Widget build(BuildContext context) {
    if (!liveApi) return const SizedBox.shrink();
    final e = engagementOf(manna);
    final day = _dayOf(manna);
    return ListenableBuilder(
      listenable: e,
      builder: (context, _) => Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _weekday(context, day),
                style: const TextStyle(
                  color: _dateRed,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${day.day} ${monthShort(context, day.month)}',
                style: const TextStyle(
                  color: _dateRed,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${day.year}',
                style: const TextStyle(
                  color: _dateRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: AppColors.border,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: e.toggleLike,
                      child: _Stat(
                        icon: e.liked
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        color: _likeBlue,
                        count: e.likes,
                      ),
                    ),
                    const SizedBox(width: 18),
                    _Stat(
                      icon: Icons.visibility_outlined,
                      color: _viewPurple,
                      count: e.views,
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showMannaComments(context, manna),
                      child: _Stat(
                        icon: Icons.chat_bubble,
                        color: _commentAmber,
                        count: e.commentCount,
                      ),
                    ),
                  ],
                ),
                if (manna.writer.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    manna.writer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The top of a Manna page: the day on the left ("Wed / 04 / Nov"), the title and the writer beside it.
class MannaDateTitle extends StatelessWidget {
  const MannaDateTitle({super.key, required this.manna, required this.title});

  final Manna manna;
  final String title;

  @override
  Widget build(BuildContext context) {
    final day = _dayOf(manna);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 54,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _weekday(context, day),
                style: const TextStyle(
                  color: _dateRed,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                day.day.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: _dateRed,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                monthShort(context, day.month),
                style: const TextStyle(
                  color: _dateRed,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (manna.writer.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  manna.writer,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14.5,
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

/// Likes and comments on the left, the views on the right. Only shown when talking to the server.
class MannaStatsRow extends StatelessWidget {
  const MannaStatsRow({super.key, required this.manna});

  final Manna manna;

  @override
  Widget build(BuildContext context) {
    if (!liveApi) return const SizedBox.shrink();
    final e = engagementOf(manna);
    return ListenableBuilder(
      listenable: e,
      builder: (context, _) => Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: e.toggleLike,
            child: _Stat(
              icon: e.liked ? Icons.thumb_up : Icons.thumb_up_outlined,
              color: _likeBlue,
              count: e.likes,
            ),
          ),
          const SizedBox(width: 18),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showMannaComments(context, manna),
            child: _Stat(
              icon: Icons.chat_bubble,
              color: _commentAmber,
              count: e.commentCount,
            ),
          ),
          const Spacer(),
          _Stat(
            icon: Icons.visibility_outlined,
            color: _viewPurple,
            count: e.views,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.count});

  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 6),
      Text(
        '$count',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF55576F),
        ),
      ),
    ],
  );
}

/// Opens the comments of a Manna in a sheet that slides up (drag it down to close), like Instagram:
/// the comments scroll in the middle and the box to write one stays at the bottom, above the keyboard.
Future<void> showMannaComments(BuildContext context, Manna manna) {
  if (!liveApi) return Future.value();
  final e = engagementOf(manna);
  e.refresh(); // the newest comments, and fresh counts
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _CommentsSheet(engagement: e),
  );
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.engagement});

  final MannaEngagement engagement;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _when(BuildContext context, DateTime d) {
    final ago = DateTime.now().difference(d);
    if (ago.inMinutes < 1) return tr(context, 'today');
    if (ago.inHours < 1) return '${ago.inMinutes} ${tr(context, 'unit_min')}';
    String two(int n) => n.toString().padLeft(2, '0');
    if (ago.inHours < 24) return '${two(d.hour)}:${two(d.minute)}';
    return '${d.day} ${monthShort(context, d.month)}';
  }

  Future<void> _post() async {
    final value = _text.text.trim();
    if (value.isEmpty || widget.engagement.posting) return;
    if (await widget.engagement.post(value)) _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engagement;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        // Most of the screen, like Instagram's comments.
        height: MediaQuery.of(context).size.height * 0.78,
        child: ListenableBuilder(
          listenable: e,
          builder: (context, _) => Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8D8E2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                tr(context, 'manna_comments'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: !e.loaded && e.error == null
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : e.comments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            e.error ?? tr(context, 'manna_comments_none'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                        itemCount: e.comments.length,
                        itemBuilder: (_, i) => _CommentRow(
                          comment: e.comments[i],
                          when: _when(context, e.comments[i].at),
                          onRemove: () => e.remove(e.comments[i]),
                        ),
                      ),
              ),
              if (e.error != null && e.comments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Text(
                    e.error!,
                    style: const TextStyle(
                      color: Color(0xFFE5334B),
                      fontSize: 12.5,
                    ),
                  ),
                ),
              const Divider(height: 1, color: AppColors.border),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _text,
                          focusNode: _focus,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 500,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: tr(context, 'manna_comment_hint'),
                            counterText: '',
                            filled: true,
                            fillColor: AppColors.tint,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      e.posting
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: _text.text.trim().isEmpty
                                  ? null
                                  : _post,
                              child: Text(
                                tr(context, 'manna_comment_post'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.when,
    required this.onRemove,
  });

  final MannaComment comment;
  final String when;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.tint,
          child: Text(
            comment.author.isEmpty ? '?' : comment.author[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.magenta,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: comment.author,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: '  $when',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                comment.text,
                style: const TextStyle(fontSize: 14.5, height: 1.4),
              ),
            ],
          ),
        ),
        if (comment.mine)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: tr(context, 'manna_comment_delete'),
            onPressed: onRemove,
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.muted,
            ),
          ),
      ],
    ),
  );
}
