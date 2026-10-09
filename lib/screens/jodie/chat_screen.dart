import 'package:flutter/material.dart';

import '../../data/jodie_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'jodie_widgets.dart';

/// Opens a chat, asking for a subscription first when the member has none.
Future<void> openChat(BuildContext context, JodieMatch match) async {
  if (!jodie.isPremium) {
    await showSubscribeSheet(context);
    if (!jodie.isPremium || !context.mounted) return;
  }
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ChatScreen(match: match)));
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.match});

  final JodieMatch match;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Notifying during initState would rebuild listeners mid-build.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => jodie.markRead(widget.match),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    jodie.sendMessage(widget.match, text);
    _controller.clear();
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.match.profile;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        titleSpacing: 0,
        title: Row(
          children: [
            JodieAvatar.of(profile, size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  tr(context, 'jd_active_now'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF1F8A4C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: jodie,
              builder: (context, _) {
                final messages = widget.match.messages;
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        JodieAvatar.of(profile, size: 84),
                        const SizedBox(height: 14),
                        Text(
                          tr(context, 'jd_say_hello'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                _toBottom();
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _Bubble(message: messages[i]),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: tr(context, 'jd_type_message'),
                          hintStyle: const TextStyle(color: AppColors.muted),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _controller.text.trim().isEmpty
                            ? null
                            : AppColors.buttonGradient,
                        color: _controller.text.trim().isEmpty
                            ? const Color(0xFFE2DDF1)
                            : null,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          gradient: mine ? AppColors.buttonGradient : null,
          color: mine ? null : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: mine ? Colors.white : AppColors.ink,
                fontSize: 14.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              clock(message.at),
              style: TextStyle(
                color: mine
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.muted,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
