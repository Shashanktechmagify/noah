import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  // Events the member has tapped "Book" on during this session.
  final _booked = <String>{};

  @override
  Widget build(BuildContext context) {
    final events = [
      ('ev_worship', 'ev_worship_meta', 'Book', Icons.calendar_today_outlined),
      ('ev_marathi', 'ev_marathi_meta', 'Book', Icons.calendar_today_outlined),
      ('ev_convention', 'ev_convention_meta', 'Soon', Icons.calendar_today_outlined),
    ];
    return PageScaffold(
      title: tr(context, 'nav_events'),
      subtitle: tr(context, 'ev_sub'),
      leadingIcon: Icons.settings_outlined,
      children: [
        const _TicketCard(),
        const SizedBox(height: 22),
        SectionTitle(
            title: tr(context, 'ev_open'), action: tr(context, 'ev_calendar')),
        const SizedBox(height: 12),
        WhiteCard(
          child: Column(
            children: [
              for (var i = 0; i < events.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                _EventRow(
                  icon: events[i].$4,
                  title: tr(context, events[i].$1 == 'ev_worship' ? 's1_title' : events[i].$1),
                  meta: tr(context, events[i].$2),
                  pill: _pillFor(context, events[i].$1, events[i].$3),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionTitle(title: tr(context, 'ev_bus')),
        const SizedBox(height: 12),
        WhiteCard(
          child: _EventRow(
            icon: Icons.directions_bus_outlined,
            title: tr(context, 'ev_bus_route'),
            meta: tr(context, 'ev_bus_meta'),
            pill: StatusPill(
              text: tr(context, 'ev_on'),
              background: StatusPill.booked.$1,
              foreground: StatusPill.booked.$2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pillFor(BuildContext context, String id, String kind) {
    if (kind == 'Soon') {
      return StatusPill(
        text: tr(context, 'ev_soon'),
        background: StatusPill.soon.$1,
        foreground: StatusPill.soon.$2,
      );
    }
    final booked = _booked.contains(id);
    return StatusPill(
      text: tr(context, booked ? 'ev_booked' : 'ev_book'),
      background: booked ? StatusPill.booked.$1 : StatusPill.book.$1,
      foreground: booked ? StatusPill.booked.$2 : StatusPill.book.$2,
      onTap: () => setState(() {
        booked ? _booked.remove(id) : _booked.add(id);
      }),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.icon,
    required this.title,
    required this.meta,
    required this.pill,
  });

  final IconData icon;
  final String title;
  final String meta;
  final Widget pill;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(meta,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            pill,
          ],
        ),
      );
}

/// Booked-pass ticket with side notches and a dashed tear line.
class _TicketCard extends StatelessWidget {
  const _TicketCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleDeep.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(context, 'ev_sunday2'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(tr(context, 'ev_sunday2_meta'),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                StatusPill(
                  text: tr(context, 'ev_booked'),
                  background: StatusPill.booked.$1,
                  foreground: StatusPill.booked.$2,
                ),
              ],
            ),
          ),
          const _TearLine(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Row(
              children: [
                _TicketStat(label: tr(context, 'ev_seats'), value: 'C–14, C–15'),
                _TicketStat(
                    label: tr(context, 'ev_passes'),
                    value: tr(context, 'ev_passes_val')),
                _TicketStat(
                    label: tr(context, 'ev_gate'),
                    value: tr(context, 'ev_north')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketStat extends StatelessWidget {
  const _TicketStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
            const SizedBox(height: 4),
            Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15.5, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _TearLine extends StatelessWidget {
  const _TearLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                    (_) => Container(
                        width: 5, height: 1.2, color: AppColors.border),
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
}
