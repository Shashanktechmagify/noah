import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class MenuItem {
  const MenuItem(this.id, this.icon, {this.key, this.brand});

  /// What the shell does when this is tapped (see `_MainShellState._onMenu`).
  final String id;
  final IconData icon;

  /// Translation key, or null when [brand] (a proper name) is shown as is.
  final String? key;
  final String? brand;

  String label(BuildContext context) =>
      key != null ? tr(context, key!) : brand!;
}

/// Every destination reachable from the Menu button. Entries without a screen
/// yet show "Coming soon".
const kMenuItems = [
  MenuItem('info', Icons.person_outline, key: 'mn_info'),
  MenuItem('notifications', Icons.notifications_none, key: 'me_notifications'),
  MenuItem('ebooks', Icons.menu_book_outlined, key: 'mn_ebooks'),
  MenuItem('chat', Icons.chat_bubble_outline, key: 'mn_chat'),
  MenuItem('donations', Icons.volunteer_activism_outlined, key: 'mn_donations'),
  MenuItem('podcast', Icons.podcasts, key: 'mn_podcast'),
  MenuItem('spotify', Icons.headphones_outlined, key: 'mn_spotify'),
  MenuItem('manna', Icons.auto_stories_outlined, key: 'manna_daily'),
  MenuItem('bible_school', Icons.school_outlined, key: 'mn_bible_school'),
  MenuItem('live', Icons.live_tv_outlined, key: 'mn_live'),
  MenuItem('events', Icons.event_outlined, key: 'nav_events'),
  MenuItem('praises', Icons.celebration_outlined, key: 'mn_praises'),
  MenuItem('noahtube', Icons.smart_display_outlined, brand: 'Noahtube'),
  MenuItem(
    'bible_study',
    Icons.import_contacts_outlined,
    key: 'mn_bible_study',
  ),
  MenuItem('gallery', Icons.photo_library_outlined, key: 'mn_gallery'),
  MenuItem('daily_prayer', Icons.self_improvement, key: 'mn_daily_prayer'),
  MenuItem('dream', Icons.nights_stay_outlined, key: 'mn_dream'),
  MenuItem(
    'confessions',
    Icons.record_voice_over_outlined,
    key: 'mn_confessions',
  ),
  MenuItem(
    'prayer_request',
    Icons.front_hand_outlined,
    key: 'mn_prayer_request',
  ),
  MenuItem('testimonials', Icons.format_quote, key: 'mn_testimonials'),
  MenuItem('tv', Icons.tv_outlined, key: 'mn_tv'),
  MenuItem('commentary', Icons.comment_bank_outlined, key: 'mn_commentary'),
  MenuItem('prayer_wall', Icons.view_quilt_outlined, key: 'mn_prayer_wall'),
  MenuItem('obituaries', Icons.local_florist_outlined, key: 'mn_obituaries'),
];

/// Bottom popup with the icon grid. Resolves to the tapped item's id.
Future<String?> showMenuSheet(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _MenuSheet(),
    );

class _MenuSheet extends StatefulWidget {
  const _MenuSheet();

  @override
  State<_MenuSheet> createState() => _MenuSheetState();
}

class _MenuSheetState extends State<_MenuSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = kMenuItems
        .where((i) => q.isEmpty || i.label(context).toLowerCase().contains(q))
        .toList();
    return SafeArea(
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.muted, size: 21),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: tr(context, 'ng_search'),
                        hintStyle: const TextStyle(color: AppColors.muted),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.92,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                // Alternate two shades of the app's purple.
                final color = i.isEven ? AppColors.purple : AppColors.magenta;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(item.id),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(item.icon, color: color, size: 29),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label(context),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
