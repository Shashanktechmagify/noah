import 'package:flutter/material.dart';

import '../../data/ministry_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/header_band.dart';
import '../../widgets/page_scaffold.dart';
import '../jodie/chat_screen.dart' show ChatBubble;

/// Private chat with the member's pastor, cell leader or the church office.
class MinistryChatScreen extends StatefulWidget {
  const MinistryChatScreen({super.key, required this.contact});

  final MinistryContact contact;

  @override
  State<MinistryChatScreen> createState() => _MinistryChatScreenState();
}

class _MinistryChatScreenState extends State<MinistryChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Notifying during initState would rebuild listeners mid-build.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ministry.markRead(widget.contact),
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
    if (_controller.text.trim().isEmpty) return;
    ministry.send(widget.contact, _controller.text);
    _controller.clear();
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
    final contact = widget.contact;
    final top = MediaQuery.of(context).padding.top;
    final empty = _controller.text.trim().isEmpty;
    return Scaffold(
      body: Stack(
        children: [
          HeaderBand(controller: _scroll, height: 120),
          Column(
            children: [
              SizedBox(height: top + 14),
              PageHeaderRow(
                title: contact.name,
                subtitle: tr(context, contact.roleKey),
                leadingIcon: Icons.arrow_back,
                onLeading: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListenableBuilder(
                  listenable: ministry,
                  builder: (context, _) {
                    _toBottom();
                    final messages = contact.messages;
                    return ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        for (final m in messages)
                          ChatBubble(message: m, theirColor: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          tr(context, 'ch_note', args: {'name': contact.name}),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  14,
                  10,
                  10,
                  10 + MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: AppColors.tint,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: tr(context, 'ch_write'),
                            hintStyle: const TextStyle(color: AppColors.muted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: empty ? null : AppColors.buttonGradient,
                          color: empty ? const Color(0xFFE2DDF1) : null,
                        ),
                        child: const Icon(
                          Icons.send_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
