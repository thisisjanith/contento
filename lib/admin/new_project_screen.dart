import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/employee.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/app_toast.dart';
import '../widgets/status_badge.dart';
import '../models/post.dart';

final _dueFormat = DateFormat('MM/dd/yyyy');

/// New Project — one employee per project (single-select, never
/// multi-select — a common bug risk if copied from a multi-assign
/// pattern). Live "what the employee will see" preview so admins can
/// sanity-check nothing identifying leaked into the title/brief.
class NewProjectScreen extends ConsumerStatefulWidget {
  const NewProjectScreen({super.key});

  @override
  ConsumerState<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends ConsumerState<NewProjectScreen> {
  final _titleController = TextEditingController();
  final _briefController = TextEditingController();
  String? _employeeId;
  DateTime _firstPostDue = DateTime.now().add(const Duration(days: 5));
  String _batch = 'General';

  static const _batches = ['General', 'Wildlife & Recovery', 'Human Interest', 'Mystery & Legends', 'Weekend Recap'];

  @override
  void dispose() {
    _titleController.dispose();
    _briefController.dispose();
    super.dispose();
  }

  int _peekNextProjectNumber(WidgetRef ref) {
    final projects = ref.read(projectsProvider);
    return projects.fold<int>(0, (m, p) => p.number > m ? p.number : m) + 1;
  }

  Future<void> _create({required bool draft}) async {
    final employeeId = _employeeId;
    if (_titleController.text.trim().isEmpty || employeeId == null) {
      AppToast.show(context, 'Add a project title and assign an employee first.', isError: true);
      return;
    }
    final project = await ref.read(projectsProvider.notifier).create(
          title: _titleController.text.trim(),
          employeeId: employeeId,
          sourceBrief: _briefController.text.trim(),
        );
    if (!draft) {
      await ref.read(postsProvider.notifier).createPost(
            projectId: project.id,
            title: 'First post',
            dueDate: _firstPostDue,
          );
    }
    if (!mounted) return;
    AppToast.show(context, draft ? 'Draft saved.' : 'Project created — ${project.displayTitle}');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider).where((e) => e.role == UserRole.employee).toList();
    final nextNumber = _peekNextProjectNumber(ref);
    final title = _titleController.text.trim().isEmpty ? 'Wildlife & Recovery Series' : _titleController.text.trim();

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
              label: const Text('Back to Overview'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted, padding: EdgeInsets.zero),
            ),
            const SizedBox(height: 12),
            Text('New Project', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text(
              "Each project belongs to one employee. This creates the anonymized project they'll see — no client or page names.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final form = _formCard(employees);
              final preview = _previewCard(nextNumber, title);
              if (!wide) return Column(children: [form, const SizedBox(height: 20), preview]);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: form),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: preview),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _formCard(List<Employee> employees) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project title', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'e.g. Wildlife & Recovery Series'),
          ),
          const SizedBox(height: 4),
          Text('Shown to the employee as "Project #? — [this title]". Keep it generic.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 18),
          Text('Assign to', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(9)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _employeeId,
                hint: const Text('Select one employee'),
                items: [for (final e in employees) DropdownMenuItem(value: e.id, child: Text(e.name))],
                onChanged: (v) => setState(() => _employeeId = v),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text("One employee per project. Individual posts are added under this project once it's created.",
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 18),
          Text('Source link / brief', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          TextField(
            controller: _briefController,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Paste a reference link and any fact-checking notes for the first post…'),
          ),
          const SizedBox(height: 4),
          Text('Visible only to reviewers and the assigned employee — never shows the originating page.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('First post due', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _firstPostDue,
                          firstDate: DateTime(2026, 1, 1),
                          lastDate: DateTime(2027, 12, 31),
                        );
                        if (picked != null) setState(() => _firstPostDue = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Row(
                          children: [
                            Text(_dueFormat.format(_firstPostDue)),
                            const Spacer(),
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Content batch', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(9)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _batch,
                          items: [for (final b in _batches) DropdownMenuItem(value: b, child: Text(b))],
                          onChanged: (v) => setState(() => _batch = v ?? _batch),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: () => _create(draft: true), child: const Text('Save as draft')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () => _create(draft: false), child: const Text('Create project')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewCard(int nextNumber, String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHAT THE EMPLOYEE WILL SEE', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROJECT #$nextNumber — ${title.toUpperCase()}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary)),
                const SizedBox(height: 8),
                const StatusBadge(status: PostStatus.pending),
                const SizedBox(height: 8),
                Text('First post', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Source brief attached', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Due ${DateFormat('MMM d').format(_firstPostDue)}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Employees never see the client, page name or brand — only the project, post title, brief and due date shown above.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
