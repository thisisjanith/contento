import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/calendar_grid.dart';
import 'new_project_screen.dart';

final _monthFormat = DateFormat('MMMM y');

/// Admin "Content Calendar" — every post across every project, plotted by
/// due date, color-coded by status, with the employee's name on each
/// event chip (unlike the employee's own calendar, which omits names).
class ContentCalendarScreen extends ConsumerStatefulWidget {
  const ContentCalendarScreen({super.key});

  @override
  ConsumerState<ContentCalendarScreen> createState() => _ContentCalendarScreenState();
}

class _ContentCalendarScreenState extends ConsumerState<ContentCalendarScreen> {
  late DateTime _month = DateTime(2026, 9);

  void _shift(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(postsProvider);
    final projects = ref.watch(projectsProvider);

    final events = posts.map((p) {
      final project = projects.firstWhere((pr) => pr.id == p.projectId);
      final employee = ref.watch(employeeByIdProvider(project.employeeId));
      return CalendarEvent(p, employeeName: employee?.name.split(' ').first);
    }).toList();

    final today = DateTime(2026, 9, 22);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Content Calendar', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('Every post across every project, laid out by due date.', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewProjectScreen())),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Project'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(_monthFormat.format(_month), style: Theme.of(context).textTheme.headlineMedium),
              IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left_rounded)),
              IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right_rounded)),
              OutlinedButton(onPressed: () => setState(() => _month = DateTime(today.year, today.month)), child: const Text('Today')),
              const Spacer(),
              _legendDot('Pending', AppColors.statusPending),
              _legendDot('Submitted', AppColors.statusSubmitted),
              _legendDot('Needs Revision', AppColors.statusNeedsRevision),
              _legendDot('Approved', AppColors.statusApproved),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(child: CalendarMonthGrid(month: _month, events: events, today: today)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
