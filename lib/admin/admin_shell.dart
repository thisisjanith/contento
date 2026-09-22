import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import '../widgets/adaptive_scaffold.dart';
import 'content_calendar_screen.dart';
import 'employees_screen.dart';
import 'overview_screen.dart';
import 'projects_screen.dart';
import 'settings_screen.dart';
import 'submissions_queue_screen.dart';

/// Root navigation shell for the admin console — web only, per the brief
/// (Overview, Submissions Queue, Projects, Calendar, Employees, Settings).
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider)!;

    return AdaptiveScaffold(
      user: user,
      onSignOut: () => ref.read(sessionProvider.notifier).signOut(),
      items: [
        AdaptiveNavItem(icon: Icons.insights_outlined, activeIcon: Icons.insights_rounded, label: 'Overview', builder: (_) => const OverviewScreen()),
        AdaptiveNavItem(
            icon: Icons.fact_check_outlined,
            activeIcon: Icons.fact_check_rounded,
            label: 'Submissions Queue',
            builder: (_) => const SubmissionsQueueScreen()),
        AdaptiveNavItem(icon: Icons.folder_open_outlined, activeIcon: Icons.folder_rounded, label: 'Projects', builder: (_) => const ProjectsScreen()),
        AdaptiveNavItem(
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Calendar',
            builder: (_) => const ContentCalendarScreen()),
        AdaptiveNavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Employees', builder: (_) => const EmployeesScreen()),
        AdaptiveNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings', builder: (_) => const SettingsScreen()),
      ],
    );
  }
}
