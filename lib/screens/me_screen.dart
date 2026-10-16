import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/me_data.dart';
import '../data/ministry_data.dart';
import '../data/noahgram_data.dart';
import '../data/profile_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import 'login_screen.dart';
import 'main_shell.dart' show ShellScope;
import 'me/drive_screen.dart';
import 'me/family_screen.dart';
import 'me/identity_screen.dart';
import 'me/language_screen.dart';
import 'me/location_screen.dart';
import 'me/messages_screen.dart';
import 'me/notifications_screen.dart';
import 'me/profile_info_screen.dart';
import 'me/profile_photo_screen.dart';
import 'me/rewards_screen.dart';
import 'me/store_screen.dart';
import 'me/terms_screen.dart';
import 'menu_sheet.dart' show kMenuItems;

/// Nav slot of the Jodie tab (see `main_shell.dart`).
const _jodieSlot = 4;

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  /// Opens a page inside the Me tab (the bottom bar stays visible).
  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  void _signOut(BuildContext context) {
    if (liveApi) api.logout();
    // The root navigator, so the login page replaces the whole app shell.
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([noahgram, ministry, meState, profile]),
      builder: (context, _) {
        final me = noahgram.me;
        final rec = ministry.record;
        final unread = ministry.unreadTotal;
        final shell = ShellScope.maybeOf(context);
        final lang = AppLocale.of(context).lang;
        final reviewing = meState.pendingPhoto != null;
        return PageScaffold(
          title: me.name,
          subtitle: tr(
            context,
            'me2_member_since',
            args: {
              'year': '${rec.memberSince}',
              'place': rec.place,
              'cell': rec.cell,
            },
          ),
          leadingIcon: Icons.settings_outlined,
          onLeading: () => _open(context, const LanguageScreen()),
          children: [
            // Pastor / cell leader / family
            WhiteCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Fact(
                          label: tr(context, 'me2_pastor'),
                          value: ministry.pastor.name,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => openMinistryChat(context, ministry.pastor),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.buttonGradient,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tr(context, 'me2_chat_pastor'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _Fact(
                      label: tr(context, 'me2_cell_leader'),
                      value: '${ministry.leader.name} · ${rec.cellArea}',
                    ),
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _Fact(
                      label: tr(context, 'me2_family'),
                      value: tr(
                        context,
                        'me2_members_linked',
                        args: {'n': '${rec.familyLinked}'},
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (profile.missingRequired > 0) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _open(context, const ProfileInfoScreen()),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEBD3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFC2620A),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr(
                            context,
                            'pf_banner',
                            args: {'n': '${profile.missingRequired}'},
                          ),
                          style: const TextStyle(
                            color: Color(0xFFC2620A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFFC2620A)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),

            SectionTitle(title: tr(context, 'me2_record')),
            const SizedBox(height: 12),
            _Group(
              rows: [
                _Row(
                  icon: Icons.badge_outlined,
                  title: tr(context, 'pf_title'),
                  subtitle: tr(context, 'pf_row_sub'),
                  pill: profile.missingRequired > 0
                      ? _Pill(
                          tr(
                            context,
                            'pf_n_missing',
                            args: {'n': '${profile.missingRequired}'},
                          ),
                          StatusPill.soon,
                        )
                      : null,
                  onTap: () => _open(context, const ProfileInfoScreen()),
                ),
                _Row(
                  icon: Icons.group_outlined,
                  title: tr(context, 'me2_family'),
                  subtitle: tr(
                    context,
                    'me2_family_sub',
                    args: {'n': '${rec.familyLinked}'},
                  ),
                  onTap: () => _open(context, const FamilyScreen()),
                ),
                _Row(
                  icon: Icons.flag_outlined,
                  title: tr(context, 'me2_location'),
                  subtitle: meState.location.name,
                  onTap: () => _open(context, const LocationScreen()),
                ),
                _Row(
                  icon: Icons.person_outline,
                  title: tr(context, 'me2_photo'),
                  subtitle: tr(
                    context,
                    reviewing ? 'me2_in_review' : 'ph_approved',
                  ),
                  pill: reviewing
                      ? _Pill(tr(context, 'me2_review'), StatusPill.soon)
                      : null,
                  onTap: () => _open(context, const ProfilePhotoScreen()),
                ),
                _Row(
                  icon: Icons.shield_outlined,
                  title: tr(context, 'me2_identity'),
                  subtitle: tr(context, 'me2_identity_sub'),
                  pill: _Pill(
                    tr(
                      context,
                      'me2_of',
                      args: {
                        'a': '${meState.identityDone}',
                        'b': '${MeState.identityTotal}',
                      },
                    ),
                    meState.identityDone == MeState.identityTotal
                        ? StatusPill.booked
                        : StatusPill.soon,
                  ),
                  onTap: () => _open(context, const IdentityScreen()),
                ),
                _Row(
                  icon: Icons.grid_view_rounded,
                  title: tr(context, 'me2_everything'),
                  subtitle: tr(
                    context,
                    'me2_everything_sub',
                    args: {'n': '${kMenuItems.length}'},
                  ),
                  onTap: () => shell?.openMenu(),
                ),
                _Row(
                  icon: Icons.chat_bubble_outline,
                  title: tr(context, 'me2_messages'),
                  subtitle: tr(context, 'me2_messages_sub'),
                  pill: unread > 0
                      ? _Pill(
                          tr(context, 'me2_new', args: {'n': '$unread'}),
                          StatusPill.book,
                        )
                      : null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MessagesScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            SectionTitle(title: tr(context, 'me2_more')),
            const SizedBox(height: 12),
            _Group(
              rows: [
                _Row(
                  icon: Icons.favorite_border,
                  title: 'Jodie',
                  subtitle: tr(context, 'me2_jodie_sub'),
                  pill: _Pill(tr(context, 'me2_open'), StatusPill.book),
                  onTap: () => shell?.selectSlot(_jodieSlot),
                ),
                _Row(
                  icon: Icons.folder_outlined,
                  title: tr(context, 'me2_drive'),
                  subtitle: tr(context, 'me2_drive_sub'),
                  onTap: () => _open(context, const DriveScreen()),
                ),
                _Row(
                  icon: Icons.shopping_cart_outlined,
                  title: tr(context, 'me2_store'),
                  subtitle: tr(context, 'me2_store_sub'),
                  onTap: () => _open(context, const StoreScreen()),
                ),
                _Row(
                  icon: Icons.currency_rupee,
                  title: tr(context, 'me2_rewards'),
                  subtitle: tr(context, 'me2_rewards_sub'),
                  onTap: () => _open(context, const RewardsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 22),

            SectionTitle(title: tr(context, 'me_settings')),
            const SizedBox(height: 12),
            _Group(
              rows: [
                _Row(
                  icon: Icons.language,
                  title: tr(context, 'me_language'),
                  subtitle: lang.native,
                  onTap: () => _open(context, const LanguageScreen()),
                ),
                _Row(
                  icon: Icons.notifications_none,
                  title: tr(context, 'me_notifications'),
                  subtitle: tr(context, 'me2_notif_sub'),
                  onTap: () => _open(context, const NotificationsScreen()),
                ),
                _Row(
                  icon: Icons.description_outlined,
                  title: tr(context, 'me2_terms'),
                  subtitle: tr(context, 'me2_terms_sub'),
                  onTap: () => _open(context, const TermsScreen()),
                ),
                _Row(
                  icon: Icons.logout,
                  title: tr(context, 'me2_logout'),
                  subtitle: tr(context, 'me2_logout_sub'),
                  destructive: true,
                  onTap: () => _signOut(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.colors);

  final String text;
  final (Color, Color) colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _Group extends StatelessWidget {
  const _Group({required this.rows});

  final List<_Row> rows;

  @override
  Widget build(BuildContext context) => WhiteCard(
    child: Column(
      children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.border),
          r,
        ],
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.pill,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? pill;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            destructive
                ? Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: AppColors.muted,
                      size: 24,
                    ),
                  )
                : IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: destructive
                          ? const Color(0xFFD6334B)
                          : AppColors.ink,
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
            pill ??
                (destructive
                    ? const SizedBox.shrink()
                    : const Icon(
                        Icons.chevron_right,
                        color: AppColors.ink,
                        size: 20,
                      )),
          ],
        ),
      ),
    );
  }
}
