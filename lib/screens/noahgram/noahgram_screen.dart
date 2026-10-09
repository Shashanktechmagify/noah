import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/noahgram_data.dart';
import '../../theme/app_theme.dart';
import 'explore_view.dart';
import 'feed_view.dart';
import 'noahgram_widgets.dart';
import 'profile_view.dart';
import 'reels_view.dart';

/// Instagram-style social tab: feed, explore, reels and your profile.
class NoahgramScreen extends StatefulWidget {
  const NoahgramScreen({super.key});

  @override
  State<NoahgramScreen> createState() => _NoahgramScreenState();
}

class _NoahgramScreenState extends State<NoahgramScreen> {
  int _tab = 0;

  static const _icons = [
    (Icons.home_outlined, Icons.home),
    (Icons.search, Icons.search),
    (Icons.smart_display_outlined, Icons.smart_display),
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // White header, so the status bar icons must be dark here.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(height: top),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Color(0xFF6A2DA8), Color(0xFFC13FBF)],
                    ).createShader(r),
                    child: const Text(
                      'Noahgram',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => showCreatePostSheet(context),
                    icon: const Icon(Icons.add_box_outlined,
                        color: AppColors.ink, size: 26),
                  ),
                  const IconButton(
                    onPressed: null,
                    icon: Icon(Icons.favorite_border,
                        color: AppColors.ink, size: 26),
                  ),
                  IconButton(
                    onPressed: () => showShareSheet(context),
                    icon: const Icon(Icons.send_outlined,
                        color: AppColors.ink, size: 25),
                  ),
                ],
              ),
            ),
            _TabBar(
              index: _tab,
              onSelect: (i) => setState(() => _tab = i),
              icons: _icons,
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  const FeedView(),
                  const ExploreView(),
                  const ReelsView(),
                  ProfileView(person: noahgram.me, bottomPadding: 110),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.index,
    required this.onSelect,
    required this.icons,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final List<(IconData, IconData)> icons;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: LayoutBuilder(
        builder: (context, c) {
          final slot = c.maxWidth / 4;
          return Stack(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(i),
                        child: Center(
                          child: i < 3
                              ? Icon(
                                  i == index ? icons[i].$2 : icons[i].$1,
                                  size: 26,
                                  color: i == index
                                      ? AppColors.ink
                                      : AppColors.muted,
                                )
                              : ListenableBuilder(
                                  listenable: noahgram,
                                  builder: (_, _) => Container(
                                    padding: const EdgeInsets.all(1.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: i == index
                                            ? AppColors.ink
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Avatar(
                                        person: noahgram.me, size: 24),
                                  ),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: index * slot,
                bottom: 0,
                width: slot,
                child: Container(height: 2, color: AppColors.ink),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Divider(height: 0.5, color: AppColors.border),
              ),
            ],
          );
        },
      ),
    );
  }
}
