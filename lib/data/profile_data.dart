import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'registration_data.dart';

/// The member's full profile shown in Me → My information. Demo data; the
/// server will hold the real values (many come from registration).

enum PfKind {
  text,
  date,
  choice,
  phone,
  email,
  pin,
  idNumber,
  number,
  readOnly,
}

class PfField {
  const PfField(
    this.id,
    this.labelKey,
    this.kind, {
    this.required = false,
    this.options,
    this.idType,
  });

  final String id;

  /// Translation key of the label.
  final String labelKey;
  final PfKind kind;

  /// Required fields are counted, and the member is asked to fill them in.
  final bool required;

  /// For [PfKind.choice]: (stored value, translation key or null to show as is).
  final List<(String, String?)>? options;

  /// For [PfKind.idNumber]: which ID format to validate against.
  final String? idType;
}

class PfSection {
  const PfSection(this.titleKey, this.fields);

  final String titleKey;
  final List<PfField> fields;
}

const _bloodGroups = [
  ('A+', null),
  ('A-', null),
  ('B+', null),
  ('B-', null),
  ('AB+', null),
  ('AB-', null),
  ('O+', null),
  ('O-', null),
];

const _yesNo = [
  ('no', 'pf_no'),
  ('occasionally', 'pf_occasionally'),
  ('yes', 'pf_yes'),
];

const kProfileSections = [
  PfSection('pf_sec_personal', [
    PfField(
      'salutation',
      'reg_sal',
      PfKind.choice,
      required: true,
      options: [
        ('Mr', null),
        ('Mrs', null),
        ('Ms', null),
        ('Miss', null),
        ('Dr', null),
        ('Rev', null),
        ('Ps', null),
      ],
    ),
    PfField('first_name', 'reg_first', PfKind.text, required: true),
    PfField('middle_name', 'reg_middle', PfKind.text),
    PfField('last_name', 'reg_last', PfKind.text, required: true),
    PfField(
      'gender',
      'reg_gender',
      PfKind.choice,
      required: true,
      options: [
        ('male', 'reg_male'),
        ('female', 'reg_female'),
        ('other', 'reg_other'),
      ],
    ),
    PfField(
      'blood_group',
      'pf_blood',
      PfKind.choice,
      required: true,
      options: _bloodGroups,
    ),
    PfField('dob', 'reg_dob', PfKind.date, required: true),
    PfField(
      'marital',
      'reg_marital',
      PfKind.choice,
      required: true,
      options: [
        ('single', 'reg_single'),
        ('married', 'reg_married'),
        ('widow', 'reg_widow'),
        ('widower', 'reg_widower'),
        ('separated', 'reg_separated'),
        ('divorced', 'reg_divorced'),
      ],
    ),
    // Required only when the member is married (see ProfileState.isRequired).
    PfField('anniversary', 'reg_anniv', PfKind.date),
    PfField('deceased', 'pf_deceased', PfKind.date),
  ]),
  PfSection('pf_sec_contact', [
    PfField('phone1', 'pf_phone1', PfKind.phone, required: true),
    PfField('email', 'reg_email', PfKind.email, required: true),
    PfField('email2', 'pf_email2', PfKind.email),
    PfField('phone2', 'pf_phone2', PfKind.phone),
    PfField('landline', 'pf_landline', PfKind.phone),
    PfField('occupation', 'pf_occupation', PfKind.text),
    // Set automatically from the registration date; members cannot change it.
    PfField('joined', 'pf_joined', PfKind.readOnly),
  ]),
  PfSection('pf_sec_address', [
    PfField('address', 'pf_address', PfKind.text, required: true),
    PfField('location', 'pf_location', PfKind.text, required: true),
    PfField('pin', 'reg_pin', PfKind.pin, required: true),
  ]),
  PfSection('pf_sec_corr', [
    PfField('corr_address', 'pf_address', PfKind.text),
    PfField('corr_location', 'pf_location', PfKind.text),
    PfField('corr_pin', 'reg_pin', PfKind.pin),
  ]),
  PfSection('pf_sec_other', [
    PfField('mother_tongue', 'pf_mother_tongue', PfKind.text, required: true),
    PfField(
      'comm_language',
      'pf_comm_lang',
      PfKind.choice,
      required: true,
      options: [
        ('English', null),
        ('Hindi', null),
        ('Marathi', null),
        ('Kannada', null),
        ('Malayalam', null),
        ('Telugu', null),
      ],
    ),
    PfField('groups', 'pf_groups', PfKind.text),
    PfField('pan', 'reg_id_pan', PfKind.idNumber, idType: 'pan'),
    PfField('aadhaar', 'reg_id_aadhaar', PfKind.idNumber, idType: 'aadhaar'),
    PfField('emirates', 'reg_id_emirates', PfKind.idNumber, idType: 'emirates'),
    PfField('passport', 'reg_id_passport', PfKind.idNumber, idType: 'passport'),
    PfField('voter', 'reg_id_voter', PfKind.idNumber, idType: 'voter'),
    PfField('dl', 'reg_id_dl', PfKind.idNumber, idType: 'dl'),
    PfField('religion', 'pf_religion', PfKind.text),
    PfField('age', 'pf_age', PfKind.readOnly),
    PfField('height', 'pf_height', PfKind.number),
    PfField('weight', 'pf_weight', PfKind.number),
    PfField(
      'complexion',
      'pf_complexion',
      PfKind.choice,
      options: [
        ('fair', 'pf_cx_fair'),
        ('wheatish', 'pf_cx_wheatish'),
        ('brown', 'pf_cx_brown'),
        ('dark', 'pf_cx_dark'),
      ],
    ),
    PfField(
      'diet',
      'pf_diet',
      PfKind.choice,
      options: [
        ('veg', 'pf_diet_veg'),
        ('nonveg', 'pf_diet_nonveg'),
        ('egg', 'pf_diet_egg'),
        ('vegan', 'pf_diet_vegan'),
      ],
    ),
    PfField('smoking', 'pf_smoking', PfKind.choice, options: _yesNo),
    PfField('drink', 'pf_drink', PfKind.choice, options: _yesNo),
    PfField('income', 'pf_income', PfKind.text),
    PfField('reference', 'reg_ref', PfKind.text),
    PfField('reference_phone', 'pf_ref_phone', PfKind.phone),
    PfField('education', 'pf_education', PfKind.text),
    PfField('employed', 'pf_employed', PfKind.text),
  ]),
];

/// dd/mm/yyyy from an ISO date string.
String displayDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

enum RequestStatus { pending, approved, rejected }

/// A member's request to change or add one detail. Members cannot edit their
/// details themselves: the admin sees the request and the detail changes only
/// if the admin accepts it.
class ChangeRequest {
  ChangeRequest({
    required this.fieldId,
    required this.oldValue,
    required this.newValue,
    DateTime? at,
    this.status = RequestStatus.pending,
  }) : at = at ?? DateTime.now();

  final String fieldId;

  /// What the detail was when the request was made (empty if it was missing).
  final String oldValue;
  final String newValue;
  final DateTime at;
  RequestStatus status;
}

class ProfileState extends ChangeNotifier {
  final _values = <String, String>{};

  /// Id of the member's photo on the server (live mode), shown on the Me page.
  String? photoId;

  /// Requests raised with the admin, newest first (demo store; the backend
  /// keeps these and the admin accepts or rejects them).
  final requests = <ChangeRequest>[];

  /// The open request for [fieldId], if any.
  ChangeRequest? pendingFor(String fieldId) {
    for (final r in requests) {
      if (r.fieldId == fieldId && r.status == RequestStatus.pending) return r;
    }
    return null;
  }

  int get pendingCount =>
      requests.where((r) => r.status == RequestStatus.pending).length;

  /// Sends a change to the admin. The detail itself does not change yet. A new
  /// request for the same detail replaces the open one.
  void requestChange(String fieldId, String newValue) {
    requests.removeWhere(
      (r) => r.fieldId == fieldId && r.status == RequestStatus.pending,
    );
    requests.insert(
      0,
      ChangeRequest(
        fieldId: fieldId,
        oldValue: get(fieldId),
        newValue: newValue.trim(),
      ),
    );
    notifyListeners();
    if (liveApi) _sendToServer(fieldId, newValue.trim());
  }

  /// Live mode: the request goes to the office. If the server refuses it, the
  /// app shows what the server holds again.
  Future<void> _sendToServer(String fieldId, String value) async {
    try {
      await api.requestChange(fieldId, value);
    } on ApiException {
      try {
        loadFromServer(await api.getProfile());
      } on ApiException {
        // Offline: keep what is on screen.
      }
    }
  }

  /// Replaces everything with what the server holds for the signed-in member.
  void loadFromServer(Map<String, dynamic> data) {
    _values.clear();
    photoId = (data['photo'] as Map<String, dynamic>?)?['id'] as String?;
    final fields = (data['fields'] as Map<String, dynamic>?) ?? const {};
    fields.forEach((id, value) {
      final v = '$value'.trim();
      if (v.isNotEmpty) _values[id] = v;
    });
    requests
      ..clear()
      ..addAll(
        ((data['requests'] as List?) ?? const []).map((r) {
          final m = r as Map<String, dynamic>;
          return ChangeRequest(
            fieldId: '${m['fieldId']}',
            oldValue: '${m['oldValue'] ?? ''}',
            newValue: '${m['newValue'] ?? ''}',
            at: DateTime.tryParse('${m['createdAt']}')?.toLocal(),
            status: switch ('${m['status']}') {
              'approved' => RequestStatus.approved,
              'rejected' => RequestStatus.rejected,
              _ => RequestStatus.pending,
            },
          );
        }),
      );
    notifyListeners();
  }

  /// Admin accepts: the detail is updated.
  void approveRequest(ChangeRequest r) {
    if (r.status != RequestStatus.pending) return;
    r.status = RequestStatus.approved;
    set(r.fieldId, r.newValue);
  }

  /// Admin rejects: the detail stays as it was.
  void rejectRequest(ChangeRequest r) {
    if (r.status != RequestStatus.pending) return;
    r.status = RequestStatus.rejected;
    notifyListeners();
  }

  String get(String id) => _values[id] ?? '';

  bool has(String id) => get(id).trim().isNotEmpty;

  void set(String id, String value) {
    final v = value.trim();
    if (v.isEmpty) {
      _values.remove(id);
    } else {
      _values[id] = v;
    }
    // Anniversary only applies to married members.
    if (id == 'marital' && v != 'married') _values.remove('anniversary');
    notifyListeners();
  }

  /// Whole years since the date of birth, or null.
  int? get age {
    final d = DateTime.tryParse(get('dob'));
    if (d == null) return null;
    final now = DateTime.now();
    var a = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) a--;
    return a;
  }

  /// The anniversary becomes required once the member is married.
  bool isRequired(PfField f) =>
      f.required || (f.id == 'anniversary' && get('marital') == 'married');

  Iterable<PfField> get _allFields => kProfileSections.expand((s) => s.fields);

  int get totalRequired => _allFields.where(isRequired).length;

  int get missingRequired =>
      _allFields.where((f) => isRequired(f) && !has(f.id)).length;

  /// Copies what the member entered during registration.
  void loadFromRegistration(RegistrationState r) {
    void put(String id, String value) {
      if (value.trim().isNotEmpty) _values[id] = value.trim();
    }

    put('salutation', r.salutation);
    put('first_name', r.firstName);
    put('middle_name', r.middleName);
    put('last_name', r.lastName);
    put('gender', r.gender);
    if (r.dob != null) put('dob', _iso(r.dob!));
    put('marital', r.marital);
    if (r.anniversary != null) put('anniversary', _iso(r.anniversary!));
    // The member joined the day the registration was submitted.
    put('joined', _iso(r.registeredOn ?? DateTime.now()));
    put('phone1', r.phone);
    put('email', r.email);
    put(
      'address',
      [r.address1, r.address2].where((e) => e.isNotEmpty).join(', '),
    );
    put(
      'location',
      [r.city, r.state, r.country].where((e) => e.isNotEmpty).join(', '),
    );
    put('pin', r.pin);
    put('reference', r.reference);
    if (r.referencePhone.trim().isNotEmpty) {
      put('reference_phone', '${r.referenceDial} ${r.referencePhone}');
    }
    if (r.idType != null) put(r.idType!, r.idNumber);
    notifyListeners();
  }

  /// Demo member (Daniel): most details present, blood group missing.
  void seedDemo() {
    _values
      ..['salutation'] = 'Mr'
      ..['first_name'] = 'Daniel'
      ..['last_name'] = 'Fernandes'
      ..['gender'] = 'male'
      ..['dob'] = '1992-03-14'
      ..['marital'] = 'single'
      ..['phone1'] = '+91 98765 43210'
      ..['email'] = 'daniel.fernandes@example.com'
      ..['address'] = 'Flat 4, St Mary Apartments, Church Road'
      ..['location'] = 'Thane, Maharashtra, India'
      ..['pin'] = '400601'
      ..['mother_tongue'] = 'Konkani'
      ..['comm_language'] = 'English'
      ..['religion'] = 'Christian'
      ..['joined'] = '2019-06-02';
  }
}

final profile = ProfileState()..seedDemo();
