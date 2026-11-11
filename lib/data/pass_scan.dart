import 'api_client.dart';

/// An event door staff can scan for right now.
class ScanEvent {
  ScanEvent({
    required this.id,
    required this.name,
    required this.start,
    required this.place,
  });

  final String id;
  final String name;
  final DateTime? start;
  final String place;

  factory ScanEvent.fromJson(Map<String, dynamic> j) => ScanEvent(
    id: '${j['id']}',
    name: '${j['name'] ?? ''}',
    start: j['start'] == null ? null : DateTime.tryParse('${j['start']}'),
    place: '${j['place'] ?? ''}',
  );
}

/// The answer to checking or admitting one pass.
class ScanOutcome {
  ScanOutcome({
    required this.result,
    required this.message,
    required this.memberName,
    required this.memberNumber,
    required this.attendedAt,
    required this.otherEvent,
  });

  /// `valid`, `admitted`, `already_scanned`, `invalid`, `wrong_event`, `cancelled`, `not_confirmed`, `event_closed`, `busy`.
  final String result;

  /// The sentence the server wrote for this result.
  final String message;
  final String? memberName;
  final String? memberNumber;
  final DateTime? attendedAt;

  /// For a pass that belongs to another event: that event's name.
  final String? otherEvent;

  bool get isValid => result == 'valid';
  bool get isAdmitted => result == 'admitted';
  bool get ok => isValid || isAdmitted;

  /// Amber: not wrong, but not a new entry either.
  bool get isWarning => result == 'already_scanned' || result == 'busy';

  factory ScanOutcome.fromJson(Map<String, dynamic> j) {
    final member = j['member'] as Map?;
    final pass = j['pass'] as Map?;
    final other = j['other'] as Map?;
    return ScanOutcome(
      result: '${j['result']}',
      message: '${j['message'] ?? ''}',
      memberName: member == null ? null : '${member['name']}',
      memberNumber: member?['number'] == null ? null : '${member!['number']}',
      attendedAt: pass?['attendedAt'] == null
          ? null
          : DateTime.tryParse('${pass!['attendedAt']}'),
      otherEvent: other == null ? null : '${other['name']}',
    );
  }
}

/// How many are in so far.
class ScanCounts {
  ScanCounts({required this.checkedIn, required this.confirmed});

  final int checkedIn;
  final int confirmed;
}

/// Door staff: events to scan for, checking and admitting passes. Every call is made as the signed-in staff member, so
/// the server records who let each person in.
class PassScanner {
  Future<List<ScanEvent>> events() async {
    final d = await api.getScanEvents();
    return [for (final j in d) ScanEvent.fromJson(j)];
  }

  /// Looks at a scanned code ([token]) or a typed [reference] without changing anything.
  Future<ScanOutcome> check(
    String eventId, {
    String? token,
    String? reference,
  }) async => ScanOutcome.fromJson(
    await api.scanPass(eventId, token: token, reference: reference),
  );

  /// Lets the member in. Throws when the server could not record it: that is never shown as a success.
  Future<ScanOutcome> admit(
    String eventId, {
    String? token,
    String? reference,
  }) async => ScanOutcome.fromJson(
    await api.scanPass(
      eventId,
      token: token,
      reference: reference,
      confirm: true,
    ),
  );

  Future<ScanCounts> counts(String eventId) async {
    final d = await api.scanCounts(eventId);
    return ScanCounts(
      checkedIn: (d['checkedIn'] as num?)?.toInt() ?? 0,
      confirmed: (d['confirmed'] as num?)?.toInt() ?? 0,
    );
  }
}

final passScanner = PassScanner();
