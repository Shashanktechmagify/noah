import 'package:flutter/material.dart';

import '../../data/events_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../jodie/jodie_widgets.dart' show clock, toast;

String monthName(BuildContext context, int month) => tr(context, 'mo_$month');

/// "Oct" in English, the full month name elsewhere.
String monthShort(BuildContext context, int month) {
  final name = monthName(context, month);
  return AppLocale.of(context).lang == AppLang.en ? name.substring(0, 3) : name;
}

String fullDate(BuildContext context, DateTime d) =>
    '${d.day} ${monthName(context, d.month)} ${d.year}';

/// e.g. "24 Oct · 7:00 pm · Hall A · 180 seats left". With [withDate] false
/// the date part is dropped (used under a chosen day in the calendar).
String eventMeta(BuildContext context, EventItem e, {bool withDate = true}) {
  final end = e.endsOn;
  if (end != null) {
    return '${e.start.day}–${end.day} ${monthShort(context, e.start.month)} · ${e.place}';
  }
  final parts = <String>[
    if (withDate) '${e.start.day} ${monthShort(context, e.start.month)}',
    clock(e.start),
    e.place,
    if (e.seatsLeft != null && !e.isPast)
      tr(context, 'ev2_seats_left', args: {'n': '${e.seatsLeft}'}),
  ];
  return parts.join(' · ');
}

/// The status pill for an event: Past, Soon, Booked or a tappable Book.
Widget eventPill(BuildContext context, EventItem e) {
  if (e.isPast) {
    return StatusPill(
      text: tr(context, 'ev2_past'),
      background: StatusPill.past.$1,
      foreground: StatusPill.past.$2,
    );
  }
  if (e.soon) {
    return StatusPill(
      text: tr(context, 'ev_soon'),
      background: StatusPill.soon.$1,
      foreground: StatusPill.soon.$2,
    );
  }
  if (eventsState.isBooked(e)) {
    return StatusPill(
      text: tr(context, 'ev_booked'),
      background: StatusPill.booked.$1,
      foreground: StatusPill.booked.$2,
    );
  }
  return StatusPill(
    text: tr(context, 'ev_book'),
    background: StatusPill.book.$1,
    foreground: StatusPill.book.$2,
    onTap: () {
      eventsState.book(e);
      toast(
        context,
        '${tr(context, 'ev_booked')} · ${tr(context, e.titleKey)}',
      );
    },
  );
}

/// A row in an events list: icon, title, meta line and status pill.
class EventRow extends StatelessWidget {
  const EventRow({super.key, required this.event, this.withDate = true});

  final EventItem event;
  final bool withDate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        const IconTile(icon: Icons.calendar_today_outlined),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, event.titleKey),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                eventMeta(context, event, withDate: withDate),
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
        eventPill(context, event),
      ],
    ),
  );
}
