import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/jodie_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../noahgram/noahgram_widgets.dart' show LookCanvas;
import 'chat_screen.dart';
import 'jodie_widgets.dart';
import 'profile_detail.dart';

/// People who already liked you. Blurred until you go Premium or spend credits.
class LikesView extends StatelessWidget {
  const LikesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: jodie,
      builder: (context, _) {
        final likes = jodie.likesYou;
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 110),
          children: [
            if (!jodie.isPremium)
              GestureDetector(
                onTap: () => showSubscribeSheet(context),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: AppColors.buttonGradient,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium,
                          color: Colors.white, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(tr(context, 'jd_see_all_likes'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            if (likes.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(tr(context, 'jd_no_matches'),
                      style: const TextStyle(color: AppColors.muted)),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 2),
                child: Text(
                    tr(context, 'jd_likes_sub', args: {'n': '${likes.length}'}),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.74,
                ),
                itemCount: likes.length,
                itemBuilder: (_, i) => _LikeCard(profile: likes[i]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LikeCard extends StatelessWidget {
  const _LikeCard({required this.profile});

  final JodieProfile profile;

  Future<void> _likeBack(BuildContext context) async {
    final p = profile;
    jodie.like(p);
    if (!context.mounted) return;
    final match = jodie.matches.first;
    await showMatchDialog(context, p,
        onMessage: () => openChat(context, match));
  }

  Future<void> _reveal(BuildContext context) async {
    if (jodie.reveal(profile)) return;
    toast(context, tr(context, 'jd_not_enough'));
    await showCreditsSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final visible = jodie.canSeeLike(p);
    return GestureDetector(
      onTap: () {
        if (!visible) {
          _reveal(context);
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => JodieProfileScreen(
            profile: p,
            onLike: () => _likeBack(context),
            onPass: () => jodie.pass(p),
          ),
        ));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              enabled: !visible,
              imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LookCanvas(look: p.photos.first, showText: false),
                  Center(
                    child: Text(p.initials,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 70,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xAA000000)],
                  ),
                ),
              ),
            ),
            if (visible)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${p.firstName}, ${p.age}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    Text(p.city,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _likeBack(context),
                      child: Container(
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite,
                                color: AppColors.magenta, size: 16),
                            const SizedBox(width: 6),
                            Text(tr(context, 'jd_like_back'),
                                style: const TextStyle(
                                    color: AppColors.magenta,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: Colors.white, size: 30),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, color: kGold, size: 16),
                          const SizedBox(width: 5),
                          Text(
                              tr(context, 'jd_reveal',
                                  args: {'n': '$kRevealCost'}),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
