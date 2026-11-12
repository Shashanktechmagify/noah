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
    expect(education.kind, PfKind.multi);
    expect(education.options, isNotEmpty);
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
