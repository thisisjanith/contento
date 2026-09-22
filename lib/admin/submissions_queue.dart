import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/employee.dart';
import '../models/post.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/app_toast.dart';
import '../widgets/status_badge.dart';

final _dateTimeFormat = DateFormat('MMM d, h:mm a');

/// The filterable, expandable submissions queue — shared by Overview
/// (embedded under the stat cards) and the standalone Submissions Queue
/// page, so the review workflow only exists in one place.
class SubmissionsQueue extends ConsumerStatefulWidget {
  const SubmissionsQueue({super.key});

  @override
  ConsumerState<SubmissionsQueue> createState() => SubmissionsQueueState();
}

class SubmissionsQueueState extends ConsumerState<SubmissionsQueue> {
  PostStatus? _statusFilter;
  String? _employeeFilter;
  String _search = '';
  String? _expandedPostId;

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(postsProvider);
    final projects = ref.watch(projectsProvider);
    final employees = ref.watch(employeesProvider).where((e) => e.role == UserRole.employee).toList();

    var queue = posts.where((p) => p.submittedAt != null).toList()
      ..sort((a, b) => b.submittedAt!.compareTo(a.submittedAt!));

    String employeeIdOf(Post p) => projects.firstWhere((pr) => pr.id == p.projectId).employeeId;
    if (_statusFilter != null) queue = queue.where((p) => p.status == _statusFilter).toList();
    if (_employeeFilter != null) queue = queue.where((p) => employeeIdOf(p) == _employeeFilter).toList();
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      queue = queue.where((p) => p.title.toLowerCase().contains(q) || p.number.toString().contains(q)).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                decoration: const InputDecoration(hintText: 'Search submissions', prefixIcon: Icon(Icons.search_rounded, size: 20)),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            _statusDropdown(),
            _employeeDropdown(employees),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: queue.isEmpty
              ? Center(child: Text('No submissions match these filters.', style: Theme.of(context).textTheme.bodyMedium))
              : ListView.builder(
                  itemCount: queue.length,
                  itemBuilder: (context, i) {
                    final post = queue[i];
                    final employee = ref.watch(employeeByIdProvider(employeeIdOf(post)))!;
                    final project = projects.firstWhere((pr) => pr.id == post.projectId);
                    return QueueRow(
                      post: post,
                      employee: employee,
                      project: project,
                      expanded: _expandedPostId == post.id,
                      onToggle: () => setState(() => _expandedPostId = _expandedPostId == post.id ? null : post.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _statusDropdown() {
    return _dropdownShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PostStatus?>(
          value: _statusFilter,
          hint: const Text('All statuses'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All statuses')),
            for (final s in PostStatus.values) DropdownMenuItem(value: s, child: Text(s.label)),
          ],
          onChanged: (v) => setState(() => _statusFilter = v),
        ),
      ),
    );
  }

  Widget _employeeDropdown(List<Employee> employees) {
    return _dropdownShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _employeeFilter,
          hint: const Text('All employees'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All employees')),
            for (final e in employees) DropdownMenuItem(value: e.id, child: Text(e.name)),
          ],
          onChanged: (v) => setState(() => _employeeFilter = v),
        ),
      ),
    );
  }

  Widget _dropdownShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.border)),
      child: child,
    );
  }
}

class QueueRow extends ConsumerStatefulWidget {
  final Post post;
  final Employee employee;
  final dynamic project;
  final bool expanded;
  final VoidCallback onToggle;

  const QueueRow({
    super.key,
    required this.post,
    required this.employee,
    required this.project,
    required this.expanded,
    required this.onToggle,
  });

  @override
  ConsumerState<QueueRow> createState() => QueueRowState();
}

class QueueRowState extends ConsumerState<QueueRow> {
  late final TextEditingController _feedbackController = TextEditingController();
  late final TextEditingController _editController = TextEditingController(text: widget.post.caption);
  bool _editing = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(widget.employee.initials, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: Text(widget.employee.name, style: Theme.of(context).textTheme.titleMedium)),
                  Expanded(flex: 5, child: Text('Project #${widget.project.number} · ${post.displayTitle}', style: Theme.of(context).textTheme.bodyMedium)),
                  Expanded(flex: 2, child: StatusBadge(status: post.status)),
                  Expanded(
                    flex: 3,
                    child: Text(_dateTimeFormat.format(post.submittedAt!), textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Icon(widget.expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          if (widget.expanded) _expandedBody(context, post),
        ],
      ),
    );
  }

  Widget _expandedBody(BuildContext context, Post post) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: post.imageUrl.isEmpty
                  ? const Icon(Icons.image_outlined, color: AppColors.textMuted)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(post.imageUrl, fit: BoxFit.cover, width: 96, height: 96),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _editing ? TextField(controller: _editController, maxLines: 4) : Text('"${post.caption}"', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(post.referenceLink, style: const TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 12.5, color: AppColors.primary)),
                      const SizedBox(width: 14),
                      Text('Submitted by ${widget.employee.name}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  if (post.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Employee notes: ${post.notes}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 10),
                  TextField(controller: _feedbackController, decoration: const InputDecoration(hintText: 'Add feedback if requesting a revision…')),
                  if (post.status == PostStatus.approved) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: post.scheduled,
                          onChanged: (_) async {
                            try {
                              await ref.read(postsProvider.notifier).toggleScheduled(post.id);
                            } catch (e) {
                              if (!context.mounted) return;
                              AppToast.show(context, 'Could not update — $e', isError: true);
                            }
                          },
                        ),
                        const Text('Mark as Scheduled', style: TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 140,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await ref.read(postsProvider.notifier).approve(post.id);
                          if (!context.mounted) return;
                          AppToast.show(context, 'Approved — ${post.displayTitle}');
                        } catch (e) {
                          if (!context.mounted) return;
                          AppToast.show(context, 'Could not approve — $e', isError: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.approved),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (_feedbackController.text.trim().isEmpty) {
                          AppToast.show(context, 'Add feedback before rejecting.', isError: true);
                          return;
                        }
                        try {
                          await ref.read(postsProvider.notifier).reject(post.id, _feedbackController.text.trim());
                          if (!context.mounted) return;
                          AppToast.show(context, 'Sent back — ${post.displayTitle}');
                        } catch (e) {
                          if (!context.mounted) return;
                          AppToast.show(context, 'Could not send back — $e', isError: true);
                        }
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: const BorderSide(color: AppColors.accent)),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (_editing) {
                          try {
                            await ref.read(postsProvider.notifier).editCaption(post.id, _editController.text.trim());
                            if (!context.mounted) return;
                            AppToast.show(context, 'Caption updated.');
                          } catch (e) {
                            if (!context.mounted) return;
                            AppToast.show(context, 'Could not save — $e', isError: true);
                            return;
                          }
                        }
                        setState(() => _editing = !_editing);
                      },
                      child: Text(_editing ? 'Save edit' : 'Edit inline'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
