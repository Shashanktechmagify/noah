import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Bible study: plans, their steps, the verses of a step and the member's progress. Everything comes from
/// the server (`/bible-study/...`); the verse text is the King James Version.

class BiblePlan {
  BiblePlan({
    required this.id,
    required this.name,
    required this.description,
    required this.photo,
    required this.days,
    required this.maxStepsPerDay,
    required this.type,
    required this.locked,
    this.completedSteps = 0,
    this.finished = false,
  });

  final String id;
  final String name;
  final String description;
  final String? photo;
  final int days;

  /// One step a day.
  final bool maxStepsPerDay;

  /// 1 free for everyone, 2 only partners, 3 only with a donation.
  final int type;
  final bool locked;
  final int completedSteps;
  final bool finished;

  bool get started => completedSteps > 0;

  factory BiblePlan.fromJson(Map<String, dynamic> j) => BiblePlan(
    id: '${j['id']}',
    name: '${j['name'] ?? ''}',
    description: '${j['description'] ?? ''}',
    photo: (j['photo'] as String?)?.isEmpty ?? true ? null : j['photo'] as String,
    days: (j['days'] as num?)?.toInt() ?? 0,
    maxStepsPerDay: j['maxStepsPerDay'] == true,
    type: (j['type'] as num?)?.toInt() ?? 1,
    locked: j['locked'] == true,
    completedSteps: (j['completedSteps'] as num?)?.toInt() ?? 0,
    finished: j['finished'] == true,
  );
}

class BibleStep {
  BibleStep({required this.id, required this.order, required this.name, this.description});

  final String id;
  final int order;
  final String name;
  final String? description;

  factory BibleStep.fromJson(Map<String, dynamic> j) => BibleStep(
    id: '${j['id']}',
    order: (j['order'] as num?)?.toInt() ?? 0,
    name: '${j['name'] ?? ''}',
    description: j['description'] as String?,
  );
}

class BibleProgress {
  BibleProgress({
    required this.completed,
    required this.nextStepId,
    required this.completedAll,
    required this.limitedToday,
  });

  final Set<String> completed;
  final String? nextStepId;
  final bool completedAll;

  /// "One step a day" plan and today's step is already done.
  final bool limitedToday;

  factory BibleProgress.fromJson(Map<String, dynamic> j) => BibleProgress(
    completed: ((j['completed'] as List?) ?? const []).map((e) => '$e').toSet(),
    nextStepId: j['nextStepId'] == null ? null : '${j['nextStepId']}',
    completedAll: j['completedAll'] == true,
    limitedToday: j['limitedToday'] == true,
  );
}

class BibleVerse {
  BibleVerse(this.n, this.text);

  final int n;
  final String text;
}

/// A chapter (or part of one) to read.
class BiblePassage {
  BiblePassage({required this.book, required this.chapter, required this.verses});

  final String book;
  final int chapter;
  final List<BibleVerse> verses;

  factory BiblePassage.fromJson(Map<String, dynamic> j) => BiblePassage(
    book: '${j['book'] ?? ''}',
    chapter: (j['chapter'] as num?)?.toInt() ?? 0,
    verses: ((j['verses'] as List?) ?? const [])
        .map((v) => BibleVerse((v['n'] as num).toInt(), '${v['text']}'))
        .toList(),
  );
}

class BibleQuizOption {
  BibleQuizOption(this.text, this.correct);

  final String text;
  final bool correct;
}

class BibleQuestion {
  BibleQuestion(this.question, this.options);

  final String question;
  final List<BibleQuizOption> options;
}

class BibleStepContent {
  BibleStepContent({
    required this.id,
    required this.name,
    required this.description,
    required this.passages,
    required this.quiz,
    this.youtubeId,
  });

  final String id;
  final String name;
  final String? description;
  final String? youtubeId;
  final List<BiblePassage> passages;
  final List<BibleQuestion> quiz;

  factory BibleStepContent.fromJson(Map<String, dynamic> j) => BibleStepContent(
    id: '${j['id']}',
    name: '${j['name'] ?? ''}',
    description: j['description'] as String?,
    youtubeId: j['youtubeId'] as String?,
    passages: ((j['passages'] as List?) ?? const [])
        .map((p) => BiblePassage.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList(),
    quiz: ((j['quiz'] as List?) ?? const [])
        .map(
          (q) => BibleQuestion(
            '${q['question']}',
            ((q['options'] as List?) ?? const [])
                .map((o) => BibleQuizOption('${o['text']}', o['correct'] == true))
                .toList(),
          ),
        )
        .toList(),
  );
}

/// The list of plans. Read when the page opens, and kept for a couple of minutes.
class BiblePlans extends ChangeNotifier {
  List<BiblePlan> items = [];
  bool loading = false;
  String? error;
  DateTime? _at;

  Future<void> load(int lang, {bool force = false}) async {
    if (!liveApi || !api.signedIn || loading) return;
    if (!force && _at != null && DateTime.now().difference(_at!) < const Duration(minutes: 2)) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final d = await api.biblePlans(lang);
      items = ((d['items'] as List?) ?? const [])
          .map((e) => BiblePlan.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _at = DateTime.now();
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// A plan's numbers changed (a step was finished, or it was restarted): read the list again next time.
  void stale() => _at = null;
}

final biblePlans = BiblePlans();

/// One plan being read: its steps, the member's place in it and the step on screen.
class BiblePlanController extends ChangeNotifier {
  BiblePlanController(this.plan);

  final BiblePlan plan;
  List<BibleStep> steps = [];
  BibleProgress? progress;
  bool loading = true;
  bool contentLoading = false;
  bool completing = false;
  String? error;

  /// The step being read. Null shows the plan's status instead (all done, or "come back tomorrow").
  String? viewingStepId;
  BibleStepContent? content;
  final _contents = <String, BibleStepContent>{};

  BibleStep? get viewing => steps.where((s) => s.id == viewingStepId).firstOrNull;
  bool get viewingDone => viewingStepId != null && (progress?.completed.contains(viewingStepId) ?? false);

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final d = await api.biblePlan(plan.id);
      steps = ((d['steps'] as List?) ?? const [])
          .map((e) => BibleStep.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      progress = BibleProgress.fromJson(Map<String, dynamic>.from(d['progress'] as Map));
      loading = false;
      _showCurrent();
    } on ApiException catch (e) {
      error = e.message;
      loading = false;
      notifyListeners();
    }
  }

  /// What to show after the progress changed: the next step, or the status when there is none for today.
  void _showCurrent() {
    final p = progress!;
    viewingStepId = (p.completedAll || p.limitedToday) ? null : p.nextStepId;
    content = null;
    notifyListeners();
    if (viewingStepId != null) _loadContent(viewingStepId!);
  }

  Future<void> view(String stepId) async {
    viewingStepId = stepId;
    content = _contents[stepId];
    notifyListeners();
    if (content == null) await _loadContent(stepId);
  }

  Future<void> _loadContent(String stepId) async {
    final cached = _contents[stepId];
    if (cached != null) {
      content = cached;
      notifyListeners();
      return;
    }
    contentLoading = true;
    error = null;
    notifyListeners();
    try {
      final c = BibleStepContent.fromJson(await api.bibleStep(stepId));
      _contents[stepId] = c;
      if (viewingStepId == stepId) content = c;
    } on ApiException catch (e) {
      error = e.message;
    }
    contentLoading = false;
    notifyListeners();
  }

  /// Marks the step on screen as read. Returns null when it worked, or the server's message.
  Future<String?> completeCurrent() async {
    final id = viewingStepId;
    if (id == null || completing) return null;
    completing = true;
    notifyListeners();
    try {
      final d = await api.bibleComplete(id);
      progress = BibleProgress.fromJson(Map<String, dynamic>.from(d['progress'] as Map));
      biblePlans.stale();
      completing = false;
      _showCurrent();
      return null;
    } on ApiException catch (e) {
      completing = false;
      if (e.code == 'come_back_tomorrow') {
        progress = BibleProgress(
          completed: progress?.completed ?? {},
          nextStepId: progress?.nextStepId,
          completedAll: false,
          limitedToday: true,
        );
        _showCurrent();
        return null;
      }
      notifyListeners();
      return e.message;
    }
  }

  Future<String?> restart() async {
    try {
      final d = await api.bibleRestart(plan.id);
      progress = BibleProgress.fromJson(Map<String, dynamic>.from(d['progress'] as Map));
      biblePlans.stale();
      _showCurrent();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
