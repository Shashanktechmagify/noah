import 'package:flutter/material.dart';

import '../../data/family_data.dart';
import '../../data/noahgram_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../main_shell.dart' show ShellScope;
import 'sub_page.dart';

// Adding a relative, the "your requests" list and the green "Verified" tag are switched off for now.
// The data layer (familyState, the dialog and the office endpoints) is kept, so they can come back.
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  @override
  void initState() {
    super.initState();
    familyState.load();
  }

  static String _initials(String name) => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  Widget _avatar(String initials, {required bool soft}) => Container(
    width: 46,
    height: 46,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: soft ? const Color(0xFFF7E8F4) : const Color(0xFFA719C8),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(
      initials,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: soft ? const Color(0xFFB3641A) : Colors.white,
      ),
    ),
  );

  Widget _row({
    required String name,
    required String subtitle,
    required bool soft,
    StatusPill? pill,
  }) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        _avatar(_initials(name), soft: soft),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (pill != null) ...[const SizedBox(width: 8), pill],
      ],
    ),
  );

  StatusPill _pill(String text, (Color, Color) colors) =>
      StatusPill(text: text, background: colors.$1, foreground: colors.$2);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([noahgram, familyState]),
      builder: (context, _) {
        final me = noahgram.me.name;
        final people = familyState.people;
        return SubPage(
          title: tr(context, 'me2_family'),
          subtitle: tr(context, 'fm_sub'),
          children: [
            SectionTitle(title: tr(context, 'fm_linked')),
            const SizedBox(height: 12),
            WhiteCard(
              child: Column(
                children: [
                  _row(name: me, subtitle: tr(context, 'fm_you'), soft: false),
                  for (final p in people) ...[
                    const Divider(height: 1, color: AppColors.border),
                    _row(
                      name: p.name,
                      subtitle: p.isKid && p.age != null
                          ? '${tr(context, 'rel_${p.relation}')} · '
                                '${tr(context, 'fam_age', args: {'n': '${p.age}'})}'
                          : tr(context, 'rel_${p.relation}'),
                      soft: p.isKid,
                      pill: p.isKid
                          ? _pill(tr(context, 'fm_minor'), StatusPill.past)
                          : null,
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
