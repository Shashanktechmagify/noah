import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../l10n/app_strings.dart';
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

/// Opens a picture on its own, full screen on black: pinch or double-tap to zoom, tap to hide the buttons.
void openImageViewer(BuildContext context, String url) =>
    openImageProviderViewer(context, NetworkImage(url));

/// The same viewer for a picture from anywhere (for example a file on the phone).
void openImageProviderViewer(BuildContext context, ImageProvider image) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => _ImageViewerPage(image: image),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _ImageViewerPage extends StatefulWidget {
  const _ImageViewerPage({required this.image});

  final ImageProvider image;

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  final _transform = TransformationController();
  Offset _tapAt = Offset.zero;
  bool _chrome = true;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_transform.value.getMaxScaleOnAxis() > 1.01) {
      _transform.value = Matrix4.identity();
      return;
    }
    const scale = 2.5;
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        -_tapAt.dx * (scale - 1),
        -_tapAt.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    // Without `expand` the stack would shrink to the close button and the picture would be drawn inside that.
    body: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _chrome = !_chrome),
            onDoubleTapDown: (d) => _tapAt = d.localPosition,
            onDoubleTap: _toggleZoom,
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 1,
              maxScale: 5,
              // The viewer gives its child no size of its own, so the picture is given the whole screen to fit in.
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height,
                child: Image(
                  image: widget.image,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                  errorBuilder: (_, _, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr(context, 'pf_doc_nopreview'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_chrome)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
      ],
    ),
  );
}

/// A picture the office attached to an entry (a link). Nothing is shown if it cannot be loaded.
/// Tapping it opens it full screen.
class EntryImage extends StatelessWidget {
  const EntryImage(this.url, {super.key});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => openImageViewer(context, u),
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
      ),
    );
  }
}
