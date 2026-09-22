import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/project.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/app_toast.dart';

final _dueFormat = DateFormat('MM/dd/yyyy');

/// Adds a new post to an *existing* project. New Project creates a
/// project plus its first post; this is how every post after that gets
/// added — "Individual posts are added under this project once it's
/// created" per the brief.
class AddPostScreen extends ConsumerStatefulWidget {
  final Project project;
  const AddPostScreen({super.key, required this.project});

  @override
  ConsumerState<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends ConsumerState<AddPostScreen> {
  final _titleController = TextEditingController();
  final _referenceController = TextEditingController();
  final _factCheckController = TextEditingController();
  final _styleController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 5));

  @override
  void dispose() {
    _titleController.dispose();
    _referenceController.dispose();
    _factCheckController.dispose();
    _styleController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleController.text.trim().isEmpty) {
      AppToast.show(context, 'Give the post a title first.', isError: true);
      return;
    }
    final factCheckNotes = _factCheckController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final post = await ref.read(postsProvider.notifier).createPost(
          projectId: widget.project.id,
          title: _titleController.text.trim(),
          dueDate: _dueDate,
          referenceLink: _referenceController.text.trim(),
          factCheckNotes: factCheckNotes,
          styleNotes: _styleController.text.trim(),
        );
    if (!mounted) return;
    AppToast.show(context, 'Post added — ${post.displayTitle}');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
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
              label: const Text('Back to Project'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted, padding: EdgeInsets.zero),
            ),
            const SizedBox(height: 12),
            Text('New Post', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text('Adding a post under ${widget.project.displayTitle}.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Post title', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'e.g. Wildlife topic')),
                    const SizedBox(height: 4),
                    Text('Shown to the employee as "Post #? — [this title]". Keep it generic.', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 18),
                    Text('Due date', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2026, 1, 1),
                          lastDate: DateTime(2027, 12, 31),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Row(
                          children: [
                            Text(_dueFormat.format(_dueDate)),
                            const Spacer(),
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Source link / brief (optional)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    TextField(controller: _referenceController, decoration: const InputDecoration(hintText: 'contento.link/src/…')),
                    const SizedBox(height: 18),
                    Text('Fact-check notes (optional, one per line)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    TextField(controller: _factCheckController, maxLines: 3, decoration: const InputDecoration(hintText: 'Confirm species name spelling before posting.')),
                    const SizedBox(height: 18),
                    Text('Style notes (optional)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    TextField(controller: _styleController, maxLines: 2, decoration: const InputDecoration(hintText: 'Length, tone, formatting guidance…')),
                    const SizedBox(height: 4),
                    Text('Visible only to reviewers and the assigned employee — never shows the originating page.',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [ElevatedButton(onPressed: _create, child: const Text('Add post'))],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
