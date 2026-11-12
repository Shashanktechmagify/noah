import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/live_noahgram.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/insta_icon.dart';
import 'ng_pages.dart';
import 'ng_sheets.dart';
import 'ng_widgets.dart';

/// Noahgram for a member signed in to the server: feed, explore, reels and your own page.
/// Posts, likes, comments and views are real; there is no chat in Noahgram.
class LiveNoahgramScreen extends StatefulWidget {
  const LiveNoahgramScreen({super.key});

  @override
  State<LiveNoahgramScreen> createState() => _LiveNoahgramScreenState();
}

class _LiveNoahgramScreenState extends State<LiveNoahgramScreen> {
  int _tab = 0;
  // Tabs open the first time they are shown, so a member who only reads the feed does not load the rest.
  final _opened = <int>{0};

  static const _icons = [
    (Icons.home_outlined, Icons.home),
    (Icons.search, Icons.search),
    (Icons.smart_display_outlined, Icons.smart_display),
  ];

  @override
  void initState() {
    super.initState();
    liveNoahgram.loadMe();
    liveNoahgram.addListener(_tellError);
  }

  @override
  void dispose() {
    liveNoahgram.removeListener(_tellError);
    super.dispose();
  }

  /// Something the member did (a like, a follow) did not go through: say so once.
  void _tellError() {
    final message = liveNoahgram.lastError;
    if (message == null || !mounted) return;
    liveNoahgram.lastError = null;
    ngSay(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                  const InstaIcon(size: 26, color: Color(0xFF8E3BB8)),
                  const SizedBox(width: 10),
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
                    onPressed: () => showNgCreateSheet(context),
                    icon: const Icon(
                      Icons.add_box_outlined,
                      color: AppColors.ink,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            _TabBar(
              index: _tab,
              onSelect: (i) => setState(() {
                _tab = i;
                _opened.add(i);
              }),
              icons: _icons,
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  const NgFeedView(),
                  _opened.contains(1)
                      ? const NgExploreView()
                      : const SizedBox.shrink(),
                  _opened.contains(2)
                      ? NgReelsView(visible: _tab == 2)
                      : const SizedBox.shrink(),
                  _opened.contains(3)
                      ? const NgProfileView(memberId: 'me', bottomPadding: 110)
                      : const SizedBox.shrink(),
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
                                  listenable: liveNoahgram,
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
                                    child: NgAvatar(
                                      author:
                                          liveNoahgram.me?.author ??
                                          const NgAuthor(id: '0', name: 'Me'),
                                      size: 24,
                                    ),
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
