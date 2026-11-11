import 'package:flutter/foundation.dart';

import 'api_client.dart';

DateTime? _time(Object? v) => v == null ? null : DateTime.tryParse('$v');

/// An event the office published, as the server shows it to this member.
class LiveEvent {
  LiveEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.photo,
    required this.start,
    required this.end,
    required this.placeName,
    required this.placeAddress,
    required this.passRequired,
    required this.bookingBlocked,
    required this.seatsTotal,
    required this.seatsLeft,
    required this.status,
    required this.passId,
    required this.passStatus,
  });

  final String id;
  final String name;

  /// HTML written in the console.
  final String description;

  /// A picture link, when the office attached one.
  final String? photo;
  final DateTime? start;
  final DateTime? end;
  final String placeName;
  final String placeAddress;
  final bool passRequired;

  /// `paid` or `partners_only` when the app cannot book it, else null.
  final String? bookingBlocked;
  final int? seatsTotal;
  final int? seatsLeft;

  /// `upcoming`, `booking_open`, `fully_booked`, `booking_closed` or `completed`.
  final String status;

  /// This member's own booking: its pass and `confirmed`, `attended` or `cancelled`.
  final String? passId;
  final String? passStatus;

  bool get booked => passStatus == 'confirmed' || passStatus == 'attended';
  bool get canBook =>
      status == 'booking_open' && !booked && bookingBlocked == null;

  factory LiveEvent.fromJson(Map<String, dynamic> j) {
    final place = (j['place'] as Map?) ?? const {};
    final seats = j['seats'] as Map?;
    final mine = j['mine'] as Map?;
    final photo = '${j['photo'] ?? ''}';
    return LiveEvent(
      id: '${j['id']}',
      name: '${j['name'] ?? ''}',
      description: '${j['description'] ?? ''}',
      photo: photo.startsWith('http') ? photo : null,
      start: _time(j['start']),
      end: _time(j['end']),
      placeName: '${place['name'] ?? ''}',
      placeAddress: '${place['address'] ?? ''}',
      passRequired: j['passRequired'] == true,
      bookingBlocked: j['bookingBlocked'] as String?,
      seatsTotal: (seats?['total'] as num?)?.toInt(),
      seatsLeft: (seats?['left'] as num?)?.toInt(),
      status: '${j['status'] ?? 'upcoming'}',
      passId: mine == null ? null : '${mine['passId']}',
      passStatus: mine == null ? null : '${mine['status']}',
    );
  }
}

/// An entry pass: one member's booking of one event, with the code the door scans.
class LivePass {
  LivePass({
    required this.id,
    required this.status,
    required this.reference,
    required this.qr,
    required this.bookedAt,
    required this.attendedAt,
    required this.eventId,
    required this.eventName,
    required this.eventStart,
    required this.placeName,
    required this.placeAddress,
    required this.memberName,
    required this.memberNumber,
  });

  final String id;

  /// `confirmed`, `attended` or `cancelled`.
  final String status;
  final String reference;

  /// What the QR code holds (null for a cancelled pass). It carries no personal details.
  final String? qr;
  final DateTime? bookedAt;
  final DateTime? attendedAt;
  final String eventId;
  final String eventName;
  final DateTime? eventStart;
  final String placeName;
  final String placeAddress;
  final String memberName;
  final String? memberNumber;

  bool get isLive => status == 'confirmed';

  factory LivePass.fromJson(Map<String, dynamic> j) {
    final event = (j['event'] as Map?) ?? const {};
    final place = (event['place'] as Map?) ?? const {};
    final member = (j['member'] as Map?) ?? const {};
    return LivePass(
      id: '${j['id']}',
      status: '${j['status']}',
      reference: '${j['reference'] ?? ''}',
      qr: j['qr'] as String?,
      bookedAt: _time(j['bookedAt']),
      attendedAt: _time(j['attendedAt']),
      eventId: '${event['id'] ?? ''}',
      eventName: '${event['name'] ?? ''}',
      eventStart: _time(event['start']),
      placeName: '${place['name'] ?? ''}',
      placeAddress: '${place['address'] ?? ''}',
      memberName: '${member['name'] ?? ''}',
      memberNumber: member['number'] == null ? null : '${member['number']}',
    );
  }
}

/// The live events and the member's passes (talking to the server). The demo events live in events_data.dart.
class LiveEventsState extends ChangeNotifier {
  List<LiveEvent> events = [];
  List<LivePass> passes = [];
  bool loading = false;
  bool loaded = false;
  String? error;

  Future<void> load() async {
    if (!liveApi || loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final e = await api.getEvents();
      final p = await api.getPasses();
      events = [for (final j in e) LiveEvent.fromJson(j)];
      passes = [for (final j in p) LivePass.fromJson(j)];
      loaded = true;
    } on ApiException catch (ex) {
      error = ex.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Books [event]; returns the pass (its QR code is shown at once).
  Future<LivePass> book(LiveEvent event) async {
    final pass = LivePass.fromJson(await api.bookEvent(event.id));
    await load();
    return pass;
  }

  Future<void> cancel(LivePass pass) async {
    await api.cancelPass(pass.id);
    await load();
  }

  /// The pass for [event], if this member holds one that is still good.
  LivePass? passFor(LiveEvent event) =>
      passes.where((p) => p.id == event.passId).firstOrNull;
}

final liveEvents = LiveEventsState();
