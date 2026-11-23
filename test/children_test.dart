import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/family_data.dart';
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
}
