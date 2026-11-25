import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_client.dart';
import '../data/celebration_links.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import 'events/events_widgets.dart' show fullDate, monthName;
import 'me/sub_page.dart';

/// Reads the celebrations between two dates (as `2026-11-25`).
typedef CelebrationsLoader = Future<Map<String, dynamic>> Function(
  String from,
  String to,
);

/// Opens a link outside the app (a call, WhatsApp). True when it opened.
typedef LinkLauncher = Future<bool> Function(Uri uri);

/// The birthdays and wedding anniversaries of a range of dates, for the pastors and the cell leaders (the menu shows it to them,
/// and the server refuses anyone else). Two date pickers choose the range, looking back or ahead; each person comes with how to
/// reach them (phone, WhatsApp, email, address) and who they are (marital status), a Call button, and a WhatsApp button that
/// opens the chat with the greeting already written: only "send" is left to press.
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

/// The longest range the server answers (a year).
const _maxDays = 365;

class _CelebrationsScreenState extends State<CelebrationsScreen> {
  late DateTime _from;
  late DateTime _to;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _birth = const [];
  List<Map<String, dynamic>> _anniv = const [];

  DateTime get _today {
    final t = widget.today ?? DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }

  @override
  void initState() {
    super.initState();
    // The week ahead to begin with.
    _from = _today;
    _to = _today.add(const Duration(days: 6));
    _load();
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
      final d = await read(_iso(_from), _iso(_to));
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

  /// A range from [from] to [to]; the other end follows when the two would cross or be more than a year apart.
  void _setRange(DateTime from, DateTime to, {required bool fromChanged}) {
    if (to.isBefore(from)) {
      if (fromChanged) {
        to = from;
      } else {
        from = to;
      }
    }
    if (to.difference(from).inDays > _maxDays) {
      if (fromChanged) {
        to = from.add(const Duration(days: _maxDays));
      } else {
        from = to.subtract(const Duration(days: _maxDays));
      }
    }
    setState(() {
      _from = from;
      _to = to;
    });
    _load();
  }

  Future<void> _pick({required bool from}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    final day = DateTime(picked.year, picked.month, picked.day);
    _setRange(from ? day : _from, from ? _to : day, fromChanged: from);
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

  // ── The range ───────────────────────────────────────────────────────────

  Widget _dateField(String key, String label, DateTime date, bool from) =>
      Expanded(
        child: GestureDetector(
          key: ValueKey(key),
          onTap: () => _pick(from: from),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: AppColors.magenta,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        fullDate(context, date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _quick(String key, String label, DateTime from, DateTime to) {
    final on = _from == from && _to == to;
    return GestureDetector(
      key: ValueKey(key),
      onTap: () => _setRange(from, to, fromChanged: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? AppColors.tint : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? AppColors.magenta : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: on ? AppColors.magenta : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _rangeCard(BuildContext context) {
    final t = _today;
    return WhiteCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _dateField('cel-from', tr(context, 'cel_from'), _from, true),
              const SizedBox(width: 10),
              _dateField('cel-to', tr(context, 'cel_to'), _to, false),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quick('cel-today', tr(context, 'cel_r_today'), t, t),
              _quick(
                'cel-week',
                tr(context, 'cel_r_week'),
                t,
                t.add(const Duration(days: 6)),
              ),
              _quick(
                'cel-30',
                tr(context, 'cel_r_30'),
                t,
                t.add(const Duration(days: 29)),
              ),
              _quick(
                'cel-month',
                tr(context, 'cel_r_month'),
                DateTime(t.year, t.month),
                DateTime(t.year, t.month + 1, 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
    final greeting = tr(
      context,
      birthday ? 'bday_wish' : 'anv_wish',
      args: {'name': first},
    );
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
    final today = p['today'] == true;
    final n = (p[birthday ? 'turning' : 'years'] as num?)?.toInt() ?? 0;
    final sub = birthday
        ? tr(context, 'cel_turning', args: {'n': '$n'})
        : tr(context, 'cel_years', args: {'n': '$n'});
    final mobile = _text(p, 'mobile');
    final whatsapp = _text(p, 'whatsapp');
    final email = _text(p, 'email');
    final address = _text(p, 'address');
    final marital = _text(p, 'maritalStatus');
    final month = (p['month'] as num?)?.toInt() ?? 1;
    return Container(
      color: today ? const Color(0xFFFFF4D6) : null,
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
              if (today)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.cake_rounded, color: _pink),
                ),
              SizedBox(
                width: 46,
                child: Column(
                  children: [
                    Text(
                      '${p['day']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.magenta,
                      ),
                    ),
                    Text(
                      monthName(context, month),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
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

  Widget _section(
    String title,
    List<Map<String, dynamic>> people,
    bool birthday,
  ) {
    if (people.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              '$title (${people.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          WhiteCard(
            child: Column(
              children: [
                for (final (i, p) in people.indexed) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _person(p, birthday),
                ],
              ],
            ),
          ),
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
        _rangeCard(context),
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
        else if (_birth.isEmpty && _anniv.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Text(
                tr(context, 'cel_none_range'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else ...[
          _section(tr(context, 'cel_birthdays'), _birth, true),
          _section(tr(context, 'cel_anniversaries'), _anniv, false),
        ],
      ],
    );
  }
}
