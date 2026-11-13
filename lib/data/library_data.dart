import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
import 'api_client.dart';
import 'content_data.dart' show contentLanguage;
import 'manna_data.dart' show EmbedMedia;

/// What the office writes besides the daily content: the home screen banners and announcements, the dream dictionary and the
/// Bible commentary. The server decides what is live (dates, switches, partners only, language); the app only shows it.

String _s(Object? v) => v == null ? '' : '$v';
String? _link(Object? v) {
  final s = _s(v).trim();
  return s.startsWith('http') ? s : null;
}

List<EmbedMedia> _media(Object? list) => [
  for (final m in (list as List?) ?? const [])
    if (m is Map && _s(m['url']).startsWith('http'))
      EmbedMedia.fromJson(Map<String, dynamic>.from(m)),
];

class LibBanner {
  const LibBanner({
    required this.id,
    required this.caption,
    this.landscape,
    this.portrait,
    this.url,
  });

  final String id;
  final String caption;
  final String? landscape;
  final String? portrait;

  /// What a tap opens.
  final String? url;

  /// The picture for a phone (portrait), else the other one.
  String? get picture => portrait ?? landscape;

  factory LibBanner.fromJson(Map<String, dynamic> j) => LibBanner(
    id: _s(j['id']),
    caption: _s(j['caption']),
    landscape: _link(j['landscapeImage']),
    portrait: _link(j['portraitImage']),
    url: _link(j['url']),
  );
}

class LibAnnouncement {
  const LibAnnouncement({
    required this.id,
    required this.title,
    this.message,
    this.link,
    this.image,
  });

  final String id;
  final String title;
  final String? message;
  final String? link;
  final String? image;

  factory LibAnnouncement.fromJson(Map<String, dynamic> j) => LibAnnouncement(
    id: _s(j['id']),
    title: _s(j['title']),
    message: _s(j['message']).isEmpty ? null : _s(j['message']),
    link: _link(j['link']),
    image: _link(j['image']),
  );
}

class DictEntry {
  const DictEntry({
    required this.id,
    required this.title,
    required this.meaning,
    this.categoryId,
    this.featured = false,
    this.image,
    this.media = const [],
  });

  final String id;
  final String title;

  /// HTML written in the console's editor.
  final String meaning;
  final String? categoryId;
  final bool featured;
  final String? image;
  final List<EmbedMedia> media;

  factory DictEntry.fromJson(Map<String, dynamic> j) => DictEntry(
    id: _s(j['id']),
    title: _s(j['title']),
    meaning: _s(j['meaning']),
    categoryId: j['categoryId'] == null ? null : _s(j['categoryId']),
    featured: j['featured'] == true,
    image: _link(j['image']),
    media: _media(j['media']),
  );
}

class DictCategory {
  const DictCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory DictCategory.fromJson(Map<String, dynamic> j) =>
      DictCategory(id: _s(j['id']), name: _s(j['name']));
}

class CommentaryItem {
  const CommentaryItem({
    required this.id,
    required this.title,
    required this.book,
    required this.chapter,
    required this.body,
    this.writer = '',
    this.youtubeId,
    this.image,
    this.media = const [],
  });

  final String id;
  final String title;

  /// 1 (Genesis) to 66 (Revelation), and the chapter.
  final int book;
  final int chapter;
  final String body;
  final String writer;
  final String? youtubeId;
  final String? image;
  final List<EmbedMedia> media;

  /// The video of the entry as a card (its picture and a link to YouTube), then the embeds.
  List<EmbedMedia> get allMedia => [
    if (youtubeId != null)
      EmbedMedia(
        kind: 'youtube',
        url: 'https://www.youtube.com/watch?v=$youtubeId',
        host: 'youtube.com',
        thumbnail: 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg',
      ),
    ...media.where((m) => youtubeId == null || !m.url.contains(youtubeId!)),
  ];

  factory CommentaryItem.fromJson(Map<String, dynamic> j) => CommentaryItem(
    id: _s(j['id']),
    title: _s(j['title']),
    book: (j['book'] as num?)?.toInt() ?? 0,
    chapter: (j['chapter'] as num?)?.toInt() ?? 0,
    body: _s(j['body']),
    writer: j['writer'] is Map ? _s((j['writer'] as Map)['name']) : '',
    youtubeId: j['youtubeId'] == null ? null : _s(j['youtubeId']),
    image: _link(j['image']),
    media: _media(j['media']),
  );
}

/// The lists, kept while the app is open. Banners and announcements are read when the home screen opens and on pull to
/// refresh; the dictionary and commentary when their screens open.
class LibraryState extends ChangeNotifier {
  List<LibBanner> banners = const [];
  List<LibAnnouncement> announcements = const [];
  List<DictCategory> categories = const [];

  /// The newest commentary entries (the home screen shows the first few).
  List<CommentaryItem> latestCommentary = const [];
  List<DictEntry> latestDictionary = const [];

  bool _homeLoaded = false;
  AppLang? _homeLang;

  /// Reads the banners and announcements once (again when the language changes).
  Future<void> ensureHome(AppLang lang) async {
    if (!liveApi || !api.signedIn) return;
    if (_homeLoaded && _homeLang == lang) return;
    await refreshHome(lang);
  }

  Future<void> refreshHome(AppLang lang) async {
    if (!liveApi || !api.signedIn) return;
    final code = contentLanguage(lang);
    try {
      final b = await api.libBanners(code);
      banners = [
        for (final e in (b['items'] as List?) ?? const [])
          LibBanner.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      // Offline: what is shown stays.
    }
    try {
      final a = await api.libAnnouncements();
      announcements = [
        for (final e in (a['items'] as List?) ?? const [])
          LibAnnouncement.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {}
    try {
      final c = await api.libCommentary(code, limit: 6);
      latestCommentary = [
        for (final e in (c['items'] as List?) ?? const [])
          CommentaryItem.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {}
    try {
      final d = await api.libDictionary(code, limit: 6);
      latestDictionary = [
        for (final e in (d['items'] as List?) ?? const [])
          DictEntry.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {}
    _homeLoaded = true;
    _homeLang = lang;
    notifyListeners();
  }

  Future<List<DictEntry>> dictionary(
    AppLang lang, {
    String q = '',
    String? category,
  }) async {
    final d = await api.libDictionary(
      contentLanguage(lang),
      q: q.trim(),
      category: category,
      limit: 200,
    );
    return [
      for (final e in (d['items'] as List?) ?? const [])
        DictEntry.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
  }

  Future<List<DictCategory>> loadCategories(AppLang lang) async {
    final d = await api.libDictionaryCategories(contentLanguage(lang));
    categories = [
      for (final e in (d['items'] as List?) ?? const [])
        DictCategory.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
    notifyListeners();
    return categories;
  }

  Future<List<CommentaryItem>> commentary(
    AppLang lang, {
    int? book,
    int? chapter,
    int limit = 30,
  }) async {
    final d = await api.libCommentary(
      contentLanguage(lang),
      book: book,
      chapter: chapter,
      limit: limit,
    );
    return [
      for (final e in (d['items'] as List?) ?? const [])
        CommentaryItem.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
  }

  /// Forgets everything (sign-out).
  void clear() {
    banners = const [];
    announcements = const [];
    categories = const [];
    latestCommentary = const [];
    latestDictionary = const [];
    _homeLoaded = false;
    _homeLang = null;
    notifyListeners();
  }
}

final library = LibraryState();
