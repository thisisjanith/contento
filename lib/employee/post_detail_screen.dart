import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/post.dart';
import '../state/app_state.dart';
import '../state/image_upload.dart';
import '../theme/adaptive.dart';
import '../theme/colors.dart';
import '../widgets/app_toast.dart';
import '../widgets/status_badge.dart';

final _dueFormat = DateFormat('MMMM d, y');

/// Post detail / submission form. Reference material (source link,
/// fact-check notes, style notes) is read-only, supplied by the admin.
/// Submission section: caption with a live counter, optional image,
/// optional notes-to-reviewer, Save Draft / Submit for Review.
class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  late final TextEditingController _captionController;
  late final TextEditingController _notesController;
  String _existingImageUrl = '';
  Uint8List? _pickedImageBytes;
  String _pickedImageExt = 'jpg';
  bool _initialized = false;
  bool _submitting = false;

  static const _maxLength = 500;

  Post _post(WidgetRef ref) =>
      ref.watch(postsProvider).firstWhere((p) => p.id == widget.postId);

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _hydrate(Post post) {
    if (_initialized) return;
    _initialized = true;
    _captionController.text = post.caption;
    _notesController.text = post.notes;
    _existingImageUrl = post.imageUrl;
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

  void _removeImage() {
    setState(() {
      _pickedImageBytes = null;
      _existingImageUrl = '';
    });
  }

  Future<String> _resolveImageUrl(Post post) async {
    if (_pickedImageBytes == null) return _existingImageUrl;
    return uploadPostImage(postId: post.id, bytes: _pickedImageBytes!, fileExtension: _pickedImageExt);
  }

  Future<void> _saveDraft(Post post) async {
    setState(() => _submitting = true);
    try {
      final imageUrl = await _resolveImageUrl(post);
      await ref.read(postsProvider.notifier).saveDraft(
            post.id,
            caption: _captionController.text.trim(),
            imageUrl: imageUrl,
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      AppToast.show(context, 'Draft saved.');
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'Could not save — $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submit(Post post) async {
    if (_captionController.text.trim().isEmpty) {
      AppToast.show(context, 'Add a caption before submitting.', isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final imageUrl = await _resolveImageUrl(post);
      await ref.read(postsProvider.notifier).submit(
            post.id,
            caption: _captionController.text.trim(),
            imageUrl: imageUrl,
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      AppToast.show(context, 'Submitted — ${post.displayTitle} sent for review');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'Could not submit — $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post(ref);
    _hydrate(post);

    if (Adaptive.isIOSNative) return _iosBuild(context, post);
    if (Adaptive.isAndroidNative) return _androidBuild(context, post);
    return _webBuild(context, post);
  }

  // ------------------------------------------------------------- shared --
  Widget _referenceBlock(BuildContext context, Post post, {bool uppercaseHeadings = false}) {
    String heading(String s) => uppercaseHeadings ? s.toUpperCase() : s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading('Reference material'), style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 10),
        if (post.hasBrief)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(post.referenceLink,
                      style: const TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 13.5, color: AppColors.primary)),
                ),
              ],
            ),
          ),
        if (post.factCheckNotes.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Fact-check notes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final note in post.factCheckNotes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: Icon(Icons.circle, size: 4, color: AppColors.textMuted),
                  ),
                  Expanded(child: Text(note, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
        if (post.styleNotes.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Style notes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(post.styleNotes, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }

  Widget _captionField(BuildContext context, {int maxLines = 6}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _captionController,
            maxLines: maxLines,
            maxLength: _maxLength,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              isDense: true,
            ),
            style: const TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 14.5, height: 1.5),
          ),
          Text('${_captionController.text.length} / $_maxLength', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _photoPicker(BuildContext context) {
    final hasImage = _pickedImageBytes != null || _existingImageUrl.isNotEmpty;

    if (hasImage) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: double.infinity,
              height: 160,
              child: _pickedImageBytes != null
                  ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                  : Image.network(_existingImageUrl, fit: BoxFit.cover),
            ),
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
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'Add any context for the reviewer…',
        ),
        style: const TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 14),
      ),
    );
  }

  // ---------------------------------------------------------------- iOS --
  Widget _iosBuild(BuildContext context, Post post) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(post.displayTitle),
        backgroundColor: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      StatusBadge(status: post.status),
                      const SizedBox(width: 8),
                      Text('Due ${_dueFormat.format(post.dueDate)}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _referenceBlock(context, post),
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
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _submitting ? null : () => _submit(post),
                      child: const Text('Submit for Review'),
                    ),
                  ),
                  CupertinoButton(onPressed: _submitting ? null : () => _saveDraft(post), child: const Text('Save Draft')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ Android --
  Widget _androidBuild(BuildContext context, Post post) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(post.displayTitle), backgroundColor: AppColors.surface, elevation: 2),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        children: [
          Row(
            children: [
              StatusBadge(status: post.status, uppercase: true),
              const SizedBox(width: 8),
              Text('Due ${_dueFormat.format(post.dueDate)}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 18),
          _referenceBlock(context, post, uppercaseHeadings: true),
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
            onPressed: _submitting ? null : () => _submit(post),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('SUBMIT FOR REVIEW'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _submitting ? null : () => _saveDraft(post), child: const Text('SAVE DRAFT')),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- Web/desk --
  Widget _webBuild(BuildContext context, Post post) {
    return SingleChildScrollView(
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
          Text('PROJECT · POST #${post.number}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(post.displayTitle, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(width: 12),
              StatusBadge(status: post.status),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('Due ${_dueFormat.format(post.dueDate)}', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final reference = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: _referenceBlock(context, post, uppercaseHeadings: true),
              );
              final submission = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
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
                    _captionFieldWeb(),
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
                        OutlinedButton(onPressed: _submitting ? null : () => _saveDraft(post), child: const Text('Save draft')),
                        const SizedBox(width: 12),
                        ElevatedButton(onPressed: _submitting ? null : () => _submit(post), child: const Text('Submit for review')),
                      ],
                    ),
                  ],
                ),
              );

              if (!wide) {
                return Column(children: [reference, const SizedBox(height: 20), submission]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: reference),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: submission),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _captionFieldWeb() {
    return TextField(
      controller: _captionController,
      maxLines: 6,
      maxLength: _maxLength,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(counterText: ''),
    );
  }
}
