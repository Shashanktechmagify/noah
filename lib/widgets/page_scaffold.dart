import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'header_band.dart';

/// Tab page with the purple honeycomb header band; [children] scroll beneath
/// the title row and overlap the band like on the home screen.
class PageScaffold extends StatefulWidget {
  const PageScaffold({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.leadingIcon,
    this.onLeading,
    this.actions = const [],
    this.bandHeight = 150,
    this.above,
    this.headerExtra,
    required this.children,
  });

  final String title;

  /// Left empty to show the title alone.
  final String subtitle;
  final IconData leadingIcon;

  /// Makes the leading circle a button (e.g. a back arrow).
  final VoidCallback? onLeading;

  /// Extra round buttons shown before the bell.
  final List<Widget> actions;

  /// Height of the purple band below the status bar.
  final double bandHeight;

  /// Shown above the header row (e.g. a "< Noah" pill).
  final Widget? above;

  /// Shown on the band below the header row (e.g. a progress bar or chips).
  final Widget? headerExtra;
  final List<Widget> children;

  @override
  State<PageScaffold> createState() => _PageScaffoldState();
}

class _PageScaffoldState extends State<PageScaffold> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        HeaderBand(controller: _controller, height: widget.bandHeight),
        ListView(
          controller: _controller,
          padding: EdgeInsets.only(top: top + 14, bottom: 120),
          children: [
            if (widget.above != null) ...[
              widget.above!,
              const SizedBox(height: 12),
            ],
            PageHeaderRow(
              title: widget.title,
              subtitle: widget.subtitle,
              leadingIcon: widget.leadingIcon,
              onLeading: widget.onLeading,
              actions: widget.actions,
            ),
            if (widget.headerExtra != null) ...[
              const SizedBox(height: 14),
              widget.headerExtra!,
            ],
            const SizedBox(height: 20),
            ...widget.children,
          ],
        ),
      ],
    );
  }
}

/// Leading circle, title (+ optional subtitle) and trailing buttons.
class PageHeaderRow extends StatelessWidget {
  const PageHeaderRow({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.leadingIcon,
    this.onLeading,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final VoidCallback? onLeading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        GlassCircle(icon: leadingIcon, onTap: onLeading),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final a in actions) ...[a, const SizedBox(width: 8)],
        const GlassCircle(icon: Icons.notifications_none),
      ],
    ),
  );
}

/// Translucent round button used on the purple header.
class GlassCircle extends StatelessWidget {
  const GlassCircle({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 21),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  action!,
                  style: const TextStyle(
                    color: AppColors.magenta,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.magenta,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// White rounded card with the soft border used across the app.
class WhiteCard extends StatelessWidget {
  const WhiteCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  final String text;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  static const book = (Color(0xFFF1E4F8), AppColors.magenta);
  static const booked = (Color(0xFFE1F3E7), Color(0xFF1F8A4C));
  static const soon = (Color(0xFFFDEBD3), Color(0xFFC2620A));
  static const past = (Color(0xFFECEAF5), AppColors.muted);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// Purple rounded-square icon used at the start of list rows.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: const Color(0xFFA719C8),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Icon(icon, color: Colors.white, size: 21),
  );
}
