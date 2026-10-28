import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../theme/app_theme.dart';

/// Text the office wrote in the admin console's editor: bold, italic, underline, strike-through,
/// sub/superscript, headings, lists, quotes and links. The server sends it as HTML limited to those
/// tags (it removes scripts and everything else), and nothing here runs JavaScript.
///
/// Older entries are plain text with no tags: they are shown as they are, line breaks kept.
class RichHtml extends StatelessWidget {
  const RichHtml(this.html, {super.key, this.style});

  final String html;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle(fontSize: 14.5, height: 1.5);
    if (!html.contains('<')) return Text(html, style: base);
    return HtmlWidget(
      html,
      textStyle: base,
      customStylesBuilder: (e) =>
          e.localName == 'a' ? {'color': '#A719C8'} : null,
      // No browser in the app: a tapped link is copied so it can be pasted where it can be opened.
      onTapUrl: (url) async {
        await Clipboard.setData(ClipboardData(text: url));
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(content: Text(url), behavior: SnackBarBehavior.floating),
            );
        }
        return true;
      },
    );
  }
}

/// A picture the office attached to an entry (a link). Nothing is shown if it cannot be loaded.
class EntryImage extends StatelessWidget {
  const EntryImage(this.url, {super.key});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          u,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  height: 180,
                  color: AppColors.tint,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
          errorBuilder: (_, _, _) {
            // Staff see why in a debug build: the link must be the picture file itself (JPG, PNG or WebP),
            // not a web page and not an SVG. Members just see nothing.
            if (!kDebugMode) return const SizedBox.shrink();
            debugPrint(
              '[image] cannot show $u (use a direct JPG / PNG / WebP link)',
            );
            return Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.tint,
              child: const Text(
                'Picture not shown: the link must be a direct JPG, PNG or WebP file.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            );
          },
        ),
      ),
    );
  }
}
