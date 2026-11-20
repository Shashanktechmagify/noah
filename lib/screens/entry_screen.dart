import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/hex_pattern.dart';
import '../widgets/language_dropdown.dart';
import 'login_screen.dart';

/// The first page when nobody is signed in: a child (who signs in through a parent's mobile number) or a member
/// (everyone else). Two big square choices side by side, each a round icon with its name.
class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FD),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(22, top + 10, 14, 18),
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: Stack(
              children: [
                const Positioned.fill(child: HexPattern()),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(context, 'welcome_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const LanguageDropdown(),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr(context, 'entry_select'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: _Choice(
                            icon: Icons.child_care,
                            title: tr(context, 'entry_child'),
                            hint: tr(context, 'entry_child_hint'),
                            colors: const [
                              Color(0xFFFFB23F),
                              Color(0xFFF2780C),
                            ],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(child: true),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _Choice(
                            icon: Icons.groups_2_outlined,
                            title: tr(context, 'entry_members'),
                            hint: tr(context, 'entry_members_hint'),
                            colors: const [
                              Color(0xFFC72BE0),
                              Color(0xFF7A12B5),
                            ],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.hint,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 22, 10, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    ),
  );
}
