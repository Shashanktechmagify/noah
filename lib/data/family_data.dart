import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// The relations a member can ask to add. The server's names, in the order they are offered.
const kFamilyRelations = [
  'spouse',
  'son',
  'daughter',
  'father',
  'mother',
  'brother',
  'sister',
  'other',
];

/// Someone already linked to the member: another member (their own account) or a child (no account).
class FamilyPerson {
  const FamilyPerson({
    required this.name,
    required this.relation,
    required this.isKid,
    this.age,
    this.since,
  });

  final String name;

  /// `spouse`, `son`, `father`, `child`, ... what this person is to the member.
  final String relation;
  final bool isKid;
  final int? age;
  final String? since;

  factory FamilyPerson.fromJson(Map<String, dynamic> j) => FamilyPerson(
    name: '${j['name']}',
    relation: '${j['relation']}',
    isKid: j['kind'] == 'kid',
    age: (j['age'] as num?)?.toInt(),
    since: j['since'] == null ? null : '${j['since']}',
  );

  String get initials => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();
}

/// What the member asked the office for, and where it stands.
class FamilyRequest {
  const FamilyRequest({
    required this.id,
    required this.name,
    required this.relation,
    required this.state,
    required this.waiting,
    required this.remark,
  });

  final String id;
  final String name;
  final String relation;

  /// `Pending`, `Rejected` or `Approved` (an approved grown-up who has not joined Noah yet is [waiting]).
  final String state;
  final bool waiting;
  final String remark;

  bool get pending => state == 'Pending';
  bool get rejected => state == 'Rejected';

  factory FamilyRequest.fromJson(Map<String, dynamic> j) => FamilyRequest(
    id: '${j['id']}',
    name: '${j['name']}',
    relation: '${j['relation']}',
    state: '${j['state']}',
    waiting: j['waiting'] == true,
    remark: '${j['remark'] ?? ''}',
  );
}

class FamilyState extends ChangeNotifier {
  List<FamilyPerson> people = [];
  List<FamilyRequest> requests = [];
  bool loaded = false;
  bool loading = false;

  /// Linked people (the member themself is not counted).
  int get count => people.length;

  Future<void> ensureLoaded() => loaded ? Future.value() : load();

  Future<void> load() async {
    if (!liveApi || !api.signedIn || loading) return;
    loading = true;
    try {
      final d = await api.family();
      people = ((d['family'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(FamilyPerson.fromJson)
          .toList();
      requests = ((d['requests'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(FamilyRequest.fromJson)
          .toList();
      loaded = true;
    } on ApiException {
      // Offline: keep what is on screen.
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Sends the request. Throws [ApiException] with the reason (shown in the dialog).
  Future<void> ask({
    required String relation,
    required String firstName,
    String lastName = '',
    String? dateOfBirth,
    String? countryCode,
    String? mobileNumber,
    String? note,
  }) async {
    await api.createFamilyRequest(
      relation: relation,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      countryCode: countryCode,
      mobileNumber: mobileNumber,
      note: note,
    );
    await load();
  }

  Future<void> cancel(String id) async {
    await api.cancelFamilyRequest(id);
    await load();
  }

  void clear() {
    people = [];
    requests = [];
    loaded = false;
    notifyListeners();
  }
}

final familyState = FamilyState();
