import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/content_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';

void main() {
  test(
    'Tamil is one of the app languages, last in the list, with its own name',
    () {
      expect(AppLang.values.last, AppLang.ta);
      expect(AppLang.ta.native, 'தமிழ்');
      expect(AppLang.ta.english, 'Tamil');
      expect(contentLanguage(AppLang.ta), 6);
    },
  );

  test('screens have Tamil words, with the {placeholders} kept', () {
    expect(trIn(AppLang.ta, 'pf_title'), isNot(trIn(AppLang.en, 'pf_title')));
    expect(trIn(AppLang.ta, 'pf_title'), contains('தகவல்'));
    final likes = trIn(AppLang.ta, 'ng_likes');
    expect(likes, contains('{n}'));
    expect(likes, isNot(trIn(AppLang.en, 'ng_likes')));
    expect(trIn(AppLang.ta, 'ng_share_text'), contains('{url}'));
    // The education section added with Tamil has its words too.
    expect(trIn(AppLang.ta, 'pf_sec_education'), 'கல்வி விவரங்கள்');
    // A word that has no Tamil falls back to English, then to the key.
    expect(trIn(AppLang.ta, 'no_such_key'), 'no_such_key');
  });
}
