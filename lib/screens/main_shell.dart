import 'package:flutter/material.dart';

import '../widgets/insta_icon.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'events/events_screen.dart';
import 'home_screen.dart';
import '../widgets/prayer_dialog.dart';
import 'jodie/jodie_screen.dart';
import 'manna_screen.dart';
import 'menu_sheet.dart';
import 'me_screen.dart';
import 'noahgram/noahgram_screen.dart';
import 'noahtube_screen.dart';
import 'word_screens.dart';
import '../widgets/tab_navigator.dart';

class _NavItem {
  const _NavItem({this.icon, this.key, this.brand});

  final IconData? icon;

  /// Translation key, or null when [brand] (a proper name) is shown as is.
  final String? key;
  final String? brand;

  /// The icon, or the Instagram-style glyph for Noahgram.
  Widget glyph(Color color) => icon == null
      ? InstaIcon(size: 22, color: color)
      : Icon(icon, size: 22, color: color);

  String label(BuildContext context) =>
      key != null ? tr(context, key!) : brand!;
}

const _items = [
  _NavItem(icon: Icons.home_outlined, key: 'nav_home'),
  _NavItem(icon: Icons.apps_rounded, key: 'nav_menu'),
  _NavItem(brand: 'Noahgram'), // drawn as an Instagram-style glyph
  _NavItem(icon: Icons.calendar_today_outlined, key: 'nav_events'),
  _NavItem(icon: Icons.favorite_border, brand: 'Jodie'),
  _NavItem(icon: Icons.person_outline, key: 'nav_me'),
];

/// Nav slot of the Menu button. It opens a sheet instead of a page.
const _menuSlot = 1;

/// Which page each nav slot shows (Menu has none).
const _slotToPage = {0: 0, 2: 1, 3: 2, 4: 3, 5: 4};

/// The Noahtube page lives under Menu, so Menu stays highlighted for it.
const _noahtubePage = 5;
const _pageToSlot = [0, 2, 3, 4, 5, _menuSlot];

/// Lets pages inside the shell (e.g. Me) drive the shell: open the Menu popup
/// or jump to a tab by its nav slot (0 Home, 2 Noahgram, 3 Events, 4 Jodie, 5 Me).
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.openMenu,
    required this.selectSlot,
    required super.child,
  });

  final VoidCallback openMenu;
  final ValueChanged<int> selectSlot;

  static ShellScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _page = 0;
  bool _menuOpen = false;

  /// While the Menu sheet is open the circle sits on Menu.
  int get _slot => _menuOpen ? _menuSlot : _pageToSlot[_page];

  void _onSelect(int slot) {
    if (slot == _menuSlot) {
      _openMenu();
    } else {
      setState(() => _page = _slotToPage[slot]!);
    }
  }

  Future<void> _openMenu() async {
    setState(() => _menuOpen = true);
    final id = await showMenuSheet(context);
    if (!mounted) return;
    setState(() => _menuOpen = false);
    if (id == null) return;
    switch (id) {
      case 'noahtube' || 'live':
        setState(() => _page = _noahtubePage);
      case 'events':
        setState(() => _page = 2);
      case 'info' || 'notifications':
        setState(() => _page = 4);
      case 'manna':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const MannaScreen()));
      case 'ebooks':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const EbooksScreen()));
      case 'praises':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const PraisesScreen()));
      case 'daily_prayer':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DailyPrayersScreen()));
      case 'confessions':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const WordsOfFaithScreen()));
      case 'commentary':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const CommentaryScreen()));
      case 'prayer_request':
        showPrayerDialog(context);
      default:
        final item = kMenuItems.firstWhere((i) => i.id == id);
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${item.label(context)} · ${tr(context, 'coming_soon')}',
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      openMenu: _openMenu,
      selectSlot: _onSelect,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _page,
          children: const [
            HomeScreen(),
            NoahgramScreen(),
            TabNavigator(root: EventsScreen()),
            JodieScreen(),
            TabNavigator(root: MeScreen()),
            NoahtubeScreen(),
          ],
        ),
        bottomNavigationBar: _BottomBar(index: _slot, onSelect: _onSelect),
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
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
                          _items[index].glyph(Colors.white),
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
      item.glyph(const Color(0xFF3B3B4F)),
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
