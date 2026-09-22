import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../theme/adaptive.dart';
import '../theme/colors.dart';
import '../widgets/calendar_grid.dart';

final _monthFormat = DateFormat('MMMM y');

/// "My Calendar" — month view of just this employee's own posts, plotted
/// by due date. Web: full grid with text chips. Native (narrower width):
/// compact dot-indicator grid + a scrollable "Upcoming" agenda list below.
class MyCalendarScreen extends ConsumerStatefulWidget {
  const MyCalendarScreen({super.key});

  @override
  ConsumerState<MyCalendarScreen> createState() => _MyCalendarScreenState();
}

class _MyCalendarScreenState extends ConsumerState<MyCalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider)!;
    final project = ref.watch(projectForEmployeeProvider(user.id));
    if (project == null) return const Center(child: Text('No project assigned yet.'));

    final posts = ref.watch(postsByProjectProvider(project.id));
    final events = posts.map((p) => CalendarEvent(p)).toList();
    final today = DateTime.now();

    if (Adaptive.isIOSNative) return _iosBuild(context, events, today);
    if (Adaptive.isAndroidNative) return _androidBuild(context, events, today);
    return _webBuild(context, events, today);
  }

  Widget _navRow(BuildContext context) {
    return Row(
      children: [
        Text(_monthFormat.format(_month), style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(width: 12),
        IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left_rounded)),
        IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right_rounded)),
      ],
    );
  }

  Widget _iosBuild(BuildContext context, List<CalendarEvent> events, DateTime today) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('My Calendar'),
        backgroundColor: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(padding: EdgeInsets.zero, onPressed: () => _shift(-1), child: const Icon(CupertinoIcons.chevron_left)),
                SizedBox(width: 160, child: Center(child: Text(_monthFormat.format(_month), style: Theme.of(context).textTheme.headlineMedium))),
                CupertinoButton(padding: EdgeInsets.zero, onPressed: () => _shift(1), child: const Icon(CupertinoIcons.chevron_right)),
              ],
            ),
            const SizedBox(height: 8),
            CompactCalendarGrid(month: _month, events: events, today: today),
            const SizedBox(height: 20),
            AgendaList(events: events),
          ],
        ),
      ),
    );
  }

  Widget _androidBuild(BuildContext context, List<CalendarEvent> events, DateTime today) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Calendar'), backgroundColor: AppColors.surface, elevation: 2),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left_rounded)),
                      Text(_monthFormat.format(_month), style: Theme.of(context).textTheme.headlineMedium),
                      IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right_rounded)),
                    ],
                  ),
                  CompactCalendarGrid(month: _month, events: events, today: today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AgendaList(events: events),
        ],
      ),
    );
  }

  Widget _webBuild(BuildContext context, List<CalendarEvent> events, DateTime today) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Calendar', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Every post in ${_month.year == today.year ? "your project" : "your project"}, laid out by due date.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              _navRow(context),
              const Spacer(),
              OutlinedButton(
                onPressed: () => setState(() => _month = DateTime(today.year, today.month)),
                child: const Text('Today'),
              ),
              const SizedBox(width: 16),
              _legendDot(context, 'Pending', AppColors.statusPending),
              _legendDot(context, 'Submitted', AppColors.statusSubmitted),
              _legendDot(context, 'Needs Revision', AppColors.statusNeedsRevision),
              _legendDot(context, 'Approved', AppColors.statusApproved),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: CalendarMonthGrid(month: _month, events: events, today: today),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(BuildContext context, String label, Color color) {
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
