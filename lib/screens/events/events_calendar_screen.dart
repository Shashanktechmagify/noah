import 'package:flutter/material.dart';

import '../../data/events_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import 'events_widgets.dart';

/// Month calendar. Days with events carry a dot; tapping a day lists its
/// events, and each can be booked from there.
class EventsCalendarScreen extends StatefulWidget {
  const EventsCalendarScreen({super.key});

  @override
  State<EventsCalendarScreen> createState() => _EventsCalendarScreenState();
}

class _EventsCalendarScreenState extends State<EventsCalendarScreen> {
  late DateTime _month = DateTime(
    eventsState.today.year,
    eventsState.today.month,
  );
  late DateTime _selected = eventsState.today;

  void _shift(int months) {
    setState(() {
      _month = DateTime(_month.year, _month.month + months);
      if (_selected.year != _month.year || _selected.month != _month.month) {
        _selected = _month;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = eventsState.today;
    final first = DateTime(_month.year, _month.month);
    final lead = first.weekday % 7; // Sunday-first grid
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((lead + days) / 7).ceil();
    final letters = tr(context, 'wd_letters').split(',');

    return Scaffold(
      body: ListenableBuilder(
        listenable: eventsState,
        builder: (context, _) {
          final dayEvents = eventsState.on(_selected);
          return PageScaffold(
            title: tr(context, 'ev2_book_by_date'),
            subtitle: '${monthName(context, _month.month)} ${_month.year}',
            leadingIcon: Icons.arrow_back,
            onLeading: () => Navigator.of(context).pop(),
            children: [
              WhiteCard(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _shift(-1),
                          icon: const Icon(
                            Icons.chevron_left,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          '${monthName(context, _month.month)} ${_month.year}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _shift(1),
                          icon: const Icon(
                            Icons.chevron_right,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        for (final l in letters)
                          Expanded(
                            child: Center(
                              child: Text(
                                l,
                                style: const TextStyle(
                                  color: Color(0xFFB4B6CC),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (var r = 0; r < rows; r++)
                      Row(
                        children: [
                          for (var c = 0; c < 7; c++)
                            Expanded(
                              child: _DayCell(
                                day: r * 7 + c - lead + 1,
                                month: _month,
                                daysInMonth: days,
                                today: today,
                                selected: _selected,
                                onTap: (d) => setState(() => _selected = d),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selected.day} ${monthName(context, _selected.month)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dayEvents.length}',
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
              const SizedBox(height: 12),
              if (dayEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      tr(context, 'ev2_no_events'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                WhiteCard(
                  child: Column(
                    children: [
                      for (final (i, e) in dayEvents.indexed) ...[
                        if (i > 0)
                          const Divider(height: 1, color: AppColors.border),
                        EventRow(event: e, withDate: false),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  tr(context, 'ev2_pick_date'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.month,
    required this.daysInMonth,
    required this.today,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final DateTime month;
  final int daysInMonth;
  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 46);
    final date = DateTime(month.year, month.month, day);
    final isSelected = DateUtils.isSameDay(date, selected);
    final isToday = DateUtils.isSameDay(date, today);
    final hasEvents = eventsState.hasEvents(date);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(date),
      child: Container(
        height: 46,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFA719C8)
              : isToday
              ? AppColors.tint
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isSelected || isToday
                    ? FontWeight.w800
                    : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !hasEvents
                    ? Colors.transparent
                    : isSelected
                    ? Colors.white
                    : const Color(0xFFA719C8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
