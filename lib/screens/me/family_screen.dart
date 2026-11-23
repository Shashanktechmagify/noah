import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/family_data.dart';
import '../../data/noahgram_data.dart';
import '../../data/profile_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_child_dialog.dart';
import '../../widgets/page_scaffold.dart';
import 'aadhaar_view_screen.dart';
import 'make_member_screen.dart';
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

  static const _titles = {'mr', 'mrs', 'ms', 'miss', 'dr', 'jr', 'master'};

  // "Mr Ayushi Jain" is AJ, not MA: a title in front of the name is not an initial.
  static String _initials(String name) => name
      .split(' ')
      .where(
        (p) =>
            p.isNotEmpty &&
            !_titles.contains(p.toLowerCase().replaceAll('.', '')),
      )
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  Widget _avatar(String initials, {required bool soft, String? photoUrl}) {
    final letters = Container(
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
    // The profile photo when there is one; the initials while it loads or when it cannot be shown.
    if (photoUrl == null) return letters;
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Image.network(
          photoUrl,
          headers: api.authHeaders,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => letters,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : letters,
        ),
      ),
    );
  }

  Widget _row({
    required String name,
    required String subtitle,
    required bool soft,
    String? photoUrl,
    StatusPill? pill,
    Widget? below,
  }) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        _avatar(_initials(name), soft: soft, photoUrl: photoUrl),
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
              if (below != null) ...[const SizedBox(height: 8), below],
            ],
          ),
        ),
        if (pill != null) ...[const SizedBox(width: 8), pill],
      ],
    ),
  );

  StatusPill _pill(String text, (Color, Color) colors) =>
      StatusPill(text: text, background: colors.$1, foreground: colors.$2);

  Future<void> _addChild() async {
    final name = await showAddChildDialog(context);
    if (name == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(tr(context, 'add_child_done', args: {'name': name})),
        ),
      );
  }

  /// Make member: not before 15 (a popup says so); from 15 the parents give the child's number and Aadhaar.
  Future<void> _makeMember(FamilyPerson kid) async {
    if (!kid.canMakeMember) {
      await showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(tr(d, 'fm_too_young_title')),
          content: Text(
            tr(
              d,
              'fm_too_young',
              args: {'name': kid.name.split(' ').first, 'age': '15'},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(),
              child: Text(tr(d, 'fm_ok')),
            ),
          ],
        ),
      );
      return;
    }
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => MakeMemberScreen(child: kid)));
  }

  /// Where a child stands on becoming a member: the line under the name, and the pill.
  (String?, StatusPill?) _memberState(FamilyPerson p) {
    final first = p.name.split(' ').first;
    switch (p.memberState) {
      case 'requested':
        return (
          tr(context, 'fm_ms_requested'),
          _pill(tr(context, 'fm_pill_checking'), StatusPill.soon),
        );
      case 'login':
        return (
          tr(context, 'fm_ms_login', args: {'name': first}),
          _pill(tr(context, 'fm_pill_login'), StatusPill.booked),
        );
      case 'waiting':
        return (
          tr(context, 'fm_ms_waiting'),
          _pill(tr(context, 'fm_pill_waiting'), StatusPill.soon),
        );
      case 'rejected':
        return (
          p.note.isNotEmpty ? p.note : tr(context, 'fm_ms_rejected'),
          _pill(tr(context, 'fm_pill_rejected'), StatusPill.past),
        );
      default:
        return (null, null);
    }
  }

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
          // A shorter purple band, so the headings sit on the white page.
          bandHeight: 84,
          // A parent adds a child with the plus (photo, name, age; the Aadhaar is optional).
          actions: [
            if (liveApi) GlassCircle(icon: Icons.add, onTap: _addChild),
          ],
          children: [
            SectionTitle(title: tr(context, 'fm_linked')),
            const SizedBox(height: 12),
            WhiteCard(
              child: Column(
                children: [
                  _row(
                    name: me,
                    subtitle: tr(context, 'fm_you'),
                    soft: false,
                    photoUrl: liveApi && (profile.photoId ?? '').isNotEmpty
                        ? api.mediaUrl(profile.photoId!)
                        : null,
                  ),
                  for (final p in people) ...[
                    const Divider(height: 1, color: AppColors.border),
                    _row(
                      name: p.name,
                      subtitle: p.isKid && p.age != null
                          ? [
                              '${tr(context, 'rel_${p.relation}')} · '
                                  '${tr(context, 'fam_age', args: {'n': '${p.age}'})}',
                              ?_memberState(p).$1,
                            ].join('\n')
                          : [
                              tr(context, 'rel_${p.relation}'),
                              if ((p.mobile ?? '').isNotEmpty) p.mobile!,
                              if ((p.email ?? '').isNotEmpty) p.email!,
                            ].join('\n'),
                      soft: p.isKid,
                      photoUrl: p.photoUrl,
                      pill: !p.isKid
                          ? null
                          : _memberState(p).$2 ??
                                _pill(tr(context, 'fm_minor'), StatusPill.past),
                      below: p.isKid && p.kidId != null
                          ? Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (p.memberState == 'none' ||
                                    p.memberState == 'rejected')
                                  OutlinedButton(
                                    onPressed: () => _makeMember(p),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.magenta,
                                      side: const BorderSide(
                                        color: AppColors.magenta,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: Text(tr(context, 'fm_make_member')),
                                  ),
                                if (p.aadhaarAdded)
                                  TextButton.icon(
                                    onPressed: () => openAadhaar(context, p),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      size: 17,
                                    ),
                                    label: Text(tr(context, 'aadhaar_view')),
                                  ),
                              ],
                            )
                          : null,
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
