import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/project.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/status_badge.dart';
import 'add_post_screen.dart';

final _dueFormat = DateFormat('MMM d');

/// One project's posts, with an "Add post" action — this is how posts
/// after the first one get added to a project (New Project only creates
/// the project plus its first post).
class ProjectDetailScreen extends ConsumerWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(employeeByIdProvider(project.employeeId));
    final posts = ref.watch(postsByProjectProvider(project.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to Projects'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted, padding: EdgeInsets.zero),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.displayTitle, style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 4),
                      Text('Assigned to ${employee?.name ?? "—"} · ${posts.length} posts', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddPostScreen(project: project))),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add post'),
                ),
              ],
            ),
            if (project.sourceBrief.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(project.sourceBrief, style: const TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 13.5, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (posts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No posts yet — add the first one.', style: Theme.of(context).textTheme.bodyMedium)),
              )
            else
              for (final post in posts)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusBadge(status: post.status),
                            const SizedBox(height: 8),
                            Text(post.displayTitle, style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                      Text('Due ${_dueFormat.format(post.dueDate)}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
