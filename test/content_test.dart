import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/widgets/content_card.dart';
import 'package:noah_frontend_flutter/widgets/rich_html.dart';
import 'package:noah_frontend_flutter/data/content_data.dart';
import 'package:noah_frontend_flutter/data/manna_engagement.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';

void main() {
  test("the office's Manna becomes one block of text with its category and a reading time", () {
    final m = mannaFromJson({
      'id': '73626000000143029',
      'date': istDay(),
      'title': 'Nothing can separate us',
      'message': List.filled(450, 'word').join(' '),
      'prayer': 'Amen.',
      'category': {'id': '1', 'title': 'Hope', 'color': '#F59E0B'},
    });
    expect(m.id, '73626000000143029');
    expect(m.titleKey, 'Nothing can separate us');
    expect(m.ref, 'Hope');
    expect(m.verse, '');
    expect(m.minutes, 3);
    expect(m.daysAgo, 0);
    expect(m.prayer, 'Amen.');
  });

  test('prayers and confessions keep their text and a missing prayer is empty', () {
    final p = prayerFromJson({'title': 'Peace', 'body': 'Lord...', 'prayer': null, 'date': '2020-01-01'});
    expect(p.title, 'Peace');
    expect(p.daysAgo, greaterThan(100));
    final c = confessionFromJson({'title': 'I am blessed', 'body': 'Blessed.', 'prayer': null});
    expect(c.prayer, '');
    expect(c.theme, '');
  });

  test('each app language maps to the server language number', () {
    expect(contentLanguage(AppLang.en), 1);
    expect(contentLanguage(AppLang.hi), 2);
    expect(contentLanguage(AppLang.mr), 3);
    expect(contentLanguage(AppLang.te), 4);
    expect(contentLanguage(AppLang.ml), 5);
    expect(contentLanguage(AppLang.kn), 7);
  });

  test("today is the date in India, not UTC", () {
    // 20:00 UTC on 27 Oct is already 28 Oct in India.
    expect(istDay(DateTime.utc(2026, 10, 27, 20)), '2026-10-28');
    expect(istDay(DateTime.utc(2026, 10, 27, 10)), '2026-10-27');
  });

  test('Manna keeps its picture, writer, word count and whether it ends in a confession', () {
    final m = mannaFromJson({
      'id': '1',
      'date': istDay(),
      'title': 'T',
      'message': '<p>Hello <strong>world</strong></p>',
      'prayer': '<p><em>I am free</em></p>',
      'closingType': 'confession',
      'writer': {'id': '9', 'name': 'Michael Fernandes'},
      'wordCount': 400,
      'image': 'https://example.com/a.jpg',
    });
    expect(m.closingConfession, true);
    expect(m.writer, 'Michael Fernandes');
    expect(m.image, 'https://example.com/a.jpg');
    expect(m.minutes, 2);
    expect(m.reflection, '<p>Hello <strong>world</strong></p>');
    final p = prayerFromJson({'id': '5', 'source': 'manna', 'title': 'x', 'body': 'b', 'date': istDay()});
    expect(p.mannaId, '5');
    expect(prayerFromJson({'id': '6', 'source': 'prayers', 'title': 'x', 'body': 'b', 'date': istDay()}).mannaId, null);
  });

  testWidgets('bold written in the console is bold in the app; plain text is shown as it is', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              RichHtml('<p>Hello <strong>bold words</strong> and <em>slanted</em></p>'),
              RichHtml('Older entry\nsecond line'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    bool has(InlineSpan root, bool Function(TextStyle?) test) {
      var found = false;
      root.visitChildren((s) {
        if (s is TextSpan && s.text != null && test(s.style)) found = true;
        return true;
      });
      return found;
    }

    final rich = tester.widgetList<RichText>(find.byType(RichText)).where((w) => w.text.toPlainText().contains('bold words')).first;
    expect(has(rich.text, (st) => st?.fontWeight == FontWeight.bold || st?.fontWeight == FontWeight.w700), isTrue);
    expect(has(rich.text, (st) => st?.fontStyle == FontStyle.italic), isTrue);
    expect(find.text('Older entry\nsecond line'), findsOneWidget);
  });

  testWidgets('a View all card shows its title and details; a broken or missing picture does not break it', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ContentCard(title: 'Nothing can separate us', meta: 'Hope · 3 min', badge: 'Today', onTap: () => tapped = true),
              const ContentCard(title: 'Second', image: 'https://invalid.invalid/not-a-picture.jpg', preview: 'A line of text'),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Nothing can separate us'), findsOneWidget);
    expect(find.text('Hope · 3 min'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('A line of text'), findsOneWidget);
    await tester.tap(find.text('Nothing can separate us'));
    expect(tapped, isTrue);
  });

  test('previews drop the formatting tags', () {
    expect(plainPreview('<p>Hello <strong>bold</strong></p><p>Second&nbsp;line &amp; more</p>'), 'Hello bold Second line & more');
  });

  test('a Manna keeps its day and its like, view and comment counts; comments know which are mine', () {
    final m = mannaFromJson({
      'id': '7',
      'date': '2026-10-27',
      'title': 'T',
      'message': 'm',
      'prayer': '',
      'likes': 3,
      'views': 120,
      'comments': 2,
    });
    expect(m.date, DateTime(2026, 10, 27));
    expect([m.likes, m.views, m.comments], [3, 120, 2]);
    final e = engagementOf(m);
    expect([e.likes, e.views, e.commentCount, e.liked], [3, 120, 2, false]);
    // A newer list from the server updates the counts of a page that has not read its comments yet.
    syncEngagement([mannaFromJson({'id': '7', 'date': '2026-10-27', 'title': 'T', 'message': 'm', 'likes': 5, 'views': 130, 'comments': 4})]);
    expect([e.likes, e.views, e.commentCount], [5, 130, 4]);
    final c = MannaComment.fromJson({
      'id': '9',
      'author': {'id': '1', 'name': 'Asha Rao'},
      'text': 'Amen',
      'createdAt': '2026-10-27T10:00:00.000Z',
      'mine': true,
    });
    expect([c.author, c.text, c.mine], ['Asha Rao', 'Amen', true]);
  });
}
