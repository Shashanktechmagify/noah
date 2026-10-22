import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/profile_data.dart';
import 'package:noah_frontend_flutter/data/registration_data.dart';

void main() {
  test('a registration reply with sizes as text still loads', () {
    // Big numbers can reach the phone as text; sign-in must not crash on them.
    registration.loadFromServer({
      'status': 'approved',
      'firstName': 'Jj',
      'submittedAt': '2026-10-21T10:00:00.000Z',
      'video': {
        'file': {'id': '73626000000116319', 'url': '/files/1'},
        'seconds': '90',
        'bytes': '2004',
      },
    }, '+91 9000000100');
    expect(registration.firstName, 'Jj');
    expect(registration.videoSeconds, 90);
    expect(registration.videoBytes, 2004);
    profile.loadFromServer({'fields': {'first_name': 'Jj'}, 'requests': []});
  });
}
