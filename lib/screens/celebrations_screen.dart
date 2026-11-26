import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_client.dart';
import '../data/celebration_links.dart';
import '../data/celebration_template.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import 'me/sub_page.dart';

/// Reads the celebrations of the days from one date to another (as `2026-11-25`); the screen asks for today only.
typedef CelebrationsLoader = Future<Map<String, dynamic>> Function(
  String from,
  String to,
);

/// Opens a link outside the app (a call, WhatsApp). True when it opened.
typedef LinkLauncher = Future<bool> Function(Uri uri);

/// The birthdays and wedding anniversaries of TODAY only (nothing past, nothing ahead), for the pastors and the cell leaders (the
/// menu shows it to them, and the server refuses anyone else). Two tabs, Birthdays and Anniversaries. Each person comes with how to
/// reach them (phone, WhatsApp, email, address) and who they are (marital status), a Call button, and a WhatsApp button that opens
/// the chat with the greeting already written; the greeting can be changed ("WhatsApp message"), and is kept on the phone.
class CelebrationsScreen extends StatefulWidget {
  const CelebrationsScreen({super.key, this.load, this.launch, this.today});

  /// Tests give their own (also "today").
  final CelebrationsLoader? load;
  final LinkLauncher? launch;
  final DateTime? today;

  @override
  State<CelebrationsScreen> createState() => _CelebrationsScreenState();
}

const _pink = Color(0xFFE0409A);
const _whatsapp = Color(0xFF1FA855);

class _CelebrationsScreenState extends State<CelebrationsScreen> {
  bool _loading = true;
  String? _error;
  bool _birthdaysTab = true;
  List<Map<String, dynamic>> _birth = const [];
  List<Map<String, dynamic>> _anniv = const [];
  String? _tplBirthday;
  String? _tplAnniversary;

  DateTime get _today {
    final t = widget.today ?? DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }

  @override
  void initState() {
    super.initState();
    _load();
    CelebrationTemplate.read(true).then((v) {
      if (mounted) setState(() => _tplBirthday = v);
    });
    CelebrationTemplate.read(false).then((v) {
      if (mounted) setState(() => _tplAnniversary = v);
    });
  }

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final read = widget.load ?? (f, t) => api.celebrations(from: f, to: t);
      final d = await read(_iso(_today), _iso(_today));
      if (!mounted) return;
      setState(() {
        _birth = ((d['birthdays'] as List?) ?? const []).cast();
        _anniv = ((d['anniversaries'] as List?) ?? const []).cast();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _open(Uri? uri, String? number) async {
    var opened = false;
    if (uri != null) {
      try {
        opened =
            await (widget.launch ??
                (u) => launchUrl(u, mode: LaunchMode.externalApplication))(uri);
      } catch (_) {
        // No phone or WhatsApp on this device: the message below gives the number.
      }
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              tr(context, 'cel_open_failed', args: {'phone': number ?? ''}),
            ),
          ),
        );
    }
  }

  // ── The tabs and the message ────────────────────────────────────────────

  Widget _tab(String key, String label, int count, bool birthday) {
    final on = _birthdaysTab == birthday;
    return Expanded(
      child: GestureDetector(
        key: ValueKey(key),
        onTap: () => setState(() => _birthdaysTab = birthday),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: on ? AppColors.magenta : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: on ? AppColors.magenta : AppColors.border,
            ),
          ),
          child: Text(
            _loading ? label : '$label ($count)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: on ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabs(BuildContext context) => Row(
    children: [
      _tab('cel-tab-b', tr(context, 'cel_birthdays'), _birth.length, true),
      const SizedBox(width: 10),
      _tab('cel-tab-a', tr(context, 'cel_anniversaries'), _anniv.length, false),
    ],
  );

  String _standard(bool birthday) => tr(
    context,
    birthday ? 'bday_wish' : 'anv_wish',
    args: {'name': '{name}'},
  );

  String _template(bool birthday) =>
      (birthday ? _tplBirthday : _tplAnniversary) ?? _standard(birthday);

  Future<void> _editTemplate() async {
    final birthday = _birthdaysTab;
    final controller = TextEditingController(text: _template(birthday));
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Above the phone's own buttons (SafeArea) and the keyboard (viewInsets); scrolls when the screen is short.
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            24 + MediaQuery.of(sheet).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(sheet, birthday ? 'cel_tpl_title_b' : 'cel_tpl_title_a'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(sheet, 'cel_tpl_hint', args: {'name': '{name}'}),
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('cel-tpl-field'),
                controller: controller,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Flexible(
                    child: TextButton(
                      key: const ValueKey('cel-tpl-reset'),
                      onPressed: () => Navigator.of(sheet).pop(''),
                      child: Text(
                        tr(sheet, 'cel_tpl_reset'),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('cel-tpl-save'),
                    onPressed: () =>
                        Navigator.of(sheet).pop(controller.text.trim()),
                    child: Text(tr(sheet, 'cel_tpl_save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == null) return;
    // The standard text saved as it is stays "standard", so it follows the app language.
    final value = saved == _standard(birthday) ? '' : saved;
    await CelebrationTemplate.write(birthday, value);
    if (!mounted) return;
    setState(() {
      if (birthday) {
        _tplBirthday = value.isEmpty ? null : value;
      } else {
        _tplAnniversary = value.isEmpty ? null : value;
      }
    });
  }

  Widget _templateButton() => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      key: const ValueKey('cel-tpl-edit'),
      onPressed: _editTemplate,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: Text(tr(context, 'cel_tpl_edit')),
      style: TextButton.styleFrom(foregroundColor: _whatsapp),
    ),
  );

  // ── The people ──────────────────────────────────────────────────────────

  Widget _avatar(Map<String, dynamic> p) {
    final name = '${p['name']}';
    final letters = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFA719C8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
    final id = p['photoFileId'];
    if (id == null) return letters;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Image.network(
          api.mediaUrl('$id'),
          headers: api.authHeaders,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => letters,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : letters,
        ),
      ),
    );
  }

  String _text(Map<String, dynamic> p, String key) => '${p[key] ?? ''}'.trim();

  /// One line of what is known about the person: an icon and the text.
  Widget _info(IconData icon, String text, {Key? key}) => Padding(
    key: key,
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3)),
        ),
      ],
    ),
  );

  /// The marital status in the member's language (the words of the registration form), or the raw word for one the app does not know.
  String _marital(String status) {
    const known = {
      'single',
      'married',
      'widow',
      'widower',
      'separated',
      'divorced',
    };
    return known.contains(status) ? tr(context, 'reg_$status') : status;
  }

  /// The two buttons of a person: a call, and WhatsApp with the greeting written (only "send" is left to press). WhatsApp goes to the
  /// member's WhatsApp number when there is one, else to the mobile number.
  Widget _actions(Map<String, dynamic> p, bool birthday) {
    final mobile = _text(p, 'mobile');
    final whatsapp = _text(p, 'whatsapp');
    final callNumber = mobile.isNotEmpty ? mobile : whatsapp;
    final waNumber = whatsapp.isNotEmpty ? whatsapp : mobile;
    if (celebrationDigits(callNumber).isEmpty &&
        celebrationDigits(waNumber).isEmpty) {
      return const SizedBox.shrink();
    }
    final first = '${p['name']}'.split(' ').first;
    final greeting = _template(birthday).replaceAll('{name}', first);
    final kind = birthday ? 'b' : 'a';
    final id = '${p['memberId']}-$kind-${p['date']}';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          OutlinedButton.icon(
            key: ValueKey('cel-call-$id'),
            onPressed: () => _open(callLink(callNumber), callNumber),
            icon: const Icon(Icons.call_outlined, size: 18),
            label: Text(tr(context, 'cel_call')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purple,
              side: const BorderSide(color: AppColors.purple),
              visualDensity: VisualDensity.compact,
            ),
          ),
          FilledButton.icon(
            key: ValueKey('cel-wa-$id'),
            onPressed: () => _open(whatsappLink(waNumber, greeting), waNumber),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('WhatsApp'),
            style: FilledButton.styleFrom(
              backgroundColor: _whatsapp,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _person(Map<String, dynamic> p, bool birthday) {
    final n = (p[birthday ? 'turning' : 'years'] as num?)?.toInt() ?? 0;
    final sub = birthday
        ? tr(context, 'cel_turning', args: {'n': '$n'})
        : tr(context, 'cel_years', args: {'n': '$n'});
    final mobile = _text(p, 'mobile');
    final whatsapp = _text(p, 'whatsapp');
    final email = _text(p, 'email');
    final address = _text(p, 'address');
    final marital = _text(p, 'maritalStatus');
    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(p),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p['name']}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                birthday ? Icons.cake_rounded : Icons.favorite,
                color: _pink,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (mobile.isNotEmpty) _info(Icons.call_outlined, mobile),
          if (whatsapp.isNotEmpty && whatsapp != mobile)
            _info(Icons.chat_outlined, 'WhatsApp · $whatsapp'),
          if (email.isNotEmpty) _info(Icons.mail_outline, email),
          if (address.isNotEmpty) _info(Icons.home_outlined, address),
          if (marital.isNotEmpty)
            _info(Icons.favorite_border, _marital(marital)),
          _actions(p, birthday),
        ],
      ),
    );
  }

  Widget _list(List<Map<String, dynamic>> people, bool birthday) {
    if (people.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Text(
            tr(context, 'cel_none_today'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return WhiteCard(
      child: Column(
        children: [
          for (final (i, p) in people.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _person(p, birthday),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: tr(context, 'cel_title'),
      subtitle: tr(context, 'cel_sub'),
      bandHeight: 84,
      children: [
        _tabs(context),
        _templateButton(),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.muted),
            ),
          )
        else
          _list(_birthdaysTab ? _birth : _anniv, _birthdaysTab),
      ],
    );
  }
}
