import 'package:flutter/material.dart';

import '../../data/me_data.dart';
import '../../data/noahgram_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../events/events_widgets.dart' show fullDate, monthShort;
import '../jodie/jodie_widgets.dart' show toast;
import '../noahgram/noahgram_widgets.dart' show agoText;
import 'sub_page.dart';

const _returnedBg = Color(0xFFFDE7EA);
const _returnedFg = Color(0xFFD6334B);

class ProfilePhotoScreen extends StatelessWidget {
  const ProfilePhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([meState, noahgram]),
      builder: (context, _) {
        final pending = meState.pendingPhoto;
        final hoursAgo = pending == null
            ? 0
            : DateTime.now().difference(pending.at).inHours;
        return SubPage(
          title: tr(context, 'me2_photo'),
          subtitle: tr(context, 'ph_sub'),
          children: [
            WhiteCard(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA719C8),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Text(
                      noahgram.me.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (pending != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: StatusPill.soon.$1,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        tr(
                          context,
                          'ph_review_pill',
                          args: {'when': agoText(context, hoursAgo)},
                        ),
                        style: TextStyle(
                          color: StatusPill.soon.$2,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    tr(context, 'ph_rules'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  meState.uploadPhoto();
                  toast(context, tr(context, 'ph_uploaded'));
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        tr(context, 'ph_upload'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SectionTitle(title: tr(context, 'ph_history')),
            const SizedBox(height: 12),
            WhiteCard(
              child: Column(
                children: [
                  for (final (i, p) in meState.photos.indexed) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.border),
                    _HistoryRow(entry: p),
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

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final PhotoEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = fullDate(context, entry.at);
    final (
      String sub,
      String pill,
      Color bg,
      Color fg,
    ) = switch (entry.status) {
      PhotoStatus.review => (
        tr(context, 'ph_awaiting', args: {'date': date}),
        tr(context, 'me2_in_review'),
        StatusPill.soon.$1,
        StatusPill.soon.$2,
      ),
      PhotoStatus.approved => (
        tr(
          context,
          'ph_approved_by',
          args: {'date': date, 'name': entry.by ?? ''},
        ),
        tr(context, 'ph_approved'),
        StatusPill.booked.$1,
        StatusPill.booked.$2,
      ),
      PhotoStatus.returned => (
        tr(context, 'ph_returned_why', args: {'date': date}),
        tr(context, 'ph_returned'),
        _returnedBg,
        _returnedFg,
      ),
    };
    return Padding(
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
              Icons.insert_drive_file_outlined,
              color: AppColors.ink,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr(context, entry.titleKey)} · '
                  '${monthShort(context, entry.at.month)} ${entry.at.year}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
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
          StatusPill(text: pill, background: bg, foreground: fg),
        ],
      ),
    );
  }
}
