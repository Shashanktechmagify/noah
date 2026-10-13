import 'package:flutter/material.dart';

import '../data/noahgram_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import 'login_screen.dart';
import 'noahgram/noahgram_widgets.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  bool _notifications = true;

  void _signOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return ListenableBuilder(
      listenable: noahgram,
      builder: (context, _) => _buildPage(context, locale),
    );
  }

  Widget _buildPage(BuildContext context, LocaleController locale) {
    final me = noahgram.me;
    return PageScaffold(
      title: tr(context, 'nav_me'),
      subtitle: '+91 98765 43210',
      leadingIcon: Icons.person_outline,
      children: [
        // Profile card
        WhiteCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Avatar(person: me, size: 60, ring: 1),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: StatusPill.booked.$1,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_outlined,
                              size: 13, color: StatusPill.booked.$2),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(tr(context, 'me_verified'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: StatusPill.booked.$2,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Basic information
        SectionTitle(title: tr(context, 'me_info')),
        const SizedBox(height: 12),
        WhiteCard(
          child: Column(
            children: [
              _InfoRow(
                  icon: Icons.person_outline,
                  label: tr(context, 'me_name'),
                  value: me.name),
              const _Line(),
              _InfoRow(
                  icon: Icons.alternate_email,
                  label: 'Noahgram',
                  value: '@${me.handle}'),
              const _Line(),
              _InfoRow(
                  icon: Icons.phone_outlined,
                  label: tr(context, 'me_mobile'),
                  value: '+91 98765 43210'),
              const _Line(),
              _InfoRow(
                  icon: Icons.church_outlined,
                  label: tr(context, 'me_church'),
                  value: 'Karuna Sadan, Dadar'),
              const _Line(),
              _InfoRow(
                  icon: Icons.event_outlined,
                  label: tr(context, 'me_since'),
                  value: '2019'),
              const _Line(),
              _InfoRow(
                  icon: Icons.badge_outlined,
                  label: tr(context, 'me_id'),
                  value: 'KSM-004821'),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Language
        SectionTitle(title: tr(context, 'me_language')),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(tr(context, 'me_language_sub'),
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final lang in AppLang.values)
                _LanguageChip(
                  lang: lang,
                  selected: locale.lang == lang,
                  onTap: () => locale.value = lang,
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Settings
        SectionTitle(title: tr(context, 'me_settings')),
        const SizedBox(height: 12),
        WhiteCard(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const IconTile(icon: Icons.notifications_none),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(tr(context, 'me_notifications'),
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700)),
                    ),
                    Switch(
                      value: _notifications,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.magenta,
                      onChanged: (v) => setState(() => _notifications = v),
                    ),
                  ],
                ),
              ),
              const _Line(),
              _TapRow(
                icon: Icons.help_outline,
                label: tr(context, 'me_help'),
                onTap: () {},
              ),
              const _Line(),
              _TapRow(
                icon: Icons.logout,
                label: tr(context, 'me_signout'),
                destructive: true,
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.border);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.magenta),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Text(label,
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
            Expanded(
              flex: 6,
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFD6334B) : AppColors.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 21, color: destructive ? color : AppColors.magenta),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
            if (!destructive)
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final AppLang lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.buttonGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: selected ? Colors.transparent : AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.native,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.ink,
                )),
            if (lang != AppLang.en)
              Text(lang.english,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.muted,
                  )),
          ],
        ),
      ),
    );
  }
}
