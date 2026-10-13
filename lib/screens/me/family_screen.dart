import 'package:flutter/material.dart';

import '../../data/ministry_data.dart';
import '../../data/noahgram_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../jodie/jodie_widgets.dart' show toast;
import '../main_shell.dart' show ShellScope;
import 'sub_page.dart';

class _Member {
  const _Member(this.name, this.relKey, {this.since, this.guardian});

  final String name;
  final String relKey;
  final int? since;
  final String? guardian;

  bool get minor => guardian != null;

  String get initials => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();
}

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: noahgram,
      builder: (context, _) {
        final me = noahgram.me.name;
        final last = me.split(' ').last;
        final spouse = 'Rebecca $last';
        final members = [
          _Member(me, 'fm_you', since: ministry.record.memberSince),
          _Member(spouse, 'fm_spouse', since: 2009),
          _Member('Hannah $last', 'fm_daughter', guardian: me),
          _Member('Ruth $last', 'fm_daughter', guardian: spouse),
        ];
        final rec = ministry.record;
        return SubPage(
          title: tr(context, 'me2_family'),
          subtitle: tr(context, 'fm_sub'),
          children: [
            WhiteCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconTile(icon: Icons.group_outlined),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(context, 'fm_household', args: {'name': last}),
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${tr(context, 'me2_members_linked', args: {'n': '${members.length}'})}'
                              ' · ${rec.cellArea} · ${tr(context, 'fm_cell', args: {'cell': rec.cell})}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 1,
                      minHeight: 5,
                      backgroundColor: AppColors.tint,
                      color: AppColors.magenta,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(context, 'fm_all_verified'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionTitle(
              title: tr(context, 'fm_linked'),
              action: '${tr(context, 'fm_add')} +',
              onAction: () => toast(
                context,
                '${tr(context, 'fm_add')} · ${tr(context, 'coming_soon')}',
              ),
            ),
            const SizedBox(height: 12),
            WhiteCard(
              child: Column(
                children: [
                  for (final (i, m) in members.indexed) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: m.minor
                                  ? const Color(0xFFF7E8F4)
                                  : const Color(0xFFA719C8),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              m.initials,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: m.minor
                                    ? const Color(0xFFB3641A)
                                    : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  m.minor
                                      ? tr(
                                          context,
                                          'fm_rel_guardian',
                                          args: {
                                            'rel': tr(context, m.relKey),
                                            'name': m.guardian!,
                                          },
                                        )
                                      : tr(
                                          context,
                                          'fm_rel_since',
                                          args: {
                                            'rel': tr(context, m.relKey),
                                            'y': '${m.since}',
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
                          StatusPill(
                            text: tr(
                              context,
                              m.minor ? 'fm_minor' : 'jd_verified',
                            ),
                            background: m.minor
                                ? StatusPill.past.$1
                                : StatusPill.booked.$1,
                            foreground: m.minor
                                ? StatusPill.past.$2
                                : StatusPill.booked.$2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionTitle(title: tr(context, 'fm_passes')),
            const SizedBox(height: 12),
            WhiteCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
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
                          tr(context, 'ev_sunday2'),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tr(
                            context,
                            'fm_passes_held',
                            args: {'n': '4', 's': 'C-14 – C-17'},
                          ),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ShellScope.maybeOf(context)?.selectSlot(3),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        tr(context, 'fm_view'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(
                tr(context, 'fm_pass_note'),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
