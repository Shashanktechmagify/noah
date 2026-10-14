import 'package:flutter/material.dart';

import '../../data/profile_data.dart';
import '../../data/registration_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hex_pattern.dart';
import '../events/events_widgets.dart' show fullDate;
import '../login_screen.dart';
import '../main_shell.dart';
import 'registration_flow.dart';
import 'registration_video.dart';

String _clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Shown after the video is submitted, until the office approves the member.
class RegistrationStatusScreen extends StatefulWidget {
  const RegistrationStatusScreen({super.key, this.showSuccess = false});

  /// Pops the "Successful" dialog once, right after the registration.
  final bool showSuccess;

  @override
  State<RegistrationStatusScreen> createState() =>
      _RegistrationStatusScreenState();
}

class _RegistrationStatusScreenState extends State<RegistrationStatusScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.showSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSuccess();
      });
    }
  }

  void _showSuccess() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialog) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: Stack(
              children: [
                const Positioned.fill(child: HexPattern()),
                Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
            child: Column(
              children: [
                Text(
                  tr(dialog, 'reg_success'),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(dialog, 'reg_success_body'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(dialog, 'reg_success_call', args: {'phone': kOfficePhone}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
            child: GestureDetector(
              onTap: () => Navigator.of(dialog).pop(),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  tr(dialog, 'reg_ok'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _signOut() =>
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );

  Future<void> _approve() async {
    registration.approve();
    profile.loadFromRegistration(registration);
    // Tell the member, using the number they registered with.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                tr(dialog, 'reg_approved_title'),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tr(
                  dialog,
                  'reg_approved_body',
                  args: {'phone': registration.phone},
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => Navigator.of(dialog).pop(),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    tr(dialog, 'reg_ok'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  void _returnVideo() {
    registration.returnVideo();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegistrationFlow(initialStep: 5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = registration;
    final idLabel = r.idType == null
        ? ''
        : tr(context, kIdTypes.firstWhere((t) => t.$1 == r.idType).$2);
    final rows = <(IconData, String, String, String, bool)>[
      (
        Icons.person_outline,
        tr(context, 'reg_row_details'),
        '${r.displayName}${r.phone.isEmpty ? '' : ' · ${r.phone}'}',
        '',
        true,
      ),
      (
        Icons.home_outlined,
        tr(context, 'reg_row_address'),
        '${r.city}, ${r.country}',
        '',
        true,
      ),
      (
        Icons.insert_drive_file_outlined,
        idLabel,
        tr(context, 'reg_uploaded'),
        '',
        true,
      ),
      (
        Icons.camera_alt_outlined,
        tr(context, 'reg_row_photo'),
        tr(context, 'reg_uploaded'),
        '',
        true,
      ),
      (
        Icons.check,
        tr(context, 'reg_s5'),
        tr(
          context,
          'reg_signed_on',
          args: {'date': fullDate(context, r.signedOn ?? DateTime.now())},
        ),
        '',
        true,
      ),
      (
        Icons.videocam_outlined,
        tr(context, 'reg_s6'),
        tr(
          context,
          'reg_row_video_sub',
          args: {'len': _clock(r.videoSeconds ?? 0)},
        ),
        '',
        true,
      ),
      (
        Icons.shield_outlined,
        tr(context, 'reg_row_office'),
        tr(context, 'reg_row_office_sub'),
        '',
        false,
      ),
      (
        Icons.lock_outline,
        tr(context, 'reg_row_access'),
        tr(context, 'reg_row_locked'),
        '',
        false,
      ),
    ];
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 200 + top,
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: Stack(
              children: [
                const Positioned.fill(child: HexPattern()),
                Padding(
                  padding: EdgeInsets.only(top: top),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          tr(context, 'reg_done_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            tr(context, 'reg_done_sub'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: AppColors.border),
                        _StatusRow(
                          icon: rows[i].$1,
                          title: rows[i].$2,
                          sub: rows[i].$3,
                          done: rows[i].$5,
                          // The video row opens the recording.
                          onTap: i == 5 ? () => showVideoDialog(context) : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'reg_enq').toUpperCase(),
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: spacing(context, 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Anitha Varghese · $kOfficePhone',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr(context, 'reg_enq_sub'),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr(context, 'reg_hours'),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    tr(context, 'reg_wait_note'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _signOut,
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      tr(context, 'me2_logout'),
                      style: const TextStyle(
                        color: Color(0xFF555770),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  tr(context, 'reg_proto').toUpperCase(),
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: spacing(context, 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                _ProtoButton(
                  label: tr(context, 'reg_sim_approve'),
                  onTap: _approve,
                ),
                const SizedBox(height: 8),
                _ProtoButton(
                  label: tr(context, 'reg_sim_return'),
                  onTap: _returnVideo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.done,
    this.onTap,
  });

  final VoidCallback? onTap;

  final IconData icon;
  final String title;
  final String sub;
  final bool done;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: done ? AppColors.tint : const Color(0xFFFDEBD3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              size: 20,
              color: done ? AppColors.magenta : const Color(0xFFC2620A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.play_circle_outline,
                color: AppColors.magenta,
                size: 22,
              ),
            ),
          if (done) const Icon(Icons.check, color: Color(0xFF1F8A4C), size: 20),
        ],
      ),
    ),
  );
}

class _ProtoButton extends StatelessWidget {
  const _ProtoButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.magenta),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.magenta,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
