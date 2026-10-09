import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/jodie_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'discover_view.dart';
import 'jodie_widgets.dart';
import 'likes_view.dart';
import 'matches_view.dart';

/// Matchmaking tab: Discover (swipe), Likes, Matches + chat.
class JodieScreen extends StatefulWidget {
  const JodieScreen({super.key});

  @override
  State<JodieScreen> createState() => _JodieScreenState();
}

class _JodieScreenState extends State<JodieScreen> {
  int _tab = 0;

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
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Color(0xFF6A2DA8), Color(0xFFE5334B)],
                    ).createShader(r),
                    child: const Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.white, size: 26),
                        SizedBox(width: 6),
                        Text('Jodie',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  CreditChip(onTap: () => showCreditsSheet(context)),
                  IconButton(
                    onPressed: () => showFiltersSheet(context),
                    icon: const Icon(Icons.tune, color: AppColors.ink),
                  ),
                  IconButton(
                    onPressed: () => showMyProfileSheet(context),
                    icon: const Icon(Icons.person_outline, color: AppColors.ink),
                  ),
                  ListenableBuilder(
                    listenable: jodie,
                    builder: (_, _) => IconButton(
                      onPressed: () => showSubscribeSheet(context),
                      icon: Icon(
                        Icons.workspace_premium,
                        color: jodie.isPremium ? kGold : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Tabs(index: _tab, onSelect: (i) => setState(() => _tab = i)),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  DiscoverView(),
                  LikesView(),
                  MatchesView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final labels = [
      tr(context, 'jd_discover'),
      tr(context, 'jd_likes'),
      tr(context, 'jd_matches'),
    ];
    return SizedBox(
      height: 44,
      child: LayoutBuilder(
        builder: (context, c) {
          final slot = c.maxWidth / 3;
          return ListenableBuilder(
            listenable: jodie,
            builder: (context, _) {
              final badges = [
                0,
                jodie.likesYou.length,
                jodie.matches.where((m) => m.unread).length,
              ];
              return Stack(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onSelect(i),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(labels[i],
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: i == index
                                            ? AppColors.ink
                                            : AppColors.muted,
                                      )),
                                  if (badges[i] > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: kPink,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Text('${badges[i]}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: index * slot + slot * 0.2,
                    bottom: 0,
                    width: slot * 0.6,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
          );
        },
      ),
    );
  }
}
