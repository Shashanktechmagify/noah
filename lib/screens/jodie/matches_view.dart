import 'package:flutter/material.dart';

import '../../data/jodie_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';
import 'jodie_widgets.dart';

/// New matches on top, conversations below. Opening one needs Premium.
class MatchesView extends StatelessWidget {
  const MatchesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: jodie,
      builder: (context, _) {
        final all = jodie.matches;
        if (all.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border,
                    color: AppColors.magenta, size: 44),
                const SizedBox(height: 12),
                Text(tr(context, 'jd_no_matches'),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
          );
        }
        final fresh = all.where((m) => m.messages.isEmpty).toList();
        final chats = all.where((m) => m.messages.isNotEmpty).toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            if (!jodie.isPremium)
              GestureDetector(
                onTap: () => showSubscribeSheet(context),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.tint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          color: AppColors.magenta, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr(context, 'jd_unlock_chat'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14)),
                            Text(tr(context, 'jd_unlock_chat_sub'),
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.magenta),
                    ],
                  ),
                ),
              ),
            if (fresh.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Text(tr(context, 'jd_new_matches'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: fresh.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => openChat(context, fresh[i]),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.buttonGradient,
                          ),
                          child: JodieAvatar.of(fresh[i].profile,
                              size: 62, border: true),
                        ),
                        const SizedBox(height: 4),
                        Text(fresh[i].profile.firstName,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (chats.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(tr(context, 'jd_messages'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              for (final m in chats)
                ListTile(
                  onTap: () => openChat(context, m),
                  leading: JodieAvatar.of(m.profile, size: 52),
                  title: Text(m.profile.name,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    jodie.isPremium ? m.last!.text : '••••••••••',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: m.unread ? AppColors.ink : AppColors.muted,
                      fontWeight: m.unread ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(clock(m.last!.at),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                      const SizedBox(height: 4),
                      if (!jodie.isPremium)
                        const Icon(Icons.lock_outline,
                            size: 16, color: AppColors.magenta)
                      else if (m.unread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: AppColors.magenta, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
