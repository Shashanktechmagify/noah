import 'dart:async';

import 'package:flutter/widgets.dart';

/// Calls [task] now and then, to look for something new on the server.
///
/// Every call costs a database read on the server, so it is kept cheap:
///  * it waits [fast] between calls while things are changing, and backs off to
///    [slow] once [backoffAfter] calls in a row found nothing new;
///  * it does nothing while the app is in the background;
///  * [nudge] (after the user sends something) goes back to the fast pace.
///
/// [task] returns true when it found something new.
class AdaptivePoll {
  AdaptivePoll({
    required this.task,
    this.fast = const Duration(seconds: 6),
    this.slow = const Duration(seconds: 30),
    this.backoffAfter = 4,
  });

  final Future<bool> Function() task;
  final Duration fast;
  final Duration slow;
  final int backoffAfter;

  Timer? _timer;
  bool _running = false;
  int _quiet = 0;

  bool get running => _running;

  /// Starts polling; the first call comes after one wait, so start it after
  /// the screen has done its own first load.
  void start() {
    _running = true;
    _quiet = 0;
    _schedule();
  }

  /// Something just happened (a message was sent): look again soon.
  void nudge() {
    if (!_running) return;
    _quiet = 0;
    _schedule();
  }

  /// Look right now (a push said something changed), then carry on at the fast pace.
  Future<void> refreshNow() async {
    if (!_running) return;
    _quiet = 0;
    try {
      await task();
    } catch (_) {}
    _schedule();
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void _schedule() {
    _timer?.cancel();
    if (!_running) return;
    _timer = Timer(_quiet >= backoffAfter ? slow : fast, _tick);
  }

  Future<void> _tick() async {
    if (!_running) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) {
      _schedule(); // in the background: wait without asking the server
      return;
    }
    var changed = false;
    try {
      changed = await task();
    } catch (_) {
      // The next call tries again.
    }
    _quiet = changed ? 0 : _quiet + 1;
    _schedule();
  }
}
