import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import 'new_project_screen.dart';
import 'project_detail_screen.dart';

/// Admin "Projects" — every project across the team, one row per project
/// (each belongs to exactly one employee), with a post-status breakdown.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final posts = ref.watch(postsProvider);

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
                    Text('Projects', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('Every project belongs to exactly one employee.', style: Theme.of(context).textTheme.bodyMedium),
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
          Expanded(
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, i) {
                final project = projects[i];
                final employee = ref.watch(employeeByIdProvider(project.employeeId));
                final projectPosts = posts.where((p) => p.projectId == project.id).toList();
                final pending = projectPosts.where((p) => p.status == PostStatus.pending).length;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project))),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                            child: const Icon(Icons.dashboard_customize_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(project.displayTitle, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 3),
                                Text('Assigned to ${employee?.name ?? "—"}', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Text('${projectPosts.length} posts · $pending pending', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(width: 10),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
