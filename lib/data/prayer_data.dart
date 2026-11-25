import 'package:flutter/foundation.dart';

import 'api_client.dart';

class PrayerRequest {
  PrayerRequest({
    required this.categoryKey,
    required this.text,
    required this.anonymous,
    required this.everyone,
    this.mannaTitleKey,
  }) : at = DateTime.now();

  /// Translation key, e.g. `pr_cat_healing`.
  final String categoryKey;
  final String text;
  final bool anonymous;

  /// true: visible to the whole congregation.
  /// false: visible to the prayer warriors only.
  final bool everyone;

  /// Set when the request was written from a Daily Manna reading.
  final String? mannaTitleKey;
  final DateTime at;
}

/// One request on the prayer wall (someone else's, or the member's own).
class WallRequest {
  WallRequest({
    required this.id,
    required this.category,
    required this.text,
    required this.everyone,
    required this.name,
    required this.mine,
    required this.prayedBy,
    required this.iPrayed,
    required this.createdAt,
  });

  final String id;

  /// `healing`, `family`, `guidance`, `thanks` or `other`.
  final String category;
  final String text;

  /// false: meant for the prayer warriors only.
  final bool everyone;

  /// Null when the writer asked to be anonymous.
  final String? name;
  final bool mine;
  int prayedBy;
  bool iPrayed;
  final DateTime? createdAt;

  factory WallRequest.fromJson(Map<String, dynamic> j) => WallRequest(
    id: '${j['id']}',
    category: '${j['category']}',
    text: '${j['text']}',
    everyone: j['everyone'] == true,
    name: j['name'] == null ? null : '${j['name']}',
    mine: j['mine'] == true,
    prayedBy: (j['prayedBy'] as num?)?.toInt() ?? 0,
    iPrayed: j['iPrayed'] == true,
    createdAt: DateTime.tryParse('${j['createdAt']}')?.toLocal(),
  );
}

/// One of the member's own requests and where it stands.
class MyPrayer {
  MyPrayer({
    required this.id,
    required this.category,
    required this.text,
    required this.everyone,
    required this.state,
    required this.prayedBy,
    required this.createdAt,
  });

  final String id;
  final String category;
  final String text;
  final bool everyone;

  /// `Pending`, `Approved` or `Declined`.
  final String state;
  final int prayedBy;
  final DateTime? createdAt;

  factory MyPrayer.fromJson(Map<String, dynamic> j) => MyPrayer(
    id: '${j['id']}',
    category: '${j['category']}',
    text: '${j['text']}',
    everyone: j['everyone'] == true,
    state: '${j['state']}',
    prayedBy: (j['prayedBy'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse('${j['createdAt']}')?.toLocal(),
  );
}

/// Demo store for prayer requests. Replace [add] with an API call; the
/// backend should route requests to the prayer team.
class PrayerState extends ChangeNotifier {
  final requests = <PrayerRequest>[];

  // ── Live: the prayer wall and the member's own requests ───────────────
  List<WallRequest> wall = [];
  List<MyPrayer> mine = [];

  /// The office marked this member as a prayer warrior: the wall also shows the warriors' requests.
  bool warrior = false;
  bool loaded = false;
  bool loading = false;
  bool failed = false;

  Future<void> load() async {
    if (!liveApi || !api.signedIn || loading) return;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      final w = await api.prayerWall();
      final m = await api.myPrayerRequests();
      warrior = w['warrior'] == true;
      wall = ((w['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(WallRequest.fromJson)
          .where(
            (r) => !r.iPrayed,
          ) // one the member prayed for is not shown again
          .toList();
      mine = ((m['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(MyPrayer.fromJson)
          .toList();
      loaded = true;
    } on ApiException {
      failed = true; // offline: what is shown stays
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// How "I prayed" reaches the server (a test gives its own).
  Future<Map<String, dynamic>> Function(String id) sendPrayer = (id) =>
      api.prayFor(id);

  /// "I prayed": the request leaves the wall at once (the wall then shows the one that follows), and comes back to its place
  /// if the server refuses.
  Future<void> pray(WallRequest r) async {
    if (r.mine) return;
    final at = wall.indexOf(r);
    if (at < 0) return;
    wall.removeAt(at);
    notifyListeners();
    try {
      await sendPrayer(r.id);
    } on ApiException {
      wall.insert(at.clamp(0, wall.length), r);
      notifyListeners();
    }
  }

  void clear() {
    wall = [];
    mine = [];
    warrior = false;
    loaded = false;
    failed = false;
    notifyListeners();
  }

  void add({
    required String categoryKey,
    required String text,
    required bool anonymous,
    required bool everyone,
    String? mannaTitleKey,
  }) {
    requests.insert(
      0,
      PrayerRequest(
        categoryKey: categoryKey,
        text: text.trim(),
        anonymous: anonymous,
        everyone: everyone,
        mannaTitleKey: mannaTitleKey,
      ),
    );
    notifyListeners();
  }
}

final prayer = PrayerState();

const kPrayerCategories = [
  'pr_cat_healing',
  'pr_cat_family',
  'pr_cat_guidance',
  'pr_cat_thanks',
  'pr_cat_other',
];
