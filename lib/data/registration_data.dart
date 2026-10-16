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

/// The Emirates ID is only offered to members whose address is in the UAE.
const kUaeCountry = 'United Arab Emirates';

List<(String, String, String)> idTypesFor(String country) => [
  for (final t in kIdTypes)
    if (t.$1 != 'emirates' || country == kUaeCountry) t,
];

/// Allowed length (min, max seconds) of the video, which is the member reading
/// the whole declaration aloud: 1 to 2 minutes in every language.
(int, int) videoLimits(AppLang lang) => (60, 120);
const kOfficePhone = '+91 98200 00000';

/// Salutations offered in step 1.
const kSalutations = ['Mr', 'Mrs', 'Ms', 'Miss', 'Dr', 'Rev', 'Ps'];

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

  // Step 2: address
  String address1 = '';
  String address2 = '';
  String country = 'India';
  String state = '';
  String city = '';
  String pin = '';

  // Step 3: ID proof
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

  void start(String phoneNumber) {
    phone = phoneNumber;
    firstName = middleName = lastName = email = gender = marital = salutation =
        '';
    nationality = 'India';
    anniversary = null;
    reference = referencePhone = address1 = address2 = city = pin = idNumber =
        signature = '';
    dob = null;
    country = 'India';
    referenceDial = '+91';
    state = '';
    idType = idFile = idPath = photoFile = photoPath = null;
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

  bool get detailsValid =>
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

  bool get idValid =>
      idType != null &&
      idNumberError(idType, idNumber) == null &&
      idFile != null;

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

    final decl = (m['declaration'] as Map<String, dynamic>?) ?? const {};
    agreed = decl['agreed'] == true;
    signature = '${decl['signature'] ?? ''}';
    signedOn = agreed ? DateTime.now() : null;

    final video = (m['video'] as Map<String, dynamic>?) ?? const {};
    final vf = video['file'] as Map<String, dynamic>?;
    videoFileId = vf?['id'] as String?;
    videoSeconds = (video['seconds'] as num?)?.toInt();
    videoBytes = (video['bytes'] as num?)?.toInt();
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
