import 'package:flutter/material.dart';

import '../../data/me_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../events/events_widgets.dart' show fullDate;
import 'sub_page.dart';

/// Three one-time steps before Jodie opens: Aadhaar, consent, video.
class IdentityScreen extends StatelessWidget {
  const IdentityScreen({super.key});

  void _readFullText(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        tr(dialog, 'id_c_title'),
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: Text(tr(dialog, 'id_full_text')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: Text(
            tr(dialog, 'jd_done'),
            style: const TextStyle(
              color: AppColors.magenta,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: meState,
      builder: (context, _) {
        final done = meState.identityDone;
        return SubPage(
          title: tr(context, 'me2_identity'),
          subtitle: tr(context, 'id_sub'),
          bandHeight: 175,
          headerExtra: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                for (var i = 0; i < MeState.identityTotal; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i < done
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          children: [
            _Heading(tr(context, 'id_s1')),
            _StepCard(
              icon: Icons.shield_outlined,
              title: tr(
                context,
                'id_verified',
                args: {'last': MeState.aadhaarLast4},
              ),
              subtitle: tr(context, 'id_matched'),
              pill: _donePill(context),
            ),
            const SizedBox(height: 18),
            _Heading(tr(context, 'id_s2')),
            if (meState.consentDone)
              _StepCard(
                icon: Icons.insert_drive_file_outlined,
                title: tr(context, 'id_recorded'),
                subtitle: tr(
                  context,
                  'id_recorded_sub',
                  args: {'date': fullDate(context, meState.consentAt!)},
                ),
                pill: _donePill(context),
              )
            else
              WhiteCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'id_c_title'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'id_c_body'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr(context, 'id_c_version'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Button(
                      label: tr(context, 'id_agree'),
                      icon: Icons.check,
                      onTap: meState.agreeConsent,
                    ),
                    const SizedBox(height: 10),
                    _Button(
                      label: tr(context, 'id_read'),
                      secondary: true,
                      onTap: () => _readFullText(context),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            _Heading(tr(context, 'id_s3')),
            if (meState.videoDone)
              _StepCard(
                icon: Icons.videocam_outlined,
                title: tr(context, 'id_submitted'),
                subtitle: tr(
                  context,
                  'id_submitted_sub',
                  args: {'n': '${meState.videoSeconds}'},
                ),
                pill: StatusPill(
                  text: tr(context, 'me2_in_review'),
                  background: StatusPill.soon.$1,
                  foreground: StatusPill.soon.$2,
                ),
              )
            else
              WhiteCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.tint,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.videocam_outlined,
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
                                tr(context, 'id_v_title'),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tr(context, 'id_v_sub'),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Button(
                      label: tr(context, 'id_record'),
                      icon: Icons.videocam_outlined,
                      // Camera capture isn't wired yet: records a demo video.
                      onTap: meState.submitVideo,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                tr(context, 'id_footer'),
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

  Widget _donePill(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: StatusPill.booked.$1,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check, size: 14, color: StatusPill.booked.$2),
        const SizedBox(width: 4),
        Text(
          tr(context, 'jd_done'),
          style: TextStyle(
            color: StatusPill.booked.$2,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    ),
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pill,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget pill;

  @override
  Widget build(BuildContext context) => WhiteCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        IconTile(icon: icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
        const SizedBox(width: 8),
        pill,
      ],
    ),
  );
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    this.icon,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool secondary;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: secondary ? null : AppColors.buttonGradient,
        color: secondary ? AppColors.tint : null,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: secondary ? const Color(0xFF555770) : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}
