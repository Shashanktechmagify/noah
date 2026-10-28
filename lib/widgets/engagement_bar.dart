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
                    _Stat(
                      icon: Icons.chat_bubble,
                      color: _commentAmber,
                      count: e.commentCount,
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

/// The comments under a Manna: a box to write one, and what members have written.
class MannaComments extends StatefulWidget {
  const MannaComments({super.key, required this.manna});

  final Manna manna;

  @override
  State<MannaComments> createState() => _MannaCommentsState();
}

class _MannaCommentsState extends State<MannaComments> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _when(BuildContext context, DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.day} ${monthShort(context, d.month)}, ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _post(MannaEngagement e) async {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    FocusScope.of(context).unfocus();
    if (await e.post(value)) _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (!liveApi) return const SizedBox.shrink();
    final e = engagementOf(widget.manna);
    return ListenableBuilder(
      listenable: e,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Text(
              '${tr(context, 'manna_comments')} (${e.commentCount})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: tr(context, 'manna_comment_hint'),
                          counterText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    e.posting
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: tr(context, 'manna_comment_post'),
                            onPressed: () => _post(e),
                            icon: const Icon(
                              Icons.send_rounded,
                              color: AppColors.magenta,
                            ),
                          ),
                  ],
                ),
                if (e.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      e.error!,
                      style: const TextStyle(
                        color: Color(0xFFE5334B),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                if (e.loaded && e.comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      tr(context, 'manna_comments_none'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                for (final c in e.comments) ...[
                  const Divider(height: 22, color: AppColors.border),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.tint,
                        child: Text(
                          c.author.isEmpty ? '?' : c.author[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.magenta,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    c.author,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _when(context, c.at),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              c.text,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      if (c.mine)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: tr(context, 'manna_comment_delete'),
                          onPressed: () => e.remove(c),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
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
