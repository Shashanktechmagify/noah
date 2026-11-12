import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/manna_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// The videos and links the office attached to an entry. A YouTube video shows its picture with a play button; any
/// other link is a card with its address. A tap opens it in the YouTube app or the browser (nothing runs inside the app).
class EmbedCards extends StatelessWidget {
  const EmbedCards({super.key, required this.items});

  final List<EmbedMedia> items;

  Future<void> _open(BuildContext context, EmbedMedia m) async {
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(m.url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.url)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (final m in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: m.thumbnail != null
                  ? _video(context, m)
                  : _link(context, m),
            ),
        ],
      ),
    );
  }

  Widget _video(BuildContext context, EmbedMedia m) => GestureDetector(
    onTap: () => _open(context, m),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              m.thumbnail!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Colors.black87),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xAA000000)],
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 66,
              ),
            ),
            if (m.title != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: 10,
                child: Text(
                  m.title!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _link(BuildContext context, EmbedMedia m) => GestureDetector(
    onTap: () => _open(context, m),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            m.kind == 'vimeo' ? Icons.play_circle_outline : Icons.link,
            color: AppColors.magenta,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title ?? (m.host.isEmpty ? m.url : m.host),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  tr(context, 'embed_open'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new, size: 18, color: AppColors.muted),
        ],
      ),
    ),
  );
}
