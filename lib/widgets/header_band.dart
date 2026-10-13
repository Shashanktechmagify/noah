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
