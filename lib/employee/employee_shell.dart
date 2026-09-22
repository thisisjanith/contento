import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import '../theme/adaptive.dart';
import '../widgets/adaptive_scaffold.dart';
import 'my_calendar_screen.dart';
import 'my_submissions_screen.dart';
import 'profile_screen.dart';
import 'project_home_screen.dart';

/// Root navigation shell for the employee flow: sidebar on web/desktop,
/// bottom tab bar on iOS/Android. A 4th "Profile" destination only shows
/// on native/mobile-web (the wide sidebar surfaces account info in its
/// own footer instead).
class EmployeeShell extends ConsumerWidget {
  const EmployeeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider)!;

    final items = <AdaptiveNavItem>[
      AdaptiveNavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Project',
        builder: (_) => const ProjectHomeScreen(),
      ),
      AdaptiveNavItem(
        icon: Icons.check_circle_outline_rounded,
        activeIcon: Icons.check_circle_rounded,
        label: 'Submissions',
        builder: (_) => const MySubmissionsScreen(),
      ),
      AdaptiveNavItem(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today_rounded,
        label: 'Calendar',
        builder: (_) => const MyCalendarScreen(),
      ),
    ];

    if (Adaptive.isNativeMobile) {
      items.add(
        AdaptiveNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profile',
          builder: (_) => const ProfileScreen(),
        ),
      );
    }

    return AdaptiveScaffold(
      items: items,
      user: user,
      onSignOut: () => ref.read(sessionProvider.notifier).signOut(),
    );
  }
}
