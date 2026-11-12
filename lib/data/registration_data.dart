import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart' show AppLang;
import 'noahgram_data.dart';
import 'world_data.dart';

/// Demo state for the new-member registration. Replace the actions with API
/// calls; the server must store the declaration, ID proof, photo and video.

enum RegStatus { pending, approved, videoReturned }

/// Numbers that are already members (they skip registration).
const kDemoMembers = {'+91 98765 43210'};

bool isExistingMember(String phone) => kDemoMembers.contains(phone.trim());

/// ID proofs: translation key of the label, and a number placeholder.
const kIdTypes = [
  ('aadhaar', 'reg_id_aadhaar', '2345 6789 0123'),
  ('pan', 'reg_id_pan', 'ABCDE1234F'),
  ('passport', 'reg_id_passport', 'A1234567'),
  ('dl', 'reg_id_dl', 'MH12 20110012345'),
  ('voter', 'reg_id_voter', 'ABC1234567'),
  ('emirates', 'reg_id_emirates', '784-1990-1234567-1'),
];

/// Other documents a member may add: only the file is needed (no number).
const kOtherDocTypes = [
  ('salary', 'doc_salary'),
  ('qualification', 'doc_qualification'),
  ('marriage', 'doc_marriage'),
];

/// Translation key for the name of a document type (an ID or one of the other documents).
String docLabelKey(String type) {
  for (final t in kIdTypes) {
    if (t.$1 == type) return t.$2;
  }
  return kOtherDocTypes.firstWhere((t) => t.$1 == type).$2;
}

/// A further document of the registration: another ID with its number, or a salary slip, a qualification or
/// a marriage certificate. The main ID proof is kept apart (idType, idNumber, idFile).
class RegDocument {
  RegDocument({
    required this.type,
    this.number = '',
    this.fileName,
    this.path,
    this.fileId,
  });

  final String type;
  String number;
  String? fileName;

  /// The file picked on this phone, and the one the server holds.
  String? path;
  String? fileId;

  /// The path last uploaded, so a file is not sent twice.
  String? uploadedFrom;

  bool get isId => kIdTypes.any((t) => t.$1 == type);

  /// A file is chosen, and an ID has a number that fits.
  bool get valid =>
      (path != null || fileId != null) &&
      (!isId || idNumberError(type, number) == null);
}

/// The Emirates ID is only offered to members whose address is in the UAE.
const kUaeCountry = 'United Arab Emirates';

List<(String, String, String)> idTypesFor(String country) => [
  for (final t in kIdTypes)
    if (t.$1 != 'emirates' || country == kUaeCountry) t,
];

/// Allowed length (min, max seconds) of the video, which is the member reading
/// the whole declaration aloud: 1 to 2 minutes in every language.
(int, int) videoLimits(AppLang lang) => (60, 120);
const kOfficePhone = '+91 82915 65758';

/// Salutations offered in step 1.
const kSalutations = [
  'Mr.',
  'Mrs.',
  'Miss',
  'Ms',
  'Master',
  'Pastor',
  'Evg.',
  'Rev.',
  'Fr.',
  'Sr.',
  'Bro.',
  'Sis.',
  'Adv.',
  'Dr.',
  'Bishop',
  'Apostle',
  'Prop.',
  'Baby',
  'Late.',
  'Dr. (Mr.)',
  'Dr. (Mrs.)',
  'Dr. (Miss)',
  'Prof.',
  'Capt.',
  'Major',
  'LT.-Col.',
  'Brgdr.',
  'Cmdr.',
  'Judge',
  'Maj.-Gen.',
];

/// Largest document or photo accepted, in bytes.
const kMaxUploadBytes = 5 * 1024 * 1024;
const kDocExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
const kPhotoExtensions = ['jpg', 'jpeg', 'png'];

String _compact(String v) => v.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

/// Error key (translation) for a name part, or null when it is fine.
String? nameError(String v, {bool required = true}) {
  final t = v.trim();
  if (t.isEmpty) return required ? 'reg_err_name' : null;
  return RegExp(r"^[\p{L}][\p{L} .'-]{1,}$", unicode: true).hasMatch(t)
      ? null
      : 'reg_err_name';
}

String? emailError(String v) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())
    ? null
    : 'reg_err_email';

/// Members must be at least 18.
String? dobError(DateTime? d) {
  if (d == null) return null;
  final now = DateTime.now();
  var age = now.year - d.year;
  if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
  return age >= 18 ? null : 'reg_err_dob18';
}

/// Anniversary must be a past date after the member turned 18.
String? anniversaryError(DateTime? a, DateTime? dob) {
  if (a == null) return null;
  if (a.isAfter(DateTime.now())) return 'reg_err_anniv_future';
  if (dob != null && a.isBefore(DateTime(dob.year + 18, dob.month, dob.day))) {
    return 'reg_err_anniv_early';
  }
  return null;
}

/// Contact number: 7 to 15 digits, optional leading +.
String? phoneError(String v) =>
    RegExp(r'^\+?\d{7,15}$').hasMatch(v.replaceAll(RegExp(r'[\s-]'), ''))
    ? null
    : 'reg_err_phone';

String? pinError(String v) =>
    RegExp(r'^[1-9]\d{5}$').hasMatch(v.trim()) ? null : 'reg_err_pin';

String? addressError(String v) => v.trim().length >= 5 ? null : 'reg_err_addr';

/// Format check for each ID type; returns an error key or null.
String? idNumberError(String? type, String v) {
  final c = _compact(v);
  final ok = switch (type) {
    'aadhaar' => RegExp(r'^[2-9]\d{11}$').hasMatch(c),
    'pan' => RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(c),
    'passport' => RegExp(r'^[A-PR-WY][1-9]\d{5}[1-9]$').hasMatch(c),
    'dl' => RegExp(r'^[A-Z]{2}\d{2}(19|20)\d{2}\d{7}$').hasMatch(c),
    'voter' => RegExp(r'^[A-Z]{3}\d{7}$').hasMatch(c),
    'emirates' => RegExp(r'^784\d{12}$').hasMatch(c),
    _ => false,
  };
  return ok ? null : 'reg_err_$type';
}

class RegistrationState extends ChangeNotifier {
  // Step 1: details
  String salutation = '';
  String nationality = 'India';
  String firstName = '';
  String middleName = '';
  String lastName = '';
  String email = '';
  String gender = ''; // male | female | other
  DateTime? dob;
  String marital =
      ''; // single | married | widow | widower | separated | divorced
  DateTime? anniversary; // required when married
  String reference = '';
  String referenceDial = '+91'; // country code of the reference number
  String referencePhone = ''; // the number without the country code

  // The two contacts. Registration needs an email address and a mobile number, each confirmed with a code sent to it.
  // The server keeps a contact only once it is confirmed, so what it sends back is what counts as confirmed.
  String mobileDial = '+91'; // typed: country code
  String mobileNumber = ''; // typed: the number without the country code
  String confirmedEmail = '';
  String confirmedDial = '';
  String confirmedMobile = ''; // digits only

  // Step 2: address
  String address1 = '';
  String address2 = '';
  String country = 'India';
  String state = '';
  String city = '';
  String pin = '';

  // Step 3: ID proof
  /// Further documents besides the main ID: any two, any three.
  final List<RegDocument> documents = [];
  String? idType;
  String idNumber = '';
  String? idFile; // display name
  String? idPath; // local path of the picked file

  // Step 4: photo
  String? photoFile; // display name
  String? photoPath; // local path of the picked image

  // Step 5: declaration
  bool agreed = false;
  String signature = '';
  DateTime? signedOn;

  // Step 6: video
  AppLang videoLang = AppLang.en; // language the declaration was read in
  int? videoSeconds;
  int? videoBytes; // size of the file that will be uploaded (compressed)
  int? videoOriginalBytes; // size as recorded
  String? videoPath; // the recorded file (null in the demo fallback)

  // Files stored on the server (live mode), and which local file each came from
  String? idProofFileId;
  String? photoFileId;
  String? videoFileId;
  String? idUploadedFrom;
  String? photoUploadedFrom;
  String? videoUploadedFrom;

  // Outcome
  String phone = '';
  bool completed = false;
  DateTime? registeredOn; // when the registration was submitted
  RegStatus status = RegStatus.pending;

  /// Call after changing a field so listeners (the footer button) refresh.
  void touch() => notifyListeners();

  static String _digitsOf(String v) => v.replaceAll(RegExp(r'\D'), '');

  /// Signing in with an email address or a mobile number confirms that one; the other is confirmed in step 1.
  void _confirmSignInContact(String identity) {
    email = confirmedEmail = '';
    confirmedDial = confirmedMobile = mobileNumber = '';
    mobileDial = '+91';
    if (identity.contains('@')) {
      email = confirmedEmail = identity.trim().toLowerCase();
      return;
    }
    final m = RegExp(r'^(\+\d{1,4})\s*(.*)$').firstMatch(identity.trim());
    if (m == null) return;
    mobileDial = confirmedDial = m.group(1)!;
    mobileNumber = m.group(2)!;
    confirmedMobile = _digitsOf(mobileNumber);
  }

  void start(String phoneNumber) {
    phone = phoneNumber;
    firstName = middleName = lastName = email = gender = marital = salutation =
        '';
    _confirmSignInContact(phoneNumber);
    nationality = 'India';
    anniversary = null;
    reference = referencePhone = address1 = address2 = city = pin = idNumber =
        signature = '';
    dob = null;
    country = 'India';
    referenceDial = '+91';
    state = '';
    idType = idFile = idPath = photoFile = photoPath = null;
    documents.clear();
    agreed = false;
    signedOn = null;
    videoSeconds = null;
    videoPath = null;
    videoLang = AppLang.en;
    videoBytes = videoOriginalBytes = null;
    idProofFileId = photoFileId = videoFileId = null;
    idUploadedFrom = photoUploadedFrom = videoUploadedFrom = null;
    completed = false;
    registeredOn = null;
    status = RegStatus.pending;
    notifyListeners();
  }

  // ── Derived ────────────────────────────────────────────────────────────
  String get fullName => [
    firstName,
    middleName,
    lastName,
  ].map((p) => p.trim()).where((p) => p.isNotEmpty).join(' ');

  /// e.g. "Mr Shashank Sanjay Gupta".
  String get displayName => '$salutation $fullName'.trim();

  /// Whole years since [dob].
  int? get age {
    final d = dob;
    if (d == null) return null;
    final now = DateTime.now();
    var a = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) a--;
    return a;
  }

  bool get signatureMatches =>
      signature.trim().isNotEmpty &&
      signature.trim().toLowerCase() == fullName.toLowerCase();

  bool get emailConfirmed =>
      confirmedEmail.isNotEmpty && email.trim().toLowerCase() == confirmedEmail;
  bool get mobileConfirmed =>
      confirmedMobile.isNotEmpty &&
      _digitsOf(mobileNumber) == confirmedMobile &&
      mobileDial == confirmedDial;

  /// Both the email address and the mobile number have been confirmed with a code.
  bool get contactsConfirmed => emailConfirmed && mobileConfirmed;

  /// A code came back right: the address (or number) is now the member's.
  void confirmEmail(String value) {
    email = value.trim();
    confirmedEmail = email.toLowerCase();
    notifyListeners();
  }

  void confirmMobile(String dial, String number) {
    mobileDial = confirmedDial = dial;
    mobileNumber = number;
    confirmedMobile = _digitsOf(number);
    notifyListeners();
  }

  bool get detailsValid =>
      contactsConfirmed &&
      nameError(firstName) == null &&
      nameError(middleName, required: false) == null &&
      nameError(lastName) == null &&
      emailError(email) == null &&
      salutation.isNotEmpty &&
      nationality.isNotEmpty &&
      gender.isNotEmpty &&
      dob != null &&
      dobError(dob) == null &&
      marital.isNotEmpty &&
      (marital != 'married' ||
          (anniversary != null &&
              anniversaryError(anniversary, dob) == null)) &&
      nameError(reference, required: false) == null &&
      referenceValid;

  /// The reference person is optional, but name and number go together.
  bool get referenceValid {
    final hasName = reference.trim().isNotEmpty;
    final hasPhone = referencePhone.trim().isNotEmpty;
    if (!hasName && !hasPhone) return true;
    return hasName && hasPhone && phoneError(referencePhone) == null;
  }

  bool get addressValid =>
      addressError(address1) == null &&
      city.trim().isNotEmpty &&
      country.isNotEmpty &&
      (state.isNotEmpty || (World.ready?.statesOf(country).isEmpty ?? true)) &&
      pinError(pin) == null;

  bool get documentsValid => documents.every((d) => d.valid);

  bool get idValid =>
      idType != null &&
      idNumberError(idType, idNumber) == null &&
      idFile != null &&
      documentsValid;

  bool get photoValid => photoFile != null;

  bool get declarationValid => agreed && signatureMatches;

  bool get videoValid {
    final (min, max) = videoLimits(videoLang);
    return videoSeconds != null && videoSeconds! >= min && videoSeconds! <= max;
  }

  bool stepValid(int step) => switch (step) {
    0 => detailsValid,
    1 => addressValid,
    2 => idValid,
    3 => photoValid,
    4 => declarationValid,
    _ => videoValid,
  };

  // ── Actions ────────────────────────────────────────────────────────────
  /// Sets the signing date the first time the declaration is accepted.
  void sign() {
    signedOn ??= DateTime.now();
    notifyListeners();
  }

  void complete() {
    completed = true;
    registeredOn = DateTime.now();
    status = RegStatus.pending;
    notifyListeners();
  }

  /// Demo: the office approves. The member's name then shows across the app.
  void approve() {
    status = RegStatus.approved;
    noahgram.updateProfile(name: fullName, bio: noahgram.me.bio);
    notifyListeners();
  }

  /// Demo: the office sends the video back for a re-record.
  void returnVideo() {
    status = RegStatus.videoReturned;
    videoSeconds = null;
    videoPath = null;
    videoBytes = videoOriginalBytes = null;
    notifyListeners();
  }

  // ── Server (live mode) ─────────────────────────────────────────────────
  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// What the API stores. Empty fields are left out so a save never wipes
  /// something the member filled in earlier.
  Map<String, dynamic> toApi() {
    final m = <String, dynamic>{};
    void put(String k, String v) {
      if (v.trim().isNotEmpty) m[k] = v.trim();
    }

    put('salutation', salutation);
    put('nationality', nationality);
    put('firstName', firstName);
    put('middleName', middleName);
    put('lastName', lastName);
    put('email', email);
    put('gender', gender);
    if (dob != null) m['dob'] = _day(dob!);
    put('marital', marital);
    if (marital == 'married' && anniversary != null) {
      m['anniversary'] = _day(anniversary!);
    }
    put('reference', reference);
    put('referenceDial', referenceDial);
    put('referencePhone', referencePhone);
    put('address1', address1);
    put('address2', address2);
    put('country', country);
    put('state', state);
    put('city', city);
    put('pin', pin);
    if (idType != null) m['idType'] = idType;
    put('idNumber', idNumber.replaceAll(RegExp(r'[\s-]'), '').toUpperCase());
    if (idProofFileId != null) m['idProofFileId'] = idProofFileId;
    // The whole list every time: a document that is no longer in it is removed on the server.
    m['documents'] = [
      for (final d in documents)
        if (d.fileId != null)
          {
            'fileId': d.fileId,
            'type': d.type,
            if (d.isId)
              'number': d.number.replaceAll(RegExp(r'[\s-]'), '').toUpperCase(),
          },
    ];
    if (photoFileId != null) m['photoFileId'] = photoFileId;
    if (agreed || signature.trim().isNotEmpty) {
      m['declaration'] = {
        'agreed': agreed,
        'signature': signature.trim(),
        'language': 'en',
      };
    }
    if (videoSeconds != null || videoFileId != null) {
      m['video'] = {
        'fileId': ?videoFileId,
        'seconds': ?videoSeconds,
        'bytes': ?videoBytes,
        'language': videoLang.name,
      };
    }
    return m;
  }

  /// Fills the form from what the server holds (resuming after sign-in).
  void loadFromServer(Map<String, dynamic> m, String phoneNumber) {
    String s(String k, [String fallback = '']) {
      final v = m[k];
      return v == null || '$v'.isEmpty ? fallback : '$v';
    }

    DateTime? d(String k) => m[k] == null ? null : DateTime.tryParse('${m[k]}');
    phone = phoneNumber;
    salutation = s('salutation');
    nationality = s('nationality', 'India');
    firstName = s('firstName');
    middleName = s('middleName');
    lastName = s('lastName');
    email = s('email');
    confirmedEmail = email.toLowerCase();
    confirmedDial = s('countryCode');
    confirmedMobile = _digitsOf(s('mobileNumber'));
    if (confirmedMobile.isNotEmpty) {
      mobileDial = confirmedDial;
      mobileNumber = s('mobileNumber');
    }
    gender = s('gender');
    dob = d('dob');
    marital = s('marital');
    anniversary = d('anniversary');
    reference = s('reference');
    referenceDial = s('referenceDial', '+91');
    referencePhone = s('referencePhone');
    address1 = s('address1');
    address2 = s('address2');
    country = s('country', 'India');
    state = s('state');
    city = s('city');
    pin = s('pin');
    idType = m['idType'] as String?;
    idNumber = s('idNumber');

    final idProof = m['idProof'] as Map<String, dynamic>?;
    idProofFileId = idProof?['id'] as String?;
    idFile = idProofFileId == null ? null : 'Uploaded';
    idPath = null;
    idUploadedFrom = null;

    final photo = m['photo'] as Map<String, dynamic>?;
    photoFileId = photo?['id'] as String?;
    photoFile = photoFileId == null ? null : 'Uploaded';
    photoPath = null;
    photoUploadedFrom = null;

    documents
      ..clear()
      ..addAll([
        for (final d in (m['documents'] as List?) ?? const [])
          if (d is Map)
            RegDocument(
              type: '${d['type']}',
              number: '${d['number'] ?? ''}',
              fileName: '${d['name'] ?? 'Uploaded'}',
              fileId: '${d['id']}',
            ),
      ]);

    final decl = (m['declaration'] as Map<String, dynamic>?) ?? const {};
    agreed = decl['agreed'] == true;
    signature = '${decl['signature'] ?? ''}';
    signedOn = agreed ? DateTime.now() : null;

    final video = (m['video'] as Map<String, dynamic>?) ?? const {};
    final vf = video['file'] as Map<String, dynamic>?;
    videoFileId = vf?['id'] as String?;
    // The server sends numbers, but accept text too so a stray string cannot crash sign-in.
    int? whole(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
    videoSeconds = whole(video['seconds']);
    videoBytes = whole(video['bytes']);
    videoPath = null;
    videoUploadedFrom = null;

    final submitted = m['submittedAt'] == null
        ? null
        : DateTime.tryParse('${m['submittedAt']}');
    registeredOn = submitted;
    completed = submitted != null && '${m['status']}' != 'draft';
    status = switch ('${m['status']}') {
      'approved' => RegStatus.approved,
      'videoReturned' => RegStatus.videoReturned,
      _ => RegStatus.pending,
    };
    notifyListeners();
  }

  /// The first step that still needs work (where a returning member resumes).
  int get firstIncompleteStep {
    for (var i = 0; i < 6; i++) {
      if (!stepValid(i)) return i;
    }
    return 5;
  }
}

final registration = RegistrationState();
