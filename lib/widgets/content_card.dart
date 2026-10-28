import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'rich_html.dart';

/// Plain text of an entry for a short preview in a list: tags removed, spaces collapsed.
String plainPreview(String html) => html
    .replaceAll(
      RegExp(r'<br\s*/?>|</p>|</li>|</h[1-4]>', caseSensitive: false),
      ' ',
    )
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// A card for the "View all" lists (Manna, prayers, confessions): the picture the office attached across
/// the top, then the title and a line of details. Without a picture, a soft gradient with an icon stands in.
class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.title,
    this.image,
    this.meta = '',
    this.preview = '',
    this.badge,
    this.icon = Icons.menu_book_outlined,
    this.onTap,
    this.footer,
  });

  final String title;
  final String? image;

  /// Details under the title ("Hope · 3 min").
  final String meta;

  /// A line or two of the text.
  final String preview;

  /// A small label on the picture ("Today").
  final String? badge;
  final IconData icon;
  final VoidCallback? onTap;

  /// Shown at the bottom of the card (e.g. the likes, views and comments).
  final Widget? footer;

  Widget _placeholder() => Container(
    decoration: const BoxDecoration(gradient: AppColors.headerGradient),
    alignment: Alignment.center,
    child: Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 44),
  );

  @override
  Widget build(BuildContext context) {
    final url = image;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A0A55).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (url == null || url.isEmpty)
                      _placeholder()
                    else
                      Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                color: AppColors.tint,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                        // A link that is not a picture file shows the same stand-in as no picture.
                        errorBuilder: (_, _, _) => _placeholder(),
                      ),
                    if (badge != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: AppColors.magenta,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        meta,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 12),
                      footer!,
                    ],
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF55576F),
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full text of a prayer or confession, in a sheet that slides up from the card.
void showContentSheet(
  BuildContext context, {
  required String title,
  required String body,
  String date = '',
  String prayer = '',
  String? image,
  VoidCallback? onOpenManna,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EntryImage(image),
            if (date.isNotEmpty)
              Text(
                date,
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            RichHtml(body, style: const TextStyle(fontSize: 15, height: 1.5)),
            if (prayer.isNotEmpty) ...[
              const SizedBox(height: 14),
              RichHtml(
                prayer,
                style: const TextStyle(
                  color: Color(0xFF55576F),
                  fontSize: 14.5,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            // A prayer that ends a Daily Manna can open that Manna.
            if (onOpenManna != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(sheet).pop();
                  onOpenManna();
                },
                child: Text(tr(sheet, 'open_manna')),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
