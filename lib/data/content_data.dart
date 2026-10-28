import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import 'api_client.dart';
import 'manna_data.dart';
import 'manna_engagement.dart';
import 'word_data.dart';

/// Daily Manna, prayers and confessions written in the office's admin console.
///
/// Live mode reads them once a day from the Noah API (`/content/...`) and keeps the last answer on the
/// phone, so the screens open at once and work offline. Without a server (demo mode) the screens use
/// the sample content in `manna_data.dart` / `word_data.dart`.

/// The server's language number for each app language (English 1, Hindi 2, Marathi 3, Telugu 4,
/// Malayalam 5, Tamil 6, Kannada 7). The app has no Tamil; an app language the office has no content
/// for falls back to English on the server.
int contentLanguage(AppLang lang) => switch (lang) {
  AppLang.en => 1,
  AppLang.hi => 2,
  AppLang.mr => 3,
  AppLang.te => 4,
  AppLang.ml => 5,
  AppLang.kn => 7,
};

/// Today's date in India (the server decides what is live by this date).
String istDay([DateTime? now]) => (now ?? DateTime.now())
    .toUtc()
    .add(const Duration(hours: 5, minutes: 30))
    .toIso8601String()
    .substring(0, 10);

int _daysAgo(String? day) {
  final d = DateTime.tryParse(day ?? '');
  final today = DateTime.tryParse(istDay());
  if (d == null || today == null) return 0;
  return today.difference(d).inDays.clamp(0, 36500);
}

/// About 200 words a minute. The server sends the word count; otherwise it is counted here (without tags).
int _minutes(String html, [int? wordCount]) {
  final words =
      wordCount ??
      html
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
  return (words / 200).ceil().clamp(1, 20);
}

String? _img(Object? v) {
  final s = _s(v).trim();
  return s.isEmpty ? null : s;
}

String _s(Object? v) => v == null ? '' : '$v';

Manna mannaFromJson(Map<String, dynamic> j) {
  final message = _s(j['message']);
  final category = j['category'] is Map
      ? _s((j['category'] as Map)['title'])
      : '';
  return Manna(
    id: _s(j['id']),
    // A translation key falls back to its own text when it is not a key, so the live title is passed as the key.
    titleKey: _s(j['title']),
    ref: category,
    minutes: _minutes(message, (j['wordCount'] as num?)?.toInt()),
    daysAgo: _daysAgo(_s(j['date'])),
    verse: '',
    reflection: message,
    prayer: _s(j['prayer']),
    image: _img(j['image']),
    closingConfession: j['closingType'] == 'confession',
    writer: j['writer'] is Map ? _s((j['writer'] as Map)['name']) : '',
    date: DateTime.tryParse(_s(j['date'])),
    likes: (j['likes'] as num?)?.toInt() ?? 0,
    views: (j['views'] as num?)?.toInt() ?? 0,
    comments: (j['comments'] as num?)?.toInt() ?? 0,
  );
}

DailyPrayer prayerFromJson(Map<String, dynamic> j) => DailyPrayer(
  title: _s(j['title']),
  ref: '',
  body: _s(j['body']),
  daysAgo: _daysAgo(_s(j['date'])),
  image: _img(j['image']),
  // A prayer that is the ending of a Daily Manna opens that Manna.
  mannaId: j['source'] == 'manna' ? _s(j['id']) : null,
);

Confession confessionFromJson(Map<String, dynamic> j) => Confession(
  title: _s(j['title']),
  ref: '',
  body: _s(j['body']),
  theme: '',
  prayer: _s(j['prayer']),
  image: _img(j['image']),
  mannaId: j['source'] == 'manna' ? _s(j['id']) : null,
);

class ContentState extends ChangeNotifier {
  static const _cacheKey = 'noah_content_v1';

  /// The saved copy is used for this long before the app asks the server again.
  static const _staleAfter = Duration(hours: 3);

  List<Map<String, dynamic>> _mannaRaw = [];
  List<Map<String, dynamic>> _prayersRaw = [];
  List<Map<String, dynamic>> _confessionsRaw = [];
  List<Manna> _manna = [];
  List<DailyPrayer> _prayers = [];
  List<Confession> _confessions = [];
  String? _day; // the day the saved lists were fetched (IST)
  int _fetchedAt = 0; // when (milliseconds since 1970)
  int? _language;
  bool _restored = false;
  bool _busy = false;

  /// True while the first read of the day is running and nothing is saved yet.
  bool loading = false;

  /// What the screens show: the office's content live, the sample content in demo mode. Newest first.
  List<Manna> get mannas => liveApi ? _manna : kMannas;
  List<DailyPrayer> get prayers => liveApi ? _prayers : kPrayers;
  List<Confession> get confessions => liveApi ? _confessions : kConfessions;

  void _build() {
    _manna = _mannaRaw.map(mannaFromJson).toList();
    syncEngagement(_manna);
    _prayers = _prayersRaw.map(prayerFromJson).toList();
    _confessions = _confessionsRaw.map(confessionFromJson).toList();
  }

  Future<void> _restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_cacheKey);
      if (raw == null) return;
      final d = jsonDecode(raw) as Map<String, dynamic>;
      List<Map<String, dynamic>> list(String k) => ((d[k] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _mannaRaw = list('manna');
      _prayersRaw = list('prayers');
      _confessionsRaw = list('confessions');
      _day = d['day'] as String?;
      _fetchedAt = (d['fetchedAt'] as num?)?.toInt() ?? 0;
      _language = (d['language'] as num?)?.toInt();
      _build();
      notifyListeners();
    } catch (_) {
      // A damaged copy is ignored: the next read replaces it.
    }
  }

  /// Shows what was saved, then reads the day's content once (again when the app language changes).
  /// [force] (pull to refresh) reads it now.
  Future<void> ensureFresh(AppLang lang, {bool force = false}) async {
    if (!liveApi || !api.signedIn) return;
    await _restore();
    final code = contentLanguage(lang);
    // Read again when the day or the language changed, or the saved copy is a few hours old (so an
    // edit the office makes during the day reaches the phone the next time the app is opened).
    final age = DateTime.now().millisecondsSinceEpoch - _fetchedAt;
    if (!force &&
        _day == istDay() &&
        _language == code &&
        age < _staleAfter.inMilliseconds)
      return;
    if (_busy) return;
    _busy = true;
    loading = _manna.isEmpty && _prayers.isEmpty && _confessions.isEmpty;
    if (loading) notifyListeners();
    try {
      final results = await Future.wait([
        api.content('manna', code),
        api.content('prayers', code),
        api.content('confessions', code),
      ]);
      List<Map<String, dynamic>> items(Map<String, dynamic> d) =>
          ((d['items'] as List?) ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
      _mannaRaw = items(results[0]);
      _prayersRaw = items(results[1]);
      _confessionsRaw = items(results[2]);
      if (kDebugMode) {
        debugPrint(
          '[content] read: ${_mannaRaw.length} manna, ${_prayersRaw.length} prayers, '
          '${_confessionsRaw.length} confessions; today: ${_mannaRaw.isEmpty ? '-' : _mannaRaw.first['title']}',
        );
      }
      _day = istDay();
      _fetchedAt = DateTime.now().millisecondsSinceEpoch;
      _language = code;
      _build();
      try {
        (await SharedPreferences.getInstance()).setString(
          _cacheKey,
          jsonEncode({
            'day': _day,
            'fetchedAt': _fetchedAt,
            'language': _language,
            'manna': _mannaRaw,
            'prayers': _prayersRaw,
            'confessions': _confessionsRaw,
          }),
        );
      } catch (_) {}
    } on ApiException {
      // Offline or the server is busy: keep showing what is saved; the next start tries again.
    } finally {
      _busy = false;
      loading = false;
      notifyListeners();
    }
  }

  /// Pull to refresh.
  Future<void> refresh(AppLang lang) => ensureFresh(lang, force: true);
}

final contentState = ContentState();
