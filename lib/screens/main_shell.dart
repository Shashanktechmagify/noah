import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'events_screen.dart';
import 'home_screen.dart';
import 'jodie/jodie_screen.dart';
import 'me_screen.dart';
import 'noahgram/noahgram_screen.dart';
import 'noahtube_screen.dart';

class _NavItem {
  const _NavItem({required this.icon, this.key, this.brand});

  final IconData icon;

  /// Translation key, or null when [brand] (a proper name) is shown as is.
  final String? key;
  final String? brand;

  String label(BuildContext context) =>
      key != null ? tr(context, key!) : brand!;
}

const _items = [
  _NavItem(icon: Icons.home_outlined, key: 'nav_home'),
  _NavItem(icon: Icons.grid_view_rounded, brand: 'Noahgram'),
  _NavItem(icon: Icons.videocam_outlined, brand: 'Noahtube'),
  _NavItem(icon: Icons.calendar_today_outlined, key: 'nav_events'),
  _NavItem(icon: Icons.favorite_border, brand: 'Jodie'),
  _NavItem(icon: Icons.person_outline, key: 'nav_me'),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: [
          const HomeScreen(),
          const NoahgramScreen(),
          const NoahtubeScreen(),
          const EventsScreen(),
          const JodieScreen(),
          const MeScreen(),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        index: _tab,
        onSelect: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// White bar with a purple circle that glides to whichever tab is selected.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const _circle = 62.0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: 92 + bottom,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / _items.length;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 68 + bottom,
                child: Container(
                  padding: EdgeInsets.only(bottom: bottom),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purpleDeep.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onSelect(i),
                            // The selected item lives inside the circle.
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: i == index ? 0 : 1,
                              child: _BarItem(item: _items[i]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                left: index * slot + (slot - _circle) / 2,
                bottom: 18 + bottom,
                width: _circle,
                height: _circle,
                child: GestureDetector(
                  onTap: () => onSelect(index),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.buttonGradient,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.magenta.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(scale: anim, child: child),
                      ),
                      child: Column(
                        key: ValueKey(index),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_items[index].icon,
                              color: Colors.white, size: 22),
                          const SizedBox(height: 1),
                          SizedBox(
                            width: 50,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _items[index].label(context),
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({required this.item});

  final _NavItem item;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 22, color: const Color(0xFF3B3B4F)),
          const SizedBox(height: 3),
          Text(
            item.label(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B3B4F),
            ),
          ),
        ],
      );
}
