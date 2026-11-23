import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/family_data.dart';
import 'package:noah_frontend_flutter/data/profile_data.dart';
import 'package:noah_frontend_flutter/widgets/birthday_celebration.dart';
import 'package:noah_frontend_flutter/data/dial_data.dart';
import 'package:noah_frontend_flutter/data/registration_data.dart';

void main() {
  test('a child of the family keeps where they stand on becoming a member', () {
    final p = FamilyPerson.fromJson({
      'name': 'Asha Jain',
      'relation': 'daughter',
      'kind': 'kid',
      'age': 16,
      'kidId': 'k1',
      'memberState': 'login',
      'canMakeMember': false,
      'aadhaarAdded': true,
      'dob': '2010-01-02',
    });
    expect(p.isKid, isTrue);
    expect(p.kidId, 'k1');
    expect(p.memberState, 'login');
    expect(p.aadhaarAdded, isTrue);
    expect(p.dob, '2010-01-02');
  });

  test('a child without state defaults to none and cannot become a member', () {
    final p = FamilyPerson.fromJson({
      'name': 'Ravi',
      'relation': 'son',
      'kind': 'kid',
      'age': 9,
      'kidId': 'k2',
    });
    expect(p.memberState, 'none');
    expect(p.canMakeMember, isFalse);
  });

  test(
    'a consent-only registration sends only the declaration and the video',
    () {
      final r = RegistrationState();
      r.loadFromServer({
        'firstName': 'Asha',
        'lastName': 'Jain',
        'dob': '2010-01-02',
        'consentOnly': true,
        'status': 'draft',
        'declaration': {'agreed': true, 'signature': 'Asha Jain'},
        'video': {'seconds': 70},
      }, '+919000000001');
      expect(r.consentOnly, isTrue);
      final m = r.toApi();
      expect(m.keys.toSet(), {'declaration', 'video'});
      expect(m.containsKey('dob'), isFalse);
    },
  );

  test('start() leaves consent-only mode', () {
    final r = RegistrationState();
    r.loadFromServer({'consentOnly': true, 'status': 'draft'}, '+919000000001');
    r.start('+919000000002');
    expect(r.consentOnly, isFalse);
  });

  test('the Aadhaar the parents gave can be viewed', () {
    final p = FamilyPerson.fromJson({
      'name': 'Asha Jain',
      'relation': 'daughter',
      'kind': 'kid',
      'kidId': 'k1',
      'aadhaarAdded': true,
      'aadhaarNo': '234567890123',
      'aadhaarFile': true,
    });
    expect(p.aadhaarNo, '234567890123');
    expect(p.aadhaarFile, isTrue);
  });

  test('Aadhaar and mobile number checks', () {
    expect(idNumberError('aadhaar', '234567890123'), isNull);
    expect(
      idNumberError('aadhaar', '123456789012'),
      isNotNull,
    ); // starts with 1
    expect(idNumberError('aadhaar', '2345'), isNotNull);
    const india = DialCountry('India', 'IN', '+91');
    expect(india.validLength(10), isTrue);
    expect(india.validLength(9), isFalse);
  });

  test(
    'a birthday is today by day and month, and 29 February on 28 February',
    () {
      profile.set('dob', '1990-11-23');
      expect(isBirthdayToday(DateTime(2026, 11, 23)), isTrue);
      expect(isBirthdayToday(DateTime(2026, 11, 24)), isFalse);
      profile.set('dob', '2000-02-29');
      expect(isBirthdayToday(DateTime(2026, 2, 28)), isTrue); // not a leap year
      expect(isBirthdayToday(DateTime(2028, 2, 28)), isFalse);
      expect(isBirthdayToday(DateTime(2028, 2, 29)), isTrue);
      profile.set('dob', '');
      expect(isBirthdayToday(DateTime(2026, 11, 23)), isFalse);
    },
  );

  test('the anniversary is today by day and month', () {
    profile.set('anniversary', '2020-11-23');
    expect(isAnniversaryToday(DateTime(2026, 11, 23)), isTrue);
    expect(isAnniversaryToday(DateTime(2026, 11, 22)), isFalse);
    profile.set('anniversary', '');
    expect(isAnniversaryToday(DateTime(2026, 11, 23)), isFalse);
  });
}
