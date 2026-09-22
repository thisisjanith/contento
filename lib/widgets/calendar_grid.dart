import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/post.dart';
import '../theme/colors.dart';
import 'status_badge.dart';

/// One event plotted on the calendar — a post, optionally labeled with the
/// owning employee's name (admin's cross-team calendar only; an employee's
/// own calendar omits names since it's already scoped to one person).
class CalendarEvent {
  final Post post;
  final String? employeeName;

  const CalendarEvent(this.post, {this.employeeName});
}

List<DateTime> _weeksGridDays(DateTime month) {
  final firstOfMonth = DateTime(month.year, month.month, 1);
  final startOffset = firstOfMonth.weekday % 7; // Sunday-first grid
  final gridStart = firstOfMonth.subtract(Duration(days: startOffset));
  return List.generate(42, (i) => gridStart.add(Duration(days: i)));
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Full month grid with text chips per event — the web/desktop layout.
class CalendarMonthGrid extends StatelessWidget {
  final DateTime month;
  final List<CalendarEvent> events;
  final DateTime? today;

  const CalendarMonthGrid({super.key, required this.month, required this.events, this.today});

  @override
  Widget build(BuildContext context) {
    final days = _weeksGridDays(month);
    const weekdayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Column(
      children: [
        Row(
          children: weekdayLabels
              .map((d) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium),
                    ),
                  ))
              .toList(),
        ),
        const Divider(height: 1, color: AppColors.border),
        for (int w = 0; w < 6; w++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int d = 0; d < 7; d++)
                Expanded(child: _dayCell(context, days[w * 7 + d])),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(BuildContext context, DateTime day) {
    final inMonth = day.month == month.month;
    final isToday = today != null && _sameDay(day, today!);
    final dayEvents = events.where((e) => _sameDay(e.post.dueDate, day)).toList();

    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 0.5),
        color: inMonth ? AppColors.surface : AppColors.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: isToday
                ? const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)
                : null,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isToday
                    ? Colors.white
                    : inMonth
                        ? AppColors.textDark
                        : AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          ...dayEvents.take(3).map((e) => Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.statusBackground(e.post.status),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  e.employeeName != null ? '#${e.post.number} ${e.employeeName}' : '#${e.post.number}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusColor(e.post.status),
                  ),
                ),
              )),
          if (dayEvents.length > 3)
            Text('+${dayEvents.length - 3} more', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Compact dot-indicator grid for native (390–412px can't fit text chips
/// per cell) — pair with [AgendaList] below it.
class CompactCalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<CalendarEvent> events;
  final DateTime? today;
  final DateTime? selected;
  final ValueChanged<DateTime>? onSelect;

  const CompactCalendarGrid({
    super.key,
    required this.month,
    required this.events,
    this.today,
    this.selected,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final days = _weeksGridDays(month);
    const weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        Row(
          children: weekdayLabels
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d, style: Theme.of(context).textTheme.labelMedium),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        for (int w = 0; w < 6; w++)
          Row(
            children: [
              for (int d = 0; d < 7; d++)
                Expanded(child: _dayCell(context, days[w * 7 + d])),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(BuildContext context, DateTime day) {
    final inMonth = day.month == month.month;
    final isToday = today != null && _sameDay(day, today!);
    final isSelected = selected != null && _sameDay(day, selected!);
    final dayEvents = events.where((e) => _sameDay(e.post.dueDate, day)).toList();

    return GestureDetector(
      onTap: onSelect == null ? null : () => onSelect!(day),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isToday ? AppColors.primary.withValues(alpha: 0.12) : null),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : inMonth
                        ? AppColors.textDark
                        : AppColors.textMuted.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 6,
              child: dayEvents.isEmpty
                  ? null
                  : StatusDot(status: dayEvents.first.post.status, size: 6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable "Upcoming" agenda list — pairs with [CompactCalendarGrid].
class AgendaList extends StatelessWidget {
  final List<CalendarEvent> events;

  const AgendaList({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(events)..sort((a, b) => a.post.dueDate.compareTo(b.post.dueDate));
    final fmt = DateFormat('MMM d');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UPCOMING', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 10),
        for (final e in sorted)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                StatusDot(status: e.post.status, size: 9),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.post.displayTitle,
                          style: const TextStyle(
                              fontFamily: 'IBM Plex Sans', fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('${fmt.format(e.post.dueDate)} · ${e.post.status.label}',
                          style: Theme.of(context).textTheme.bodySmall),
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
