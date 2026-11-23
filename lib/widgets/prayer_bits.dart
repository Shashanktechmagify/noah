import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// "5 min ago", "2 days ago"... for the prayer pages.
String prayerWhen(BuildContext context, DateTime? at) {
  if (at == null) return '';
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return tr(context, 'pw_now');
  if (d.inMinutes < 60) {
    return tr(context, 'pw_min', args: {'n': '${d.inMinutes}'});
  }
  if (d.inHours < 24) {
    return tr(context, 'pw_hour', args: {'n': '${d.inHours}'});
  }
  return tr(context, 'pw_day', args: {'n': '${d.inDays}'});
}

/// A small coloured label (a category, a status). [c] is a (background, text) pair, for example `StatusPill.book`.
class PrayerChip extends StatelessWidget {
  const PrayerChip(this.text, this.c, {super.key});

  final String text;
  final (Color, Color) c;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.$1,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: c.$2,
      ),
    ),
  );
}

/// A line of muted text for an empty list or a failed load.
class PrayerNote extends StatelessWidget {
  const PrayerNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 28, 32, 8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 13.5,
        height: 1.4,
      ),
    ),
  );
}
