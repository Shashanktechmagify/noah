import 'package:flutter/material.dart';

import '../../data/jodie_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../noahgram/noahgram_widgets.dart' show LookCanvas;
import 'jodie_widgets.dart';

/// Full profile of a Jodie member, with photos, details and why you match.
class JodieProfileScreen extends StatefulWidget {
  const JodieProfileScreen({
    super.key,
    required this.profile,
    this.onLike,
    this.onPass,
  });

  final JodieProfile profile;

  /// When set, like/pass buttons are shown at the bottom.
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  @override
  State<JodieProfileScreen> createState() => _JodieProfileScreenState();
}

class _JodieProfileScreenState extends State<JodieProfileScreen> {
  int _photo = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final compat = jodie.compat(p);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
                bottom: widget.onLike != null ? 110 : 30),
            children: [
              // Photos
              SizedBox(
                height: 430,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      itemCount: p.photos.length,
                      onPageChanged: (i) => setState(() => _photo = i),
                      itemBuilder: (_, i) => Stack(
                        fit: StackFit.expand,
                        children: [
                          LookCanvas(look: p.photos[i], showText: false),
                          Center(
                            child: Text(p.initials,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.28),
                                    fontSize: 130,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      top: MediaQuery.of(context).padding.top + 10,
                      child: Row(
                        children: [
                          for (var i = 0; i < p.photos.length; i++)
                            Expanded(
                              child: Container(
                                height: 3,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: i == _photo
                                      ? Colors.white
                                      : Colors.white38,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text('${p.name}, ${p.age}',
                              style: const TextStyle(
                                  fontSize: 23, fontWeight: FontWeight.w800)),
                        ),
                        if (p.verified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              color: Color(0xFF2E8BEA), size: 22),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 16, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text('${p.city} · ${p.congregation}',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 13.5)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Why you match
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.tint,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.favorite,
                                  color: AppColors.magenta, size: 18),
                              const SizedBox(width: 8),
                              Text(tr(context, 'jd_compat'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5)),
                              const Spacer(),
                              Text(
                                  tr(context, 'jd_match_pct',
                                      args: {'n': '${compat.score}'}),
                                  style: const TextStyle(
                                      color: AppColors.magenta,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: compat.score / 100,
                              minHeight: 6,
                              backgroundColor: Colors.white,
                              color: AppColors.magenta,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final r in compat.reasons)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  const Icon(Icons.check,
                                      size: 16, color: AppColors.magenta),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(reasonText(context, r),
                                        style: const TextStyle(fontSize: 13.5)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Heading(tr(context, 'jd_about')),
                    Text(p.bio, style: const TextStyle(fontSize: 14.5, height: 1.4)),
                    const SizedBox(height: 20),
                    _Heading(tr(context, 'jd_details')),
                    _DetailRow(Icons.work_outline, tr(context, 'jd_profession'),
                        p.profession),
                    _DetailRow(Icons.school_outlined, tr(context, 'jd_education'),
                        p.education),
                    _DetailRow(Icons.church_outlined, tr(context, 'me_church'),
                        p.congregation),
                    _DetailRow(
                        Icons.translate,
                        tr(context, 'jd_languages'),
                        p.languages.map(langNative).join(', ')),
                    const SizedBox(height: 20),
                    _Heading(tr(context, 'jd_interests')),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final k in p.interests)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: jodie.me.interests.contains(k)
                                    ? AppColors.magenta
                                    : AppColors.border,
                              ),
                              color: jodie.me.interests.contains(k)
                                  ? AppColors.tint
                                  : Colors.white,
                            ),
                            child: Text(tr(context, 'int_$k'),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => toast(context, tr(context, 'jd_reported')),
                        icon: const Icon(Icons.flag_outlined,
                            color: AppColors.muted, size: 18),
                        label: Text('${tr(context, 'jd_report')} ${p.firstName}',
                            style: const TextStyle(color: AppColors.muted)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 22,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    color: Colors.black38, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
          if (widget.onLike != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundAction(
                    icon: Icons.close,
                    color: kPink,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onPass?.call();
                    },
                  ),
                  const SizedBox(width: 28),
                  _RoundAction(
                    icon: Icons.favorite,
                    color: Colors.white,
                    background: AppColors.buttonGradient,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onLike?.call();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.magenta),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.background,
  });

  final IconData icon;
  final Color color;
  final Gradient? background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: background,
            color: background == null ? Colors.white : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 30),
        ),
      );
}
