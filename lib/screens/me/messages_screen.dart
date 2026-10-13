import 'package:flutter/material.dart';

import '../../data/ministry_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../jodie/jodie_widgets.dart' show JodieAvatar, clock;
import 'ministry_chat_screen.dart';

void openMinistryChat(BuildContext context, MinistryContact contact) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => MinistryChatScreen(contact: contact)),
  );
}

/// Conversations with the pastor, the cell leader and the church office.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: ministry,
        builder: (context, _) => PageScaffold(
          title: tr(context, 'me2_messages'),
          subtitle: tr(context, 'me2_messages_sub'),
          leadingIcon: Icons.arrow_back,
          onLeading: () => Navigator.of(context).pop(),
          children: [
            WhiteCard(
              child: Column(
                children: [
                  for (final (i, c) in ministry.contacts.indexed) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.border),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => openMinistryChat(context, c),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            JodieAvatar(
                              initials: c.initials,
                              colors: c.colors,
                              size: 50,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.last?.text ?? tr(context, c.roleKey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: c.unread > 0
                                          ? AppColors.ink
                                          : AppColors.muted,
                                      fontWeight: c.unread > 0
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (c.last != null)
                                  Text(
                                    clock(c.last!.at),
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                if (c.unread > 0) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.magenta,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${c.unread}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
