import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/registration_data.dart';

void main() {
  test('each kind of ID keeps its own number and picture', () {
    final r = RegistrationState()..start('+91 98765 43210');

    // Aadhaar: number and picture.
    r.selectIdType('aadhaar');
    r
      ..idNumber = '234567890123'
      ..idFile = 'aadhaar.jpg'
      ..idPath = '/tmp/aadhaar.jpg'
      ..idProofFileId = '11'
      ..idUploadedFrom = '/tmp/aadhaar.jpg';

    // PAN: nothing of the Aadhaar shows.
    r.selectIdType('pan');
    expect(r.idType, 'pan');
    expect(r.idNumber, '');
    expect(r.idFile, isNull);
    expect(r.idPath, isNull);
    expect(r.idProofFileId, isNull);
    expect(r.idValid, isFalse, reason: 'PAN has no number and no picture yet');
    r
      ..idNumber = 'ABCDE1234F'
      ..idFile = 'pan.png'
      ..idPath = '/tmp/pan.png';

    // Back to Aadhaar: its number and picture are there again, and PAN's are kept too.
    r.selectIdType('aadhaar');
    expect(r.idNumber, '234567890123');
    expect(r.idFile, 'aadhaar.jpg');
    expect(r.idPath, '/tmp/aadhaar.jpg');
    expect(r.idProofFileId, '11');
    expect(r.idUploadedFrom, '/tmp/aadhaar.jpg');

    r.selectIdType('pan');
    expect(r.idNumber, 'ABCDE1234F');
    expect(r.idFile, 'pan.png');
    expect(r.idProofFileId, isNull, reason: 'not uploaded yet');

    // Choosing the kind that is already chosen changes nothing.
    r.selectIdType('pan');
    expect(r.idNumber, 'ABCDE1234F');
  });

  test('a kind with nothing entered leaves no trace, and a new start forgets them all', () {
    final r = RegistrationState()..start('+91 98765 43210');
    r.selectIdType('voter');
    r.selectIdType('dl'); // voter had nothing: nothing is kept
    expect(r.idSlots, isEmpty);
    r
      ..idNumber = 'MH1220110012345'
      ..idFile = 'dl.jpg';
    r.selectIdType('passport');
    expect(r.idSlots.keys, ['dl']);
    r.start('+91 98765 43210');
    expect(r.idSlots, isEmpty);
    expect(r.idType, isNull);
  });

  test('what the server holds comes back as the ID picture, the photo and the video', () {
    final r = RegistrationState();
    r.loadFromServer({
      'status': 'rejected',
      'reviewNote': 'x',
      'firstName': 'Ravi',
      'idType': 'pan',
      'idNumber': 'ABCDE1234F',
      'idProof': {'id': '21'},
      'photo': {'id': '22'},
      'video': {
        'file': {'id': '23'},
        'seconds': 75,
      },
      'submittedAt': '2026-11-10T10:00:00.000Z',
    }, '+91 9000000001');
    expect(r.idType, 'pan');
    expect(r.idProofFileId, '21');
    expect(r.idFile, isNotNull);
    expect(r.photoFileId, '22');
    expect(r.photoFile, isNotNull);
    expect(r.videoFileId, '23');
    expect(r.videoSeconds, 75);
    expect(r.videoValid, isTrue, reason: 'no need to record it again');
    expect(r.idValid, isTrue);
    expect(r.photoValid, isTrue);
  });
}
