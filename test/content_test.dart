import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/content_data.dart';
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
}
