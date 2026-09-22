import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../state/image_upload.dart';
import '../theme/adaptive.dart';
import '../theme/colors.dart';
import '../widgets/app_toast.dart';

final _dueFormat = DateFormat('MMMM d, y');

/// Employee-authored new post: the employee originates the brief
/// themselves (title, due date, reference link, fact-check/style notes)
/// alongside the usual caption / image / reviewer notes, then Save Draft
/// or Submit for Review — same as post_detail_screen.dart, just with the
/// reference fields editable instead of read-only.
class NewPostScreen extends ConsumerStatefulWidget {
  final String projectId;
  const NewPostScreen({super.key, required this.projectId});

  @override
  ConsumerState<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<NewPostScreen> {
  final _titleController = TextEditingController();
  final _referenceController = TextEditingController();
  final _factCheckController = TextEditingController();
  final _styleController = TextEditingController();
  final _captionController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 5));
  Uint8List? _pickedImageBytes;
  String _pickedImageExt = 'jpg';
  bool _submitting = false;

  static const _maxLength = 500;

  @override
  void dispose() {
    _titleController.dispose();
    _referenceController.dispose();
    _factCheckController.dispose();
    _styleController.dispose();
    _captionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _factCheckNotes =>
      _factCheckController.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  bool _validateTitle() {
    if (_titleController.text.trim().isEmpty) {
      AppToast.show(context, 'Give the post a title first.', isError: true);
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageExt = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    });
  }

  void _removeImage() => setState(() => _pickedImageBytes = null);

  Future<void> _create({required bool submit}) async {
    if (!_validateTitle()) return;
    if (submit && _captionController.text.trim().isEmpty) {
      AppToast.show(context, 'Add a caption before submitting.', isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final post = await ref.read(postsProvider.notifier).createPost(
            projectId: widget.projectId,
            title: _titleController.text.trim(),
            dueDate: _dueDate,
            referenceLink: _referenceController.text.trim(),
            factCheckNotes: _factCheckNotes,
            styleNotes: _styleController.text.trim(),
            caption: _captionController.text.trim(),
            notes: _notesController.text.trim(),
            submit: submit,
          );
      if (_pickedImageBytes != null) {
        final imageUrl = await uploadPostImage(postId: post.id, bytes: _pickedImageBytes!, fileExtension: _pickedImageExt);
        await ref.read(postsProvider.notifier).saveDraft(
              post.id,
              caption: _captionController.text.trim(),
              imageUrl: imageUrl,
              notes: _notesController.text.trim(),
            );
      }
      if (!mounted) return;
      AppToast.show(context, submit ? 'Submitted — ${post.displayTitle} sent for review' : 'Draft saved — ${post.displayTitle}');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'Could not save — $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Adaptive.isIOSNative) return _iosBuild(context);
    if (Adaptive.isAndroidNative) return _androidBuild(context);
    return _webBuild(context);
  }

  // ------------------------------------------------------------- shared --
  Widget _titleField(BuildContext context) {
    return TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'e.g. Wildlife topic'));
  }

  Widget _dueDateField(BuildContext context) {
    return InkWell(
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
    );
  }

  Widget _referenceBlock(BuildContext context, {bool uppercaseHeadings = false}) {
    String heading(String s) => uppercaseHeadings ? s.toUpperCase() : s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading('Reference material'), style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 10),
        Text('Source link (optional)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        TextField(controller: _referenceController, decoration: const InputDecoration(hintText: 'contento.link/src/…')),
        const SizedBox(height: 14),
        Text('Fact-check notes (optional, one per line)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        TextField(
          controller: _factCheckController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Confirm species name spelling before posting.'),
        ),
        const SizedBox(height: 14),
        Text('Style notes (optional)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        TextField(controller: _styleController, maxLines: 2, decoration: const InputDecoration(hintText: 'Length, tone, formatting guidance…')),
      ],
    );
  }

  Widget _captionField(BuildContext context, {int maxLines = 6}) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _captionController,
            maxLines: maxLines,
            maxLength: _maxLength,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(border: InputBorder.none, counterText: '', isDense: true),
            style: const TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 14.5, height: 1.5),
          ),
          Text('${_captionController.text.length} / $_maxLength', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _photoPicker(BuildContext context) {
    if (_pickedImageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: double.infinity, height: 160, child: Image.memory(_pickedImageBytes!, fit: BoxFit.cover)),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _removeImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.upload_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(height: 6),
            const Text(
              'Click to upload or drag and drop',
              style: TextStyle(fontFamily: 'IBM Plex Sans', fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
            ),
            const SizedBox(height: 2),
            Text('PNG or JPG, up to 10MB', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _notesField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Add any context for the reviewer…'),
        style: const TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 14),
      ),
    );
  }

  // ---------------------------------------------------------------- iOS --
  Widget _iosBuild(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('New Post'),
        backgroundColor: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Post title', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  _titleField(context),
                  const SizedBox(height: 14),
                  Text('Due date', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  _dueDateField(context),
                  const SizedBox(height: 20),
                  _referenceBlock(context),
                  const SizedBox(height: 22),
                  Text('Your submission', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 10),
                  _captionField(context),
                  const SizedBox(height: 14),
                  _photoPicker(context),
                  const SizedBox(height: 14),
                  Text('Notes for reviewer (optional)', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  _notesField(context),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _submitting ? null : () => _create(submit: true),
                      child: const Text('Submit for Review'),
                    ),
                  ),
                  CupertinoButton(onPressed: _submitting ? null : () => _create(submit: false), child: const Text('Save Draft')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ Android --
  Widget _androidBuild(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New Post'), backgroundColor: AppColors.surface, elevation: 2),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        children: [
          Text('POST TITLE', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          _titleField(context),
          const SizedBox(height: 14),
          Text('DUE DATE', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          _dueDateField(context),
          const SizedBox(height: 20),
          _referenceBlock(context, uppercaseHeadings: true),
          const SizedBox(height: 22),
          Text('YOUR SUBMISSION', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          Text('CAPTION', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          _captionField(context),
          const SizedBox(height: 14),
          Text('PHOTO (OPTIONAL)', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          _photoPicker(context),
          const SizedBox(height: 14),
          Text('NOTES (OPTIONAL)', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          _notesField(context),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : () => _create(submit: true),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
            child: const Text('SUBMIT FOR REVIEW'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _submitting ? null : () => _create(submit: false), child: const Text('SAVE DRAFT')),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- Web/desk --
  Widget _webBuild(BuildContext context) {
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
              label: const Text('Back to My Project'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted, padding: EdgeInsets.zero),
            ),
            const SizedBox(height: 8),
            Text('New Post', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text('Add a new post under your project.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final left = Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Post title', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      _titleField(context),
                      const SizedBox(height: 18),
                      Text('Due date', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      _dueDateField(context),
                      const SizedBox(height: 22),
                      _referenceBlock(context, uppercaseHeadings: true),
                    ],
                  ),
                );
                final right = Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Caption / description', style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          Text('${_captionController.text.length} / $_maxLength', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _captionController,
                        maxLines: 6,
                        maxLength: _maxLength,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(counterText: ''),
                      ),
                      const SizedBox(height: 18),
                      Text('Image (optional)', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _photoPicker(context),
                      const SizedBox(height: 18),
                      Text('Notes for reviewer (optional)', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _notesField(context),
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(onPressed: _submitting ? null : () => _create(submit: false), child: const Text('Save draft')),
                          const SizedBox(width: 12),
                          ElevatedButton(onPressed: _submitting ? null : () => _create(submit: true), child: const Text('Submit for review')),
                        ],
                      ),
                    ],
                  ),
                );

                if (!wide) return Column(children: [left, const SizedBox(height: 20), right]);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: left),
                    const SizedBox(width: 20),
                    Expanded(flex: 5, child: right),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
