import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/family_data.dart';
import '../../data/noahgram_data.dart';
import '../../data/profile_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_child_dialog.dart';
import '../../widgets/page_scaffold.dart';
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
    final sent = await showAddChildDialog(context);
    if (!sent || !mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(tr(context, 'add_child_sent'))));
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
          // A parent adds a child with the plus (the office checks it, then the child is registered from the Child section).
          actions: [
            if (liveApi && !api.isChild)
              GlassCircle(icon: Icons.add, onTap: _addChild),
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
                          ? '${tr(context, 'rel_${p.relation}')} · '
                                '${tr(context, 'fam_age', args: {'n': '${p.age}'})}'
                          : tr(context, 'rel_${p.relation}'),
                      soft: p.isKid,
                      photoUrl: p.photoUrl,
                      pill: p.isKid
                          ? _pill(tr(context, 'fm_minor'), StatusPill.past)
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            if (liveApi && familyState.requests.any((q) => q.kid)) ...[
              const SizedBox(height: 22),
              SectionTitle(title: tr(context, 'fm_children_req')),
              const SizedBox(height: 12),
              WhiteCard(
                child: Column(
                  children: [
                    for (final (i, q)
                        in familyState.requests
                            .where((q) => q.kid)
                            .indexed) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.border),
                      _row(
                        name: q.name,
                        subtitle: q.rejected && q.remark.isNotEmpty
                            ? q.remark
                            : tr(
                                context,
                                q.rejected
                                    ? 'fm_req_rejected'
                                    : q.pending
                                    ? 'fm_req_pending'
                                    : 'fm_req_approved',
                              ),
                        soft: true,
                        pill: _pill(
                          tr(
                            context,
                            q.rejected
                                ? 'fm_req_rejected_pill'
                                : q.pending
                                ? 'fm_req_pending_pill'
                                : 'fm_req_approved_pill',
                          ),
                          q.rejected
                              ? StatusPill.past
                              : q.pending
                              ? StatusPill.soon
                              : StatusPill.booked,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
