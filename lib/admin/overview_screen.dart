import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../models/post.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import 'new_project_screen.dart';
import 'submissions_queue.dart';

/// Admin "Overview" — top-line stats + the filterable, expandable
/// submissions queue: a queue you can clear quickly, not a chore.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsProvider);
    final employees = ref.watch(employeesProvider).where((e) => e.role == UserRole.employee).toList();

    final now = DateTime(2026, 9, 22);
    final pendingReview = posts.where((p) => p.status == PostStatus.submitted).length;
    final approvedThisWeek = posts
        .where((p) => p.status == PostStatus.approved && p.submittedAt != null && now.difference(p.submittedAt!).inDays <= 7)
        .length;
    final needsRevision = posts.where((p) => p.status == PostStatus.needsRevision).length;

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
                    Text('Overview', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('Review the queue and keep the content pipeline moving.', style: Theme.of(context).textTheme.bodyMedium),
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
          const SizedBox(height: 22),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statCard(context, 'PENDING REVIEW', '$pendingReview', AppColors.textDark),
              _statCard(context, 'APPROVED THIS WEEK', '$approvedThisWeek', AppColors.approved),
              _statCard(context, 'NEEDS REVISION', '$needsRevision', AppColors.accent),
              _statCard(context, 'ACTIVE EMPLOYEES', '${employees.length}', AppColors.textDark),
            ],
          ),
          const SizedBox(height: 22),
          const Expanded(child: SubmissionsQueue()),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 28, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
