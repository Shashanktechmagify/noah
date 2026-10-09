import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'hex_pattern.dart';

/// Tab page with the purple honeycomb header band; [children] scroll beneath
/// the title row and overlap the band like on the home screen.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        Container(
          height: top + 150,
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: const HexPattern(),
        ),
        ListView(
          padding: EdgeInsets.only(top: top + 14, bottom: 120),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _GlassCircle(icon: leadingIcon),
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
                    ),
                  ),
                  const _GlassCircle(icon: Icons.notifications_none),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ],
    );
  }
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            if (action != null)
              Row(
                children: [
                  Text(action!,
                      style: const TextStyle(
                          color: AppColors.magenta,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.magenta),
                ],
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
          color: const Color(0xFFA81BC4),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      );
}
