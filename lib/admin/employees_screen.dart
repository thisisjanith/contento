import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../models/post.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import 'add_employee_screen.dart';
import 'new_project_screen.dart';
import 'project_detail_screen.dart';

/// Admin "Employees" — roster list, and the entry point for the
/// employee → project → posts drill-down. Tap an employee to see their
/// project and every post under it (including ones they created
/// themselves via "New Post").
class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);
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
                    Text('Employees', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('Everyone with access to Contento. Tap an employee to see their project and posts.',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEmployeeScreen())),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add Employee'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, i) {
                final e = employees[i];
                final project = projects.where((p) => p.employeeId == e.id).firstOrNull;
                final activePosts = project == null ? 0 : posts.where((p) => p.projectId == project.id && p.status != PostStatus.approved).length;
                final isEmployee = e.role == UserRole.employee;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: !isEmployee
                        ? null
                        : () {
                            if (project != null) {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)));
                            } else {
                              _promptCreateProject(context, e);
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: e.role == UserRole.admin ? AppColors.textDark : AppColors.primary,
                            child: Text(e.initials, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.name, style: Theme.of(context).textTheme.titleMedium),
                                Text(e.email, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          if (isEmployee)
                            Text(
                              project != null ? '${project.displayTitle} · $activePosts active' : 'No project yet',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: e.role == UserRole.admin ? AppColors.textDark.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(e.roleLabel,
                                style: TextStyle(
                                    fontFamily: 'IBM Plex Sans',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: e.role == UserRole.admin ? AppColors.textDark : AppColors.primary)),
                          ),
                          if (isEmployee) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          ],
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

  void _promptCreateProject(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${employee.name} has no project yet'),
        content: const Text('Create a project for them to start assigning work.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewProjectScreen()));
            },
            child: const Text('New Project'),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
