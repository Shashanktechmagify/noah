import 'package:flutter/material.dart';

import '../../data/me_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import 'sub_page.dart';

/// Where the member is counted; events, passes, transport and giving follow it.
class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  Future<void> _change(BuildContext context, LocationItem to) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          tr(dialog, 'lc_confirm_title'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text(tr(dialog, 'lc_confirm_body', args: {'name': to.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(
              tr(dialog, 'jd_cancel'),
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(
              tr(dialog, 'lc_confirm'),
              style: const TextStyle(
                color: AppColors.magenta,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) meState.setLocation(to);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: meState,
      builder: (context, _) {
        final current = meState.location;
        return SubPage(
          title: tr(context, 'me2_location'),
          subtitle: tr(context, 'lc_sub'),
          children: [
            WhiteCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      tr(context, 'lc_your'),
                      style: TextStyle(
                        color: AppColors.magenta,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: spacing(context, 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    current.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(context, 'lc_desc'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(context, 'lc_group', args: {'g': current.group}),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionTitle(title: tr(context, 'lc_change')),
            const SizedBox(height: 12),
            WhiteCard(
              child: Column(
                children: [
                  for (final (i, l) in MeState.locations.indexed) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.border),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: l == current ? null : () => _change(context, l),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            l == current
                                ? const IconTile(icon: Icons.flag_outlined)
                                : Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: AppColors.tint,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.flag_outlined,
                                      color: AppColors.muted,
                                      size: 21,
                                    ),
                                  ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.name,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tr(
                                      context,
                                      'lc_members',
                                      args: {
                                        'g': l.group,
                                        'n': groupDigits(l.members),
                                      },
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            l == current
                                ? StatusPill(
                                    text: tr(context, 'lang_current'),
                                    background: StatusPill.booked.$1,
                                    foreground: StatusPill.booked.$2,
                                  )
                                : const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.ink,
                                    size: 20,
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
