import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../screens/me/sub_page.dart';
import 'page_scaffold.dart';

/// The card of a part of the app that is not built yet (the signed-in app shows this instead of made-up sample content).
class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => WhiteCard(
    padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
    child: Column(
      children: [
        Icon(icon, size: 48, color: AppColors.magenta),
        const SizedBox(height: 16),
        Text(
          tr(context, 'cs_title'),
          key: const ValueKey('coming-soon'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          tr(context, 'cs_body'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
      ],
    ),
  );
}

/// A tab (inside the bottom bar) that says "Coming soon".
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: title,
    leadingIcon: icon,
    bandHeight: 84,
    children: [_ComingSoonCard(icon: icon)],
  );
}

/// A page opened from a menu (with a back button) that says "Coming soon".
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SubPage(
    title: title,
    bandHeight: 84,
    children: [_ComingSoonCard(icon: icon)],
  );
}
