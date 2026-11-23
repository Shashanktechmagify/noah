import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import 'me/sub_page.dart';

/// Everyone's birthdays and wedding anniversaries, a month at a time. Only pastors and cell leaders can open it (the menu
/// shows it to them, and the server refuses anyone else). Nothing is sent to anyone from here: it is a list.
class CelebrationsScreen extends StatefulWidget {
  const CelebrationsScreen({super.key});

  @override
  State<CelebrationsScreen> createState() => _CelebrationsScreenState();
}

class _CelebrationsScreenState extends State<CelebrationsScreen> {
  int? _month;
  int _year = DateTime.now().year;
  bool _birthdays = true;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _birth = const [];
  List<Map<String, dynamic>> _anniv = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([int? month]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await api.celebrations(month: month);
      if (!mounted) return;
      setState(() {
        _month = (d['month'] as num).toInt();
        _year = (d['year'] as num).toInt();
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

  void _step(int by) {
    final m = (_month ?? DateTime.now().month) + by;
    _load(((m - 1) % 12) + 1);
  }

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  Widget _chip(String label, bool on, VoidCallback tap) => Expanded(
    child: GestureDetector(
      onTap: tap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.tint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? AppColors.magenta : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: on ? AppColors.magenta : AppColors.ink,
          ),
        ),
      ),
    ),
  );

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

  Widget _row(Map<String, dynamic> p, bool birthday) {
    final today = p['today'] == true;
    final n = (p[birthday ? 'turning' : 'years'] as num?)?.toInt() ?? 0;
    final sub = birthday
        ? tr(context, 'cel_turning', args: {'n': '$n'})
        : tr(context, 'cel_years', args: {'n': '$n'});
    return Container(
      color: today ? const Color(0xFFFFF4D6) : null,
      padding: const EdgeInsets.all(14),
      child: Row(
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
                  [
                    sub,
                    if ((p['mobile'] ?? '').toString().isNotEmpty)
                      '${p['mobile']}',
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (today)
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.cake_rounded, color: Color(0xFFE0409A)),
            ),
          Column(
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
                _months[((_month ?? 1) - 1) % 12].substring(0, 3),
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _birthdays ? _birth : _anniv;
    return SubPage(
      title: tr(context, 'cel_title'),
      subtitle: tr(context, 'cel_sub'),
      bandHeight: 84,
      children: [
        Row(
          children: [
            _chip(
              '${tr(context, 'cel_birthdays')} (${_birth.length})',
              _birthdays,
              () => setState(() => _birthdays = true),
            ),
            const SizedBox(width: 10),
            _chip(
              '${tr(context, 'cel_anniversaries')} (${_anniv.length})',
              !_birthdays,
              () => setState(() => _birthdays = false),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _loading ? null : () => _step(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_months[((_month ?? DateTime.now().month) - 1) % 12]} $_year',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            IconButton(
              onPressed: _loading ? null : () => _step(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Text(
                tr(context, 'cel_none'),
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          WhiteCard(
            child: Column(
              children: [
                for (final (i, p) in list.indexed) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _row(p, _birthdays),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
