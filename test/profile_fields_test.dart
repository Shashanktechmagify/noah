import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/profile_data.dart';

void main() {
  final ids = [
    for (final s in kProfileSections)
      for (final f in s.fields) f,
  ];

  test('My information no longer has a second email, a landline or a communication language', () {
    final names = ids.map((f) => f.id).toSet();
    expect(names, isNot(contains('email2')));
    expect(names, isNot(contains('landline')));
    expect(names, isNot(contains('comm_language')));
  });

  test('the second phone is the WhatsApp number, and education is a list of choices', () {
    final phone = ids.firstWhere((f) => f.id == 'phone2');
    expect(phone.labelKey, 'pf_phone2');
    expect(phone.kind, PfKind.phone);
    final education = ids.firstWhere((f) => f.id == 'education');
    expect(education.kind, PfKind.education);
    expect(education.options, isNotEmpty);
  });

  test('10th and 12th ask for the school, marks and academic year, and the text reads back', () {
    final entries = [
      EduEntry(kEduSsc, school: "St Mary's High; Thane", marks: '85%', year: '2008-09'),
      EduEntry("Bachelor's degree"),
      EduEntry(kEduHsc, school: 'Holy Cross', marks: '425/500', year: '2010-11'),
    ];
    final text = composeEducation(entries);
    expect(text.split(r'\n').length, 1, reason: 'a raw backslash-n is not the separator');
    expect(text.split('\n').length, 3);
    expect(text.split('\n').first, startsWith('10th (SSC) — School: '));
    final back = parseEducation(text);
    expect(back.map((e) => e.label), [kEduSsc, "Bachelor's degree", kEduHsc]);
    expect(back[0].school, "St Mary's High, Thane", reason: 'a semicolon in a name is kept out of the separators');
    expect(back[0].marks, '85%');
    expect(back[0].year, '2008-09');
    expect(back[2].marks, '425/500');
    expect(back.every((e) => e.complete), isTrue);

    // Missing details are noticed; other qualifications ask for nothing more.
    expect(EduEntry(kEduSsc, school: 'x').complete, isFalse);
    expect(EduEntry('Diploma').complete, isTrue);
    // An older value (qualifications separated by commas) is read as well.
    final old = parseEducation("Diploma, Bachelor's degree", ['Diploma', "Bachelor's degree"]);
    expect(old.map((e) => e.label), ['Diploma', "Bachelor's degree"]);
  });

  test('born 27 September 2005 is 21 years 1 month on 12 November 2026', () {
    final p = ProfileState()..seedDemo();
    // As when the server sends the member's profile.
    p.loadFromServer({
      'fields': {'dob': '2005-09-27'},
    });
    final on = p.ageOn(DateTime(2026, 11, 12))!;
    expect((on.years, on.months), (21, 1));
    expect(p.ageOn(DateTime(2026, 11, 27))!.months, 2, reason: 'the day the month is complete');
    expect(p.ageOn(DateTime(2026, 9, 26))!.years, 20);
    expect(p.ageOn(DateTime(2026, 9, 27))!.years, 21);
    expect(p.ageOn(DateTime(2026, 10, 12)), (years: 21, months: 0));
  });

  test('age is worked out in years and whole months', () {
    final p = ProfileState()..seedDemo(); // born 14 March 1992
    final a = p.ageParts!;
    final now = DateTime.now();
    final total =
        (now.year - 1992) * 12 + now.month - 3 - (now.day < 14 ? 1 : 0);
    expect(a.years * 12 + a.months, total);
    expect(a.months, inInclusiveRange(0, 11));
  });
}
