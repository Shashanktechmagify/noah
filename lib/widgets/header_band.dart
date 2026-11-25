import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'hex_pattern.dart';

/// The purple honeycomb band behind page headers. It follows [controller], so
/// it scrolls away with the content instead of staying fixed under it.
/// Must be a direct child of a [Stack], placed beneath the scrollable.
class HeaderBand extends StatelessWidget {
  const HeaderBand({super.key, required this.controller, this.height = 150});

  final ScrollController controller;

  /// Height below the status bar.
  final double height;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final offset = controller.hasClients ? controller.offset : 0.0;
        return Positioned(
          top: offset < 0 ? 0.0 : -offset,
          left: 0,
          right: 0,
          height: top + height,
          child: Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: const HexPattern(),
          ),
        );
      },
    );
  }
}

/// A strip the height of the status bar, in the page's own colour, that appears once the purple band has scrolled off the top:
/// content that scrolls up no longer runs under the clock and the battery (it looked like an overflow). While the band is
/// there the strip is not shown, so the band still reaches the top of the screen. Must be a direct child of a [Stack], above the
/// scrollable. [bandHeight] is the one given to the [HeaderBand] on the same [controller].
class StatusBarScrim extends StatelessWidget {
  const StatusBarScrim({
    super.key,
    required this.controller,
    this.bandHeight = 150,
  });

  final ScrollController controller;
  final double bandHeight;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    if (top <= 0) return const Positioned(top: 0, height: 0, child: SizedBox());
    final color = Theme.of(context).scaffoldBackgroundColor;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: top,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final offset = controller.hasClients ? controller.offset : 0.0;
            // The band leaves the status bar when the page has scrolled by its height plus the status bar; the strip
            // fades in over the last 30 pixels of that.
            final gone = top + bandHeight;
            final shown = ((offset - (gone - 30)) / 30).clamp(0.0, 1.0);
            return Opacity(
              key: const ValueKey('status-bar-scrim'),
              opacity: shown,
              child: ColoredBox(color: color),
            );
          },
        ),
      ),
    );
  }
}
