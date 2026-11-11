import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api_client.dart';
import '../../data/live_events.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart' show GradientButton;
import '../../widgets/page_scaffold.dart';
import '../../widgets/rich_html.dart';
import '../jodie/jodie_widgets.dart' show clock, toast;
import 'events_widgets.dart' show monthShort;
import 'pass_scanner_screen.dart';

const _red = Color(0xFFD6334B);

/// "Sat, 15 Nov · 6:00 pm", in the phone's own time.
String whenText(BuildContext context, DateTime? utc) {
  if (utc == null) return '';
  final d = utc.toLocal();
  return '${tr(context, 'wdshort_${d.weekday}')}, ${d.day} ${monthShort(context, d.month)} · ${clock(d)}';
}

StatusPill _eventPill(BuildContext context, LiveEvent e) {
  if (e.booked) {
    return StatusPill(
      text: tr(
        context,
        e.passStatus == 'attended' ? 'ev_ps_attended' : 'ev_booked',
      ),
      background: StatusPill.booked.$1,
      foreground: StatusPill.booked.$2,
    );
  }
  final colors = switch (e.status) {
    'booking_open' || 'upcoming' => StatusPill.book,
    'completed' => StatusPill.past,
    _ => StatusPill.soon,
  };
  return StatusPill(
    text: tr(context, 'ev_st_${e.status}'),
    background: colors.$1,
    foreground: colors.$2,
  );
}

StatusPill _passPill(BuildContext context, LivePass p) {
  final colors = switch (p.status) {
    'confirmed' => StatusPill.booked,
    'attended' => StatusPill.book,
    _ => StatusPill.past,
  };
  return StatusPill(
    text: tr(context, 'ev_ps_${p.status}'),
    background: colors.$1,
    foreground: colors.$2,
  );
}

/// The Events tab of a member signed in to the server: the events the office published, and the member's passes.
class LiveEventsScreen extends StatefulWidget {
  const LiveEventsScreen({super.key});

  @override
  State<LiveEventsScreen> createState() => _LiveEventsScreenState();
}

class _LiveEventsScreenState extends State<LiveEventsScreen> {
  bool _passes = false;

  @override
  void initState() {
    super.initState();
    liveEvents.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: liveEvents,
      builder: (context, _) {
        final s = liveEvents;
        return PageScaffold(
          title: tr(context, 'nav_events'),
          leadingIcon: Icons.calendar_today_outlined,
          bandHeight: 84,
          onRefresh: liveEvents.load,
          // Door staff (the scanner role, or an office admin) can scan entry passes.
          actions: [
            if (api.canScan)
              GlassCircle(
                icon: Icons.qr_code_scanner,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PassScannerScreen()),
                ),
              ),
          ],
          children: [
            _Toggle(
              passes: _passes,
              count: s.passes.where((p) => p.isLive).length,
              onChoose: (v) => setState(() => _passes = v),
            ),
            const SizedBox(height: 14),
            if (s.loading && !s.loaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (s.error != null && !s.loaded)
              _Message(text: s.error!, retry: liveEvents.load)
            else if (_passes)
              ..._passList(context, s)
            else
              ..._eventList(context, s),
          ],
        );
      },
    );
  }

  List<Widget> _eventList(BuildContext context, LiveEventsState s) {
    if (s.events.isEmpty) return [_Message(text: tr(context, 'ev_none'))];
    return [
      for (final e in s.events)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LiveEventScreen(eventId: e.id)),
            ),
            child: _EventCard(event: e),
          ),
        ),
    ];
  }

  List<Widget> _passList(BuildContext context, LiveEventsState s) {
    if (s.passes.isEmpty) return [_Message(text: tr(context, 'ev_no_passes'))];
    return [
      for (final p in s.passes)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GestureDetector(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => LivePassScreen(pass: p))),
            child: WhiteCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const IconTile(icon: Icons.qr_code_2),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.eventName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${whenText(context, p.eventStart)}\n${p.reference}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _passPill(context, p),
                ],
              ),
            ),
          ),
        ),
    ];
  }
}

/// Events | My passes.
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.passes,
    required this.count,
    required this.onChoose,
  });

  final bool passes;
  final int count;
  final ValueChanged<bool> onChoose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final p in [false, true])
            Expanded(
              child: GestureDetector(
                onTap: () => onChoose(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: passes == p ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    p && count > 0
                        ? '${tr(context, 'ev_tab_passes')} · $count'
                        : tr(context, p ? 'ev_tab_passes' : 'ev_tab_events'),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: passes == p ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.retry});

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

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final LiveEvent event;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final seats = e.seatsLeft;
    return WhiteCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (e.photo != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                e.photo!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          whenText(context, e.start),
                          e.placeName,
                          if (seats != null && e.status == 'booking_open')
                            tr(
                              context,
                              'ev2_seats_left',
                              args: {'n': '$seats'},
                            ),
                        ].where((p) => p.isNotEmpty).join(' · '),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _eventPill(context, e),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One event: details, and booking, the pass and cancelling.
class LiveEventScreen extends StatefulWidget {
  const LiveEventScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<LiveEventScreen> createState() => _LiveEventScreenState();
}

class _LiveEventScreenState extends State<LiveEventScreen> {
  bool _busy = false;

  Future<void> _book(LiveEvent e) async {
    setState(() => _busy = true);
    try {
      final pass = await liveEvents.book(e);
      if (!mounted) return;
      toast(context, tr(context, 'ev_booked_ok'));
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => LivePassScreen(pass: pass)));
    } on ApiException catch (ex) {
      if (mounted) toast(context, ex.message);
      liveEvents.load(); // seats may have changed
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(LivePass pass) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(tr(dialog, 'ev_cancel_ask')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(tr(dialog, 'ev_keep')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(
              tr(dialog, 'ev_cancel_yes'),
              style: const TextStyle(color: _red, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await liveEvents.cancel(pass);
      if (mounted) toast(context, tr(context, 'ev_cancelled_ok'));
    } on ApiException catch (ex) {
      if (mounted) toast(context, ex.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: liveEvents,
      builder: (context, _) {
        final e = liveEvents.events
            .where((x) => x.id == widget.eventId)
            .firstOrNull;
        if (e == null) {
          return Scaffold(
            appBar: AppBar(),
            body: _Message(text: tr(context, 'ev_none')),
          );
        }
        final pass = liveEvents.passFor(e);
        return Scaffold(
          body: PageScaffold(
            title: e.name,
            leadingIcon: Icons.arrow_back,
            onLeading: () => Navigator.of(context).pop(),
            bandHeight: 84,
            children: [
              if (e.photo != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: GestureDetector(
                    onTap: () => openImageViewer(context, e.photo!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        e.photo!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: WhiteCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _eventPill(context, e),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _Fact(
                        icon: Icons.schedule,
                        label: tr(context, 'ev_when'),
                        value: [
                          whenText(context, e.start),
                          if (e.end != null) '– ${clock(e.end!.toLocal())}',
                        ].join(' '),
                      ),
                      if (e.placeName.isNotEmpty || e.placeAddress.isNotEmpty)
                        _Fact(
                          icon: Icons.place_outlined,
                          label: tr(context, 'ev_venue'),
                          value: [
                            e.placeName,
                            e.placeAddress,
                          ].where((p) => p.isNotEmpty).join('\n'),
                        ),
                      if (e.seatsTotal != null)
                        _Fact(
                          icon: Icons.event_seat_outlined,
                          label: tr(context, 'ev_seats_label'),
                          value: tr(
                            context,
                            'ev_seat_count',
                            args: {
                              'n': '${e.seatsLeft ?? 0}',
                              't': '${e.seatsTotal}',
                            },
                          ),
                        ),
                      _Fact(
                        icon: Icons.confirmation_number_outlined,
                        label: tr(context, 'ev_entry'),
                        value: [
                          tr(context, e.paid ? 'ev_paid' : 'ev_free'),
                          if (e.passRequired) tr(context, 'ev_pass_needed'),
                        ].join(' · '),
                      ),
                      if (e.organisers.isNotEmpty)
                        _Fact(
                          icon: Icons.person_outline,
                          label: tr(context, 'ev_hosted_by'),
                          value: e.organisers.join(', '),
                        ),
                    ],
                  ),
                ),
              ),
              // The place on the map, and the online link.
              if (mapsLink(e) != null || e.meetingLink != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      if (mapsLink(e) != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _open(context, mapsLink(e)!),
                            icon: const Icon(Icons.map_outlined),
                            label: Text(tr(context, 'ev_open_maps')),
                          ),
                        ),
                      if (mapsLink(e) != null && e.meetingLink != null)
                        const SizedBox(width: 10),
                      if (e.meetingLink != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _open(context, Uri.parse(e.meetingLink!)),
                            icon: const Icon(Icons.videocam_outlined),
                            label: Text(tr(context, 'ev_join_online')),
                          ),
                        ),
                    ],
                  ),
                ),
              if (e.description.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _Section(title: tr(context, 'ev_about'), html: e.description),
              ],
              if (e.terms.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _Section(title: tr(context, 'ev_terms'), html: e.terms),
              ],
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _actions(context, e, pass),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens a link in the phone's Maps app or browser; says so if nothing can open it.
  Future<void> _open(BuildContext context, Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      toast(context, tr(context, 'ev_cannot_open'));
    }
  }

  Widget _actions(BuildContext context, LiveEvent e, LivePass? pass) {
    if (e.booked && pass != null) {
      return Column(
        children: [
          GradientButton(
            label: tr(context, 'ev_show_qr'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LivePassScreen(pass: pass)),
            ),
          ),
          if (pass.isLive &&
              e.status != 'completed' &&
              e.status != 'booking_closed')
            TextButton(
              onPressed: _busy ? null : () => _cancel(pass),
              child: Text(
                tr(context, 'ev_cancel_booking'),
                style: const TextStyle(
                  color: _red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      );
    }
    if (e.canBook) {
      return GradientButton(
        label: _busy ? '...' : tr(context, 'ev_book_now'),
        onPressed: _busy ? null : () => _book(e),
      );
    }
    final note = switch ((e.bookingBlocked, e.status)) {
      ('paid', _) => 'ev_blocked_paid',
      ('partners_only', _) => 'ev_blocked_partners',
      (_, 'fully_booked') => 'ev_full_note',
      (_, 'completed') => 'ev_st_completed',
      (_, 'upcoming') when !e.passRequired => '',
      _ => 'ev_closed_note',
    };
    if (note.isEmpty) return const SizedBox.shrink();
    return Center(
      child: Text(
        tr(context, note),
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
      ),
    );
  }
}

/// A titled card of text written in the console.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.html});

  final String title;
  final String html;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          RichHtml(html, style: const TextStyle(fontSize: 14.5, height: 1.5)),
        ],
      ),
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.magenta),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The entry pass: the QR code the door scans, with the booking's details.
class LivePassScreen extends StatelessWidget {
  const LivePassScreen({super.key, required this.pass});

  final LivePass pass;

  @override
  Widget build(BuildContext context) {
    final p = pass;
    return Scaffold(
      body: PageScaffold(
        title: tr(context, 'ev_pass_title'),
        leadingIcon: Icons.arrow_back,
        onLeading: () => Navigator.of(context).pop(),
        bandHeight: 84,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: WhiteCard(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                children: [
                  Text(
                    p.eventName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      whenText(context, p.eventStart),
                      p.placeName,
                    ].where((x) => x.isNotEmpty).join(' · '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (p.qr != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: QrImageView(
                        data: p.qr!,
                        size: 230,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        tr(context, 'ev_qr_cancelled'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _red,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  _passPill(context, p),
                  if (p.status == 'attended' && p.attendedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        tr(
                          context,
                          'ev_attended_at',
                          args: {'time': whenText(context, p.attendedAt)},
                        ),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: p.reference));
                      if (context.mounted) {
                        toast(context, tr(context, 'ev_copied'));
                      }
                    },
                    child: Column(
                      children: [
                        Text(
                          tr(context, 'ev_reference'),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          p.reference,
                          style: const TextStyle(
                            fontSize: 20,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 28, color: AppColors.border),
                  Text(
                    [
                      p.memberName,
                      if (p.memberNumber != null) p.memberNumber!,
                    ].join(' · '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (p.isLive) ...[
                    const SizedBox(height: 10),
                    Text(
                      tr(context, 'ev_qr_note'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
