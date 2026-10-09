import 'package:flutter/material.dart';

import '../../data/noahgram_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'noahgram_widgets.dart';
import 'story_viewer.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: noahgram,
      builder: (context, _) {
        final posts = noahgram.posts;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 110),
          itemCount: posts.length + 1,
          itemBuilder: (_, i) =>
              i == 0 ? const _StoriesRow() : PostCard(post: posts[i - 1]),
        );
      },
    );
  }
}

void _openStory(BuildContext context, Person person) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => StoryViewer(person: person),
      transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
    ),
  );
}

class _StoriesRow extends StatelessWidget {
  const _StoriesRow();

  @override
  Widget build(BuildContext context) {
    final people = [noahgram.me, ...noahgram.others];
    return Container(
      height: 114,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: people.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = people[i];
          final isMe = p == noahgram.me;
          final ring = noahgram.seenStories.contains(p.id) ? 2 : 1;
          return GestureDetector(
            onTap: () => _openStory(context, p),
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Avatar(person: p, size: 60, ring: ring),
                      if (isMe)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => showCreatePostSheet(context),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.magenta,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.add,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMe ? tr(context, 'ng_your_story') : p.handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
