import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/help_data.dart';
import '../data/ministry_data.dart';
import '../data/registration_data.dart' show kOfficePhone;
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/header_band.dart';
import '../widgets/page_scaffold.dart';
import 'me/ministry_chat_screen.dart';

/// The questions offered as examples: the first four when the chat is empty, and after every answer three that were not
/// asked yet.
const _exampleKeys = [
  'help_ex1',
  'help_ex2',
  'help_ex3',
  'help_ex4',
  'help_ex5',
  'help_ex6',
  'help_ex7',
  'help_ex8',
];

/// "Help" in the Menu: the member asks a question about the app and gets an answer from the office's FAQ. When the FAQ has
/// nothing (or the answer did not help) there is always a way on: "Talk to us" opens the chat with the church office.
class HelpChatScreen extends StatefulWidget {
  const HelpChatScreen({super.key, this.chat});

  /// The chat to draw (tests give their own); the screen makes one when it is not given.
  final HelpChat? chat;

  @override
  State<HelpChatScreen> createState() => _HelpChatScreenState();
}

class _HelpChatScreenState extends State<HelpChatScreen> {
  // The language the app is in now (it may be changed while the chat is open): the answer comes in it.
  late final HelpChat _chat =
      widget.chat ?? HelpChat(language: () => AppLocale.of(context).lang.name);
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  // The purple band behind the title stays where it is: tied to the list, it would scroll away and leave the white title on
  // the pale page. This controller is never attached to a list.
  final _band = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (widget.chat == null) _chat.dispose();
    _controller.dispose();
    _scroll.dispose();
    _band.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final question = (text ?? _controller.text).trim();
    if (question.isEmpty || _chat.busy) return;
    _controller.clear();
    await _chat.send(question);
  }

  /// "Talk to us": the member picks how, chat with the church office or a call to its number.
  Future<void> _talk() async {
    final how = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(sheet, 'help_talk_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                key: const ValueKey('help-chat-office'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.purple,
                ),
                title: Text(tr(sheet, 'help_chat_office')),
                onTap: () => Navigator.of(sheet).pop('chat'),
              ),
              ListTile(
                key: const ValueKey('help-call-office'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.call_outlined,
                  color: AppColors.purple,
                ),
                title: Text(
                  tr(sheet, 'help_call_office', args: {'phone': kOfficePhone}),
                ),
                onTap: () => Navigator.of(sheet).pop('call'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (how == 'chat') {
      ministry.ensureLoaded();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MinistryChatScreen(contact: ministry.office),
        ),
      );
    } else if (how == 'call') {
      await _call();
    }
  }

  Future<void> _call() async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri(scheme: 'tel', path: kOfficePhone.replaceAll(' ', '')),
      );
    } catch (_) {
      // No phone app (a tablet, an emulator): the message below gives the number.
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'help_call_fail', args: {'phone': kOfficePhone}),
          ),
        ),
      );
    }
  }

  /// After an answer (or "no answer") the member is offered other questions to ask: three of the examples they have not
  /// asked yet, so the chat can go on in one tap.
  List<Widget> _alsoAsk(BuildContext context) {
    final last = _chat.messages.isEmpty ? null : _chat.messages.last;
    if (last == null ||
        (last.kind != HelpKind.answer && last.kind != HelpKind.noAnswer)) {
      return const [];
    }
    final asked = {
      for (final m in _chat.messages)
        if (m.kind == HelpKind.mine) m.text,
    };
    final more = [
      for (final key in _exampleKeys)
        if (!asked.contains(tr(context, key))) key,
    ].take(3).toList();
    if (more.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 8),
        child: Text(
          tr(context, 'help_also'),
          style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final key in more)
            ActionChip(
              key: ValueKey('help-also-$key'),
              label: Text(tr(context, key)),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              onPressed: () => _send(tr(context, key)),
            ),
        ],
      ),
    ];
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

  Widget _action(
    String key,
    String label,
    VoidCallback onTap, {
    IconData? icon,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: OutlinedButton.icon(
      key: ValueKey(key),
      onPressed: onTap,
      icon: Icon(icon ?? Icons.chat_bubble_outline, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.purple,
        side: const BorderSide(color: AppColors.purple),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
  );

  Widget _answer(BuildContext context, HelpMessage m) {
    final helpful = m.helpful;
    return _Bubble(
      mine: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.text,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          if (helpful == null)
            Row(
              children: [
                Flexible(
                  child: Text(
                    tr(context, 'help_helpful'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _Rate(
                  key: const ValueKey('help-yes'),
                  label: tr(context, 'help_yes'),
                  onTap: () => _chat.rate(m, true),
                ),
                const SizedBox(width: 6),
                _Rate(
                  key: const ValueKey('help-no'),
                  label: tr(context, 'help_no'),
                  onTap: () => _chat.rate(m, false),
                ),
              ],
            )
          else
            Text(
              tr(context, 'help_thanks'),
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          if (helpful == false)
            _action('help-talk', tr(context, 'help_talk'), _talk),
        ],
      ),
    );
  }

  Widget _plain(BuildContext context, String key, {Widget? action}) => _Bubble(
    mine: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, key),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14.5,
            height: 1.35,
          ),
        ),
        ?action,
      ],
    ),
  );

  Widget _message(BuildContext context, HelpMessage m) => switch (m.kind) {
    HelpKind.mine => _Bubble(
      mine: true,
      child: Text(
        m.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          height: 1.3,
        ),
      ),
    ),
    HelpKind.answer => _answer(context, m),
    HelpKind.noAnswer => _plain(
      context,
      'help_none',
      action: _action('help-talk', tr(context, 'help_talk'), _talk),
    ),
    HelpKind.error => switch (m.problem) {
      HelpProblem.limit => _plain(
        context,
        'help_limit',
        action: _action('help-talk', tr(context, 'help_talk'), _talk),
      ),
      HelpProblem.notSet => _plain(
        context,
        'help_off',
        action: _action('help-talk', tr(context, 'help_talk'), _talk),
      ),
      _ => _plain(
        context,
        'help_error',
        action: _action(
          'help-retry',
          tr(context, 'help_retry'),
          () => _chat.retry(m),
          icon: Icons.refresh,
        ),
      ),
    },
  };

  Widget _thinking(BuildContext context) => _Bubble(
    mine: false,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'help_thinking'),
                style: const TextStyle(color: AppColors.ink, fontSize: 14.5),
              ),
              const SizedBox(height: 2),
              Text(
                tr(context, 'help_slow'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Column(
        children: [
          // The purple band with the title, then the chat: the chat starts exactly where the band ends, so the messages scroll
          // on the pale page and never go up into the purple.
          SizedBox(
            height: top + 120,
            child: Stack(
              children: [
                HeaderBand(controller: _band, height: 120),
                Column(
                  children: [
                    SizedBox(height: top + 14),
                    PageHeaderRow(
                      title: tr(context, 'mn_help'),
                      subtitle: tr(context, 'help_sub'),
                      leadingIcon: Icons.arrow_back,
                      onLeading: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _chat,
              builder: (context, _) {
                _toBottom();
                return ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    _plain(context, 'help_hello'),
                    if (_chat.messages.isEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final key in _exampleKeys.take(4))
                            ActionChip(
                              key: ValueKey(key),
                              label: Text(tr(context, key)),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              onPressed: () => _send(tr(context, key)),
                            ),
                        ],
                      ),
                    for (final m in _chat.messages) _message(context, m),
                    if (_chat.busy) _thinking(context),
                    if (!_chat.busy) ..._alsoAsk(context),
                    const SizedBox(height: 12),
                    Text(
                      tr(context, 'help_note'),
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
          ListenableBuilder(
            listenable: _chat,
            builder: (context, _) {
              final ready = _controller.text.trim().isNotEmpty && !_chat.busy;
              return Container(
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
                          key: const ValueKey('help-input'),
                          controller: _controller,
                          enabled: !_chat.busy,
                          maxLength: kHelpQuestionMax,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: tr(context, 'help_write'),
                            hintStyle: const TextStyle(color: AppColors.muted),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      key: const ValueKey('help-send'),
                      onTap: ready ? _send : null,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: ready ? AppColors.buttonGradient : null,
                          color: ready ? null : const Color(0xFFE2DDF1),
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
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A chat bubble: the member's on the right in the app's gradient, the assistant's on the left in white.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.mine, required this.child});

  final bool mine;
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      decoration: BoxDecoration(
        gradient: mine ? AppColors.buttonGradient : null,
        color: mine ? null : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 4),
          bottomRight: Radius.circular(mine ? 4 : 18),
        ),
      ),
      child: child,
    ),
  );
}

class _Rate extends StatelessWidget {
  const _Rate({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.purple,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
