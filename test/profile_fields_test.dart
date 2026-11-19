import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/profile_data.dart';
import 'package:noah_frontend_flutter/data/registration_data.dart'
    show kSalutations;

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

  test('the salutations are the office list, in registration and in My information', () {
    expect(kSalutations.first, 'Mr.');
    expect(
      kSalutations,
      containsAll([
        'Pastor',
        'Bishop',
        'Apostle',
        'Dr. (Mrs.)',
        'LT.-Col.',
        'Maj.-Gen.',
      ]),
    );
    expect(kSalutations.toSet().length, kSalutations.length);
    final field = ids.firstWhere((f) => f.id == 'salutation');
    expect(field.options!.map((o) => o.$1).toList(), kSalutations);
  });

  test('the second phone is the WhatsApp number, and education is a list of choices', () {
    final phone = ids.firstWhere((f) => f.id == 'phone2');
    expect(phone.labelKey, 'pf_phone2');
    expect(phone.kind, PfKind.phone);
    final education = ids.firstWhere((f) => f.id == 'education');
    expect(education.kind, PfKind.education);
    expect(education.options, isNotEmpty);
  });

  test('education is the office list and asks for nothing more', () {
    final education = ids.firstWhere((f) => f.id == 'education');
    final names = education.options!.map((o) => o.$1).toList();
    expect(names.first, 'High School');
    expect(
      names,
      containsAll([
        'Less than High School',
        'Diploma in ITI',
        'Bachelors in Arts',
        'Masters in Technology',
        'ICWA',
        'PhD',
        'Others',
      ]),
    );
    expect(names.toSet().length, names.length, reason: 'no entry twice');

    // The qualifications are kept one to a line.
    expect(
      composeEducation(['High School', 'Bachelors in Arts']),
      'High School\nBachelors in Arts',
    );
    expect(parseEducation('High School\nBachelors in Arts'), [
      'High School',
      'Bachelors in Arts',
    ]);
  });

  test('what was saved with the details of 10th and 12th reads back as the qualification alone', () {
    const saved =
        "10th (SSC) — School: St Mary's High, Thane; Marks: 85%; Academic year: 2008-09\n"
        "Bachelor's degree\n"
        '12th (HSC) — School: Holy Cross; Marks: 425/500; Academic year: 2010-11';
    expect(parseEducation(saved), [
      '10th (SSC)',
      "Bachelor's degree",
      '12th (HSC)',
    ]);
    // An older value (qualifications separated by commas) is read as well.
    expect(
      parseEducation("Diploma, Bachelor's degree", [
        'Diploma',
        "Bachelor's degree",
      ]),
      ['Diploma', "Bachelor's degree"],
    );
    expect(parseEducation(''), isEmpty);
  });

  test('born 27 September 2005 is 21 years 1 month on 12 November 2026', () {
    final p = ProfileState()..seedDemo();
    // As when the server sends the member's profile.
    p.loadFromServer({
      'fields': {'dob': '2005-09-27'},
    });
    final on = p.ageOn(DateTime(2026, 11, 12))!;
    expect((on.years, on.months), (21, 1));
    expect(
      p.ageOn(DateTime(2026, 11, 27))!.months,
      2,
      reason: 'the day the month is complete',
    );
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
