import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/me_data.dart';
import '../../data/noahgram_data.dart';
import '../../data/profile_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../events/events_widgets.dart' show fullDate, monthShort;
import '../jodie/jodie_widgets.dart' show toast;
import '../noahgram/noahgram_widgets.dart' show agoText;
import '../registration/uploads.dart' show pickPhoto;
import 'sub_page.dart';

const _returnedBg = Color(0xFFFDE7EA);
const _returnedFg = Color(0xFFD6334B);

class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // The office may have approved a new photo since the app last asked.
    profile.refresh();
  }

  /// Live mode: pick a picture, send it, and wait for the office. The current photo stays until then.
  Future<void> _change() async {
    if (_sending) return;
    final picked = await pickPhoto(context);
    if (picked == null || !mounted) return;
    if (!picked.ok) {
      toast(context, tr(context, picked.errorKey ?? 'reg_err_file_read'));
      return;
    }
    setState(() => _sending = true);
    try {
      await profile.requestPhoto(picked.path!, picked.name ?? 'photo.jpg');
      if (mounted) toast(context, tr(context, 'ph_live_sent'));
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([meState, noahgram, profile]),
      builder: (context, _) {
        final livePending = profile.pendingFor('photo');
        final pending = meState.pendingPhoto;
        final hoursAgo = pending == null
            ? 0
            : DateTime.now().difference(pending.at).inHours;
        final photoRequests = profile.requests
            .where((r) => r.fieldId == 'photo')
            .toList();
        return SubPage(
          title: tr(context, 'me2_photo'),
          subtitle: tr(context, 'ph_sub'),
          children: [
            WhiteCard(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  _PhotoBox(
                    size: 104,
                    radius: 32,
                    fileId: liveApi ? profile.photoId : null,
                    initials: noahgram.me.initials,
                    fontSize: 36,
                  ),
                  const SizedBox(height: 14),
                  if (liveApi && livePending != null) ...[
                    _Pill(
                      text: tr(context, 'me2_in_review'),
                      colors: StatusPill.soon,
                    ),
                    const SizedBox(height: 12),
                    _PhotoBox(
                      size: 64,
                      radius: 20,
                      fileId: livePending.newValue,
                      initials: noahgram.me.initials,
                      fontSize: 22,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'ph_live_waiting'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ] else if (!liveApi && pending != null)
                    _Pill(
                      text: tr(
                        context,
                        'ph_review_pill',
                        args: {'when': agoText(context, hoursAgo)},
                      ),
                      colors: StatusPill.soon,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  if (liveApi) {
                    _change();
                    return;
                  }
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
                        _sending ? '...' : tr(context, 'ph_upload'),
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
            if (liveApi && photoRequests.isNotEmpty) ...[
              const SizedBox(height: 22),
              SectionTitle(title: tr(context, 'ph_history')),
              const SizedBox(height: 12),
              WhiteCard(
                child: Column(
                  children: [
                    for (final (i, r) in photoRequests.indexed) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.border),
                      _RequestRow(request: r),
                    ],
                  ],
                ),
              ),
            ] else if (!liveApi) ...[
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
          ],
        );
      },
    );
  }
}

/// A member's picture from the server, or their initials when there is none.
class _PhotoBox extends StatelessWidget {
  const _PhotoBox({
    required this.size,
    required this.radius,
    required this.fileId,
    required this.initials,
    required this.fontSize,
  });

  final double size;
  final double radius;
  final String? fileId;
  final String initials;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: const Color(0xFFA719C8),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final id = fileId;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: id == null || id.isEmpty
            ? fallback
            : Image.network(
                api.fileUrl(id),
                headers: api.authHeaders,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.colors});

  final String text;
  final (Color, Color) colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: colors.$1,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: colors.$2,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// One photo the member asked to change to, and what the office decided.
class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final ChangeRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final (String sub, (Color, Color) colors) = switch (r.status) {
      RequestStatus.pending => (
        tr(context, 'ph_live_waiting_short'),
        StatusPill.soon,
      ),
      RequestStatus.approved => (
        tr(context, 'ph_live_approved'),
        StatusPill.booked,
      ),
      RequestStatus.rejected => (
        tr(context, 'ph_live_returned'),
        (_returnedBg, _returnedFg),
      ),
    };
    final when = r.at;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _PhotoBox(
            size: 46,
            radius: 15,
            fileId: r.newValue,
            initials: noahgram.me.initials,
            fontSize: 16,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr(context, 'ph_portrait')} · ${monthShort(context, when.month)} ${when.year}',
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
          StatusPill(
            text: tr(context, 'pf_st_${r.status.name}'),
            background: colors.$1,
            foreground: colors.$2,
          ),
        ],
      ),
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
