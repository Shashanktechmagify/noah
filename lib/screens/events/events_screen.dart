import 'package:flutter/material.dart';

import '../../data/events_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../jodie/jodie_widgets.dart' show clock;
import 'events_calendar_screen.dart';
import 'events_widgets.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _pages = PageController(viewportFraction: 0.92);
  final _search = TextEditingController();
  int _pass = 0;

  @override
  void dispose() {
    _pages.dispose();
    _search.dispose();
    super.dispose();
  }

  void _openCalendar() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const EventsCalendarScreen()));

  bool _matches(EventItem e, String q) {
    final hay = [
      tr(context, e.titleKey),
      e.place,
      fullDate(context, e.start),
    ].join(' ').toLowerCase();
    return hay.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    return ListenableBuilder(
      listenable: eventsState,
      builder: (context, _) {
        final passes = eventsState.passes;
        final results = q.isEmpty
            ? const <EventItem>[]
            : (eventsState.events.where((e) => _matches(e, q)).toList()
                    ..sort((a, b) => a.start.compareTo(b.start)))
                  .where((e) => !e.isPast)
                  .take(30)
                  .toList();
        return PageScaffold(
          title: tr(context, 'nav_events'),
          leadingIcon: Icons.calendar_today_outlined,
          bandHeight: 205,
          actions: [
            GlassCircle(
              icon: Icons.edit_calendar_outlined,
              onTap: _openCalendar,
            ),
          ],
          children: [
            _SearchBar(
              controller: _search,
              hint: tr(context, 'ev2_search'),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 16),
            if (q.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(context, 'ev2_my_passes'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${passes.length}',
                        style: const TextStyle(
                          color: AppColors.magenta,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 204,
                child: PageView.builder(
                  controller: _pages,
                  padEnds: false,
                  clipBehavior: Clip.none,
                  itemCount: passes.length,
                  onPageChanged: (i) => setState(() => _pass = i),
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 16 : 4, right: 6),
                    child: _PassCard(pass: passes[i], latest: i == 0),
                  ),
                ),
              ),
              if (passes.length > 1) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < passes.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: i == _pass ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _pass
                              ? AppColors.magenta
                              : const Color(0xFFCFD2E6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    tr(context, 'ev2_swipe'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SectionTitle(
                title: tr(context, 'ev_open'),
                action: tr(context, 'ev_calendar'),
                onAction: _openCalendar,
              ),
              const SizedBox(height: 12),
              WhiteCard(
                child: Column(
                  children: [
                    for (final (i, e) in eventsState.open.indexed) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.border),
                      EventRow(event: e),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionTitle(title: tr(context, 'ev_bus')),
              const SizedBox(height: 12),
              WhiteCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const IconTile(icon: Icons.directions_bus_outlined),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(context, 'ev_bus_route'),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tr(context, 'ev_bus_meta'),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusPill(
                        text: tr(context, 'ev_on'),
                        background: StatusPill.booked.$1,
                        foreground: StatusPill.booked.$2,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Search results replace the passes and lists.
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      tr(context, 'ev2_no_results'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                WhiteCard(
                  child: Column(
                    children: [
                      for (final (i, e) in results.indexed) ...[
                        if (i > 0)
                          const Divider(height: 1, color: AppColors.border),
                        EventRow(event: e),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13.5,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            width: 52,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFA719C8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.search, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

/// One booked pass: ticket with notches, seats, passes, gate and booking code.
class _PassCard extends StatelessWidget {
  const _PassCard({required this.pass, required this.latest});

  final EventPass pass;
  final bool latest;

  @override
  Widget build(BuildContext context) {
    final e = pass.event;
    final booked =
        '${pass.bookedOn.day} ${monthShort(context, pass.bookedOn.month)}';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleDeep.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, e.titleKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fullDate(context, e.start)} · ${clock(e.start)} · ${e.place}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (latest) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: StatusPill.booked.$1,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      tr(context, 'ev2_latest'),
                      style: TextStyle(
                        color: StatusPill.booked.$2,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const _TearLine(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              children: [
                _Stat(label: tr(context, 'ev_seats'), value: pass.seats),
                _Stat(label: tr(context, 'ev_passes'), value: pass.passes),
                _Stat(label: tr(context, 'ev_gate'), value: pass.gate),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr(
              context,
              'ev2_booked_on',
              args: {'date': booked, 'code': pass.code},
            ),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

/// Dashed tear line with half-circle notches on both edges.
class _TearLine extends StatelessWidget {
  const _TearLine();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 20,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (_, c) {
              final dashes = (c.maxWidth / 9).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  dashes,
                  (_) =>
                      Container(width: 5, height: 1.2, color: AppColors.border),
                ),
              );
            },
          ),
        ),
        for (final left in [true, false])
          Positioned(
            left: left ? -10 : null,
            right: left ? null : -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    ),
  );
}
