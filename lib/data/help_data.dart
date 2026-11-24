import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// The help bot ("Help" in the Menu): a member asks a question about the app and the server answers from the office's
/// FAQ. The state of one open chat lives here, so the screen only draws it and the rules can be tested without a screen.

enum HelpKind {
  /// The member's own question.
  mine,

  /// An answer from the FAQ (the text is the server's).
  answer,

  /// The FAQ has nothing on the question: the screen offers "Talk to us".
  noAnswer,

  /// The question could not be answered (see [HelpProblem]).
  error,
}

enum HelpProblem {
  /// The assistant is down or busy: the member may try again.
  unavailable,

  /// Too many questions today.
  limit,

  /// The server has no assistant set up (nor does demo mode).
  notSet,
}

class HelpMessage {
  HelpMessage.mine(this.text)
    : kind = HelpKind.mine,
      id = null,
      problem = null,
      question = null;

  HelpMessage.answer(this.text, this.id)
    : kind = HelpKind.answer,
      problem = null,
      question = null;

  HelpMessage.noAnswer(this.id)
    : kind = HelpKind.noAnswer,
      text = '',
      problem = null,
      question = null;

  HelpMessage.error(this.problem, this.question)
    : kind = HelpKind.error,
      text = '',
      id = null;

  final HelpKind kind;

  /// What was asked (mine) or the answer (answer); empty for the other kinds (the screen has its own words).
  final String text;

  /// The server's id of the question: what "was this helpful?" is about.
  final String? id;
  final HelpProblem? problem;

  /// The question an error stands for, so "Try again" can ask it again.
  final String? question;

  /// The member's "was this helpful?": null until they say.
  bool? helpful;
}

typedef HelpAsk = Future<Map<String, dynamic>> Function(String question);
typedef HelpFeedback = Future<void> Function(String id, bool helpful);

/// The longest question the server takes.
const kHelpQuestionMax = 300;

class HelpChat extends ChangeNotifier {
  HelpChat({HelpAsk? ask, HelpFeedback? feedback})
    : _ask =
          ask ??
          ((q) {
            // Demo mode has no server, so no assistant either.
            if (!liveApi) {
              throw ApiException(
                'help_not_configured',
                'Help needs the server.',
              );
            }
            return api.helpAsk(q);
          }),
      _feedback = feedback ?? ((id, helpful) => api.helpFeedback(id, helpful));

  final HelpAsk _ask;
  final HelpFeedback _feedback;

  final List<HelpMessage> messages = [];

  /// A question is waiting for its answer (the answer can take up to half a minute).
  bool busy = false;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  /// The member asks. Ignored when empty or while another question waits.
  Future<void> send(String text) async {
    final question = text.trim();
    if (question.isEmpty || busy) return;
    messages.add(HelpMessage.mine(question));
    await _answer(question);
  }

  /// "Try again" on an error: the same question, asked again (it is not shown twice).
  Future<void> retry(HelpMessage failed) async {
    final question = failed.question;
    if (busy || question == null || !messages.remove(failed)) return;
    await _answer(question);
  }

  Future<void> _answer(String question) async {
    busy = true;
    _changed();
    try {
      final r = await _ask(question);
      final answer = r['answer'];
      final id = r['id']?.toString();
      if (r['answered'] == true &&
          answer is String &&
          answer.trim().isNotEmpty) {
        messages.add(HelpMessage.answer(answer.trim(), id));
      } else {
        messages.add(HelpMessage.noAnswer(id));
      }
    } on ApiException catch (e) {
      messages.add(
        HelpMessage.error(switch (e.code) {
          'too_many_questions' => HelpProblem.limit,
          'help_not_configured' => HelpProblem.notSet,
          _ => HelpProblem.unavailable,
        }, question),
      );
    } catch (_) {
      messages.add(HelpMessage.error(HelpProblem.unavailable, question));
    } finally {
      busy = false;
      _changed();
    }
  }

  /// "Was this helpful?" Said once per answer; the server only keeps it for the office to read.
  Future<void> rate(HelpMessage message, bool helpful) async {
    final id = message.id;
    if (id == null || message.helpful != null) return;
    message.helpful = helpful;
    _changed();
    try {
      await _feedback(id, helpful);
    } catch (_) {
      // Not worth bothering the member: the thanks is shown either way.
    }
  }
}
