import 'package:flutter/material.dart';

import '../../data/noahgram_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'noahgram_widgets.dart';
import 'profile_view.dart';

/// Search box + grid of every post and reel; typing filters by name/caption.
class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: noahgram,
      builder: (context, _) {
        final q = _query.trim().toLowerCase();
        final posts = noahgram.all.where((p) {
          if (q.isEmpty) return true;
          return p.caption.toLowerCase().contains(q) ||
              p.author.name.toLowerCase().contains(q) ||
              p.author.handle.contains(q);
        }).toList();
        final people = q.isEmpty
            ? <Person>[]
            : noahgram.others
                .where((p) =>
                    p.name.toLowerCase().contains(q) || p.handle.contains(q))
                .toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.muted, size: 21),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: tr(context, 'ng_search'),
                          hintStyle: const TextStyle(color: AppColors.muted),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final p in people)
              ListTile(
                onTap: () => openProfile(context, p),
                leading: Avatar(person: p, size: 44),
                title: Text(p.handle,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                subtitle: Text(p.name,
                    style: const TextStyle(color: AppColors.muted)),
              ),
            if (posts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(tr(context, 'ng_no_posts'),
                      style: const TextStyle(color: AppColors.muted)),
                ),
              )
            else
              PostGrid(posts: posts),
          ],
        );
      },
    );
  }
}
