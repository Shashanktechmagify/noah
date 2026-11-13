import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/bible_books.dart';
import '../data/library_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/page_scaffold.dart';

String _why(BuildContext context, Object e) =>
    e is ApiException && e.code != 'network' ? e.message : tr(context, 'ng_no_internet');

Widget _note(BuildContext context, String text, {VoidCallback? retry}) => Padding(
  padding: const EdgeInsets.all(32),
  child: Column(
    children: [
      Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
      if (retry != null)
        TextButton(onPressed: retry, child: Text(tr(context, 'ng_try_again'))),
    ],
  ),
);

// ── Dream dictionary ────────────────────────────────────────────────────────

/// What a dream may mean, entry by entry: search by a word, or pick a category. Featured entries come first.
class DreamDictionaryScreen extends StatefulWidget {
  const DreamDictionaryScreen({super.key});

  @override
  State<DreamDictionaryScreen> createState() => _DreamDictionaryScreenState();
}

class _DreamDictionaryScreenState extends State<DreamDictionaryScreen> {
  final _query = TextEditingController();
  Timer? _typing;
  List<DictEntry>? _entries;
  List<DictCategory> _categories = const [];
  String? _category;
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final lang = AppLocale.of(context).lang;
    library
        .loadCategories(lang)
        .then((c) {
          if (mounted) setState(() => _categories = c);
        })
        .catchError((_) {});
    _load();
  }

  @override
  void dispose() {
    _typing?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await library.dictionary(
        AppLocale.of(context).lang,
        q: _query.text,
        category: _category,
      );
      if (mounted) setState(() => _entries = list);
    } catch (e) {
      if (mounted) setState(() => _error = _why(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      body: PageScaffold(
        title: tr(context, 'dict_title'),
        subtitle: tr(context, 'dict_sub'),
        leadingIcon: Icons.chevron_left,
        onLeading: () => Navigator.of(context).pop(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onChanged: (_) {
                _typing?.cancel();
                _typing = Timer(const Duration(milliseconds: 400), _load);
              },
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                hintText: tr(context, 'dict_search'),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                children: [
                  _chip(tr(context, 'dict_all'), _category == null, () {
                    setState(() => _category = null);
                    _load();
                  }),
                  for (final c in _categories)
                    _chip(c.name, _category == c.id, () {
                      setState(() => _category = c.id);
                      _load();
                    }),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (_error != null)
            _note(context, _error!, retry: _load)
          else if (entries == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (entries.isEmpty)
            _note(context, tr(context, 'dict_empty'))
          else
            WhiteCard(
              child: Column(
                children: [
                  for (final (i, e) in entries.indexed) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.border),
                    InkWell(
                      onTap: () => showContentSheet(
                        context,
                        title: e.title,
                        body: e.meaning,
                        image: e.image,
                        media: e.media,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              e.featured ? Icons.star_rounded : Icons.nights_stay_outlined,
                              color: e.featured ? const Color(0xFFF2A33A) : AppColors.magenta,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.title,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    plainPreview(e.meaning),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35),
                                  ),
                                ],
                              ),
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
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.magenta : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? AppColors.magenta : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: on ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    ),
  );
}

// ── Bible commentary ────────────────────────────────────────────────────────

/// Bible commentary the office wrote: the newest entries, or one chapter picked by book and chapter.
class LiveCommentaryScreen extends StatefulWidget {
  const LiveCommentaryScreen({super.key});

  @override
  State<LiveCommentaryScreen> createState() => _LiveCommentaryScreenState();
}

class _LiveCommentaryScreenState extends State<LiveCommentaryScreen> {
  List<CommentaryItem>? _items;
  int? _book;
  int? _chapter;
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await library.commentary(
        AppLocale.of(context).lang,
        book: _book,
        chapter: _chapter,
      );
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) setState(() => _error = _why(context, e));
    }
  }

  Future<void> _pick() async {
    final picked = await showModalBottomSheet<(int, int)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PassageSheet(),
    );
    if (picked == null) return;
    setState(() {
      _book = picked.$1;
      _chapter = picked.$2;
      _items = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      body: PageScaffold(
        title: tr(context, 'cm_title'),
        subtitle: tr(context, 'cm_live_sub'),
        leadingIcon: Icons.chevron_left,
        onLeading: () => Navigator.of(context).pop(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _pick,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, color: AppColors.magenta),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _book == null
                            ? tr(context, 'cm_pick')
                            : bibleRef(_book!, _chapter ?? 0),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (_book != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _book = null;
                            _chapter = null;
                            _items = null;
                          });
                          _load();
                        },
                        child: const Icon(Icons.close, size: 20, color: AppColors.muted),
                      )
                    else
                      const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              tr(context, _book == null ? 'cm_latest' : 'cm_title'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted),
            ),
          ),
          if (_error != null)
            _note(context, _error!, retry: _load)
          else if (items == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            _note(context, tr(context, 'cm_none'))
          else
            WhiteCard(
              child: Column(
                children: [
                  for (final (i, c) in items.indexed) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.border),
                    InkWell(
                      onTap: () => openCommentary(context, c),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.magenta,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${c.chapter}',
                                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${bibleRef(c.book, c.chapter)} · ${c.title}',
                                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.writer.isEmpty
                                        ? tr(context, 'cm_read')
                                        : tr(context, 'cm_by', args: {'name': c.writer}),
                                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                                  ),
                                ],
                              ),
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
    );
  }
}

/// Opens one commentary entry: its text, picture, video and links.
void openCommentary(BuildContext context, CommentaryItem c) => showContentSheet(
  context,
  title: '${bibleRef(c.book, c.chapter)} · ${c.title}',
  date: c.writer.isEmpty ? '' : tr(context, 'cm_by', args: {'name': c.writer}),
  body: c.body,
  image: c.image,
  media: c.allMedia,
);

/// Book first, then the chapter.
class _PassageSheet extends StatefulWidget {
  const _PassageSheet();

  @override
  State<_PassageSheet> createState() => _PassageSheetState();
}

class _PassageSheetState extends State<_PassageSheet> {
  int? _book;

  @override
  Widget build(BuildContext context) {
    final book = _book;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
            child: Row(
              children: [
                if (book != null)
                  IconButton(
                    onPressed: () => setState(() => _book = null),
                    icon: const Icon(Icons.chevron_left),
                  ),
                Expanded(
                  child: Text(
                    book == null
                        ? tr(context, 'cm_book')
                        : '${kBibleBooks[book - 1].$1} · ${tr(context, 'cm_chapter')}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: book == null
                ? ListView.builder(
                    itemCount: kBibleBooks.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(kBibleBooks[i].$1),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                      onTap: () => setState(() => _book = i + 1),
                    ),
                  )
                : GridView.count(
                    crossAxisCount: 5,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      for (var n = 1; n <= kBibleBooks[book - 1].$2; n++)
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop((book, n)),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.tint,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '$n',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.magenta),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
