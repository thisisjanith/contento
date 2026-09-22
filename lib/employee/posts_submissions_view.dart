import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/post.dart';
import '../state/app_state.dart';
import '../theme/adaptive.dart';
import '../theme/colors.dart';
import '../widgets/post_card.dart';
import '../widgets/status_badge.dart';

/// The "Posts" tab (and the project banner's count) shows the current
/// working batch: anything not yet submitted, plus anything mid-review.
/// Long-settled approved posts still show up in Submissions/Calendar
/// history, just not here.
List<Post> currentBatchPosts(List<Post> all) {
  final approvedSorted = all.where((p) => p.status == PostStatus.approved).toList()
    ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
  final mostRecentApprovedId = approvedSorted.isEmpty ? null : approvedSorted.first.id;
  return all.where((p) => p.status != PostStatus.approved || p.id == mostRecentApprovedId).toList();
}

/// Shared Posts/Submissions segmented body — both "My Project" and
/// "My Submissions" land here, just with different headers and a
/// different default tab (see project_home_screen.dart / my_submissions_screen.dart).
class PostsSubmissionsView extends ConsumerStatefulWidget {
  final String projectId;
  final int initialTab; // 0 = Posts, 1 = Submissions
  final void Function(Post post) onOpenPost;

  const PostsSubmissionsView({
    super.key,
    required this.projectId,
    required this.onOpenPost,
    this.initialTab = 0,
  });

  @override
  ConsumerState<PostsSubmissionsView> createState() => _PostsSubmissionsViewState();
}

class _PostsSubmissionsViewState extends ConsumerState<PostsSubmissionsView> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(postsByProjectProvider(widget.projectId));
    final activePosts = currentBatchPosts(posts);
    final submissions = posts.where((p) => p.submittedAt != null).toList()
      ..sort((a, b) => b.submittedAt!.compareTo(a.submittedAt!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _segmentedControl(),
        const SizedBox(height: 16),
        Expanded(
          child: _tab == 0 ? _postsList(activePosts) : _submissionsList(submissions),
        ),
      ],
    );
  }

  Widget _segmentedControl() {
    if (Adaptive.isIOSNative) {
      return CupertinoSlidingSegmentedControl<int>(
        groupValue: _tab,
        backgroundColor: AppColors.background,
        thumbColor: AppColors.surface,
        onValueChanged: (v) => setState(() => _tab = v ?? 0),
        children: const {
          0: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Posts')),
          1: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Submissions')),
        },
      );
    }
    return Row(
      children: [
        _tabButton('Posts', 0, uppercase: Adaptive.isAndroidNative),
        const SizedBox(width: 8),
        _tabButton('Submissions', 1, uppercase: Adaptive.isAndroidNative),
      ],
    );
  }

  Widget _tabButton(String label, int index, {bool uppercase = false}) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? AppColors.primary : Colors.transparent, width: 2)),
        ),
        child: Text(
          uppercase ? label.toUpperCase() : label,
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            letterSpacing: uppercase ? 0.4 : 0,
            color: selected ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _postsList(List<Post> posts) {
    if (posts.isEmpty) {
      return const _EmptyState(message: 'No posts in this batch right now.');
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: posts.length,
      itemBuilder: (context, i) => PostCard(post: posts[i], onTap: () => widget.onOpenPost(posts[i])),
    );
  }

  Widget _submissionsList(List<Post> posts) {
    if (posts.isEmpty) {
      return const _EmptyState(message: "You haven't submitted anything yet.");
    }
    final fmt = DateFormat('MMM d');
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: posts.length,
      itemBuilder: (context, i) {
        final post = posts[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: post.status == PostStatus.needsRevision ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusBadge(status: post.status),
                  const Spacer(),
                  Text('Submitted ${fmt.format(post.submittedAt!)}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(post.displayTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (post.status == PostStatus.needsRevision) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusNeedsRevisionBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text('"${post.feedback}"', style: const TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 13, color: AppColors.textDark)),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => widget.onOpenPost(post),
                  child: const Text('Revise submission →',
                      style: TextStyle(fontFamily: 'IBM Plex Sans', fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.primary)),
                ),
              ] else if (post.status == PostStatus.approved) ...[
                Text('Approved and scheduled by an admin.', style: Theme.of(context).textTheme.bodySmall),
              ] else ...[
                Text('Awaiting review — no action needed yet.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
