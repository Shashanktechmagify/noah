import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/api_client.dart';
import '../../data/pass_scan.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../jodie/jodie_widgets.dart' show toast;
import 'live_events_screen.dart' show whenText;

const _green = Color(0xFF1F8A4C);
const _greenBg = Color(0xFFE1F3E7);
const _amber = Color(0xFFC2620A);
const _amberBg = Color(0xFFFDEBD3);
const _red = Color(0xFFD6334B);
const _redBg = Color(0xFFFDE7EA);

/// Door staff: pick the event, point the camera at a member's QR code, check the pass and let them in. The attendance is
/// recorded against the staff member who is signed in.
class PassScannerScreen extends StatefulWidget {
  const PassScannerScreen({super.key});

  @override
  State<PassScannerScreen> createState() => _PassScannerScreenState();
}

class _PassScannerScreenState extends State<PassScannerScreen> {
  List<ScanEvent>? _events;
  String? _loadError;
  ScanEvent? _event;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final list = await passScanner.events();
      if (!mounted) return;
      setState(() {
        _events = list;
        if (list.length == 1) _event = list.first;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    if (event != null) {
      return _Scanning(
        event: event,
        onChangeEvent: (_events?.length ?? 0) > 1
            ? () => setState(() => _event = null)
            : null,
      );
    }
    return Scaffold(
      body: PageScaffold(
        title: tr(context, 'sc_title'),
        leadingIcon: Icons.arrow_back,
        onLeading: () => Navigator.of(context).pop(),
        bandHeight: 84,
        children: [
          if (_loadError != null)
            _Note(text: _loadError!, retry: _load)
          else if (_events == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_events!.isEmpty)
            _Note(text: tr(context, 'sc_none'), retry: _load)
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                tr(context, 'sc_pick_event'),
                style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
              ),
            ),
            for (final e in _events!)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: GestureDetector(
                  onTap: () => setState(() => _event = e),
                  child: WhiteCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const IconTile(icon: Icons.qr_code_scanner),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.name,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                [
                                  whenText(context, e.start),
                                  e.place,
                                ].where((p) => p.isNotEmpty).join(' · '),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, this.retry});

  final String text;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
    child: Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        if (retry != null)
          TextButton(onPressed: retry, child: Text(tr(context, 'ev_retry'))),
      ],
    ),
  );
}

/// The camera, the counter, the result of the last pass and the typed-reference backup, for one event.
class _Scanning extends StatefulWidget {
  const _Scanning({required this.event, this.onChangeEvent});

  final ScanEvent event;
  final VoidCallback? onChangeEvent;

  @override
  State<_Scanning> createState() => _ScanningState();
}

class _ScanningState extends State<_Scanning> {
  final _camera = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final _reference = TextEditingController();
  ScanOutcome? _outcome;
  String? _error;
  bool _busy = false;
  ScanCounts? _counts;
  Timer? _clear;

  /// What the last check was about, so Confirm admits that same pass.
  String? _token;
  String? _ref;

  @override
  void initState() {
    super.initState();
    _refreshCounts();
  }

  @override
  void dispose() {
    _clear?.cancel();
    _camera.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _refreshCounts() async {
    try {
      final c = await passScanner.counts(widget.event.id);
      if (mounted) setState(() => _counts = c);
    } on ApiException {
      // The counter is only a convenience.
    }
  }

  void _reset() {
    _clear?.cancel();
    setState(() {
      _outcome = null;
      _error = null;
      _token = null;
      _ref = null;
    });
  }

  /// Looks at a pass. Nothing is recorded until Confirm.
  Future<void> _check({String? token, String? reference}) async {
    if (_busy || _outcome != null) return;
    setState(() {
      _busy = true;
      _error = null;
      _token = token;
      _ref = reference;
    });
    try {
      final o = await passScanner.check(
        widget.event.id,
        token: token,
        reference: reference,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _outcome = o);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final o = await passScanner.admit(
        widget.event.id,
        token: _token,
        reference: _ref,
      );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _outcome = o);
      if (o.isAdmitted) {
        _reference.clear();
        _refreshCounts();
        // Back to scanning by itself after a moment.
        _clear = Timer(const Duration(milliseconds: 2500), () {
          if (mounted && _outcome?.isAdmitted == true) _reset();
        });
      }
    } on ApiException catch (e) {
      // Not recorded: say so, never a success.
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final value = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (value == null) return;
    _check(token: value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    return Scaffold(
      body: PageScaffold(
        title: widget.event.name,
        leadingIcon: Icons.arrow_back,
        onLeading: () => Navigator.of(context).pop(),
        bandHeight: 84,
        actions: [
          if (widget.onChangeEvent != null)
            GlassCircle(icon: Icons.swap_horiz, onTap: widget.onChangeEvent),
        ],
        children: [
          if (counts != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                tr(
                  context,
                  'sc_checked_in',
                  args: {
                    'n': '${counts.checkedIn}',
                    't': '${counts.confirmed}',
                  },
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 280,
                child: MobileScanner(
                  controller: _camera,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => Container(
                    color: AppColors.tint,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr(context, 'sc_camera_off'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                  overlayBuilder: (context, constraints) => Center(
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _Banner(
                title: tr(context, 'sc_failed_title'),
                detail: tr(context, 'sc_failed', args: {'why': _error!}),
                color: _red,
                background: _redBg,
                icon: Icons.error_outline,
                actions: [
                  TextButton(
                    onPressed: _outcome != null ? _confirm : _reset,
                    child: Text(
                      tr(context, _outcome != null ? 'ev_retry' : 'sc_next'),
                    ),
                  ),
                ],
              ),
            ),
          if (_outcome != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ScanResultCard(
                outcome: _outcome!,
                busy: _busy,
                onConfirm: _confirm,
                onNext: _reset,
              ),
            )
          else if (_busy == false && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                tr(context, 'sc_point'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
              ),
            ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _reference,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: tr(context, 'sc_ref_hint'),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (v) => _byReference(v),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.magenta,
                    minimumSize: const Size(0, 52),
                  ),
                  onPressed: _busy ? null : () => _byReference(_reference.text),
                  child: Text(tr(context, 'sc_check')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _byReference(String text) {
    final ref = text.trim().toUpperCase();
    if (ref.isEmpty) {
      toast(context, tr(context, 'sc_ref_hint'));
      return;
    }
    _check(reference: ref);
  }
}

/// The result of checking a pass: green to let in, amber when already in, red when something is wrong.
class ScanResultCard extends StatelessWidget {
  const ScanResultCard({
    super.key,
    required this.outcome,
    required this.onConfirm,
    required this.onNext,
    this.busy = false,
  });

  final ScanOutcome outcome;
  final VoidCallback onConfirm;
  final VoidCallback onNext;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final o = outcome;
    final (color, background, icon) = o.ok
        ? (_green, _greenBg, Icons.check_circle)
        : o.isWarning
        ? (_amber, _amberBg, Icons.warning_amber_rounded)
        : (_red, _redBg, Icons.cancel);
    final who = [
      if (o.memberName != null) o.memberName!,
      if (o.memberNumber != null) o.memberNumber!,
    ].join(' · ');
    return _Banner(
      title: tr(context, 'sc_r_${o.result}'),
      detail: [
        o.message,
        if (who.isNotEmpty) who,
        if (o.result == 'wrong_event' && o.otherEvent != null) o.otherEvent!,
        if (o.result == 'already_scanned' && o.attendedAt != null)
          whenText(context, o.attendedAt),
      ].where((p) => p.isNotEmpty).join('\n'),
      color: color,
      background: background,
      icon: icon,
      actions: [
        if (o.isValid)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              minimumSize: const Size(0, 48),
            ),
            onPressed: busy ? null : onConfirm,
            child: Text(tr(context, 'sc_confirm')),
          ),
        TextButton(
          onPressed: busy ? null : onNext,
          child: Text(tr(context, o.isValid ? 'pf_cancel' : 'sc_next')),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.title,
    required this.detail,
    required this.color,
    required this.background,
    required this.icon,
    required this.actions,
  });

  final String title;
  final String detail;
  final Color color;
  final Color background;
  final IconData icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        if (detail.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              detail,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(spacing: 10, children: actions),
          ),
      ],
    ),
  );
}
