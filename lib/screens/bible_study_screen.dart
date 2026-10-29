import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bible_data.dart';
import '../data/content_data.dart' show contentLanguage;
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart' show GradientButton;
import '../widgets/page_scaffold.dart';
import '../widgets/rich_html.dart' show EntryImage;

/// Bible study: the plans to choose from.
class BibleStudyScreen extends StatefulWidget {
  const BibleStudyScreen({super.key});

  @override
  State<BibleStudyScreen> createState() => _BibleStudyScreenState();
}

class _BibleStudyScreenState extends State<BibleStudyScreen> {
  final _search = TextEditingController();

  int get _lang => contentLanguage(AppLocale.of(context).lang);

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) biblePlans.load(_lang);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(BiblePlan plan) async {
    if (plan.locked) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(tr(context, plan.type == 2 ? 'bible_locked_partners' : 'bible_locked_donation')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => BiblePlanScreen(plan: plan)));
    // Progress may have changed while reading.
    if (mounted) biblePlans.load(_lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: biblePlans,
        builder: (context, _) {
          final q = _search.text.trim().toLowerCase();
          final items = biblePlans.items
              .where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q))
              .toList();
          return PageScaffold(
            onRefresh: () => biblePlans.load(_lang, force: true),
            title: tr(context, 'bible_title'),
            leadingIcon: Icons.arrow_back,
            onLeading: () => Navigator.of(context).pop(),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: tr(context, 'bible_search'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              if (biblePlans.loading && items.isEmpty)
                const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator()))
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    biblePlans.error ?? tr(context, 'bible_empty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
                  ),
                ),
              for (final p in items) _PlanCard(plan: p, onTap: () => _open(p)),
            ],
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onTap});

  final BiblePlan plan;
  final VoidCallback onTap;

  Widget _placeholder() => Container(
    decoration: const BoxDecoration(gradient: AppColors.headerGradient),
    alignment: Alignment.center,
    child: Icon(Icons.import_contacts_outlined, color: Colors.white.withValues(alpha: 0.85), size: 48),
  );

  @override
  Widget build(BuildContext context) {
    final photo = plan.photo;
    final label = plan.locked
        ? tr(context, plan.type == 2 ? 'bible_locked_partners' : 'bible_locked_donation')
        : plan.finished
        ? tr(context, 'bible_done')
        : plan.started
        ? tr(context, 'bible_continue')
        : tr(context, 'bible_start');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A0A55).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: photo == null
                    ? _placeholder()
                    : Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                        loadingBuilder: (_, child, p) =>
                            p == null ? child : Container(color: AppColors.tint),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${plan.days}',
                          style: const TextStyle(color: AppColors.magenta, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          tr(context, 'bible_days'),
                          style: const TextStyle(color: AppColors.magenta, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      color: AppColors.border,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.2),
                          ),
                          if (plan.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              plan.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.3),
                            ),
                          ],
                          if (plan.started && !plan.finished) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${plan.completedSteps} / ${plan.days}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: plan.locked ? null : AppColors.buttonGradient,
                        color: plan.locked ? AppColors.tint : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: plan.locked ? AppColors.muted : Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reading a plan: one step at a time, "Mark Step Complete" at the bottom, and a menu to jump to a step or restart.
class BiblePlanScreen extends StatefulWidget {
  const BiblePlanScreen({super.key, required this.plan});

  final BiblePlan plan;

  @override
  State<BiblePlanScreen> createState() => _BiblePlanScreenState();
}

class _BiblePlanScreenState extends State<BiblePlanScreen> {
  late final BiblePlanController _c = BiblePlanController(widget.plan);

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _say(String text) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  Future<void> _complete() async {
    final problem = await _c.completeCurrent();
    if (problem != null && mounted) _say(problem);
  }

  Future<void> _restart() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(tr(dialog, 'bible_restart_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(tr(dialog, 'bible_cancel'))),
          TextButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(tr(dialog, 'bible_restart_yes'))),
        ],
      ),
    );
    if (yes != true) return;
    final problem = await _c.restart();
    if (problem != null && mounted) _say(problem);
  }

  Future<void> _jump() async {
    final progress = _c.progress;
    if (progress == null) return;
    final picked = await showDialog<BibleStep>(
      context: context,
      builder: (_) => _JumpDialog(steps: _c.steps, progress: progress),
    );
    if (picked != null) await _c.view(picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          final canComplete = _c.viewingStepId != null && !_c.viewingDone && _c.content != null;
          return Column(
            children: [
              Container(
                padding: EdgeInsets.only(top: top, left: 4, right: 4),
                decoration: const BoxDecoration(gradient: AppColors.headerGradient),
                height: top + 58,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        widget.plan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                    PopupMenuButton<String>(
                      iconColor: Colors.white,
                      onSelected: (v) => v == 'jump' ? _jump() : _restart(),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'jump', child: Text(tr(context, 'bible_jump'))),
                        PopupMenuItem(value: 'restart', child: Text(tr(context, 'bible_restart'))),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(context)),
              if (canComplete)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: GradientButton(
                      label: _c.completing ? '...' : tr(context, 'bible_mark'),
                      onPressed: _c.completing ? null : _complete,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard(BuildContext context, String key, {required Color fill, required Color ink, double size = 28}) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 22),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          tr(context, key),
          textAlign: TextAlign.center,
          style: TextStyle(color: ink, fontSize: size, height: 1.3),
        ),
      ),
    ],
  );

  Widget _body(BuildContext context) {
    if (_c.loading) return const Center(child: CircularProgressIndicator());
    if (_c.error != null && _c.progress == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_c.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
              TextButton(onPressed: _c.load, child: Text(tr(context, 'reg_up_retry'))),
            ],
          ),
        ),
      );
    }
    final p = _c.progress!;
    if (_c.viewingStepId == null) {
      return p.completedAll
          ? BibleCongratsView(
              planName: widget.plan.name,
              days: _c.steps.length,
              onMore: () => Navigator.of(context).pop(),
              onAgain: _restart,
            )
          : _statusCard(context, 'bible_progress', fill: Colors.white, ink: const Color(0xFF4A4A57), size: 24);
    }
    if (_c.contentLoading || _c.content == null) {
      return _c.error != null
          ? Center(child: Text(_c.error!, style: const TextStyle(color: AppColors.muted)))
          : const Center(child: CircularProgressIndicator());
    }
    return BibleStepView(content: _c.content!, step: _c.viewing, done: _c.viewingDone);
  }
}

/// A step's text: its name, then each passage with the chapter heading and the verses.
class BibleStepView extends StatelessWidget {
  const BibleStepView({required this.content, required this.step, required this.done});

  final BibleStepContent content;
  final BibleStep? step;
  final bool done;

  static const _blue = Color(0xFF3566A8);

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      // A picture the office attached to this step.
      if (content.photo != null) Padding(padding: const EdgeInsets.only(top: 4), child: EntryImage(content.photo)),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
        child: Text(
          content.name,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _blue, fontSize: 26, fontWeight: FontWeight.w700),
        ),
      ),
      if (done)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF1F8A4C), size: 18),
              const SizedBox(width: 6),
              Text(tr(context, 'bible_step_done'), style: const TextStyle(color: Color(0xFF1F8A4C), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      if (content.description != null && content.description!.trim().isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(content.description!, style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF55576F))),
        ),
      if (content.youtubeId != null && content.youtubeId!.isNotEmpty) _Video(id: content.youtubeId!),
    ];

    String? lastBook;
    for (final p in content.passages) {
      if (p.book != lastBook) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(p.book, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF4A4A57))),
          ),
        );
        lastBook = p.book;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Text(
            tr(context, 'bible_chapter', args: {'n': '${p.chapter}'}),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _blue),
          ),
        ),
      );
      children.add(
        Text.rich(
          TextSpan(
            children: [
              for (final v in p.verses) ...[
                WidgetSpan(
                  alignment: PlaceholderAlignment.top,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Transform.translate(
                      offset: const Offset(0, -2),
                      child: Text('${v.n}', style: const TextStyle(fontSize: 12, color: Color(0xFFC62828))),
                    ),
                  ),
                ),
                TextSpan(text: '${v.text} '),
              ],
            ],
          ),
          style: const TextStyle(fontSize: 18, height: 1.9, color: Color(0xFF55576F)),
        ),
      );
    }

    if (content.quiz.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 8),
          child: Text(tr(context, 'bible_quiz'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _blue)),
        ),
      );
      for (final q in content.quiz) {
        children.add(_Question(q));
      }
    }

    return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: children);
  }
}

/// A YouTube video of the step: its picture, and a tap copies the link (the app has no player or browser).
class _Video extends StatelessWidget {
  const _Video({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: 'https://youtu.be/$id'));
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text('https://youtu.be/$id'), behavior: SnackBarBehavior.floating));
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://img.youtube.com/vi/$id/hqdefault.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: AppColors.tint),
              ),
              const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 56)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A quiz question. Tapping an answer shows whether it is right; it does not hold back the step.
class _Question extends StatefulWidget {
  const _Question(this.q);

  final BibleQuestion q;

  @override
  State<_Question> createState() => _QuestionState();
}

class _QuestionState extends State<_Question> {
  final _picked = <int>{};

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.question, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.35)),
          const SizedBox(height: 8),
          for (final (i, o) in q.options.indexed)
            GestureDetector(
              onTap: () => setState(() => _picked.add(i)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: !_picked.contains(i)
                      ? Colors.white
                      : o.correct
                      ? const Color(0xFFDDF3E4)
                      : const Color(0xFFFBE3E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(o.text, style: const TextStyle(fontSize: 15))),
                    if (_picked.contains(i))
                      Icon(
                        o.correct ? Icons.check_circle : Icons.cancel,
                        color: o.correct ? const Color(0xFF1F8A4C) : const Color(0xFFE5334B),
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Jump to Step": Day 01, Day 02 ... with a search box. Steps after the one the member is on stay locked.
class _JumpDialog extends StatefulWidget {
  const _JumpDialog({required this.steps, required this.progress});

  final List<BibleStep> steps;
  final BibleProgress progress;

  @override
  State<_JumpDialog> createState() => _JumpDialogState();
}

class _JumpDialogState extends State<_JumpDialog> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  String _day(BuildContext context, BibleStep s) =>
      tr(context, 'bible_day', args: {'n': s.order.toString().padLeft(2, '0')});

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    // The member can read the steps they finished and the one they are on; later ones open in order.
    final reachable = widget.progress.nextStepId == null
        ? widget.steps.length
        : widget.steps.indexWhere((s) => s.id == widget.progress.nextStepId) + 1;
    final shown = widget.steps
        .where((s) => q.isEmpty || _day(context, s).toLowerCase().contains(q) || s.name.toLowerCase().contains(q))
        .toList();
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Column(
          children: [
            TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: tr(context, 'bible_search')),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) {
                  final s = shown[i];
                  final open = s.order <= reachable;
                  final done = widget.progress.completed.contains(s.id);
                  return ListTile(
                    enabled: open,
                    title: Text(_day(context, s), style: TextStyle(fontSize: 17, color: open ? AppColors.ink : AppColors.muted)),
                    subtitle: s.name.isEmpty ? null : Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: done
                        ? const Icon(Icons.check_circle, color: Color(0xFF1F8A4C))
                        : open
                        ? null
                        : const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
                    onTap: open ? () => Navigator.of(context).pop(s) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when every step of a plan is done: a trophy, the plan's name and what to do next.
class BibleCongratsView extends StatelessWidget {
  const BibleCongratsView({
    required this.planName,
    required this.days,
    required this.onMore,
    required this.onAgain,
  });

  final String planName;
  final int days;
  final VoidCallback onMore;
  final VoidCallback onAgain;

  static const _confetti = [
    (0.08, 0.10, 10.0, Color(0xFFF5A524)),
    (0.22, 0.04, 7.0, Color(0xFFE5334B)),
    (0.38, 0.12, 9.0, Color(0xFF3B82F6)),
    (0.60, 0.05, 8.0, Color(0xFF1F8A4C)),
    (0.78, 0.13, 11.0, Color(0xFFA719C8)),
    (0.92, 0.06, 8.0, Color(0xFFF5A524)),
    (0.14, 0.30, 8.0, Color(0xFF3B82F6)),
    (0.88, 0.32, 9.0, Color(0xFFE5334B)),
    (0.05, 0.50, 7.0, Color(0xFFA719C8)),
    (0.95, 0.52, 7.0, Color(0xFF1F8A4C)),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEAF3FF), Color(0xFFFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFCFE2F7)),
          ),
          child: Stack(
            children: [
              // A few coloured dots and strips, like confetti.
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, box) => Stack(
                    children: [
                      for (final (x, y, size, color) in _confetti)
                        Positioned(
                          left: box.maxWidth * x,
                          top: box.maxHeight * y,
                          child: Transform.rotate(
                            angle: x * 9,
                            child: Container(
                              width: size,
                              height: x > 0.5 ? size : size * 0.45,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(x > 0.5 ? size : 2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.4, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.headerGradient,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2A0A55).withValues(alpha: 0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 60),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tr(context, 'bible_congrats_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF0B3C7D), fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr(context, 'bible_congrats_body'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF3A4A66), fontSize: 17, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFCFE2F7)),
                      ),
                      child: Text(
                        planName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (days > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF1F8A4C), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            tr(context, 'bible_congrats_days', args: {'n': '$days'}),
                            style: const TextStyle(color: Color(0xFF1F8A4C), fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),
                    GradientButton(label: tr(context, 'bible_more_plans'), onPressed: onMore),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: onAgain,
                      child: Text(tr(context, 'bible_read_again'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
