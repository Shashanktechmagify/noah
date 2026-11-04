import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/family_data.dart';
import '../../data/noahgram_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/family_dialog.dart';
import '../../widgets/page_scaffold.dart';
import '../jodie/jodie_widgets.dart' show toast;
import '../main_shell.dart' show ShellScope;
import 'sub_page.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  @override
  void initState() {
    super.initState();
    // Always look again when the page opens: the office may have decided since.
    familyState.load();
  }

  Future<void> _add() async {
    final sent = await showFamilyDialog(context);
    if (sent && mounted) toast(context, tr(context, 'fam_sent'));
  }

  Future<void> _cancel(FamilyRequest r) async {
    try {
      await familyState.cancel(r.id);
      if (mounted) toast(context, tr(context, 'fam_cancelled'));
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  static const _red = (Color(0xFFFBE3E6), Color(0xFFC62840));

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
    required StatusPill pill,
    Widget? below,
    // A long status ("Approved. Linked when they join Noah") goes under the name, where it has the room.
    bool pillBelow = false,
  }) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                  if (pillBelow) ...[const SizedBox(height: 8), pill],
                ],
              ),
            ),
            if (!pillBelow) ...[const SizedBox(width: 8), pill],
          ],
        ),
        ?below,
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
        final last = me.split(' ').last;
        final people = familyState.people;
        final requests = familyState.requests;
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
                              tr(
                                context,
                                'fam_you_linked',
                                args: {'n': '${people.length}'},
                              ),
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
                  const SizedBox(height: 10),
                  Text(
                    tr(context, 'fam_office_note'),
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
              onAction: _add,
            ),
            const SizedBox(height: 12),
            WhiteCard(
              child: Column(
                children: [
                  _row(
                    name: me,
                    subtitle: tr(context, 'fm_you'),
                    soft: false,
                    pill: _pill(tr(context, 'jd_verified'), StatusPill.booked),
                  ),
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
                          : _pill(tr(context, 'jd_verified'), StatusPill.booked),
                    ),
                  ],
                ],
              ),
            ),
            if (people.isEmpty && requests.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  tr(context, 'fam_empty'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            if (requests.isNotEmpty) ...[
              const SizedBox(height: 22),
              SectionTitle(title: tr(context, 'fam_requests')),
              const SizedBox(height: 12),
              WhiteCard(
                child: Column(
                  children: [
                    for (final (i, r) in requests.indexed) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.border),
                      _row(
                        name: r.name,
                        subtitle: r.rejected && r.remark.isNotEmpty
                            ? '${tr(context, 'rel_${r.relation}')} · ${r.remark}'
                            : tr(context, 'rel_${r.relation}'),
                        soft: true,
                        pillBelow: true,
                        pill: r.rejected
                            ? _pill(tr(context, 'fam_rejected'), _red)
                            : _pill(
                                tr(
                                  context,
                                  r.waiting ? 'fam_waiting' : 'fam_pending',
                                ),
                                StatusPill.soon,
                              ),
                        below: r.pending
                            ? Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => _cancel(r),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      tr(context, 'fam_cancel'),
                                      style: const TextStyle(
                                        color: AppColors.magenta,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
